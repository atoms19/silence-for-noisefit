# Existing phone cache inspection

The user supplied an ADB listing of `/sdcard/Android/data/com.noisefit/cache/`, containing `appLogs/` and `watchface.zip`. The user also ran `adb shell run-as com.noisefit ls -lah cache`, which returned `package not debuggable`. This confirms that `run-as` cannot access this installed app's private cache. It does not establish whether root access exists through another mechanism.

The copied file is preserved at [watchface.zip](../analysis/device-cache/watchface.zip). Offline inspection found:

| Property | Finding |
| --- | --- |
| Size | 578,740 bytes |
| Archive format | Not a standard ZIP, despite the filename |
| First four bytes | `22 aa ff 00` |
| Embedded JSON | Begins at byte offset 28; top-level keys `HEAD`, `WATCH`, `PREVIEW` |
| Layout evidence | Watch/preview counts and image/text layout fields |
| Assessment | Watch-face resource; not identified as a firmware update package |

The hash, binary header and decoded layout are recorded in [watchface-inspection.json](../analysis/device-cache/watchface-inspection.json). The assessment is based on content rather than filename. No firmware version, CPU identification or image signing policy can be concluded from this file.

No obvious OTA package appears in the supplied external cache listing. This does not rule out copies under the app's external files directory or private storage. Private TouchGUI `TGOTA` directories remain uninspected, and the SDK normally cleans those directories on success or handled failure.

The next available offline evidence is the existing `appLogs` directory and a listing of `/sdcard/Android/data/com.noisefit/files/`. Logs might retain update URLs, filenames, version or selected-device metadata even after firmware bytes are deleted; their presence is not guaranteed. The app should remain offline during preservation. No backend request or wearable communication was performed.

## Subsequent external files result

The user supplied a listing of `/sdcard/Android/data/com.noisefit/files/` showing only `.` and `..`; that directory is empty. The copied app logs were also inspected without finding firmware URLs or OTA activity; see [chapter 14](14-device-log-findings.md). Private storage contents remain unknown.
