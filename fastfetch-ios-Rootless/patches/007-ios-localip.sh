#!/bin/bash

# Fastfetch iOS LocalIP detector
#
# This patch intentionally replaces the generated Linux detector with
# an Apple/BSD implementation. We keep the filename localip_linux.c so
# the existing Fastfetch CMake configuration does not need to change.
#
# build.sh regenerates build/src, then this patch installs the detector
# before compilation.

set -e

echo "[007-ios-localip] Installing Apple/iOS LocalIP detector..."

TARGET="$BUILD_DIR/src/detection/localip/localip_linux.c"

if [ ! -d "$(dirname "$TARGET")" ]; then
    echo "[007-ios-localip] ERROR: detector directory does not exist:"
    echo "  $(dirname "$TARGET")"
    exit 1
fi

cat > "$TARGET" <<'EOF'
/*
 * Fastfetch iOS / Apple LocalIP detector
 *
 * This file replaces the generated Linux implementation.
 *
 * iOS exposes the BSD networking APIs used here, including:
 *
 *   getifaddrs()
 *   struct ifaddrs
 *   sockaddr_in
 *   sockaddr_in6
 *   AF_LINK
 *
 * The detector deliberately implements the existing Fastfetch
 * ffDetectLocalIps() interface so the LocalIp module itself remains
 * completely unchanged.
 */

#include "detection/localip/localip.h"

#include <ifaddrs.h>
#include <net/if.h>
#include <net/if_dl.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>


/*
 * Convert an IPv4 sockaddr into a Fastfetch string.
 */
static void appendIPv4(FFstrbuf* buffer, const struct sockaddr* address)
{
    if (!address || address->sa_family != AF_INET)
        return;

    const struct sockaddr_in* addr =
        (const struct sockaddr_in*) address;

    char string[INET_ADDRSTRLEN];

    if (inet_ntop(AF_INET, &addr->sin_addr, string, sizeof(string)))
        ffStrbufAppendS(buffer, string);
}


/*
 * Convert an IPv6 sockaddr into a Fastfetch string.
 */
static void appendIPv6(FFstrbuf* buffer, const struct sockaddr* address)
{
    if (!address || address->sa_family != AF_INET6)
        return;

    const struct sockaddr_in6* addr =
        (const struct sockaddr_in6*) address;

    char string[INET6_ADDRSTRLEN];

    if (inet_ntop(AF_INET6, &addr->sin6_addr, string, sizeof(string)))
        ffStrbufAppendS(buffer, string);
}


/*
 * Extract the MAC address from an AF_LINK sockaddr.
 *
 * On Darwin:
 *
 *   sdl_type
 *   sdl_alen
 *   LLADDR()
 *
 * are used to access the link-layer address.
 */
static void appendMAC(FFstrbuf* buffer, const struct sockaddr* address)
{
    if (!address || address->sa_family != AF_LINK)
        return;

    const struct sockaddr_dl* sdl =
        (const struct sockaddr_dl*) address;

    if (sdl->sdl_alen != 6)
        return;

    const unsigned char* mac =
        (const unsigned char*) LLADDR(sdl);

    ffStrbufAppendF(
        buffer,
        "%02x:%02x:%02x:%02x:%02x:%02x",
        mac[0],
        mac[1],
        mac[2],
        mac[3],
        mac[4],
        mac[5]
    );
}


/*
 * Determine whether an IPv6 address is a link-local address.
 */
static bool isIPv6LinkLocal(const struct sockaddr* address)
{
    if (!address || address->sa_family != AF_INET6)
        return false;

    const struct sockaddr_in6* addr =
        (const struct sockaddr_in6*) address;

    return IN6_IS_ADDR_LINKLOCAL(&addr->sin6_addr);
}


/*
 * Determine whether an IPv6 address is loopback.
 */
static bool isIPv6Loopback(const struct sockaddr* address)
{
    if (!address || address->sa_family != AF_INET6)
        return false;

    const struct sockaddr_in6* addr =
        (const struct sockaddr_in6*) address;

    return IN6_IS_ADDR_LOOPBACK(&addr->sin6_addr);
}


/*
 * Return true if the interface should be considered loopback.
 */
static bool isLoopbackInterface(
    const char* name,
    unsigned int flags
)
{
    if (flags & IFF_LOOPBACK)
        return true;

    if (name && strcmp(name, "lo0") == 0)
        return true;

    return false;
}


/*
 * Find an already-created result for an interface.
 */
static FFLocalIpResult* findResult(
    FFlist* results,
    const char* interfaceName
)
{
    FF_LIST_FOR_EACH (FFLocalIpResult, item, *results)
    {
        if (ffStrbufCompS(&item->name, interfaceName) == 0)
            return item;
    }

    return NULL;
}


/*
 * Create a result for an interface.
 */
static FFLocalIpResult* createResult(
    FFlist* results,
    const char* interfaceName
)
{
    FFLocalIpResult* item =
        FF_LIST_ADD(FFLocalIpResult, *results);

    item->name = ffStrbufCreate();
    item->ipv4 = ffStrbufCreate();
    item->ipv6 = ffStrbufCreate();
    item->mac = ffStrbufCreate();
    item->flags = ffStrbufCreate();

    item->speed = 0;
    item->mtu = 0;
    item->defaultRoute = FF_LOCALIP_TYPE_IPV4_BIT;

    ffStrbufAppendS(&item->name, interfaceName);

    return item;
}


/*
 * Obtain interface MTU.
 *
 * Fastfetch's FFLocalIpResult::mtu is int32_t.
 *
 * iOS does not expose Linux's /sys/class/net interface, and MTU
 * reporting is not required for the initial iOS detector.
 *
 * Returning 0 means "unknown".
 */
static int32_t getInterfaceMTU(const char* interfaceName)
{
    (void) interfaceName;

    return 0;
}


/*
 * Format basic interface flags.
 *
 * This intentionally uses the Darwin IFF_* flags rather than
 * Linux-specific /proc or netlink information.
 */
static void appendFlags(
    FFstrbuf* buffer,
    unsigned int flags
)
{
    if (flags & IFF_UP)
        ffStrbufAppendS(buffer, "UP ");

    if (flags & IFF_RUNNING)
        ffStrbufAppendS(buffer, "RUNNING ");

    if (flags & IFF_LOOPBACK)
        ffStrbufAppendS(buffer, "LOOPBACK ");

    if (flags & IFF_BROADCAST)
        ffStrbufAppendS(buffer, "BROADCAST ");

    if (flags & IFF_MULTICAST)
        ffStrbufAppendS(buffer, "MULTICAST ");

    if (buffer->length > 0)
        ffStrbufTrimRightSpace(buffer);
}


/*
 * Main detector.
 */
const char* ffDetectLocalIps(
    const FFLocalIpOptions* options,
    FFlist* results
)
{
    struct ifaddrs* interfaces = NULL;

    if (getifaddrs(&interfaces) != 0)
    {
        return "getifaddrs() failed";
    }

    /*
     * Create an entry for every relevant interface.
     */
    for (
        struct ifaddrs* current = interfaces;
        current;
        current = current->ifa_next
    )
    {
        if (!current->ifa_name)
            continue;

        unsigned int flags =
            (unsigned int) current->ifa_flags;

        bool loopback =
            isLoopbackInterface(
                current->ifa_name,
                flags
            );

        if (
            loopback &&
            !(options->showType & FF_LOCALIP_TYPE_LOOP_BIT)
        )
        {
            continue;
        }

        FFLocalIpResult* item =
            findResult(
                results,
                current->ifa_name
            );

        if (!item)
        {
            item =
                createResult(
                    results,
                    current->ifa_name
                );
        }

        /*
         * Update interface flags.
         */
        if (
            options->showType &
            FF_LOCALIP_TYPE_FLAGS_BIT
        )
        {
            ffStrbufClear(&item->flags);

            appendFlags(
                &item->flags,
                flags
            );
        }

        /*
         * MTU is optional.
         */
        if (
            options->showType &
            FF_LOCALIP_TYPE_MTU_BIT
        )
        {
            item->mtu =
                getInterfaceMTU(
                    current->ifa_name
                );
        }

        /*
         * AF_INET = IPv4
         */
        if (
            current->ifa_addr &&
            current->ifa_addr->sa_family == AF_INET
        )
        {
            if (
                options->showType &
                FF_LOCALIP_TYPE_IPV4_BIT
            )
            {
                /*
                 * Keep the first IPv4 address.
                 */
                if (item->ipv4.length == 0)
                {
                    appendIPv4(
                        &item->ipv4,
                        current->ifa_addr
                    );
                }
            }

            continue;
        }

        /*
         * AF_INET6 = IPv6
         */
        if (
            current->ifa_addr &&
            current->ifa_addr->sa_family == AF_INET6
        )
        {
            if (
                options->showType &
                FF_LOCALIP_TYPE_IPV6_BIT
            )
            {
                bool linkLocal =
                    isIPv6LinkLocal(
                        current->ifa_addr
                    );

                bool loopbackIPv6 =
                    isIPv6Loopback(
                        current->ifa_addr
                    );

                if (
                    options->ipv6Type ==
                    FF_LOCALIP_IPV6_TYPE_AUTO
                )
                {
                    if (
                        !loopbackIPv6 &&
                        (
                            !linkLocal ||
                            (
                                options->showType &
                                FF_LOCALIP_TYPE_LOOP_BIT
                            )
                        )
                    )
                    {
                        if (item->ipv6.length == 0)
                        {
                            appendIPv6(
                                &item->ipv6,
                                current->ifa_addr
                            );
                        }
                    }
                }
                else if (
                    options->ipv6Type &
                    FF_LOCALIP_IPV6_TYPE_LLA_BIT
                )
                {
                    if (linkLocal)
                    {
                        if (item->ipv6.length == 0)
                        {
                            appendIPv6(
                                &item->ipv6,
                                current->ifa_addr
                            );
                        }
                    }
                }
            }

            continue;
        }

        /*
         * AF_LINK = Ethernet/Wi-Fi link layer.
         */
        if (
            current->ifa_addr &&
            current->ifa_addr->sa_family == AF_LINK
        )
        {
            if (
                options->showType &
                FF_LOCALIP_TYPE_MAC_BIT
            )
            {
                if (item->mac.length == 0)
                {
                    appendMAC(
                        &item->mac,
                        current->ifa_addr
                    );
                }
            }

            continue;
        }
    }

    freeifaddrs(interfaces);

    /*
     * Remove entries that contain no useful information.
     */
    for (uint32_t i = 0; i < results->length;)
    {
        FFLocalIpResult* item =
            FF_LIST_GET(
                FFLocalIpResult,
                *results,
                i
            );

        bool hasIPv4 =
            item->ipv4.length > 0;

        bool hasIPv6 =
            item->ipv6.length > 0;

        bool hasMAC =
            item->mac.length > 0;

        bool keep =
            hasIPv4 ||
            hasIPv6 ||
            hasMAC ||
            item->flags.length > 0 ||
            item->mtu > 0;

        if (!keep)
        {
            ffStrbufDestroy(&item->name);
            ffStrbufDestroy(&item->ipv4);
            ffStrbufDestroy(&item->ipv6);
            ffStrbufDestroy(&item->mac);
            ffStrbufDestroy(&item->flags);

            /*
             * Fastfetch's FFlist API requires the element size.
             */
            ffListRemoveAt(
                results,
                sizeof(FFLocalIpResult),
                i
            );

            continue;
        }

        ++i;
    }

    if (results->length == 0)
    {
        return "No network interfaces with usable addresses found";
    }

    return NULL;
}
EOF

echo "[007-ios-localip] Detector installed successfully."
echo "[007-ios-localip] Target:"
echo "  $TARGET"