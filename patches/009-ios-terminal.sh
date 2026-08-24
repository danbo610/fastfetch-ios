#!/usr/bin/env bash
set -euo pipefail

echo "[009-ios-terminal] Installing iOS Terminal detection..."

TERMINAL_C="$BUILD_DIR/src/detection/terminalshell/terminalshell_linux.c"

python3 - "$TERMINAL_C" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()

old = """    /*
     * iOS applications do not have a conventional terminal process.
     * Leave terminal detection empty rather than attempting Linux
     * process traversal.
     */

    return &result;
}"""

new = """    const char* termProgram = getenv("TERM_PROGRAM");

    if (termProgram && termProgram[0] != 0) {
        ffStrbufSetS(&result.processName, termProgram);
        ffStrbufSetS(&result.exe, termProgram);
        ffStrbufSetS(&result.prettyName, termProgram);
        result.exeName = result.exe.chars;
    }

    return &result;
}"""

if old not in text:
    print("[009-ios-terminal] ERROR: expected iOS terminal block not found")
    sys.exit(1)

path.write_text(text.replace(old, new, 1))
PY

echo "[009-ios-terminal] Terminal detection patched."
echo "[009-ios-terminal] TERM_PROGRAM is used dynamically."