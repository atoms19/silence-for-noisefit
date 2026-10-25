# Bundled Python wearable SDK

## Why this is useful

The base APK contains readable `.py` source alongside `.pyc`, so part of the embedded wearable SDK can be studied directly. Its README says the SDK Python is separated to keep Android and iOS implementations synchronized. The surrounding native split includes `libpython3.11.so` and `libpersimwear.so`. Java `com.realthread.persimwear.api.Firmware` calls named Python services through `ExecService.execPyLpc`.

Sources: [SDK README](../analysis/base/assets/python/README.md), [Python asset root](../analysis/base/assets/python/), [Firmware:1](../analysis/smali/classes5/com/realthread/persimwear/api/Firmware.smali#L1), [native inventory](../analysis/native-inventory.txt).

Confirmed service names include:

```text
service_ota_get_version
service_ota_set_upgrade_state
service_ota_get_upgrade_state
service_ota_update
service_ota_quit
```

The update wrapper passes local package path and retry information; the Java class registers a callback. These are local Python service calls, not HTTP API routes. Their presence does not prove that the small band's selected adapter uses them.

## Module boundaries

| Module | Responsibility visible in source |
| --- | --- |
| `mcf` | Transport framing, protocol type and device-to-device layer |
| `urpc` | RPC client/services including remote file and flash access |
| `wearable/boot` | Wearable service/bootstrap support |
| `wearable/files` and `wearservice/files` | File push, pull, deletion and service wrappers |
| `wearable/settings.py`, `contacts.py`, `notification.py`, `dial.py` | Configuration and resource helpers |
| `wearable/tsdb.py`, `tsdb_to_sqlite3` | Wearable time-series retrieval/conversion helpers |
| `wearable/ota` | Package loading, step execution, progress and OTA service entry points |

For example, [mcf/trans/packet.py](../analysis/base/assets/python/mcf/trans/packet.py) serializes a transport protocol byte followed by payload. This is only that layer's framing; it is not proof the complete BLE frame is a one-byte header.

## OTA package loading

[ota/load.py](../analysis/base/assets/python/wearable/ota/load.py) checks a local package, clears/prepares an extraction directory, opens it as ZIP, extracts contents and discovers loader modules. `V1Load.py` and `V2Load.py` support different package descriptions. **No real update package was supplied or downloaded.** References to `rtthread.rbl` in loader comments describe a possible layout, not a recovered band firmware image.

[V2Load.py](../analysis/base/assets/python/wearable/ota/load/V2Load.py) actually looks for `config.json`, despite some comments mentioning `resource.json`. It requires `steps` to be a list and `version`/`project` to be strings; it fills local paths relative to the extracted `ota` directory where the expected path fields exist. It exposes `deviceNeedReboot` with default true and `allowQuitHalfway` with default false. Its example layout includes remote system resources and a downloadable RT-Thread `.rbl` component.

A conceptual description—not a working firmware package—is:

```json
{
  "project": "<device project>",
  "version": "<package version>",
  "deviceNeedReboot": true,
  "allowQuitHalfway": false,
  "steps": [{"uses": "<registered upgrade step>", "type": "<step type>"}]
}
```

## Step-based upgrade runner

[upgrade.py](../analysis/base/assets/python/wearable/ota/upgrade.py) scans the bundled `upgrade/` directory for Python modules, calls each module's `upgrade()` registry and matches the step's `uses` value. The module comes from the installed SDK directory; this is not evidence that arbitrary Python embedded in the downloaded package is imported. It delegates `init`, `run`, `progress`, `due_time` and `quit` to the selected object.

The package includes check-eligibility, enter/quit-upgrade, setup-info, directory/file, flash/FAL, removal and verification step implementations. Relevant sources:

- [CheckUpgradeAble.py](../analysis/base/assets/python/wearable/ota/upgrade/CheckUpgradeAble.py): queries `svc_ota_get_version`, evaluates package conditions against firmware/hardware/OTA boot versions and battery information; checks depend on the supplied step configuration.
- [EnterUpgrade.py](../analysis/base/assets/python/wearable/ota/upgrade/EnterUpgrade.py) and [QuitUpgrade.py](../analysis/base/assets/python/wearable/ota/upgrade/QuitUpgrade.py): upgrade-mode transitions.
- [DirUpgrade.py](../analysis/base/assets/python/wearable/ota/upgrade/DirUpgrade.py) and [FileUpgrade.py](../analysis/base/assets/python/wearable/ota/upgrade/FileUpgrade.py): remote resources/files.
- [FALUpgrade.py](../analysis/base/assets/python/wearable/ota/upgrade/FALUpgrade.py): flash abstraction access and incremental block updates.
- [CheckUpgrade.py](../analysis/base/assets/python/wearable/ota/upgrade/CheckUpgrade.py): post-step verification logic.

## Flash integrity behavior

`FALUpgrade.py` probes a named remote partition, calculates local and remote CRC32 for erase-sized blocks, records differences, erases and writes only differing blocks, and performs a whole-range CRC32 check. There are also file-writing helpers and progress tracking. This supports an incremental resource/flash update mechanism for this SDK.

CRC32 checks establish corruption detection in the inspected implementation; they are not cryptographic signatures. Additional image validation or bootloader security may exist outside the inspected Python layer. Partition identity, erase geometry, allowed operations and binding/transport access must be established for the actual device before drawing conclusions about acceptance or recovery.

## Confidence boundary

The Python sources are an unusually useful reference for service contracts and OTA packaging, but their exact active device coverage is unresolved. They must not be substituted for the ZH/Berry or SiFli pipeline solely because they coexist in this APK. Reconstructing a firmware image, modifying packages, running the bundled Python or invoking flash RPCs was outside this offline analysis.
