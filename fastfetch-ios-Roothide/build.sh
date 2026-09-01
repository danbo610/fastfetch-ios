#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Config (roothide variant)
# -----------------------------
# roothide 差异(相对上游 fastfetch-ios-Rootless/build.sh):
#   1. 交叉编译 SDK 用本地 theos-roothide 自带的 iPhoneOS16.5.sdk(CLT 无 iOS SDK)
#   2. 安装布局用 jbroot 绝对路径(/usr/bin、/usr/local/share),不用 /var/jb 前缀
#   3. control 的 Architecture 为 iphoneos-arm64e(roothide Bootstrap 的 dpkg 架构标签),
#      Depends 标 roothide 虚拟包 —— 与 roothide 仓库的 bash 等包约定一致
#   4. 打包不用 dpkg-deb(本机未装),用 Theos 自带 dm.pl 等价替代
PACKAGE_NAME="com.seph3421.fastfetch"
PACKAGE_VERSION="2.67.1"
# 注意:保持 /tmp/fastfetch-ios 不变 —— 下方两段 python 补丁硬编码了该路径
DEB_DIR="/tmp/fastfetch-ios"
BUILD_DIR="${DEB_DIR}/build"
INSTALL_DIR="${DEB_DIR}/package"
ARCH="arm64"
DM_PL="$HOME/theos-roothide/bin/dm.pl"
FASTFETCH_COMMIT="1b1df2e731d5f59a635a1507dac421f3ab960e9d"

# -----------------------------
# Project output locations
# -----------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PATCHES_DIR="$SCRIPT_DIR/../fastfetch-ios-Rootless/patches"
PROJECT_BUILD_DIR="$SCRIPT_DIR/build"
FINAL_DEB="$SCRIPT_DIR/${PACKAGE_NAME}_${PACKAGE_VERSION}_iphoneos-arm64e_roothide.deb"

# SDK:优先 xcrun(CI/Xcode 环境原生 iPhoneOS SDK);失败回退 theos-roothide 自带 SDK(本机 CLT)
if SDK_VIA_XCRUN="$(xcrun --sdk iphoneos --show-sdk-path 2>/dev/null)" && [ -n "$SDK_VIA_XCRUN" ]; then
	SDKROOT="$SDK_VIA_XCRUN"
else
	SDKROOT="$HOME/theos-roothide/sdks/iPhoneOS16.5.sdk"
fi

# 本机无 Xcode 只有 CLT 时才固定 DEVELOPER_DIR(CI 上有 Xcode,不干预)
if [ ! -d /Applications/Xcode.app ] && [ -d /Library/Developer/CommandLineTools ]; then
	export DEVELOPER_DIR="/Library/Developer/CommandLineTools"
fi
# cmake 4.x 对老工程 mins 版本的兼容下限
export CMAKE_POLICY_VERSION_MINIMUM="3.5"

test -d "$SDKROOT" || { echo "SDK missing: $SDKROOT"; exit 1; }

# -----------------------------
# Clean previous builds
# -----------------------------
rm -rf "$DEB_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$INSTALL_DIR"

# -----------------------------
# Clone Fastfetch
# -----------------------------
git clone https://github.com/fastfetch-cli/fastfetch.git "$BUILD_DIR"
cd "$BUILD_DIR"
git checkout "$FASTFETCH_COMMIT"

# -----------------------------
# Patch for iOS - disable OpenCL and OpenGL
# -----------------------------
sed -i '' 's/#if !defined(FF_HAVE_OPENCL) && defined(__APPLE__) && defined(MAC_OS_X_VERSION_10_15)/#if 0 \/* disabled for iOS *\//' "$BUILD_DIR/src/detection/opencl/opencl.c"
sed -i '' 's/#elif __APPLE__/#elif 0 \/* disabled for iOS *\//' "$BUILD_DIR/src/detection/opengl/opengl_shared.c"
sed -i '' 's/if (system(unsafe_yyjson_get_str(val)) < 0)/if (0 \/* system() unavailable on iOS *\/)/' "$BUILD_DIR/src/options/general.c"
sed -i '' 's/#elif __APPLE__/#elif 0 \/\* disabled for iOS - no KextManager \*\//' "$BUILD_DIR/src/common/impl/kmod_apple.c"

# Stub out netif_apple.c (net/route.h not available on iOS)
# 注意:上游 1b1df2e 的 netif.c 需要 ImplV4/ImplV6 两个符号
cat >"$BUILD_DIR/src/common/impl/netif_apple.c" <<'EOFSTUB'
#include "../netif.h"

// iOS stub - net/route.h is not available
bool ffNetifGetDefaultRouteImplV4(FFNetifDefaultRouteResult* result) {
    (void)result;
    return false;
}

bool ffNetifGetDefaultRouteImplV6(FFNetifDefaultRouteResult* result) {
    (void)result;
    return false;
}
EOFSTUB

# Stub out kmod_apple.c (KextManager not available on iOS)
cat >"$BUILD_DIR/src/common/impl/kmod_apple.c" <<'EOFSTUB'
#include "common/kmod.h"

bool ffKmodLoaded(const char* modName)
{
    (void)modName;
    return false;
}
EOFSTUB

# Stub out processing_linux.c (sys/user.h not available on iOS)
cat >"$BUILD_DIR/src/common/impl/processing_linux.c" <<'EOFSTUB'
#include "../processing.h"
#include "../io.h"
#include <unistd.h>
#include <signal.h>
#include <spawn.h>
#include <sys/wait.h>

extern char** environ;

const char* ffProcessSpawn(char* const argv[], bool useStdErr, FFProcessHandle* outHandle)
{
    int pipes[2];
    if (pipe(pipes))
        return "pipe() failed";

    pid_t pid;
    posix_spawn_file_actions_t actions;
    posix_spawn_file_actions_init(&actions);
    posix_spawn_file_actions_addclose(&actions, pipes[0]);
    posix_spawn_file_actions_adddup2(&actions, pipes[1], useStdErr ? STDERR_FILENO : STDOUT_FILENO);
    posix_spawn_file_actions_addclose(&actions, pipes[1]);

    int result = posix_spawnp(&pid, argv[0], &actions, NULL, argv, environ);
    posix_spawn_file_actions_destroy(&actions);

    close(pipes[1]);

    if (result != 0)
    {
        close(pipes[0]);
        return "posix_spawnp() failed";
    }

    outHandle->pid = pid;
    outHandle->pipeRead = pipes[0];
    return NULL;
}

const char* ffProcessReadOutput(FFProcessHandle* handle, FFstrbuf* buffer)
{
    if (handle->pid <= 0)
        return "Invalid process";

    ffStrbufClear(buffer);
    char buf[4096];
    ssize_t nRead;
    while ((nRead = read(handle->pipeRead, buf, sizeof(buf))) > 0)
        ffStrbufAppendNS(buffer, (uint32_t)nRead, buf);

    close(handle->pipeRead);
    handle->pipeRead = -1;

    int status = 0;
    waitpid(handle->pid, &status, 0);
    handle->pid = 0;

    ffStrbufTrimRight(buffer, '\n');
    return NULL;
}

const char* ffProcessGetBasicInfoLinux(pid_t pid, FFstrbuf* name, pid_t* ppid, int32_t* tty)
{
    (void)pid;
    ffStrbufSetS(name, "unknown");
    if (ppid) *ppid = 0;
    if (tty) *tty = -1;
    return "Not supported on iOS";
}

// 上游 1b1df2e 的 initsystem_linux.c 需要这个符号
void ffProcessGetInfoLinux(pid_t pid, FFstrbuf* processName, FFstrbuf* exe, const char** exeName, FFstrbuf* exePath)
{
    (void)pid;
    if (processName) ffStrbufClear(processName);
    if (exe) ffStrbufClear(exe);
    if (exePath) ffStrbufClear(exePath);
    if (exeName) *exeName = NULL;
}
EOFSTUB

# Stub out battery_apple.c (IOKit power management not available on iOS)
cat >"$BUILD_DIR/src/detection/battery/battery_apple.c" <<'EOFSTUB'
#include "battery.h"

// iOS stub - IOKit power management headers not available
const char* ffDetectBattery(FFBatteryOptions* options, FFlist* results)
{
    (void)options;
    (void)results;
    return "Battery detection not supported on iOS";
}
EOFSTUB

# Stub out bluetooth_apple.m (IOBluetooth not available on iOS)
cat >"$BUILD_DIR/src/detection/bluetooth/bluetooth_apple.m" <<'EOFSTUB'
#include "bluetooth.h"

// iOS stub - IOBluetooth not available
const char* ffDetectBluetooth(FFBluetoothOptions* options, FFlist* devices)
{
    (void)options;
    (void)devices;
    return "Bluetooth detection not supported on iOS";
}
EOFSTUB

# Stub out bluetoothradio_apple.m
cat >"$BUILD_DIR/src/detection/bluetoothradio/bluetoothradio_apple.m" <<'EOFSTUB'
#include "bluetoothradio.h"

// iOS stub - IOBluetooth not available
const char* ffDetectBluetoothRadio(FFlist* devices)
{
    (void)devices;
    return "Bluetooth radio detection not supported on iOS";
}
EOFSTUB

# Stub out brightness_apple.c (DisplayServices not available on iOS)
cat >"$BUILD_DIR/src/detection/brightness/brightness_apple.c" <<'EOFSTUB'
#include "brightness.h"

// iOS stub - DisplayServices not available
const char* ffDetectBrightness(FFBrightnessOptions* options, FFlist* result)
{
    (void)options;
    (void)result;
    return "Brightness detection not supported on iOS";
}
EOFSTUB

# Stub out media_apple.m (MediaRemote not available on iOS)
cat >"$BUILD_DIR/src/detection/media/media_apple.m" <<'EOFSTUB'
#include "media.h"

// iOS stub - MediaRemote not available
void ffDetectMediaImpl(FFMediaResult* media, bool saveCover)
{
    (void)media;
    (void)saveCover;
    // No-op on iOS
}
EOFSTUB

# Stub out wifi_apple.m (CoreWLAN not available on iOS)
cat >"$BUILD_DIR/src/detection/wifi/wifi_apple.m" <<'EOFSTUB'
#include "wifi.h"

// iOS stub - CoreWLAN not available
const char* ffDetectWifi(FFlist* result)
{
    (void)result;
    return "WiFi detection not supported on iOS";
}
EOFSTUB

# Stub out opengl_apple.c
cat >"$BUILD_DIR/src/detection/opengl/opengl_apple.c" <<'EOFSTUB'
#include "opengl.h"

// iOS stub - OpenGL not available
const char* ffDetectOpenGL(FFOpenGLOptions* options, FFOpenGLResult* result)
{
    (void)options;
    (void)result;
    return "OpenGL detection not supported on iOS";
}
EOFSTUB

# Stub out dns_apple.c (SCDynamicStore not available on iOS)
cat >"$BUILD_DIR/src/detection/dns/dns_apple.c" <<'EOFSTUB'
#include "dns.h"

// iOS stub - SCDynamicStore not available
const char* ffDetectDNS(FFDNSOptions* options, FFlist* results)
{
    (void)options;
    (void)results;
    return "DNS detection not supported on iOS";
}
EOFSTUB

# Stub out physicaldisk_apple.c (IOBSD not available on iOS)
cat >"$BUILD_DIR/src/detection/physicaldisk/physicaldisk_apple.c" <<'EOFSTUB'
#include "physicaldisk.h"

// iOS stub - IOKit/IOBSD not available
const char* ffDetectPhysicalDisk(FFlist* result, FFPhysicalDiskOptions* options)
{
    (void)result;
    (void)options;
    return "Physical disk detection not supported on iOS";
}
EOFSTUB

# Stub out diskio_apple.c (IOBSD not available on iOS)
cat >"$BUILD_DIR/src/detection/diskio/diskio_apple.c" <<'EOFSTUB'
#include "diskio.h"

// iOS stub - IOKit/IOBSD not available
const char* ffDiskIOGetIoCounters(FFlist* result, FFDiskIOOptions* options)
{
    (void)result;
    (void)options;
    return "Disk IO counters not supported on iOS";
}
EOFSTUB

# Stub out font_apple.m (AppKit not available on iOS)
cat >"$BUILD_DIR/src/detection/font/font_apple.m" <<'EOFSTUB'
#include "font.h"

// iOS stub - AppKit not available
const char* ffDetectFontImpl(FFFontResult* result)
{
    (void)result;
    return "Font detection not supported on iOS";
}
EOFSTUB

# Stub out sound_apple.c (CoreAudio not fully available on iOS)
cat >"$BUILD_DIR/src/detection/sound/sound_apple.c" <<'EOFSTUB'
#include "sound.h"

// iOS stub - CoreAudio/AudioToolbox limited on iOS
const char* ffDetectSound(FFSoundOptions* options, FFlist* devices)
{
    (void)options;
    (void)devices;
    return "Sound detection not supported on iOS";
}
EOFSTUB

# iOS CPU detection
source "$PATCHES_DIR/001-ios-cpu.sh"

# iOS GPU detection
source "$PATCHES_DIR/002-ios-gpu.sh"

# iOS host detection
source "$PATCHES_DIR/003-ios-host.sh"

# iOS OS detection
source "$PATCHES_DIR/004-ios-os.sh"

# iOS Shell detection
source "$PATCHES_DIR/005-ios-shell.sh"

# iOS Package detection
source "$PATCHES_DIR/006-ios-packages.sh"
# roothide:dpkg-query 在 jbroot 的 /usr/bin(补丁里写的是 /var/jb/usr/bin)
sed -i '' 's|/var/jb/usr/bin/dpkg-query|/usr/bin/dpkg-query|' \
	"$BUILD_DIR/src/detection/packages/packages_apple.c"

# iOS Local IP detection
source "$PATCHES_DIR/007-ios-localip.sh"

# iOS Display detection(008 硬编码 SCRIPT_DIR 与 /var/jb 布局,先借位再纠正)
_SCRIPT_DIR_SAVE="$SCRIPT_DIR"
SCRIPT_DIR="$SCRIPT_DIR/../fastfetch-ios-Rootless"
source "$PATCHES_DIR/008-ios-display.sh"
SCRIPT_DIR="$_SCRIPT_DIR_SAVE"
mkdir -p "$INSTALL_DIR/usr/local/bin"
mv "$INSTALL_DIR/var/jb/usr/local/bin/get_res" "$INSTALL_DIR/usr/local/bin/get_res"
rm -rf "$INSTALL_DIR/var"
sed -i '' 's|/var/jb/usr/local/bin/get_res|/usr/local/bin/get_res|' \
	"$BUILD_DIR/src/detection/displayserver/displayserver_apple.c"

# iOS Terminal detection
source "$PATCHES_DIR/009-ios-terminal.sh"

# iOS Top detection
source "$PATCHES_DIR/010-ios-top.sh"

# Stub out gpu_apple.m (Metal/KextManager not available on iOS the same way)
cat >"$BUILD_DIR/src/detection/gpu/gpu_apple.m" <<'EOFSTUB'
#include "gpu.h"

// iOS stub - Metal/KextManager limited
const char* ffGpuDetectDriverVersion(FFlist* gpus)
{
    (void)gpus;
    return "GPU driver version not supported on iOS";
}

const char* ffGpuDetectMetal(FFlist* gpus)
{
    (void)gpus;
    return "Metal GPU detection not supported on iOS";
}
EOFSTUB

# Stub out tpm_apple.c (TPM not available on iOS)
cat >"$BUILD_DIR/src/detection/tpm/tpm_apple.c" <<'EOFSTUB'
#include "tpm.h"

// iOS stub - TPM not available
const char* ffDetectTPM(FFTPMResult* result)
{
    (void)result;
    return "TPM not supported on iOS";
}
EOFSTUB

# Stub out bios_apple.c (IOKit registry for BIOS info not available on iOS)
cat >"$BUILD_DIR/src/detection/bios/bios_apple.c" <<'EOFSTUB'
#include "bios.h"

// iOS stub - BIOS info not available
const char* ffDetectBios(FFBiosResult* bios)
{
    (void)bios;
    return "BIOS detection not supported on iOS";
}
EOFSTUB

# Stub out board_apple.c (IOKit registry for board info not available on iOS)
cat >"$BUILD_DIR/src/detection/board/board_apple.c" <<'EOFSTUB'
#include "board.h"

// iOS stub - Board info not available
const char* ffDetectBoard(FFBoardResult* result)
{
    (void)result;
    return "Board detection not supported on iOS";
}
EOFSTUB

# Stub out keyboard_apple.c (IOKit HID not available on iOS)
cat >"$BUILD_DIR/src/detection/keyboard/keyboard_apple.c" <<'EOFSTUB'
#include "keyboard.h"

// iOS stub - IOKit HID not available
const char* ffDetectKeyboard(FFlist* devices)
{
    (void)devices;
    return "Keyboard detection not supported on iOS";
}
EOFSTUB

# Stub out mouse_apple.c (IOKit HID not available on iOS)
cat >"$BUILD_DIR/src/detection/mouse/mouse_apple.c" <<'EOFSTUB'
#include "mouse.h"

// iOS stub - IOKit HID not available
const char* ffDetectMouse(FFlist* devices)
{
    (void)devices;
    return "Mouse detection not supported on iOS";
}
EOFSTUB

# Stub out gamepad_apple.c (IOKit HID not available on iOS)
cat >"$BUILD_DIR/src/detection/gamepad/gamepad_apple.c" <<'EOFSTUB'
#include "gamepad.h"

// iOS stub - IOKit HID not available
const char* ffDetectGamepad(FFlist* devices)
{
    (void)devices;
    return "Gamepad detection not supported on iOS";
}
EOFSTUB

# Stub out poweradapter_apple.c (IOKit PS not available on iOS)
cat >"$BUILD_DIR/src/detection/poweradapter/poweradapter_apple.c" <<'EOFSTUB'
#include "poweradapter.h"

// iOS stub - IOKit power not available
const char* ffDetectPowerAdapter(FFlist* results)
{
    (void)results;
    return "Power adapter detection not supported on iOS";
}
EOFSTUB

# Stub out netio_apple.c (net/if_mib.h not available on iOS)
cat >"$BUILD_DIR/src/detection/netio/netio_apple.c" <<'EOFSTUB'
#include "netio.h"

// iOS stub - if_mib not available
const char* ffNetIOGetIoCounters(FFlist* result, FFNetIOOptions* options)
{
    (void)result;
    (void)options;
    return "Network IO counters not supported on iOS";
}
EOFSTUB

# Stub out camera_apple.m (AVCaptureDeviceTypeExternalUnknown not available on iOS)
cat >"$BUILD_DIR/src/detection/camera/camera_apple.m" <<'EOFSTUB'
#include "camera.h"

// iOS stub - external camera type not available
const char* ffDetectCamera(FFlist* result)
{
    (void)result;
    return "Camera detection not supported on iOS";
}
EOFSTUB

# Stub out osascript.m (AppKit not available on iOS)
cat >"$BUILD_DIR/src/common/apple/osascript.m" <<'EOFSTUB'
#include "osascript.h"

// iOS stub - AppleScript/AppKit not available
bool ffOsascript(const char* input, FFstrbuf* result)
{
    (void)input;
    (void)result;
    return false;
}
EOFSTUB

# Patch FFPlatform_unix.c for iOS
python3 - <<'PY'
from pathlib import Path

p = Path("/tmp/fastfetch-ios/build/src/common/impl/FFPlatform_unix.c")
s = p.read_text()

# Disable macOS-only _NSGetExecutablePath block for iOS
start = s.find("#elif defined(__APPLE__)")
end = s.find("#elif defined(__FreeBSD__) || defined(__NetBSD__)", start)

if start != -1 and end != -1:
    s = s[:start] + """#elif defined(__APPLE__)

    size_t exePathLen = 0; /* iOS: executable path unavailable */

""" + s[end:]

s = s.replace(
    "#ifdef __APPLE__",
    "#if 0 /* disabled for iOS - no libproc */"
)

s = s.replace(
    "int exePathLen = proc_pidpath((int) getpid(), exePath, sizeof(exePath));",
    "size_t exePathLen = 0; /* iOS fallback - no proc_pidpath */"
)

s = s.replace(
    """#elif defined(__APPLE__)

    uint32_t exePathLen = sizeof(exePath);

    if (_NSGetExecutablePath(exePath, &exePathLen) == 0) {
        exePathLen = (uint32_t) strlen(exePath);
    } else {
        exePathLen = 0;
    }""",
    """#elif defined(__APPLE__)

    size_t exePathLen = 0; /* iOS: executable path unavailable */"""
)

if "#include <paths.h>" in s and "#include <sys/sysctl.h>" not in s:
    s = s.replace(
        "#include <paths.h>",
        "#include <paths.h>\n#include <sys/sysctl.h>"
    )

p.write_text(s)
PY
# Add sysctl.h include for iOS (needed for other functions)
sed -i '' 's/#include <paths.h>/#include <paths.h>\n#include <sys\/sysctl.h>/' "$BUILD_DIR/src/common/impl/FFPlatform_unix.c"

# Patch CMakeLists.txt to remove macOS-only frameworks for iOS
sed -i '' 's/-framework Cocoa/-framework UIKit/' "$BUILD_DIR/CMakeLists.txt"
sed -i '' 's/-framework CoreWLAN//' "$BUILD_DIR/CMakeLists.txt"
sed -i '' 's/-framework IOBluetooth//' "$BUILD_DIR/CMakeLists.txt"
sed -i '' 's/-framework OpenGL//' "$BUILD_DIR/CMakeLists.txt"
sed -i '' 's/-framework OpenCL//' "$BUILD_DIR/CMakeLists.txt"
sed -i '' 's/-weak_framework DisplayServices//' "$BUILD_DIR/CMakeLists.txt"
sed -i '' 's/-weak_framework MediaRemote//' "$BUILD_DIR/CMakeLists.txt"
sed -i '' 's/-weak_framework CoreDisplay//' "$BUILD_DIR/CMakeLists.txt"

# Patch codec_apple.c for iOS
python3 - <<'PY'
from pathlib import Path

p = Path("/tmp/fastfetch-ios/build/src/detection/codec/codec_apple.c")
s = p.read_text()

old = """#ifdef MAC_OS_VERSION_11_0
        if (VTRegisterSupplementalVideoDecoderIfAvailable) {
            VTRegisterSupplementalVideoDecoderIfAvailable(codec.codec);
        }
#endif
"""

new = """#if !defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
        if (VTRegisterSupplementalVideoDecoderIfAvailable) {
            VTRegisterSupplementalVideoDecoderIfAvailable(codec.codec);
        }
#endif
"""

if old in s:
    s = s.replace(old, new)
    p.write_text(s)
    print("Patched codec_apple.c for iOS")
else:
    print("WARNING: codec block not found")
PY

# Stub out wallpaper_apple.m for iOS (AppKit is macOS-only)
cat >"$BUILD_DIR/src/detection/wallpaper/wallpaper_apple.m" <<'EOFSTUB'
#include "wallpaper.h"

const char* ffDetectWallpaper(FFstrbuf* result)
{
    ffStrbufClear(result);
    return "Wallpaper detection not supported on iOS";
}
EOFSTUB

# Stub out wm_apple.m (libproc/window manager APIs not available on iOS)
cat >"$BUILD_DIR/src/detection/wm/wm_apple.m" <<'EOFSTUB'
#include "wm.h"

const char* ffDetectWMPlugin(FFstrbuf* pluginName)
{
    (void)pluginName;
    return "Window manager detection not supported on iOS";
}

const char* ffDetectWMVersion(const FFstrbuf* wmName, FFstrbuf* result, FFWMOptions* options)
{
    (void)wmName;
    (void)result;
    (void)options;
    return "Window manager detection not supported on iOS";
}
EOFSTUB

# -----------------------------
# Set cross-compile environment (CLT clang + theos-roothide iPhoneOS SDK)
# -----------------------------
export CC=clang
export CXX=clang++
export CFLAGS="-isysroot $SDKROOT -arch $ARCH -O2"
export CXXFLAGS="$CFLAGS"
export LDFLAGS="-isysroot $SDKROOT -arch $ARCH"

# -----------------------------
# Configure CMake
# -----------------------------
mkdir "$BUILD_DIR/source"
cd "$BUILD_DIR/source"
cmake .. \
	-DCMAKE_SYSTEM_NAME=iOS \
	-DCMAKE_SYSTEM_PROCESSOR=arm64 \
	-DCMAKE_OSX_SYSROOT="$SDKROOT" \
	-DCMAKE_OSX_ARCHITECTURES="$ARCH" \
	-DCMAKE_OSX_DEPLOYMENT_TARGET="12.0" \
	-DCMAKE_INSTALL_PREFIX=/usr/local \
	-DCMAKE_C_COMPILER="$CC" \
	-DCMAKE_CXX_COMPILER="$CXX" \
	-DCMAKE_C_FLAGS="$CFLAGS" \
	-DCMAKE_CXX_FLAGS="$CXXFLAGS" \
	-DBUILD_SHARED_LIBS=OFF \
	-DENABLE_OPENCL=OFF \
	-DENABLE_VULKAN=OFF \
	-DENABLE_IMAGEMAGICK=OFF \
	-DENABLE_CHAFA=OFF \
	-DENABLE_WORDEXP=OFF \
	-DENABLE_LTO=OFF

# -----------------------------
# Build
# -----------------------------
cmake --build . --target fastfetch

# -----------------------------
# Install into roothide (jbroot-relative) layout
#   /usr/bin/fastfetch                 <- 在默认 PATH 上,直接敲 fastfetch 可用
#   /usr/local/share/fastfetch/presets <- 预设,与编译期 CMAKE_INSTALL_PREFIX 一致
# -----------------------------
mkdir -p "$INSTALL_DIR/usr/bin"
cp "$BUILD_DIR/source/fastfetch.app/fastfetch" "$INSTALL_DIR/usr/bin/fastfetch"

# Sign the binary with ldid for jailbroken iOS (ad-hoc signature)
cat >"/tmp/ent.plist" <<'ENTEOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>platform-application</key>
    <true/>
    <key>com.apple.private.security.container-required</key>
    <false/>
</dict>
</plist>
ENTEOF

if command -v ldid &>/dev/null; then
	ldid -S/tmp/ent.plist "$INSTALL_DIR/usr/bin/fastfetch"
	ldid -S/tmp/ent.plist "$INSTALL_DIR/usr/local/bin/get_res"
	echo "Signed with ldid"
else
	echo "ERROR: ldid not found"; exit 1
fi

# Copy presets and other data
mkdir -p "$INSTALL_DIR/usr/local/share/fastfetch"
cp -r "$BUILD_DIR/presets" "$INSTALL_DIR/usr/local/share/fastfetch/" 2>/dev/null || true

# -----------------------------
# Create Debian structure (roothide 约定:Architecture iphoneos-arm64e)
# -----------------------------
DEBIAN_DIR="${INSTALL_DIR}/DEBIAN"
mkdir -p "$DEBIAN_DIR"

cat >"$DEBIAN_DIR/control" <<EOF
Package: $PACKAGE_NAME
Name: Fastfetch (roothide)
Version: $PACKAGE_VERSION
Section: Terminal_Support
Priority: optional
Architecture: iphoneos-arm64e
Depiction: https://seph3421.github.io/repo/depictions/?p=com.seph3421.fastfetch
Maintainer: Joseph <https://github.com/seph3421>
Depends: roothide (>= 0.0.7)
Description: Un-Official Native iOS port for Fastfetch (roothide build).
EOF

# -----------------------------
# Build the .deb(有 dpkg-deb 用 dpkg-deb,否则用 Theos 的 dm.pl 等价替代)
# -----------------------------
if command -v dpkg-deb &>/dev/null; then
	dpkg-deb --build "$INSTALL_DIR" "$FINAL_DEB"
else
	perl "$DM_PL" -b -Zgzip "$INSTALL_DIR" "$FINAL_DEB"
fi

echo "Done! .deb is at:"
echo "$FINAL_DEB"

# -----------------------------
# Preserve the completed build workspace
# -----------------------------
mkdir -p "$PROJECT_BUILD_DIR"
rm -rf "$PROJECT_BUILD_DIR/fastfetch-roothide"
mv "$DEB_DIR" "$PROJECT_BUILD_DIR/fastfetch-roothide"

echo "Build workspace moved to:"
echo "$PROJECT_BUILD_DIR/fastfetch-roothide"
