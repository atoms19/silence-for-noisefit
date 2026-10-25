# Storage, integrations and open questions

## Local and cloud data paths

The app packages Room/database modules, local data sources, preference/data-store contracts and repository sync code. `WatchDataStore` exposes firmware version and per-device/session state; `DataStoredInterface` exposes the selected device and authentication state. User health repositories and database abstractions separate local records from remote uploads. The exact on-device encryption state cannot be determined merely from these interfaces.

Sources: [RoomModule:1](../analysis/smali/classes18/com/noisefit/di/RoomModule.smali#L1), [WatchDataStore:1](../analysis/smali/classes5/com/noisefit_commans/data/local/abstraction/WatchDataStore.smali#L1), [DataStoredInterface:1](../analysis/smali/classes18/com/noisefit/data/local/dataStored/abstraction/DataStoredInterface.smali#L1), [SyncRepositoryImpl$postDataToServer$2:1](../analysis/smali/classes18/com/noisefit/data/repository/implementation/SyncRepositoryImpl$postDataToServer$2.smali#L1).

The APK includes a Health Connect manager and a sync worker, plus requested Health Connect write permissions for heart rate, steps, exercise, calories, sleep, distance, resting heart rate, respiratory rate, hydration, temperature, height, weight, oxygen saturation and HRV. These are potential integrations, not proof every record type was written. Google Fit and Strava integration code also exists.

Sources: [HealthConnectManager:1](../analysis/smali/classes5/com/noisefit/util/health/HealthConnectManager.smali#L1), [HealthConnectSyncWork:1](../analysis/smali/classes18/com/noisefit/receiver/workManager/HealthConnectSyncWork.smali#L1), [manifest](../analysis/AndroidManifest.xml).

## Diagnostics data

The Falcon log upload path can add app logs, firmware logs and RRI logs, and uses `POST /logging/falcon/upload_logs`. Device complaint and crash-report APIs also exist. The inspected repository chooses which available files to attach. This establishes a capability to upload device diagnostics; the analysis did not inspect or upload any user's diagnostic files.

Source: [DeviceRepositoryImpl:574](../analysis/smali/classes18/com/noisefit/data/repository/implementation/DeviceRepositoryImpl.smali#L574) and [API catalogs](catalogs/retrofit-endpoints.md).

## Security-relevant static observations

| Observation | Evidence | What can and cannot be concluded |
| --- | --- | --- |
| Backup disabled | Manifest `android:allowBackup="false"` | Android backup declaration; does not prove all local storage is encrypted |
| Cleartext enabled | Manifest and base network config allow cleartext | HTTP URLs can be used; this alone does not establish cleartext firmware delivery |
| Default trust anchors | Network config trusts system CAs; debug overrides also include user CAs | No pin set in this XML; pinning could exist in code/native clients and was not comprehensively audited |
| Bearer tokens | Main interceptor uses `access-token`; refresh API has a refresh-token header | Authentication capability is confirmed; live credential storage/security needs runtime/storage review |
| Firmware checksums | ZH protobuf MD5 field, CommonPt MD5 field, Python CRC32 | Integrity fields are present; signed-update or verified-boot policy is unresolved |
| Exposed Android components | Manifest declares exported TVS connection and some SiFli services | Exposure declaration is confirmed; authorization/input checks require component-specific audit before claiming a vulnerability |
| Packaged crypto native code | `libRtkAesJni.so`, `libble-crypto.so`, vendor native libraries | Crypto implementation is packaged; effective use/key management is unresolved |

Sources: [manifest](../analysis/AndroidManifest.xml), [decoded network security configuration](../analysis/network_security_config.xml), [native inventory](../analysis/native-inventory.txt), firmware/protocol chapters.

No vulnerability, exploitability or firmware acceptance claim follows from missing checks in one inspected adapter. This is a structure/protocol/OTA research report, not a completed security assessment.

## Important unanswered questions

| Question | Why APK-only evidence is insufficient | Best next evidence |
| --- | --- | --- |
| Is this physical ColorFit Pulse 2 using the expected TouchGUI path? | The model-specific code points to Evolve2/TouchGUI, but no paired runtime state was supplied | Existing authorized paired device metadata / service discovery |
| Where is this band's current firmware file hosted? | Backend supplies response-driven URLs | Existing captured update response or a supplied package; no backend requests made here |
| What image components and compatibility rules apply? | DTO and adapter indicate candidates, not actual image content | Original firmware ZIP/binary plus hardware/version identifiers |
| Are packages signed and anti-rollback enforced? | Bootloader/device validation not present in a client DTO | Firmware/bootloader analysis and controlled device observations |
| Does SDK success mean rebooted/new version? | Main UI reports completion before later identity query | Post-update version and boot/reconnect trace |
| Can an interrupted update recover safely? | SDKs expose failure/DFU states, but actual device recovery is untested | Controlled hardware recovery testing and bootloader behavior |
| Which GATT channels and packet sizes does the band use? | Multiple protocols and MTU-dependent code coexist | Passive local BLE/HCI capture from authorized ordinary use |
| Are server routes and staging hosts still active? | Static literals may be obsolete | Intentionally unverified under the no-request constraint |
| What does embedded Flutter/native code do end-to-end? | Printable strings expose only fragments | Separate ARM64/Dart AOT disassembly and bridge tracing |

## Concrete coverage achieved

All supplied APK splits are inventoried and hashed; all base DEX files are disassembled; decoded manifest/network XML, resource inventory, readable Python sources and native URL evidence are preserved. The research traces the manual firmware flow end-to-end at the app/SDK boundary, catalogs shared communication contracts and handler coverage, identifies configured backend clients and records API declaration/call-site evidence.

This provides a source-backed starting point for implementing or testing the specific band protocol once its model/selected adapter is known. It does not claim complete Java/Kotlin recovery, all native code recovery, a complete wire specification, every possible backend destination, or a verified working replacement application.
