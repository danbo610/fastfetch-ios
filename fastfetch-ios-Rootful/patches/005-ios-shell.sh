#!/bin/bash

set -e

SHELL_SRC="$BUILD_DIR/src/detection/terminalshell/terminalshell_linux.c"

cat > "$SHELL_SRC" <<'IOS_SHELL'

#include "terminalshell.h"

#include "common/strutil.h"

#include <unistd.h>
#include <stdlib.h>
#include <string.h>

const FFShellResult* ffDetectShell(void)
{
    static FFShellResult result;
    static bool initialized = false;

    if (initialized)
        return &result;

    initialized = true;

    ffStrbufInit(&result.processName);
    ffStrbufInit(&result.exe);
    ffStrbufInit(&result.exePath);
    ffStrbufInit(&result.prettyName);
    ffStrbufInit(&result.version);

    result.pid = (uint32_t) getpid();
    result.ppid = (uint32_t) getppid();
    result.tty = isatty(STDIN_FILENO) ? STDIN_FILENO : -1;

    const char* shell = getenv("SHELL");

    if (shell == NULL || shell[0] == '\0')
        return &result;

    ffStrbufSetS(&result.exe, shell);
    ffStrbufSetS(&result.exePath, shell);

    const char* name = strrchr(shell, '/');
    name = name ? name + 1 : shell;

    result.exeName = name;

    ffStrbufSetS(&result.processName, name);
    ffStrbufSetS(&result.prettyName, name);

    if (strcmp(name, "zsh") == 0) {
        const char* version = getenv("ZSH_VERSION");
        if (version)
            ffStrbufSetS(&result.version, version);
    } else if (strcmp(name, "bash") == 0) {
        const char* version = getenv("BASH_VERSION");
        if (version)
            ffStrbufSetS(&result.version, version);
    } else if (strcmp(name, "fish") == 0) {
        const char* version = getenv("FISH_VERSION");
        if (version)
            ffStrbufSetS(&result.version, version);
    }

    return &result;
}

const FFTerminalResult* ffDetectTerminal(void)
{
    static FFTerminalResult result;
    static bool initialized = false;

    if (initialized)
        return &result;

    initialized = true;

    ffStrbufInit(&result.processName);
    ffStrbufInit(&result.exe);
    ffStrbufInit(&result.prettyName);
    ffStrbufInit(&result.exePath);
    ffStrbufInit(&result.version);
    ffStrbufInit(&result.tty);

    result.pid = 0;
    result.ppid = 0;

    /*
     * iOS applications do not have a conventional terminal process.
     * Leave terminal detection empty rather than attempting Linux
     * process traversal.
     */

    return &result;
}

IOS_SHELL

echo "Patched terminal shell for iOS"