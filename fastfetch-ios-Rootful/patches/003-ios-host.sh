#!/bin/bash

cat >"$BUILD_DIR/src/detection/host/host_apple.c" <<'EOFHOST'
#include "host.h"

#include <sys/sysctl.h>
#include <string.h>

static const char* detectIOSHostName(void)
{
    char model[256];
    size_t len = sizeof(model);

    if (sysctlbyname("hw.machine", model, &len, NULL, 0) != 0)
        return NULL;

    /* iPhone */
    if (strcmp(model, "iPhone1,1") == 0)
        return "iPhone";

    /* iPhone 3G */
    if (strcmp(model, "iPhone1,2") == 0)
        return "iPhone 3G";

    /* iPhone 3GS */
    if (strcmp(model, "iPhone2,1") == 0)
        return "iPhone 3GS";

    /* iPhone 4 */
    if (strcmp(model, "iPhone3,1") == 0 ||
        strcmp(model, "iPhone3,2") == 0 ||
        strcmp(model, "iPhone3,3") == 0)
        return "iPhone 4";

    /* iPhone 4S */
    if (strcmp(model, "iPhone4,1") == 0)
        return "iPhone 4S";

    /* iPhone 5 */
    if (strcmp(model, "iPhone5,1") == 0 ||
        strcmp(model, "iPhone5,2") == 0)
        return "iPhone 5";

    /* iPhone 5c */
    if (strcmp(model, "iPhone5,3") == 0 ||
        strcmp(model, "iPhone5,4") == 0)
        return "iPhone 5c";

    /* iPhone 5s */
    if (strcmp(model, "iPhone6,1") == 0 ||
        strcmp(model, "iPhone6,2") == 0)
        return "iPhone 5s";

    /* iPhone 6 Plus */
    if (strcmp(model, "iPhone7,1") == 0)
        return "iPhone 6 Plus";

    /* iPhone 6 */
    if (strcmp(model, "iPhone7,2") == 0)
        return "iPhone 6";

    /* iPhone 6s */
    if (strcmp(model, "iPhone8,1") == 0)
        return "iPhone 6s";

    /* iPhone 6s Plus */
    if (strcmp(model, "iPhone8,2") == 0)
        return "iPhone 6s Plus";

    /* iPhone SE (1st generation) */
    if (strcmp(model, "iPhone8,4") == 0)
        return "iPhone SE (1st generation)";

    /* iPhone 7 */
    if (strcmp(model, "iPhone9,1") == 0 ||
        strcmp(model, "iPhone9,3") == 0)
        return "iPhone 7";

    /* iPhone 7 Plus */
    if (strcmp(model, "iPhone9,2") == 0 ||
        strcmp(model, "iPhone9,4") == 0)
        return "iPhone 7 Plus";

    /* iPhone 8 */
    if (strcmp(model, "iPhone10,1") == 0 ||
        strcmp(model, "iPhone10,4") == 0)
        return "iPhone 8";

    /* iPhone 8 Plus */
    if (strcmp(model, "iPhone10,2") == 0 ||
        strcmp(model, "iPhone10,5") == 0)
        return "iPhone 8 Plus";

    /* iPhone X */
    if (strcmp(model, "iPhone10,3") == 0 ||
        strcmp(model, "iPhone10,6") == 0)
        return "iPhone X";

    /* iPhone XR */
    if (strcmp(model, "iPhone11,8") == 0)
        return "iPhone XR";

    /* iPhone XS */
    if (strcmp(model, "iPhone11,2") == 0)
        return "iPhone XS";

    /* iPhone XS Max */
    if (strcmp(model, "iPhone11,4") == 0 ||
        strcmp(model, "iPhone11,6") == 0)
        return "iPhone XS Max";

    /* iPhone 11 */
    if (strcmp(model, "iPhone12,1") == 0)
        return "iPhone 11";

    /* iPhone 11 Pro */
    if (strcmp(model, "iPhone12,3") == 0)
        return "iPhone 11 Pro";

    /* iPhone 11 Pro Max */
    if (strcmp(model, "iPhone12,5") == 0)
        return "iPhone 11 Pro Max";

    /* iPhone SE (2nd generation) */
    if (strcmp(model, "iPhone12,8") == 0)
        return "iPhone SE (2nd generation)";

    /* iPhone 12 mini */
    if (strcmp(model, "iPhone13,1") == 0)
        return "iPhone 12 mini";

    /* iPhone 12 */
    if (strcmp(model, "iPhone13,2") == 0)
        return "iPhone 12";

    /* iPhone 12 Pro */
    if (strcmp(model, "iPhone13,3") == 0)
        return "iPhone 12 Pro";

    /* iPhone 12 Pro Max */
    if (strcmp(model, "iPhone13,4") == 0)
        return "iPhone 12 Pro Max";

    /* iPhone 13 Pro */
    if (strcmp(model, "iPhone14,2") == 0)
        return "iPhone 13 Pro";

    /* iPhone 13 Pro Max */
    if (strcmp(model, "iPhone14,3") == 0)
        return "iPhone 13 Pro Max";

    /* iPhone 13 mini */
    if (strcmp(model, "iPhone14,4") == 0)
        return "iPhone 13 mini";

    /* iPhone 13 */
    if (strcmp(model, "iPhone14,5") == 0)
        return "iPhone 13";

    /* iPhone SE (3rd generation) */
    if (strcmp(model, "iPhone14,6") == 0)
        return "iPhone SE (3rd generation)";

    /* iPhone 14 */
    if (strcmp(model, "iPhone14,7") == 0)
        return "iPhone 14";

    /* iPhone 14 Plus */
    if (strcmp(model, "iPhone14,8") == 0)
        return "iPhone 14 Plus";

    /* iPhone 14 Pro */
    if (strcmp(model, "iPhone15,2") == 0)
        return "iPhone 14 Pro";

    /* iPhone 14 Pro Max */
    if (strcmp(model, "iPhone15,3") == 0)
        return "iPhone 14 Pro Max";

    /* iPhone 15 */
    if (strcmp(model, "iPhone15,4") == 0)
        return "iPhone 15";

    /* iPhone 15 Plus */
    if (strcmp(model, "iPhone15,5") == 0)
        return "iPhone 15 Plus";

    /* iPhone 15 Pro */
    if (strcmp(model, "iPhone16,1") == 0)
        return "iPhone 15 Pro";

    /* iPhone 15 Pro Max */
    if (strcmp(model, "iPhone16,2") == 0)
        return "iPhone 15 Pro Max";

    /* iPhone 16 Pro */
    if (strcmp(model, "iPhone17,1") == 0)
        return "iPhone 16 Pro";

    /* iPhone 16 Pro Max */
    if (strcmp(model, "iPhone17,2") == 0)
        return "iPhone 16 Pro Max";

    /* iPhone 16 */
    if (strcmp(model, "iPhone17,3") == 0)
        return "iPhone 16";

    /* iPhone 16 Plus */
    if (strcmp(model, "iPhone17,4") == 0)
        return "iPhone 16 Plus";

        /* iPad */
    if (strcmp(model, "iPad1,1") == 0)
        return "iPad";

    /* iPad 2 */
    if (strcmp(model, "iPad2,1") == 0 ||
        strcmp(model, "iPad2,2") == 0 ||
        strcmp(model, "iPad2,3") == 0 ||
        strcmp(model, "iPad2,4") == 0)
        return "iPad 2";

    /* iPad 3rd generation */
    if (strcmp(model, "iPad3,1") == 0 ||
        strcmp(model, "iPad3,2") == 0 ||
        strcmp(model, "iPad3,3") == 0)
        return "iPad (3rd generation)";

    /* iPad 4th generation */
    if (strcmp(model, "iPad3,4") == 0 ||
        strcmp(model, "iPad3,5") == 0 ||
        strcmp(model, "iPad3,6") == 0)
        return "iPad (4th generation)";

    /* iPad Air */
    if (strcmp(model, "iPad4,1") == 0 ||
        strcmp(model, "iPad4,2") == 0 ||
        strcmp(model, "iPad4,3") == 0)
        return "iPad Air";

    /* iPad Air 2 */
    if (strcmp(model, "iPad5,3") == 0 ||
        strcmp(model, "iPad5,4") == 0)
        return "iPad Air 2";

    /* iPad 5th generation */
    if (strcmp(model, "iPad6,11") == 0 ||
        strcmp(model, "iPad6,12") == 0)
        return "iPad (5th generation)";

    /* iPad 6th generation */
    if (strcmp(model, "iPad7,5") == 0 ||
        strcmp(model, "iPad7,6") == 0)
        return "iPad (6th generation)";

    /* iPad 7th generation */
    if (strcmp(model, "iPad7,11") == 0 ||
        strcmp(model, "iPad7,12") == 0)
        return "iPad (7th generation)";

    /* iPad 8th generation */
    if (strcmp(model, "iPad11,6") == 0 ||
        strcmp(model, "iPad11,7") == 0)
        return "iPad (8th generation)";

    /* iPad 9th generation */
    if (strcmp(model, "iPad12,1") == 0 ||
        strcmp(model, "iPad12,2") == 0)
        return "iPad (9th generation)";

    /* iPad 10th generation */
    if (strcmp(model, "iPad13,18") == 0 ||
        strcmp(model, "iPad13,19") == 0)
        return "iPad (10th generation)";

    /* iPad mini */
    if (strcmp(model, "iPad2,5") == 0 ||
        strcmp(model, "iPad2,6") == 0 ||
        strcmp(model, "iPad2,7") == 0)
        return "iPad mini";

    /* iPad mini 2 */
    if (strcmp(model, "iPad4,4") == 0 ||
        strcmp(model, "iPad4,5") == 0 ||
        strcmp(model, "iPad4,6") == 0)
        return "iPad mini 2";

    /* iPad mini 3 */
    if (strcmp(model, "iPad4,7") == 0 ||
        strcmp(model, "iPad4,8") == 0 ||
        strcmp(model, "iPad4,9") == 0)
        return "iPad mini 3";

    /* iPad mini 4 */
    if (strcmp(model, "iPad5,1") == 0 ||
        strcmp(model, "iPad5,2") == 0)
        return "iPad mini 4";

    /* iPad mini 5 */
    if (strcmp(model, "iPad11,1") == 0 ||
        strcmp(model, "iPad11,2") == 0)
        return "iPad mini 5";

    /* iPad mini 6 */
    if (strcmp(model, "iPad14,1") == 0 ||
        strcmp(model, "iPad14,2") == 0)
        return "iPad mini 6";

    /* iPad mini 7 */
    if (strcmp(model, "iPad16,1") == 0 ||
        strcmp(model, "iPad16,2") == 0)
        return "iPad mini 7";

    /* iPad Air 3 */
    if (strcmp(model, "iPad11,3") == 0 ||
        strcmp(model, "iPad11,4") == 0)
        return "iPad Air 3";

    /* iPad Air 4 */
    if (strcmp(model, "iPad13,1") == 0 ||
        strcmp(model, "iPad13,2") == 0)
        return "iPad Air 4";

    /* iPad Air 5 */
    if (strcmp(model, "iPad13,16") == 0 ||
        strcmp(model, "iPad13,17") == 0)
        return "iPad Air 5";

    /* iPad Air 11-inch (M2) */
    if (strcmp(model, "iPad14,8") == 0 ||
        strcmp(model, "iPad14,9") == 0)
        return "iPad Air 11-inch (M2)";

    /* iPad Air 13-inch (M2) */
    if (strcmp(model, "iPad14,10") == 0 ||
        strcmp(model, "iPad14,11") == 0)
        return "iPad Air 13-inch (M2)";

    /* iPad Air 11-inch (M3) */
    if (strcmp(model, "iPad15,4") == 0 ||
        strcmp(model, "iPad15,5") == 0)
        return "iPad Air 11-inch (M3)";

    /* iPad Air 13-inch (M3) */
    if (strcmp(model, "iPad15,6") == 0 ||
        strcmp(model, "iPad15,7") == 0)
        return "iPad Air 13-inch (M3)";

    /* iPad Pro 9.7-inch */
    if (strcmp(model, "iPad6,3") == 0 ||
        strcmp(model, "iPad6,4") == 0)
        return "iPad Pro 9.7-inch";

    /* iPad Pro 10.5-inch */
    if (strcmp(model, "iPad7,3") == 0 ||
        strcmp(model, "iPad7,4") == 0)
        return "iPad Pro 10.5-inch";

    /* iPad Pro 11-inch (1st generation) */
    if (strcmp(model, "iPad8,1") == 0 ||
        strcmp(model, "iPad8,2") == 0 ||
        strcmp(model, "iPad8,3") == 0 ||
        strcmp(model, "iPad8,4") == 0)
        return "iPad Pro 11-inch (1st generation)";

    /* iPad Pro 12.9-inch (1st generation) */
    if (strcmp(model, "iPad6,7") == 0 ||
        strcmp(model, "iPad6,8") == 0)
        return "iPad Pro 12.9-inch (1st generation)";

    /* iPad Pro 12.9-inch (2nd generation) */
    if (strcmp(model, "iPad7,1") == 0 ||
        strcmp(model, "iPad7,2") == 0)
        return "iPad Pro 12.9-inch (2nd generation)";

    /* iPad Pro 11-inch (2nd generation) */
    if (strcmp(model, "iPad8,9") == 0 ||
        strcmp(model, "iPad8,10") == 0)
        return "iPad Pro 11-inch (2nd generation)";

    /* iPad Pro 12.9-inch (3rd generation) */
    if (strcmp(model, "iPad8,5") == 0 ||
        strcmp(model, "iPad8,6") == 0 ||
        strcmp(model, "iPad8,7") == 0 ||
        strcmp(model, "iPad8,8") == 0)
        return "iPad Pro 12.9-inch (3rd generation)";

    /* iPad Pro 11-inch (3rd generation) */
    if (strcmp(model, "iPad13,4") == 0 ||
        strcmp(model, "iPad13,5") == 0 ||
        strcmp(model, "iPad13,6") == 0 ||
        strcmp(model, "iPad13,7") == 0)
        return "iPad Pro 11-inch (3rd generation)";

    /* iPad Pro 12.9-inch (5th generation) */
    if (strcmp(model, "iPad13,8") == 0 ||
        strcmp(model, "iPad13,9") == 0 ||
        strcmp(model, "iPad13,10") == 0 ||
        strcmp(model, "iPad13,11") == 0)
        return "iPad Pro 12.9-inch (5th generation)";

    /* iPad Pro 11-inch (4th generation) */
    if (strcmp(model, "iPad14,3") == 0 ||
        strcmp(model, "iPad14,4") == 0)
        return "iPad Pro 11-inch (4th generation)";

    /* iPad Pro 12.9-inch (6th generation) */
    if (strcmp(model, "iPad14,5") == 0 ||
        strcmp(model, "iPad14,6") == 0)
        return "iPad Pro 12.9-inch (6th generation)";

    /* iPad Pro 11-inch (M4) */
    if (strcmp(model, "iPad16,3") == 0 ||
        strcmp(model, "iPad16,4") == 0)
        return "iPad Pro 11-inch (M4)";

    /* iPad Pro 13-inch (M4) */
    if (strcmp(model, "iPad16,5") == 0 ||
        strcmp(model, "iPad16,6") == 0)
        return "iPad Pro 13-inch (M4)";

    /* iPad Pro 11-inch (M5) */
    if (strcmp(model, "iPad17,1") == 0 ||
        strcmp(model, "iPad17,2") == 0)
        return "iPad Pro 11-inch (M5)";

    /* iPad Pro 13-inch (M5) */
    if (strcmp(model, "iPad17,3") == 0 ||
        strcmp(model, "iPad17,4") == 0)
        return "iPad Pro 13-inch (M5)";

    /* Unknown iPhone identifier */
    return NULL;
}

const char* ffDetectHost(FFHostResult* host)
{
    const char* name = detectIOSHostName();

    if (name != NULL)
    {
        ffStrbufAppendS(&host->name, name);
    }
    else
    {
        char model[256];
        size_t len = sizeof(model);

        if (sysctlbyname("hw.machine", model, &len, NULL, 0) == 0)
            ffStrbufAppendS(&host->name, model);
    }

    return NULL;
}
EOFHOST

echo "Patched Host Identification for iOS"