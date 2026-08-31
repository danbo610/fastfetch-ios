#!/bin/sh

python3 - "$BUILD_DIR/src/detection/cpu/cpu_apple.c" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()

marker = 'const char* ffDetectCPUImpl(const FFCPUOptions* options, FFCPUResult* cpu) {'

helper = r'''
static const char* detectIOSCPUName(void)
{
    char model[256];
    size_t len = sizeof(model);

    if (sysctlbyname("hw.machine", model, &len, NULL, 0) != 0)
        return NULL;

    /* iPhone */
    if (strcmp(model, "iPhone1,1") == 0 ||
        strcmp(model, "iPhone1,2") == 0)
        return "Samsung S5L8900";

    if (strcmp(model, "iPhone2,1") == 0)
        return "Samsung S5PC100";

    if (strcmp(model, "iPhone3,1") == 0 ||
        strcmp(model, "iPhone3,2") == 0 ||
        strcmp(model, "iPhone3,3") == 0)
        return "Apple A4";

    if (strcmp(model, "iPhone4,1") == 0)
        return "Apple A5";

    if (strcmp(model, "iPhone5,1") == 0 ||
        strcmp(model, "iPhone5,2") == 0 ||
        strcmp(model, "iPhone5,3") == 0 ||
        strcmp(model, "iPhone5,4") == 0)
        return "Apple A6";

    if (strcmp(model, "iPhone6,1") == 0 ||
        strcmp(model, "iPhone6,2") == 0)
        return "Apple A7";

    if (strcmp(model, "iPhone7,1") == 0 ||
        strcmp(model, "iPhone7,2") == 0)
        return "Apple A8";

    if (strcmp(model, "iPhone8,1") == 0 ||
        strcmp(model, "iPhone8,2") == 0 ||
        strcmp(model, "iPhone8,4") == 0)
        return "Apple A9";

    if (strcmp(model, "iPhone9,1") == 0 ||
        strcmp(model, "iPhone9,2") == 0 ||
        strcmp(model, "iPhone9,3") == 0 ||
        strcmp(model, "iPhone9,4") == 0)
        return "Apple A10 Fusion";

    if (strcmp(model, "iPhone10,1") == 0 ||
        strcmp(model, "iPhone10,2") == 0 ||
        strcmp(model, "iPhone10,3") == 0 ||
        strcmp(model, "iPhone10,4") == 0 ||
        strcmp(model, "iPhone10,5") == 0 ||
        strcmp(model, "iPhone10,6") == 0)
        return "Apple A11 Bionic";

    if (strcmp(model, "iPhone11,2") == 0 ||
        strcmp(model, "iPhone11,4") == 0 ||
        strcmp(model, "iPhone11,6") == 0 ||
        strcmp(model, "iPhone11,8") == 0)
        return "Apple A12 Bionic";

    if (strcmp(model, "iPhone12,1") == 0 ||
        strcmp(model, "iPhone12,3") == 0 ||
        strcmp(model, "iPhone12,5") == 0 ||
        strcmp(model, "iPhone12,8") == 0)
        return "Apple A13 Bionic";

    if (strcmp(model, "iPhone13,1") == 0 ||
        strcmp(model, "iPhone13,2") == 0 ||
        strcmp(model, "iPhone13,3") == 0 ||
        strcmp(model, "iPhone13,4") == 0)
        return "Apple A14 Bionic";

    if (strcmp(model, "iPhone14,2") == 0 ||
        strcmp(model, "iPhone14,3") == 0 ||
        strcmp(model, "iPhone14,4") == 0 ||
        strcmp(model, "iPhone14,5") == 0)
        return "Apple A15 Bionic";

    if (strcmp(model, "iPhone14,6") == 0 ||
        strcmp(model, "iPhone14,7") == 0 ||
        strcmp(model, "iPhone14,8") == 0)
        return "Apple A15 Bionic";

    if (strcmp(model, "iPhone15,2") == 0 ||
        strcmp(model, "iPhone15,3") == 0)
        return "Apple A16 Bionic";

    if (strcmp(model, "iPhone15,4") == 0 ||
        strcmp(model, "iPhone15,5") == 0)
        return "Apple A16 Bionic";

    if (strcmp(model, "iPhone16,1") == 0 ||
        strcmp(model, "iPhone16,2") == 0)
        return "Apple A17 Pro";

    if (strcmp(model, "iPhone17,1") == 0 ||
        strcmp(model, "iPhone17,2") == 0 ||
        strcmp(model, "iPhone17,3") == 0 ||
        strcmp(model, "iPhone17,4") == 0)
        return "Apple A18";

    if (strcmp(model, "iPhone17,5") == 0)
        return "Apple A18";

    if (strcmp(model, "iPhone17,6") == 0 ||
        strcmp(model, "iPhone17,7") == 0)
        return "Apple A18 Pro";

        /* iPad 1 */
    if (strcmp(model, "iPad1,1") == 0)
        return "Apple A4";

    /* iPad 2 */
    if (strcmp(model, "iPad2,1") == 0 ||
        strcmp(model, "iPad2,2") == 0 ||
        strcmp(model, "iPad2,3") == 0 ||
        strcmp(model, "iPad2,4") == 0)
        return "Apple A5";

    /* iPad 3 */
    if (strcmp(model, "iPad3,1") == 0 ||
        strcmp(model, "iPad3,2") == 0 ||
        strcmp(model, "iPad3,3") == 0)
        return "Apple A5X";

    /* iPad 4 */
    if (strcmp(model, "iPad3,4") == 0 ||
        strcmp(model, "iPad3,5") == 0 ||
        strcmp(model, "iPad3,6") == 0)
        return "Apple A6X";

    /* iPad Air */
    if (strcmp(model, "iPad4,1") == 0 ||
        strcmp(model, "iPad4,2") == 0 ||
        strcmp(model, "iPad4,3") == 0)
        return "Apple A7";

    /* iPad mini 2 */
    if (strcmp(model, "iPad4,4") == 0 ||
        strcmp(model, "iPad4,5") == 0 ||
        strcmp(model, "iPad4,6") == 0)
        return "Apple A7";

    /* iPad mini 3 */
    if (strcmp(model, "iPad4,7") == 0 ||
        strcmp(model, "iPad4,8") == 0 ||
        strcmp(model, "iPad4,9") == 0)
        return "Apple A7";

    /* iPad Air 2 */
    if (strcmp(model, "iPad5,3") == 0 ||
        strcmp(model, "iPad5,4") == 0)
        return "Apple A8X";

    /* iPad mini 4 */
    if (strcmp(model, "iPad5,1") == 0 ||
        strcmp(model, "iPad5,2") == 0)
        return "Apple A8";

    /* iPad Pro 12.9-inch (1st generation) */
    if (strcmp(model, "iPad6,7") == 0 ||
        strcmp(model, "iPad6,8") == 0)
        return "Apple A9X";

    /* iPad Pro 9.7-inch */
    if (strcmp(model, "iPad6,3") == 0 ||
        strcmp(model, "iPad6,4") == 0)
        return "Apple A9X";

    /* iPad 5 */
    if (strcmp(model, "iPad6,11") == 0 ||
        strcmp(model, "iPad6,12") == 0)
        return "Apple A9";

    /* iPad Pro 12.9-inch (2nd generation) */
    if (strcmp(model, "iPad7,1") == 0 ||
        strcmp(model, "iPad7,2") == 0)
        return "Apple A10X Fusion";

    /* iPad Pro 10.5-inch */
    if (strcmp(model, "iPad7,3") == 0 ||
        strcmp(model, "iPad7,4") == 0)
        return "Apple A10X Fusion";

    /* iPad 6 */
    if (strcmp(model, "iPad7,5") == 0 ||
        strcmp(model, "iPad7,6") == 0)
        return "Apple A10 Fusion";

    /* iPad 7 */
    if (strcmp(model, "iPad7,11") == 0 ||
        strcmp(model, "iPad7,12") == 0)
        return "Apple A10 Fusion";

    /* iPad Pro 11-inch (1st generation) */
    if (strcmp(model, "iPad8,1") == 0 ||
        strcmp(model, "iPad8,2") == 0 ||
        strcmp(model, "iPad8,3") == 0 ||
        strcmp(model, "iPad8,4") == 0)
        return "Apple A12X Bionic";

    /* iPad Pro 12.9-inch (3rd generation) */
    if (strcmp(model, "iPad8,5") == 0 ||
        strcmp(model, "iPad8,6") == 0 ||
        strcmp(model, "iPad8,7") == 0 ||
        strcmp(model, "iPad8,8") == 0)
        return "Apple A12X Bionic";

    /* iPad Air 3 */
    if (strcmp(model, "iPad11,3") == 0 ||
        strcmp(model, "iPad11,4") == 0)
        return "Apple A12 Bionic";

    /* iPad mini 5 */
    if (strcmp(model, "iPad11,1") == 0 ||
        strcmp(model, "iPad11,2") == 0)
        return "Apple A12 Bionic";

    /* iPad 8 */
    if (strcmp(model, "iPad11,6") == 0 ||
        strcmp(model, "iPad11,7") == 0)
        return "Apple A12 Bionic";

    /* iPad Pro 11-inch (2nd generation) */
    if (strcmp(model, "iPad8,9") == 0 ||
        strcmp(model, "iPad8,10") == 0)
        return "Apple A12Z Bionic";

    /* iPad Pro 12.9-inch (4th generation) */
    if (strcmp(model, "iPad8,11") == 0 ||
        strcmp(model, "iPad8,12") == 0)
        return "Apple A12Z Bionic";

    /* iPad Air 4 */
    if (strcmp(model, "iPad13,1") == 0 ||
        strcmp(model, "iPad13,2") == 0)
        return "Apple A14 Bionic";

    /* iPad 9 */
    if (strcmp(model, "iPad12,1") == 0 ||
        strcmp(model, "iPad12,2") == 0)
        return "Apple A13 Bionic";

    /* iPad Pro 11-inch (3rd generation) */
    if (strcmp(model, "iPad13,4") == 0 ||
        strcmp(model, "iPad13,5") == 0 ||
        strcmp(model, "iPad13,6") == 0 ||
        strcmp(model, "iPad13,7") == 0)
        return "Apple M1";

    /* iPad Pro 12.9-inch (5th generation) */
    if (strcmp(model, "iPad13,8") == 0 ||
        strcmp(model, "iPad13,9") == 0 ||
        strcmp(model, "iPad13,10") == 0 ||
        strcmp(model, "iPad13,11") == 0)
        return "Apple M1";

    /* iPad mini 6 */
    if (strcmp(model, "iPad14,1") == 0 ||
        strcmp(model, "iPad14,2") == 0)
        return "Apple A15 Bionic";

    /* iPad Air 5 */
    if (strcmp(model, "iPad13,16") == 0 ||
        strcmp(model, "iPad13,17") == 0)
        return "Apple M1";

    /* iPad 10 */
    if (strcmp(model, "iPad13,18") == 0 ||
        strcmp(model, "iPad13,19") == 0)
        return "Apple A14 Bionic";

    /* iPad Pro 11-inch (4th generation) */
    if (strcmp(model, "iPad14,3") == 0 ||
        strcmp(model, "iPad14,4") == 0)
        return "Apple M2";

    /* iPad Pro 12.9-inch (6th generation) */
    if (strcmp(model, "iPad14,5") == 0 ||
        strcmp(model, "iPad14,6") == 0)
        return "Apple M2";

    /* iPad Air 11-inch (M2) */
    if (strcmp(model, "iPad14,8") == 0 ||
        strcmp(model, "iPad14,9") == 0)
        return "Apple M2";

    /* iPad Air 13-inch (M2) */
    if (strcmp(model, "iPad14,10") == 0 ||
        strcmp(model, "iPad14,11") == 0)
        return "Apple M2";

    /* iPad Pro 11-inch (M4) */
    if (strcmp(model, "iPad16,3") == 0 ||
        strcmp(model, "iPad16,4") == 0)
        return "Apple M4";

    /* iPad Pro 13-inch (M4) */
    if (strcmp(model, "iPad16,5") == 0 ||
        strcmp(model, "iPad16,6") == 0)
        return "Apple M4";

    /* iPad mini (A17 Pro) */
    if (strcmp(model, "iPad16,1") == 0 ||
        strcmp(model, "iPad16,2") == 0)
        return "Apple A17 Pro";

    /* iPad Air 11-inch (M3) */
    if (strcmp(model, "iPad15,7") == 0)
        return "Apple M3";

    /* iPad Air 13-inch (M3) */
    if (strcmp(model, "iPad15,8") == 0)
        return "Apple M3";

    /* iPad Air 11-inch (M4) */
    if (strcmp(model, "iPad17,1") == 0 ||
        strcmp(model, "iPad17,2") == 0)
        return "Apple M4";

    /* iPad Air 13-inch (M4) */
    if (strcmp(model, "iPad17,3") == 0 ||
        strcmp(model, "iPad17,4") == 0)
        return "Apple M4";

    return NULL;
}

'''

if 'detectIOSCPUName' not in text:
    text = text.replace(marker, helper + marker)

old = '''    if (ffSysctlGetString("machdep.cpu.brand_string", &cpu->name) != nullptr) {
        return "sysctlbyname(machdep.cpu.brand_string) failed";
    }'''

new = '''    const char* iosCPU = detectIOSCPUName();

    if (iosCPU != NULL) {
        ffStrbufAppendS(&cpu->name, iosCPU);
    } else if (ffSysctlGetString("machdep.cpu.brand_string", &cpu->name) != nullptr) {
        return "sysctlbyname(machdep.cpu.brand_string) failed";
    }'''

if old not in text:
    raise SystemExit("ERROR: CPU brand detection block not found")

text = text.replace(old, new, 1)

path.write_text(text)
PY

echo "Patched CPU Detection for iOS"