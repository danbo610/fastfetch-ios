#!/usr/bin/env bash

python3 - "$BUILD_DIR/src/detection/gpu/gpu_apple.c" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])

text = r'''#include "gpu.h"

#include <sys/sysctl.h>
#include <string.h>

static const char* detectIOSGPUName(void)
{
    char model[256];
    size_t len = sizeof(model);

    if (sysctlbyname("hw.machine", model, &len, NULL, 0) != 0)
        return NULL;

    /*
     * A4
     */
    if (
        strcmp(model, "iPhone1,1") == 0 ||
        strcmp(model, "iPhone1,2") == 0 ||
        strcmp(model, "iPhone3,1") == 0 ||
        strcmp(model, "iPhone3,2") == 0 ||
        strcmp(model, "iPhone3,3") == 0
    )
        return "PowerVR SGX535";

    /*
     * A5
     */
    if (strcmp(model, "iPhone4,1") == 0)
        return "PowerVR SGX543MP2";

    /*
     * A6
     */
    if (
        strcmp(model, "iPhone5,1") == 0 ||
        strcmp(model, "iPhone5,2") == 0 ||
        strcmp(model, "iPhone5,3") == 0 ||
        strcmp(model, "iPhone5,4") == 0
    )
        return "PowerVR SGX543MP3";

    /*
     * A7
     */
    if (
        strcmp(model, "iPhone6,1") == 0 ||
        strcmp(model, "iPhone6,2") == 0
    )
        return "PowerVR G6430";

    /*
     * A8
     */
    if (
        strcmp(model, "iPhone7,1") == 0 ||
        strcmp(model, "iPhone7,2") == 0
    )
        return "PowerVR GX6450";

    /*
     * A9
     */
    if (
        strcmp(model, "iPhone8,1") == 0 ||
        strcmp(model, "iPhone8,2") == 0 ||
        strcmp(model, "iPhone8,4") == 0
    )
        return "PowerVR GT7600";

    /*
     * A10 Fusion
     */
    if (
        strcmp(model, "iPhone9,1") == 0 ||
        strcmp(model, "iPhone9,2") == 0 ||
        strcmp(model, "iPhone9,3") == 0 ||
        strcmp(model, "iPhone9,4") == 0
    )
        return "PowerVR GT7600 Plus";

    /*
     * A11 Bionic
     */
    if (
        strcmp(model, "iPhone10,1") == 0 ||
        strcmp(model, "iPhone10,2") == 0 ||
        strcmp(model, "iPhone10,3") == 0 ||
        strcmp(model, "iPhone10,4") == 0 ||
        strcmp(model, "iPhone10,5") == 0 ||
        strcmp(model, "iPhone10,6") == 0
    )
        return "Apple Designed GPU (A11)";

    /*
     * A12 Bionic
     */
    if (
        strcmp(model, "iPhone11,2") == 0 ||
        strcmp(model, "iPhone11,4") == 0 ||
        strcmp(model, "iPhone11,6") == 0 ||
        strcmp(model, "iPhone11,8") == 0
    )
        return "Apple Designed GPU (A12)";

    /*
     * A13 Bionic
     */
    if (
        strcmp(model, "iPhone12,1") == 0 ||
        strcmp(model, "iPhone12,3") == 0 ||
        strcmp(model, "iPhone12,5") == 0 ||
        strcmp(model, "iPhone12,8") == 0
    )
        return "Apple Designed GPU (A13)";

    /*
     * A14 Bionic
     */
    if (
        strcmp(model, "iPhone13,1") == 0 ||
        strcmp(model, "iPhone13,2") == 0 ||
        strcmp(model, "iPhone13,3") == 0 ||
        strcmp(model, "iPhone13,4") == 0
    )
        return "Apple Designed GPU (A14)";

    /*
     * A15 Bionic
     */
    if (
        strcmp(model, "iPhone14,2") == 0 ||
        strcmp(model, "iPhone14,3") == 0 ||
        strcmp(model, "iPhone14,4") == 0 ||
        strcmp(model, "iPhone14,5") == 0
    )
        return "Apple Designed GPU (A15)";

    /*
     * A16 Bionic
     */
    if (
        strcmp(model, "iPhone14,7") == 0 ||
        strcmp(model, "iPhone14,8") == 0
    )
        return "Apple Designed GPU (A16)";

    /*
     * A17 Pro
     */
    if (
        strcmp(model, "iPhone16,1") == 0 ||
        strcmp(model, "iPhone16,2") == 0
    )
        return "Apple Designed GPU (A17 Pro)";

    /*
     * A18 / A18 Pro
     */
    if (
        strcmp(model, "iPhone17,1") == 0 ||
        strcmp(model, "iPhone17,2") == 0 ||
        strcmp(model, "iPhone17,3") == 0 ||
        strcmp(model, "iPhone17,4") == 0
    )
        return "Apple Designed GPU (A18)";

        /*
     * A4
     */
    if (strcmp(model, "iPad1,1") == 0)
        return "PowerVR SGX535";

    /*
     * A5
     */
    if (
        strcmp(model, "iPad2,1") == 0 ||
        strcmp(model, "iPad2,2") == 0 ||
        strcmp(model, "iPad2,3") == 0 ||
        strcmp(model, "iPad2,4") == 0 ||
        strcmp(model, "iPad2,5") == 0 ||
        strcmp(model, "iPad2,6") == 0 ||
        strcmp(model, "iPad2,7") == 0
    )
        return "PowerVR SGX543MP2";

    /*
     * A5X
     */
    if (
        strcmp(model, "iPad3,1") == 0 ||
        strcmp(model, "iPad3,2") == 0 ||
        strcmp(model, "iPad3,3") == 0
    )
        return "PowerVR SGX543MP4";

    /*
     * A6X
     */
    if (
        strcmp(model, "iPad3,4") == 0 ||
        strcmp(model, "iPad3,5") == 0 ||
        strcmp(model, "iPad3,6") == 0
    )
        return "PowerVR SGX554MP4";

    /*
     * A7
     */
    if (
        strcmp(model, "iPad4,1") == 0 ||
        strcmp(model, "iPad4,2") == 0 ||
        strcmp(model, "iPad4,3") == 0 ||
        strcmp(model, "iPad4,4") == 0 ||
        strcmp(model, "iPad4,5") == 0 ||
        strcmp(model, "iPad4,6") == 0 ||
        strcmp(model, "iPad4,7") == 0 ||
        strcmp(model, "iPad4,8") == 0 ||
        strcmp(model, "iPad4,9") == 0
    )
        return "PowerVR G6430";

    /*
     * A8
     */
    if (
        strcmp(model, "iPad5,1") == 0 ||
        strcmp(model, "iPad5,2") == 0
    )
        return "PowerVR GX6450";

    /*
     * A8X
     */
    if (
        strcmp(model, "iPad5,3") == 0 ||
        strcmp(model, "iPad5,4") == 0 ||
        strcmp(model, "iPad5,5") == 0 ||
        strcmp(model, "iPad5,6") == 0
    )
        return "PowerVR GXA6850";

    /*
     * A9
     */
    if (
        strcmp(model, "iPad6,11") == 0 ||
        strcmp(model, "iPad6,12") == 0 ||
        strcmp(model, "iPad6,1") == 0 ||
        strcmp(model, "iPad6,2") == 0
    )
        return "PowerVR GT7600";

    /*
     * A9X
     */
    if (
        strcmp(model, "iPad6,3") == 0 ||
        strcmp(model, "iPad6,4") == 0 ||
        strcmp(model, "iPad6,7") == 0 ||
        strcmp(model, "iPad6,8") == 0
    )
        return "PowerVR Series7XT (12-cluster)";

    /*
     * A10 Fusion
     */
    if (
        strcmp(model, "iPad7,5") == 0 ||
        strcmp(model, "iPad7,6") == 0 ||
        strcmp(model, "iPad7,11") == 0 ||
        strcmp(model, "iPad7,12") == 0
    )
        return "PowerVR GT7600 Plus";

    /*
     * A10X Fusion
     */
    if (
        strcmp(model, "iPad7,1") == 0 ||
        strcmp(model, "iPad7,2") == 0 ||
        strcmp(model, "iPad7,3") == 0 ||
        strcmp(model, "iPad7,4") == 0
    )
        return "PowerVR GT7600 Plus (G9)";

    /*
     * A12 Bionic
     */
    if (
        strcmp(model, "iPad11,1") == 0 ||
        strcmp(model, "iPad11,2") == 0 ||
        strcmp(model, "iPad11,3") == 0 ||
        strcmp(model, "iPad11,4") == 0 ||
        strcmp(model, "iPad11,6") == 0 ||
        strcmp(model, "iPad11,7") == 0
    )
        return "Apple Designed GPU (A12)";

    /*
     * A12X Bionic
     */
    if (
        strcmp(model, "iPad8,1") == 0 ||
        strcmp(model, "iPad8,2") == 0 ||
        strcmp(model, "iPad8,3") == 0 ||
        strcmp(model, "iPad8,4") == 0 ||
        strcmp(model, "iPad8,5") == 0 ||
        strcmp(model, "iPad8,6") == 0 ||
        strcmp(model, "iPad8,7") == 0 ||
        strcmp(model, "iPad8,8") == 0
    )
        return "Apple Designed GPU (A12X)";

    /*
     * A12Z Bionic
     */
    if (
        strcmp(model, "iPad8,9") == 0 ||
        strcmp(model, "iPad8,10") == 0 ||
        strcmp(model, "iPad8,11") == 0 ||
        strcmp(model, "iPad8,12") == 0
    )
        return "Apple Designed GPU (A12Z)";

    /*
     * A13 Bionic
     */
    if (
        strcmp(model, "iPad12,1") == 0 ||
        strcmp(model, "iPad12,2") == 0
    )
        return "Apple Designed GPU (A13)";

    /*
     * A14 Bionic
     */
    if (
        strcmp(model, "iPad13,1") == 0 ||
        strcmp(model, "iPad13,2") == 0 ||
        strcmp(model, "iPad13,18") == 0 ||
        strcmp(model, "iPad13,19") == 0 ||
        strcmp(model, "iPad13,20") == 0 ||
        strcmp(model, "iPad13,21") == 0
    )
        return "Apple Designed GPU (A14)";

    /*
     * A15 Bionic
     */
    if (
        strcmp(model, "iPad14,1") == 0 ||
        strcmp(model, "iPad14,2") == 0
    )
        return "Apple Designed GPU (A15)";

    /*
     * A16
     */
    if (
        strcmp(model, "iPad15,7") == 0 ||
        strcmp(model, "iPad15,8") == 0
    )
        return "Apple Designed GPU (A16)";

    /*
     * A17 Pro
     */
    if (
        strcmp(model, "iPad16,1") == 0 ||
        strcmp(model, "iPad16,2") == 0
    )
        return "Apple Designed GPU (A17 Pro)";

    /*
     * M1
     */
    if (
        strcmp(model, "iPad13,4") == 0 ||
        strcmp(model, "iPad13,5") == 0 ||
        strcmp(model, "iPad13,6") == 0 ||
        strcmp(model, "iPad13,7") == 0 ||
        strcmp(model, "iPad13,8") == 0 ||
        strcmp(model, "iPad13,9") == 0 ||
        strcmp(model, "iPad13,10") == 0 ||
        strcmp(model, "iPad13,11") == 0 ||
        strcmp(model, "iPad13,16") == 0 ||
        strcmp(model, "iPad13,17") == 0
    )
        return "Apple Designed GPU (M1)";

    /*
     * M2
     */
    if (
        strcmp(model, "iPad14,3") == 0 ||
        strcmp(model, "iPad14,4") == 0 ||
        strcmp(model, "iPad14,5") == 0 ||
        strcmp(model, "iPad14,6") == 0 ||
        strcmp(model, "iPad14,8") == 0 ||
        strcmp(model, "iPad14,9") == 0 ||
        strcmp(model, "iPad14,10") == 0 ||
        strcmp(model, "iPad14,11") == 0
    )
        return "Apple Designed GPU (M2)";

    /*
     * M3
     */
    if (
        strcmp(model, "iPad15,3") == 0 ||
        strcmp(model, "iPad15,4") == 0 ||
        strcmp(model, "iPad15,5") == 0 ||
        strcmp(model, "iPad15,6") == 0
    )
        return "Apple Designed GPU (M3)";

    /*
     * M4
     */
    if (
        strcmp(model, "iPad16,3") == 0 ||
        strcmp(model, "iPad16,4") == 0 ||
        strcmp(model, "iPad16,5") == 0 ||
        strcmp(model, "iPad16,6") == 0 ||
        strcmp(model, "iPad16,8") == 0 ||
        strcmp(model, "iPad16,9") == 0 ||
        strcmp(model, "iPad16,10") == 0 ||
        strcmp(model, "iPad16,11") == 0
    )
        return "Apple Designed GPU (M4)";

    /*
     * M5
     */
    if (
        strcmp(model, "iPad17,1") == 0 ||
        strcmp(model, "iPad17,2") == 0 ||
        strcmp(model, "iPad17,3") == 0 ||
        strcmp(model, "iPad17,4") == 0
    )
        return "Apple Designed GPU (M5)";

    return NULL;
}

const char* ffDetectGPUImpl(const FFGPUOptions* options, FFlist* gpus)
{
    (void) options;

   FFGPUResult* gpu = FF_LIST_ADD(FFGPUResult, *gpus);

ffStrbufInitS(&gpu->vendor, "Apple");
ffStrbufInit(&gpu->name);
ffStrbufInit(&gpu->driver);
ffStrbufInit(&gpu->platformApi);
ffStrbufInit(&gpu->memoryType);

gpu->type = FF_GPU_TYPE_INTEGRATED;
gpu->temperature = FF_GPU_TEMP_UNSET;
gpu->coreUsage = FF_GPU_CORE_USAGE_UNSET;
gpu->coreCount = FF_GPU_CORE_COUNT_UNSET;
gpu->frequency = FF_GPU_FREQUENCY_UNSET;
gpu->dedicated.total = FF_GPU_VMEM_SIZE_UNSET;
gpu->dedicated.used = FF_GPU_VMEM_SIZE_UNSET;
gpu->shared.total = FF_GPU_VMEM_SIZE_UNSET;
gpu->shared.used = FF_GPU_VMEM_SIZE_UNSET;
gpu->pcieSpeed = FF_GPU_PCIE_SPEED_UNSET;
gpu->index = FF_GPU_INDEX_UNSET;
gpu->deviceId = 0;

   const char* name = detectIOSGPUName();

   if (name != NULL)
       ffStrbufAppendS(&gpu->name, name);
   else
       ffStrbufAppendS(&gpu->name, "Apple GPU");

   return NULL;
}
'''

path.write_text(text)
PY

echo "Patched GPU Detection for iOS"