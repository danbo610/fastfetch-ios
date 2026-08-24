#!/usr/bin/env bash
set -euo pipefail

echo "[008-ios-display] Installing iOS Display implementation..."

DISPLAY_SERVER_DIR="$BUILD_DIR/src/detection/displayserver"
DISPLAY_SERVER_C="$DISPLAY_SERVER_DIR/displayserver_apple.c"

GET_RES_SOURCE="$SCRIPT_DIR/patches/get_res"
GET_RES_DEST="$INSTALL_DIR/var/jb/usr/local/bin/get_res"

mkdir -p "$DISPLAY_SERVER_DIR"

cat > "$DISPLAY_SERVER_C" <<'EOF_DISPLAYSERVER'
#include "displayserver.h"

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>

#define IOS_DISPLAY_HELPER "/var/jb/usr/local/bin/get_res"

static bool iosReadResolution(
    uint32_t* width,
    uint32_t* height,
    double* scale
)
{
    *width = 0;
    *height = 0;
    *scale = 0.0;

    int pipefd[2];

    if(pipe(pipefd) != 0)
        return false;

    pid_t pid = fork();

    if(pid < 0)
    {
        close(pipefd[0]);
        close(pipefd[1]);
        return false;
    }

    if(pid == 0)
    {
        close(pipefd[0]);

        dup2(pipefd[1], STDOUT_FILENO);

        close(pipefd[1]);

        execl(
            IOS_DISPLAY_HELPER,
            IOS_DISPLAY_HELPER,
            (char*)NULL
        );

        _exit(127);
    }

    close(pipefd[1]);

    char output[256];

    ssize_t total = 0;

    while(total < (ssize_t)sizeof(output) - 1)
    {
        ssize_t bytes = read(
            pipefd[0],
            output + total,
            sizeof(output) - 1 - (size_t)total
        );

        if(bytes <= 0)
            break;

        total += bytes;
    }

    close(pipefd[0]);

    output[total] = '\0';

    int status = 0;

    if(waitpid(pid, &status, 0) != pid)
        return false;

    if(!WIFEXITED(status))
        return false;

    if(WEXITSTATUS(status) != 0)
        return false;

    unsigned int parsedWidth = 0;
    unsigned int parsedHeight = 0;
    double parsedScale = 0.0;

    int parsed = sscanf(
        output,
        "%ux%u %lf",
        &parsedWidth,
        &parsedHeight,
        &parsedScale
    );

    if(parsed != 3)
        return false;

    if(parsedWidth == 0 || parsedHeight == 0)
        return false;

    if(parsedScale <= 0.0)
        return false;

    *width = (uint32_t)parsedWidth;
    *height = (uint32_t)parsedHeight;
    *scale = parsedScale;

    return true;
}

static void detectDisplays(FFDisplayServerResult* ds)
{
    uint32_t width = 0;
    uint32_t height = 0;
    double scale = 0.0;

    if(!iosReadResolution(&width, &height, &scale))
        return;

    FF_STRBUF_AUTO_DESTROY name = ffStrbufCreate();

    ffStrbufAppendS(
        &name,
        "iOS Display"
    );

    uint32_t dpi =
        (uint32_t)(scale * 96.0 + 0.5);

    FFDisplayResult* result = ffdsAppendDisplay(
        ds,
        width,
        height,
        0.0,
        (uint32_t)(scale * 96.0 + 0.5),
        width,
        height,
        0.0,
        0,
        &name,
        FF_DISPLAY_TYPE_BUILTIN,
        true,
        0,
        0,
        0,
        "UIKit"
    );

    if(!result)
        return;

    uint32_t scaledWidth =
        (result->width * 96 + result->dpi / 2)
        / result->dpi;

    uint32_t scaledHeight =
        (result->height * 96 + result->dpi / 2)
        / result->dpi;

    (void)scaledWidth;
    (void)scaledHeight;
}

void ffConnectDisplayServerImpl(FFDisplayServerResult* ds)
{
    ffListInit(&ds->displays);

    detectDisplays(ds);
}
EOF_DISPLAYSERVER

echo "[008-ios-display] Display server implementation installed."

if grep -qE 'CoreGraphics|CGDirectDisplay|CVDisplayLink|IOKit' "$DISPLAY_SERVER_C"; then
    echo "[008-ios-display] ERROR: old macOS display APIs remain"
    exit 1
fi

echo "[008-ios-display] Installing get_res helper..."

if [ ! -f "$GET_RES_SOURCE" ]; then
    echo "[008-ios-display] ERROR: get_res not found:"
    echo "  $GET_RES_SOURCE"
    exit 1
fi

mkdir -p "$INSTALL_DIR/var/jb/usr/local/bin"

cp "$GET_RES_SOURCE" "$GET_RES_DEST"

chmod 755 "$GET_RES_DEST"

echo "[008-ios-display] get_res installed:"
echo "  $GET_RES_DEST"

echo "[008-ios-display] Display implementation complete."