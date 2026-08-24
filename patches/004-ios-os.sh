python3 - "$BUILD_DIR/src/detection/os/os_apple.m" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()

start = text.index("void ffDetectOSImpl(FFOSResult* os)")
text = text[:start] + r'''void ffDetectOSImpl(FFOSResult* os)
{
    char model[256];
    size_t len = sizeof(model);

    ffStrbufSetStatic(&os->id, "macos");
    ffStrbufSetStatic(&os->name, "iPhone OS");

    ffSysctlGetString("kern.osproductversion", &os->version);
    ffStrbufAppend(&os->versionID, &os->version);

    if (sysctlbyname("hw.machine", model, &len, NULL, 0) == 0)
        ffStrbufSetS(&os->prettyName, model);

    if (os->prettyName.length > 0)
    {
        FFstrbuf modelName;
        ffStrbufInit(&modelName);
        ffStrbufAppendF(&modelName, "%s %s %s",
            os->name.chars,
            os->version.chars,
            os->prettyName.chars);
        ffStrbufSet(&os->prettyName, &modelName);
        ffStrbufDestroy(&modelName);
    }
    else
    {
        ffStrbufSetF(&os->prettyName, "%s %s",
            os->name.chars,
            os->version.chars);
    }
}
'''

path.write_text(text)
PY

echo "Patched OS Identification for iOS"