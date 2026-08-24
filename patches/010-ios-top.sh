#!/usr/bin/env bash
set -euo pipefail

echo "[010-ios-top] Installing iOS Top stub..."

TOP_C="$BUILD_DIR/src/detection/top/top_apple.c"

cat > "$TOP_C" <<'EOF_TOP'
#include "top.h"

const char* ffTopGetProcessSnapshot(FFlist* snapshots)
{
    (void)snapshots;
    return "Process detection not supported on iOS";
}
EOF_TOP

echo "[010-ios-top] Replaced:"
echo "  $TOP_C"
echo "[010-ios-top] libproc/sysctl process detection disabled."
