#!/bin/sh

python3 - "$BUILD_DIR/src/detection/packages/packages_apple.c" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])

path.write_text(r'''#include "packages.h"

#include <stdio.h>
#include <unistd.h>
#include <spawn.h>
#include <sys/wait.h>
#include <fcntl.h>

extern char **environ;

static uint32_t countDpkgPackages(void)
{
    int pipefd[2];

    if (pipe(pipefd) != 0)
        return 0;

    pid_t pid;

    char *argv[] = {
        "/usr/bin/dpkg-query",
        "-f",
        "\\n",
        "-W",
        NULL
    };

    posix_spawn_file_actions_t actions;
    posix_spawn_file_actions_init(&actions);

    posix_spawn_file_actions_adddup2(
        &actions,
        pipefd[1],
        STDOUT_FILENO
    );

    posix_spawn_file_actions_addclose(
        &actions,
        pipefd[0]
    );

    int ret = posix_spawn(
        &pid,
        "/usr/bin/dpkg-query",
        &actions,
        NULL,
        argv,
        environ
    );

    posix_spawn_file_actions_destroy(&actions);

    close(pipefd[1]);

    if (ret != 0)
    {
        close(pipefd[0]);
        return 0;
    }

    char buffer[4096];
    ssize_t bytes;

    uint32_t newlines = 0;

    while ((bytes = read(pipefd[0], buffer, sizeof(buffer))) > 0)
    {
        for (ssize_t i = 0; i < bytes; ++i)
        {
            if (buffer[i] == '\n')
                ++newlines;
        }
    }

    close(pipefd[0]);

    int status = 0;
    waitpid(pid, &status, 0);

    return newlines;
}

void ffDetectPackagesImpl(FFPackagesResult* result, FFPackagesOptions* options)
{
    (void) options;

    result->dpkg = countDpkgPackages();
}
''')

print("Patched Package Detection for IOS")
PY