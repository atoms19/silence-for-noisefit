"""Render the reviewed narrative research with local source references."""
from pathlib import Path
import json,re,collections
R=Path(__file__).resolve().parents[2];D=R/'docs'
C=json.loads((R/'analysis/classes.json').read_text())
def ref(cls, needle=None):
 key=cls.replace('.','/');p=C.get(key)
 if p is None:
  candidates=[v for k,v in C.items() if k.endswith('/'+cls)]
  if len(candidates)!=1:raise ValueError((cls,candidates))
  p=candidates[0]
 line=1
 if needle:
  s=(R/p).read_text();pos=s.find(needle)
  if pos<0:raise ValueError((p,needle))
  line=s.count('\n',0,pos)+1
 return f'[{cls.split(".")[-1]}:{line}](../{p}#L{line})'
def write(name,text): (D/name).write_text(text.strip()+'\n')
write('README.md',f'''# NoiseFit 5.4.6 — offline reverse engineering

This research covers the supplied `NoiseFit_+Health+&+Fitness_5.4.6_APKPure.xapk` (`com.noisefit`, build 876). All 18 DEX files were disassembled, the manifest and network security configuration decoded, assets extracted, and ARM64 native libraries inventoried and scanned for URL strings. **The initial APK analysis was entirely offline.** The user later authorized and ran two firmware-metadata requests; those results are documented in chapters 15–16. The APK was not installed or executed by this analysis environment, and no firmware write was attempted.

The central finding is that NoiseFit is a multi-vendor companion platform with **11 SDK families**, rather than a single BLE protocol. The app selects adapters from device metadata, then performs configuration, data synchronization and firmware installation through the selected vendor. A firmware check and download are cloud-facing; the final transfer is device-facing. Download hosts can be returned dynamically by the backend.

## Your device: ColorFit Pulse 2

The supplied model name matches `COLORFIT_PULSE_2` / `colorfit_pulse_2`. Explicit firmware-version and pairing branches identify the Evolve2/TouchGUI integration and default firmware ID 2109. A subsequent authorized backend check returned a same-version package, now downloaded and extracted locally: see [17 — Recovered firmware analysis](17-recovered-firmware-analysis.md). Start with [11 — ColorFit Pulse 2](11-colorfit-pulse-2.md); the earlier ZH/Luna chapters remain general coverage of other devices. User-supplied phone logs now corroborate the Evolve SDK selection; see [14 — Device log findings](14-device-log-findings.md). Private runtime metadata and hardware have not been inspected.

## Firmware UI and OS deep dive

The [dedicated ColorFit Pulse 2 firmware folder](firmware/README.md) covers the RTOS/task structure, 40 recovered screen registrations, GUI lifecycle, watchface parser and container, decoded cached images, and missing external resources. It distinguishes verified findings from unresolved screen identities.

## Silence OS build plan

The [Silence OS project plan](silence-os/README.md) defines the Android companion, watchface installer/builder, visual firmware milestones, architecture, and device validation gates.

## Reading guide

| Document | Scope |
| --- | --- |
| [01 — Evidence and reproduction](01-evidence-and-method.md) | Artifact hashes, toolchain, generated files, confidence and limitations |
| [02 — Application architecture](02-app-architecture.md) | Android components, modules, state and data flow |
| [03 — SDKs and device routing](03-device-routing.md) | Vendor families, metadata selection and Luna band identifiers |
| [04 — Band/app communication](04-band-communication.md) | Use-case matrix, pairing, configuration, measurements, notifications and files |
| [05 — Firmware update orchestration](05-firmware-update-flow.md) | Check requests, response fields, downloads, guards, progress and reporting |
| [06 — Vendor firmware implementations](06-vendor-firmware-paths.md) | ZH/Berry/SiFli details and other vendor paths |
| [07 — Backend and APIs](07-backend-and-apis.md) | Configured hosts, endpoint roles, headers, unknowns and call-site catalogs |
| [08 — BLE protocol evidence](08-ble-protocol-evidence.md) | GATT UUIDs, protobuf fields and transfer behavior |
| [09 — Bundled Python wearable SDK](09-python-wearable-sdk.md) | File/RPC protocol and OTA package processing |
| [10 — Storage, integrations and open questions](10-storage-and-open-questions.md) | Local/cloud data, security observations, unresolved boundaries |
| [11 — ColorFit Pulse 2](11-colorfit-pulse-2.md) | Your model: TouchGUI routing, firmware ID, OTA package flow and BLE evidence |
| [12 — Recover firmware from Android](12-firmware-recovery-from-android.md) | Authentication boundary, cache locations, ADB access and offline recovery limits |
| [13 — Device cache inspection](13-device-cache-inspection.md) | Actual copied watch-face file and private-cache access result |
| [14 — Device log findings](14-device-log-findings.md) | Runtime model/SDK confirmation and firmware search results |

## Searchable catalogs

- [All shared actions and callback events](catalogs/band-actions.md).
- [Update/configuration handler coverage](catalogs/UpdateDeviceAction-handler-coverage.md), [query handler coverage](catalogs/QueryAction-handler-coverage.md), [activity handler coverage](catalogs/UserActivityAction-handler-coverage.md). These distinguish overrides with code, empty overrides and inherited methods; they do not assert support on a physical model.
- [411 app-owned Retrofit declarations](catalogs/retrofit-endpoints.md), including dynamically supplied `@Url` declarations.
- [Dynamic URL call-site candidates](catalogs/dynamic-url-callsites.md) and [416 unique app-owned URL literals](catalogs/app-url-literals.md). Counts represent declarations/literals, not distinct live APIs or observed requests.
- [149 unique UUID literals](catalogs/uuid-literals.md), including unrelated SDK values.

Raw evidence is retained in [analysis](../analysis/), including [smali](../analysis/smali/), [decoded manifest](../analysis/AndroidManifest.xml), [hashes](../analysis/hashes.json), JSON catalogs and the original extracted assets. Start with chapters 05 and 06 for firmware work.

## Confidence rules

**Confirmed static** means directly present in bytecode, resources or assets. **Inferred** means a role or sequence deduced from those references. **Unresolved** means it needs a specific band, runtime observation, a downloaded package, or deeper native analysis. Static presence does not prove execution, server availability, device support, or effective security controls. No complete wire-compatible replacement client or firmware image was produced.
''')
write('01-evidence-and-method.md',f'''# Evidence and reproducible method

## Artifact identity

| Property | Value |
| --- | --- |
| Supplied file | `NoiseFit_+Health+&+Fitness_5.4.6_APKPure.xapk` |
| XAPK size | 311,010,347 bytes |
| XAPK SHA-256 | `2ee2eb92b990f5989b5a3611a39acd99c8c7eca15b48fa421f53b13d2656a737` |
| Base APK SHA-256 | `2ee2ec8c387d6f98be8b82ec3b58515c407cdd9b9a57e01fa911aa226abfb17c` |
| Package/version | `com.noisefit` / 5.4.6 / 876 |
| Minimum/target Android SDK | 26 / 36 |
| Splits | Base, `config.arm64_v8a`, `config.en`, `config.hdpi` |
| Bytecode | 18 DEX files; 128,185 emitted smali files |
| Native libraries | 70 ARM64 `.so` files |

Identity is read from the decoded manifest and XAPK [manifest.json](../analysis/input/manifest.json). All split hashes and sizes are in [hashes.json](../analysis/hashes.json). These hashes identify the local sample; the distribution filename and archive comments do not independently establish publisher authenticity. No signature comparison with an official release was performed.

## Toolchain and what “decompiled” means here

The installed Android SDK supplied `apkanalyzer`, `aapt2` and Android tools baksmali 3.0.9. Every DEX was translated to readable **smali disassembly**, preserving annotations, method calls, constants and branches. Original Kotlin/Java source was not recovered. Some names remain meaningful, while many method names and fields have been obfuscated. Inner coroutine names often preserve the original business operation. Native machine code and Flutter AOT were inventoried/scanned, not fully decompiled.

An attempt to download JADX from GitHub failed at DNS resolution because the environment disables networking. Analysis then used the installed SDK entirely offline. No application/backend URL was requested. The SDK's bundled JCommander is incompatible with certain baksmali help and `-j` options, so the successful command uses default options. The completed [disassembly log](../analysis/disassembly.log) records all 18 inputs.

## Reproduction

From this workspace, with the same installed SDK paths:

```sh
mkdir -p analysis/input analysis/base
unzip -q 'NoiseFit_+Health+&+Fitness_5.4.6_APKPure.xapk' -d analysis/input
unzip -q analysis/input/com.noisefit.apk 'classes*.dex' 'assets/*' -d analysis/base
/home/atoms/Android/Sdk/cmdline-tools/latest/bin/apkanalyzer manifest print analysis/input/com.noisefit.apk > analysis/AndroidManifest.xml
python3 analysis/tools/disassemble.py
python3 analysis/tools/build_catalogs.py
python3 analysis/tools/build_callsite_catalog.py
python3 analysis/tools/build_support_matrix.py
python3 analysis/tools/write_research.py
```

The scripts perform local reads/writes and invoke local Java tools; they have no network client. `disassemble.py` assumes extracted DEX inputs. For another machine, change the SDK root in that script. Standard Python 3.9 is sufficient. The narrative is reviewed interpretation; regeneration re-renders those notes rather than performing a new semantic audit.

The network XML was decoded with `apkanalyzer resources xml --file res/xml/network_security_config.xml`. Resource IDs were resolved using `aapt2 dump resources`; the output is [resources.txt](../analysis/resources.txt). ARM64 files were extracted from the native split and printable URL strings collected separately in [native-url-literals.json](../analysis/native-url-literals.json).

## Evidence layout and limits

`analysis/smali/classesN/` corresponds to `classesN.dex`; `classes/` corresponds to `classes.dex`. Each document links to source files and often a method or line. `#L` fragments are useful when hosted in a code viewer; local editors may require opening the referenced file and going to the indicated line.

Automated inventories are broad but deliberately limited: URL literals can be examples, web links or SDK defaults; dynamic URL associations are method co-occurrence candidates, not dataflow proof; UUIDs may be unrelated; handler coverage detects matching overrides, not runtime support. Data coming from remote configuration, responses, encryption, native code or constructed strings can be missing. The user identified the device as ColorFit Pulse 2. No paired runtime state, server response, BLE capture or firmware download was available for validation.
''')
write('02-app-architecture.md',f'''# Application architecture

## Android shell and application layers

The application starts at `com.noisefit.NoiseFitApplicationMain`. Its manifest includes onboarding/pairing and post-setup firmware activities, the main UI, background connection and notification services, call/SMS receivers, workers and content providers. AndroidX, Kotlin coroutines, LiveData, Hilt/Dagger, Retrofit/OkHttp, Gson and database code are present. Both view-based UI and Compose libraries are packaged. Flutter is embedded alongside the native Android app; `libapp.so`, `libflutter.so` and `assets/flutter_assets` establish this, but do not reveal every Dart feature.

Primary evidence: [AndroidManifest.xml](../analysis/AndroidManifest.xml), {ref('com.noisefit.session.SessionManager')}, {ref('com.noisefit.di.NetworkModule')}.

```mermaid
flowchart TD
    UI[Android UI and ViewModels] --> Session[SessionManager / state and actions]
    Session --> Service[ConnectionService / action dispatch]
    Service --> Router[Watch handlers and SDK selection]
    Router --> Vendor[Selected vendor Bluetooth SDK]
    Vendor <-->|BLE or supported classic channel| Band[Band or watch]
    Vendor --> Convert[Vendor DataConverter]
    Convert --> State[Shared models / callbacks]
    State --> Session
    UI --> Repo[Repositories]
    Repo --> DB[Local database and preferences]
    Repo --> HTTP[Retrofit / OkHttp / interceptors]
    HTTP --> Cloud[Configured API / dynamic download URLs]
```

This diagram summarizes source relationships; it is not a captured runtime trace.

## Main package boundaries

| Package / asset | Responsibility established from classes |
| --- | --- |
| `com.noisefit.ui` | Onboarding, dashboards, device management, firmware UI, watch faces, health and account screens |
| `com.noisefit.session` | Shared state and dispatch entry points for device queries, writes and activities |
| `com.noisefit.receiver.service` | Persistent device connection, notification handling, feedback and stocks |
| `com.noisefit.receiver.workManager` | Scheduled/background tasks including AGPS reminders |
| `com.noisefit.watch` | SDK selection and application/connection/query/update/activity handler facades |
| `com.noisefit.data` | API abstractions, repositories, response models, local storage and database code |
| `com.noisefit_commans` | Shared device models, actions, callbacks, capabilities, globals and storage contracts; spelling is from the APK |
| `com.noisefit_*`, `com.common_protocol`, `com.noisefit.hybrid`, `com.noisefit.noisefit_creek` | Device-family adapters and conversion code |
| `com.zhapp`, `com.zjw`, `com.ido`, `com.crrepa`, `com.touchgui`, `com.realsil`, `com.qcteam`, `com.topstep`, `com.ryeex`, `com.realthread` | Vendor SDK implementations and auxiliary protocols |
| `assets/python` | Python wearable RPC, files and OTA implementation |
| ARM64 split | Vendor protocol/media/crypto, Python, Flutter, speech, maps and ML native code |

## Important components

`ConnectionService` contains direct handling of `UpdateFirmware` and `VisionUpdateFirmware`, and uses selected update handlers. `ServiceUtil` dispatches many query, configuration and user-activity actions to the shared handler contracts. `SessionManager` provides the UI-facing action submission and observable callbacks. This separation explains why a screen does not directly write a GATT characteristic.

Sources: {ref('com.noisefit.receiver.service.ConnectionService','Lcom/noisefit_commans/interfaces/device_data/UpdateDeviceAction$UpdateFirmware;')}, {ref('com.noisefit.util.ServiceUtil')}, {ref('com.noisefit.watch.UpdateDeviceHandler')}.

Notification and call flows have their own Android inputs: `NotificationAlertService` is registered with `android.service.notification.NotificationListenerService`, and `CallAndMessageReceiver` listens for phone/SMS events. Those phone events can become wearable messages through the chosen adapter. Requested permissions include contact/call/SMS access, Bluetooth scan/connect, location, notifications, foreground services and Health Connect writes; a manifest request does not prove permission was granted.

## Device identity and capabilities

The shared `ColorFitDevice` contains MAC address, device type, SDK type, protocol name, MCU platform, firmware ID, feature data, serial number, subscription type, sub-wearable type, matching/name metadata and binding/watch token fields. This is a richer identity than a Bluetooth advertised name. Use the selected record and capabilities to determine which features should execute.

Source: {ref('com.noisefit_commans.models.ColorFitDevice')}.

## Non-device features

The code also contains social/challenges, trophies, content, subscriptions, shopping/warranty, watch face generation, stock/weather, TVS integration, eSIM, voice/AI and health analysis features. They account for many APIs and dependencies. Their presence should not be treated as a capability of the small band. See the backend and action catalogs for the separate scopes.
''')
write('03-device-routing.md',f'''# Device routing and vendor adapters

## The selector

`WatchesSDK.n(ColorFitDevice)` reads the SDK type and compares lowercased strings. The accepted values correspond to eleven `SDKWatchType` values. Unsupported metadata reaches an `IllegalArgumentException` with the message `Unsupported connected device found`. Device features and protocol names introduce further branches inside each adapter.

Sources: {ref('com.noisefit.watch.WatchesSDK','.method public final n(')}, {ref('com.noisefit.watch.SDKWatchType')}.

| Device `sdkType` | Enum | Adapter / underlying SDK |
| --- | --- | --- |
| `ZH` | `SDK_ZH` | `noisefit_zhsdk`; `com.zhapp.ble.ControlBleTools`; Berry/SiFli alternatives |
| `NAV_PLUS` | `SDK_NAV_PLUS` | `noisefit_nav_plus`; legacy `com.zjw.zhbraceletsdk` |
| `HYBRID` | `SDK_HYBRID` | `com.noisefit.hybrid`; Appscomm integration |
| `DAFIT` | `SDK_QUBE` | `com.noisefit.colorfit_pro`; CRREPA |
| `EVOLVE` | `SDK_EVOLVE` | `noisefit_evolve2`; TouchGUI |
| `CF_PRO` | `SDK_CF_PRO` | `noisefit_cf2`; IDO/VeryFit BLE and DFU |
| `RYEEX` | `SDK_RYEEX` | `noisefit_ryeex_sdk`; Ryeex WatchDevice |
| `DFUTURE` | `SDK_D_FUTURE` | `noisefit_sdk_dfuture`; QCTeam WearExternalManager |
| `NOISE` | `SDK_COMMON_PT` | `com.common_protocol`; `com.noise.wear` protobuf/service layer |
| `TOPSTEP` | `SDK_TOP_STEP` | `noisefit_topstep`; WKWearKit |
| `CREEK` | `SDK_CREEK` | `com.noisefit.noisefit_creek`; CreekManager / generated protobuf |

Adapter names are misleading here: `SDK_QUBE` routes to the CRREPA-backed `Pro` handler, while `SDK_CF_PRO` routes to the IDO-backed `CF2` handler. This follows the enum switch mapping and injected handler fields in `UpdateDeviceHandler`; verify routing rather than inferring it from product or class names.

## Shared contracts

Each family is integrated through application initialization, connection, query, update and activity handlers. Query/update base classes include empty implementations. A matching action class or a UI control therefore does not establish that every family implements the feature. The generated handler coverage catalogs link the dispatch method to each family's matching override.

Sources: {ref('com.noisefit.watch.ConnectionHandler')}, {ref('com.noisefit.watch.DeviceQueryHandler')}, {ref('com.noisefit.watch.UpdateDeviceHandler')}, {ref('com.noisefit_commans.interfaces.device_data.UpdateDeviceDataActions')}.

## Band-specific identifiers

The APK explicitly declares:

| Enum | Display/advertised-name string stored in enum | Device-type key |
| --- | --- | --- |
| `LUNA_BAND` | `Noise_REP` | `noise_band` |
| `LUNA_BAND_2` | `Luna_Band` | `luna_band` |

`WatchesSDK.v()` recognizes these as bands. The `LUNA_BAND` enum is referenced in ZH connection, query, update, activity and conversion handlers. That is strong evidence for a ZH integration for that type. It does **not** statically bind every device bearing the second enum to a fixed protocol or MCU; the `sdkType` and `protocolName` remain the decisive inputs.

Sources: {ref('com.noisefit_commans.models.DeviceType','const-string v1, "Noise_REP"')}, {ref('com.noisefit.watch.WatchesSDK','.method public final v(')}, {ref('com.noisefit_zhsdk.handler.ZhConnectHandler','.method public final q0()Z')}, {ref('com.noisefit_zhsdk.handler.ZhUpdateDeviceUnitsHandler','.method private final H2()Z')}.

The user identified the available device as **ColorFit Pulse 2**. Its explicit branches point to Evolve2/TouchGUI; see [the model-specific guide](11-colorfit-pulse-2.md). ZH/Luna analysis above concerns other supported devices. No physical device or paired runtime state was inspected.

## What to record from an existing authorized pairing

For future local observation, record the selected `ColorFitDevice` values (`deviceType`, `sdkType`, `protocolName`, `mcuPlatform`, `firmwareId`), firmware version, advertised services and transfer callbacks. Those distinguish the correct path much more reliably than the marketing name. This report does not initiate pairing or collect these values from a live account.
''')
write('04-band-communication.md',f'''# Band and application communication use cases

## How to read the scope

The [shared catalog](catalogs/band-actions.md) contains 505 named action/state/event types: 84 queries, 140 device update actions, 19 activity actions, 110 query callbacks, 112 update callbacks, 24 activity callbacks and 16 connection/binding states. These are application contracts, not 505 distinct BLE commands. A callback may report a phone-side operation, one action may issue several device commands, and an unimplemented action may do nothing.

The [query](catalogs/QueryAction-handler-coverage.md), [update](catalogs/UpdateDeviceAction-handler-coverage.md) and [activity](catalogs/UserActivityAction-handler-coverage.md) coverage tables map 216 actions to matching handler methods. JSON includes the discovered vendor calls in [handler-coverage.json](../analysis/handler-coverage.json). This is the broadest enumerated use-case inventory in this report; the table below explains the functional groups.

## Functional communication matrix

| Use case | Main direction | Content / behavior | Evidence and limitations |
| --- | --- | --- | --- |
| Scan and identify | Band → app | Advertised name, address, RSSI and model matching | Connection handlers and `ColorFitDevice`; metadata may also come from device catalog APIs |
| Pair / bind / reconcile owner | Bidirectional | User identity, bind success/failure, already-paired or invalid-token state | `BindState`, `WatchBindState`, ZH `setUserIdByBerryProtocol`; binding is separate from Android Bluetooth bonding |
| Connect / reconnect / disconnect | Bidirectional | Connection start/progress/success/failure, reconnect reconciliation and DFU mode | `ConnectState`; ZH schedules reconciliation after 2 seconds |
| Battery and firmware identity | Band → app | Battery power, firmware version and related device info | `QueryBatteryPower`, `QueryFirmwareVersion`, `FirmwareVersionObtained` |
| Time and profile | App → band | Clock/time format, language, units, user info/goals | Update actions and vendor conversion handlers |
| General preferences | Bidirectional | Wrist lift, screen behavior, brightness, vibration, DND, screen awake, calling switch | Feature support differs; ZH brightness override is empty in this build |
| Heart monitoring | Bidirectional | Measurement/history, automatic interval, alert thresholds, exercise HR | Query/update/activity actions; data models do not establish clinical validity |
| Oxygen, stress and breathing | Bidirectional | Spot/continuous settings and synchronized readings/history | SPO2/stress/respiratory actions; some ZH methods branch to band-specific `SW` SDK calls |
| HRV / RRI and recovery inputs | Band → app and settings → band | HRV records, raw interval logs, related health analysis | Shared HRV actions/models and backend RRI log upload support |
| Steps, movement, calories, distance | Band → app | Current/history activity, goals and synchronization | `GetStepsData`, `SyncUserActivity`, vendor activity handlers |
| Sleep | Bidirectional | Sleep history, reminders, monitoring settings | `GetSleepData`, query/update actions; `SetAutoSleep` is an empty ZH override |
| Sports | Bidirectional | Start/pause/resume/stop, history, sports modes, workout recognition and GPS data | Activity and update actions; ZH SDK exposes sport state enums |
| Notifications | App → band | Application message title/content/type and time | Notification listener → shared `AppNotification` → adapter; no live user messages inspected |
| Calls and SMS | Bidirectional where supported | Incoming-call information, contact name, alerts, reply/reject events | Phone receiver and adapter methods; headset audio uses separate capabilities |
| Contacts / SOS / quick replies | Bidirectional | Contact lists, emergency contacts, reply templates | Query and update actions; image contacts are family-specific |
| Remote camera | Band → app, app → band | Camera open/exit and shutter-related events | `OpenCameraActivity`, camera navigation callbacks and SDK helpers |
| Find phone / find wearable | Bidirectional | Find request, sound/vibration and stop | Shared callbacks/actions and find-phone receiver |
| Phone music controls | Bidirectional | Track/state updates and play/pause/skip events | Music event and settings callbacks; distinguish from transferring local music |
| Reminders | Bidirectional | Alarm lists, sedentary, drink/walk/sleep/meal/handwashing and menstrual settings | Corresponding shared actions and payload models |
| Watch faces / resources | App → device, status → app | Cloud/custom/AI/video dial files, progress and installation result | Shared face actions and large-file paths; may share transport with OTA but are different payloads |
| Firmware | App → device, status → app | Preparation, image/package transfer, installation callback and recovery/DFU state | Chapters 05–06; model-specific protocol |
| AGPS / GNSS | App → device | Downloaded assistance data, state/expiry and transfer | AGPS actions, workers and vendor handlers; not interchangeable with firmware images |
| Weather / sports scores / stocks / clocks | App → device | Server-fetched data translated to device models | API-backed phone service plus vendor writes; some devices do not expose these features |
| Files / apps / local music / maps | Bidirectional | Lists, deletion, push/pull and large data | Query/update types, SDKs and Python file service; broader than the band subset |
| Logs and diagnostics | Device → app → backend | Firmware logs, typed logs and upload archives | Firmware log actions and upload APIs; cloud upload is a distinct step |
| eSIM, vault and specialized integrations | Bidirectional | EID, eSIM workflows, vault/QR/NFC or TVS-related data | Packaged APIs/contracts; no evidence all apply to the small band |
| Voice / AI / recordings | Bidirectional and app ↔ backend | Recording/audio events, speech/AI bridge, watch face image generation | Shared callbacks plus AI APIs/native speech; model-dependent |
| Reset / unbind / remove | App → device and app → backend | Local device reset/unbind and cloud device removal | Connection and update contracts; cloud deletion and device reset are separate operations |

## Normal command path

The UI submits an action through `SessionManager`. `ConnectionService` handles important actions directly and uses `ServiceUtil` for many query/write/activity dispatches. `WatchesSDK` and the handler facades select the adapter. The adapter converts shared payloads into vendor models and calls the vendor SDK. Device notifications or SDK callbacks are converted back into shared callback models and observable UI state.

Sources: {ref('com.noisefit.session.SessionManager')}, {ref('com.noisefit.receiver.service.ConnectionService')}, {ref('com.noisefit.util.ServiceUtil')}, {ref('com.noisefit_zhsdk.handler.ZhQueryDeviceUnitsHandler')}, {ref('com.noisefit_zhsdk.handler.ZhUserActivityHandler')}.

## Pairing and background behavior

ZH connection code explicitly distinguishes Berry behavior, binding/user-ID operations, existing-owner checks and reconnect reconciliation. Its reconciliation runnable is scheduled using `0x7d0` milliseconds (2 seconds). Do not equate a successful BLE connection with successful application binding. The shared state contracts include `DfuMode`, `AlreadyPaired`, `InvalidToken`, `BindFailure` and `WatchIsUnbind`.

Source: {ref('com.noisefit_zhsdk.handler.ZhConnectHandler','.method public final s0(')} and the [state catalog](catalogs/band-actions.md).

The manifest declares foreground service permissions and connected-device/data-sync/location service types. This supports maintaining device work while the UI is backgrounded, subject to Android permissions and runtime restrictions. Static declarations alone cannot establish actual reconnect frequency, battery impact or scheduling on a particular handset.

## Band-specific differences already visible

ZH query methods switch between generic watch APIs and names such as `getSWSPO2Monitor`, `getSWStressMonitor`, `getSWBRMonitor` and continuous-monitoring APIs. The `LUNA_BAND` checks also affect activity conversion. A replacement client should start with the band's selected protocol and actual supported settings, not the combined app-wide contract.

Firmware, watch faces, AGPS and local music can all involve “large files.” Their file-type identifiers, preparation and completion callbacks distinguish them. A byte stream sent to the wrong large-file type is not a valid firmware update even if the transport UUID is the same.
''')
write('05-firmware-update-flow.md',f'''# Firmware update orchestration

## Entry points and overall sequence

The app includes manual device-management updates, post-pairing updates (`PostSetupFirmwareActivity`), home alerts and main-view-model download paths. This chapter traces the manual path through `CheckForUpdatesFragment` and `CheckForUpdatesViewModel`, whose source preserves the most explicit check/download/install lifecycle. Other entry points should not be assumed to have identical guards.

Sources: {ref('com.noisefit.ui.myDevice.manage.CheckForUpdatesFragment')}, {ref('com.noisefit.ui.myDevice.manage.CheckForUpdatesViewModel')}, {ref('com.noisefit.ui.onboarding.pairing.PostSetupFirmwareActivity')}, {ref('com.noisefit.MainViewModel')}.

```mermaid
sequenceDiagram
    participant UI as Update UI / ViewModel
    participant API as NoiseFit backend
    participant DL as Dynamic download URL
    participant S as Session / ConnectionService
    participant V as Selected vendor SDK
    participant B as Wearable
    UI->>S: Query firmware version and battery
    S->>V: Vendor queries
    V->>B: Device protocol
    B-->>UI: Shared callbacks via SDK and session
    UI->>API: POST firmware check with device/version metadata
    API-->>UI: UpdateResponse / release policy / download URLs
    UI->>DL: Download selected firmware resource
    DL-->>UI: File, progress or failure
    UI->>S: UpdateFirmware(fileUri) or VisionUpdateFirmware(files)
    S->>V: Adapter firmware implementation
    V->>B: Prepare and transfer / vendor DFU
    B-->>V: Status / acknowledgments
    V-->>UI: FirmwareUpgradeProgress / status
    UI->>API: Completion tracking on COMPLETED callback
    UI->>S: Query battery and firmware version again
```

The diagram describes intended code flow. No messages shown here were actually sent during research.

## Firmware check APIs

Configured base: `https://app-eks.gonoise.com`.

| Check | HTTP and path | Body fields constructed by the manual ViewModel |
| --- | --- | --- |
| Existing path | `POST /core/watch/firmware_versions` | `version`, `firmware_id`, `device_type`, `platform` = `android`, `mac`, `isOTARequired` |
| Recent path | `POST /firmware-versions/v3/recent` | `version_number`, `firmware_id`, `device_type`, `mac`, `build_number`, `platform` = `android` |

The two calls are exposed by distinct repository coroutine classes and different `NetworkService` methods. They are not just alternate strings for one demonstrated wire request. Null device fields and session state can affect the built object. Inspect the method for a concrete model before reproducing payloads.

Sources: {ref('com.noisefit.ui.myDevice.manage.CheckForUpdatesViewModel','.method public final u(')}, {ref('com.noisefit.ui.myDevice.manage.CheckForUpdatesViewModel','.method public final v()')}, {ref('com.noisefit.data.repository.implementation.DeviceRepositoryImpl$checkForUpdates$2')}, {ref('com.noisefit.data.repository.implementation.DeviceRepositoryImpl$checkForUpdatesRecent$2')}, {ref('com.noisefit.data.remote.abstraction.NetworkService','.method public abstract H(')}, {ref('com.noisefit.data.remote.abstraction.NetworkService','.method public abstract e0(')}.

## Update response contract

`UpdateResponse` is wrapped in a generic API response. Gson annotations establish these JSON names:

| JSON field | Client representation / role |
| --- | --- |
| `description_chinese`, `description_english` | Optional release descriptions |
| `forceUpdate` | Mutable boolean update-policy flag |
| `softUpdate` | Boolean update-policy flag |
| `version` | Integer release/version identifier |
| `version_name` | Version name string |
| `url` | Optional primary download URL |
| `hr_url` | Optional HR component URL |
| `image_url` | Optional resource/image URL |
| `touch_url` | Optional touch/component URL |

The exact semantics of release IDs, rollout eligibility and server-side version comparison cannot be established from the DTO alone. There are no package hashes or signatures in this particular DTO; that does not exclude authentication/checking inside vendor packages or bootloaders.

Source: {ref('com.noisefit.data.remote.response.UpdateResponse')}.

## Download and preconditions

In the normal manual update click path, the fragment permits a connected device or recognized DFU state; a navigation argument allows a special path around the ordinary connection check. For the common `p2()` download path, its constructor sets a battery threshold of 30 and the guard rejects battery **less than or equal to 30**, with missing battery treated as 0. The same navigation argument can bypass that battery check. This is one UI path, not a universal bootloader battery policy. The SDK_QUBE branch starts its vendor update directly with an empty URI and therefore follows a different workflow.

The fragment chooses a response URL according to SDK/device state, including `touch_url` on applicable branches, derives the filename from its last slash, and passes the URL, external cache directory and filename to `DownloadRepository`. `DownloadService` supports dynamic URL downloads; the configured `http://localhost/` is its Retrofit placeholder, **not evidence that firmware is hosted on the phone**. Firmware destinations are populated at runtime. A separate Vision path handles a list of typed component files.

Sources: {ref('com.noisefit.ui.myDevice.manage.CheckForUpdatesFragment','.method public constructor <init>')}, {ref('com.noisefit.ui.myDevice.manage.CheckForUpdatesFragment','.method public static final u2(')}, {ref('com.noisefit.ui.myDevice.manage.CheckForUpdatesFragment','.method public final p2()')}, {ref('com.noisefit.ui.myDevice.manage.CheckForUpdatesFragment','.method public final B2()')}, {ref('com.noisefit.data.remote.abstraction.DownloadService')}, {ref('com.noisefit.di.NetworkModule','.method public final f(')}.

`Download$Progress`, `Download$Finished` and `Download$Failed` represent the download stage. The finished file becomes a local URI and is submitted as `UpdateDeviceAction.UpdateFirmware`; Vision uses `VisionUpdateFirmware`. Failure code records `ble.ota.download_failed` and installs a retry callback. This download progress is distinct from the vendor's transfer/install progress.

Sources: {ref('com.noisefit.ui.myDevice.manage.CheckForUpdatesViewModel$downloadFirmware$1')}, {ref('com.noisefit.ui.myDevice.manage.CheckForUpdatesViewModel$downloadFirmware$1$1')}, {ref('com.noisefit.ui.myDevice.manage.CheckForUpdatesFragment','.method public static final F2(')}.

## Dispatch, progress and completion

`ConnectionService` recognizes `UpdateFirmware`, extracts its file URI and calls the selected `UpdateDeviceDataActions.P1(String)` implementation. That obfuscated method is the common handoff traced in chapter 06. Vendor listeners emit `UpdateDeviceDataCallback.FirmwareUpgradeProgress`, carrying `WatchUpdateStatus`. The manual UI handles progress/start-like states, completion and failure; state names come from `UpdateStatus` and the enum mapping class.

On the completion callback, the UI sends a tracking request, clears stored update state/alerts, records the last update time, deletes cached update material, and requests battery and firmware version again. **The tracking request is triggered by SDK completion before the later firmware-version query establishes the device's installed version.** An SDK success callback is not independent proof that the new firmware booted successfully.

Sources: {ref('com.noisefit.receiver.service.ConnectionService','Lcom/noisefit_commans/interfaces/device_data/UpdateDeviceAction$UpdateFirmware;')}, {ref('com.noisefit.ui.myDevice.manage.CheckForUpdatesFragment','.method private final L2(')}.

## Completion reporting

`POST https://app-eks.gonoise.com/user_detail/user/firmware/tracking` receives a JSON body built with `fw_version`, populated from the selected response version name. The ViewModel rate-limits this call locally to one per two seconds; although its method accepts an integer too, the inspected body only adds `fw_version`.

Sources: {ref('com.noisefit.ui.myDevice.manage.CheckForUpdatesViewModel','.method public final c0(')}, {ref('com.noisefit.data.repository.implementation.DeviceRepositoryImpl$markOtaUpdateComplete$2')}.

## What is still unknown

The available model is now identified as ColorFit Pulse 2; see [chapter 11](11-colorfit-pulse-2.md) for its TouchGUI path. No actual firmware response or payload was fetched. Consequently live download domains, current release versions, compatibility matrices, rollout rules, image signing keys, verified boot/anti-rollback enforcement and success after reboot remain unresolved. The app-side path is documented; a complete firmware/bootloader audit would need the actual image and device-specific protocol observation.
''')
write('06-vendor-firmware-paths.md',f'''# Vendor firmware implementations

## ZH: the most relevant explicit band integration

`ZhUpdateDeviceUnitsHandler.P1(String)` selects among three paths. The first test is `I2()`, which compares `ColorFitDevice.protocolName` to `DeviceProtocol.BERRY`. Otherwise `DataConverter.T()` tests the integer exposed by `WatchInfoGlobals.g()` against 50,000 (`0xc350`) and chooses SiFli when it is at least that value. The global getter's meaning should be established from the concrete device initialization before treating this threshold as a universal MCU rule.

Sources: {ref('com.noisefit_zhsdk.handler.ZhUpdateDeviceUnitsHandler','.method public P1(')}, {ref('com.noisefit_zhsdk.handler.ZhUpdateDeviceUnitsHandler','.method public final I2()Z')}, {ref('com.noisefit_zhsdk.handler.DataConverter','.method public final T()Z')}.

### Berry path

1. Parse the local firmware URI into a file and read its bytes.
2. Set the shared update-in-progress flag.
3. Call `ControlBleTools.getDeviceLargeFileStateByBerry(bytes, "ota", deviceType, firmwareVersion, listener)`; the latter metadata comes from `WatchInfoGlobals` getters.
4. The callback compares the returned status to `READY`.
5. On readiness call `startUploadBigDataByBerry("ota", bytes, uploadListener)`.
6. Convert upload progress, success and timeout to shared update callbacks.

Sources: {ref('com.noisefit_zhsdk.handler.ZhUpdateDeviceUnitsHandler$updateFirmware$1')}, {ref('com.noisefit_zhsdk.handler.ZhUpdateDeviceUnitsHandler$updateFirmware$1$onSuccess$1')}.

The packaged `BerryLargeFileManager` maintains send mode, current index, cached indices, slice length, resume-related state and unanswered transmission state. Its constants include a 1 MiB slice limit, 1 MiB unanswered-data limit, 20,000 ms unanswered timeout, 9-byte base header, 12-byte data header and 990-byte payload base multiple. These describe manager internals, **not** a universal BLE packet length or a complete wire format. There are both BLE and SPP-related transport hooks and separate ring-service paths; which is used depends on the connected device and protocol.

Source: {ref('com.zhapp.ble.manager.BerryLargeFileManager')}.

### SiFli path

The updater marks OTA in progress, registers its SiFli handling, derives a file list using `DiyHelperSdkSide.i(fileUri)`, calls `SifliDFUService.p0(context, address, files, 1, 0)`, then disconnects the normal `ControlBleTools` connection. That handoff explains why the ordinary BLE link can drop as part of an intended update.

The packaged manifest declares `com.sifli.siflidfu.SifliDFUService`; this is an actual adapter call into that implementation, not just a dormant service declaration. Packet-level SiFli DFU behavior and the exact component list require further tracing of that SDK/package.

Sources: {ref('com.noisefit_zhsdk.handler.ZhUpdateDeviceUnitsHandler','.method public P1(')}, {ref('com.noisefit_zhsdk.DiyHelperSdkSide')}, [manifest](../analysis/AndroidManifest.xml).

### Other ZH large-file path

The remaining branch constructs a local file and calls:

```text
getDeviceLargeFileState(true, "443", "1305828", listener)
READY -> startUploadBigData("ota", fileBytes, false, uploadListener)
```

Those two strings are hardcoded in this build. SDK logging labels the corresponding arguments as version and MD5, but their actual values and short length should not be interpreted as a validated package digest. The old preparation API explicitly rejects Berry protocol in SDK code; the app's earlier Berry branch avoids that route.

Sources: {ref('com.noisefit_zhsdk.handler.ZhUpdateDeviceUnitsHandler$updateFirmware$2')}, {ref('com.zhapp.ble.ControlBleTools','.method public static synthetic g3(')}.

Upload progress is computed as `sent * 100 / total`. Upload success clears the shared OTA flag and emits `COMPLETED`; timeout clears the flag and emits `ERROR`. Preparation not-ready and timeout paths also report failure. This callback does not by itself prove post-reboot firmware identity.

Source: {ref('com.noisefit_zhsdk.handler.ZhUpdateDeviceUnitsHandler$updateFirmware$2$onSuccess$1')}.

The SDK's preparation status enum includes `READY`, `BUSY`, `DUPLICATED`, `LOW_STORAGE`, `LOW_BATTERY`, `DOWNGRADE`, device-ID and space errors, plus other resource-specific errors. These enum names establish that such status concepts exist; they do not establish every firmware's policy, or numeric on-wire values.

Source: {ref('com.zhapp.ble.callback.DeviceLargeFileStatusListener$PrepareStatus')}.

## Other actively integrated adapter paths

| Family | Firmware path observed in adapter | Important distinction |
| --- | --- | --- |
| DAFIT / QUBE / Pro / CRREPA | `CRPBleConnection.startFirmwareUpgrade`; alternative Realtek `RtkDfuController` and Jieli `JieliDfuController` branches | SDK-directed upgrade selection; manual UI can invoke with empty URI rather than the common downloader |
| CF_PRO / CF2 / IDO | `BLEManager.startTranCommonFile(FileTransferConfig)` or `BLEManager.startDFU(BleDFUConfig)` with DFU listener | File-transfer and DFU alternatives; IDO native `libVeryFitMulti.so` is also packaged |
| EVOLVE / TouchGUI | Obtain `TGOTAManager`, register `TGOTACallback` and pass local file through its OTA method | Vendor owns transfer details |
| RYEEX | Unpack archive, read config/resource data, populate `FirmwareUpdateInfo` and update items, call `WatchDevice.updateFirmware` | Multiple components with IDs and lengths; not a raw flat image path |
| DFUTURE / QCTeam | `getPackageHeader(file)`, build `UpgradeConfig` from version/size/mode, `prepareUpgrade`, then `upgrade(file, FileCallback)` | Explicit package header and preparation response before transfer |
| NOISE / CommonPt | Unzip local archive; parse `config.json` (`version`, `isFullRes`); read `.res` bytes; call `DeviceService.updateFirmware(FirmwareUpdate, callback)` | Firmware DTO carries resource-full flag and bytes; actual version/length/MD5 protocol message below |
| TOPSTEP | `WKWearKit.s()` supplies `WKOtaAbility`; OTA Observable is subscribed with progress/error/completion handlers | Reactive vendor OTA pipeline |
| CREEK | Validate file and invoke CreekManager OTA operation with callbacks | Separate generated protobuf/native boundary |
| NAV_PLUS | Prepare via `ZhBraceletService` and upload bytes with `"ota"` after status callback | Legacy ZJW API, distinct from current `ControlBleTools` |
| HYBRID / Appscomm | `P1(String)` override has no update work | Packaged Appscomm OTA service is not proof of a working app-level firmware handoff in this method |

Primary adapter evidence:

- {ref('com.noisefit.colorfit_pro.handler.ProUpdateDeviceUnitsHandler','.method public P1(')}.
- {ref('com.noisefit_cf2.handler.CF2UpdateDeviceUnitsHandler','.method public P1(')}.
- {ref('com.noisefit_evolve2.handler.Evolve2UpdateDeviceUnitsHandler','.method public P1(')}.
- {ref('com.noisefit_ryeex_sdk.handler.RyeexUpdateDeviceUnitsHandler','.method public P1(')}.
- {ref('com.noisefit_sdk_dfuture.handler.DFutureUpdateDeviceUnitsHandler$updateFirmware$1')}.
- {ref('com.common_protocol.handler.CommonPtUpdateDeviceUnitsHandler','.method public P1(')}.
- {ref('com.noisefit_topstep.handler.TopstepUpdateDeviceUnitsHandler','.method public P1(')}.
- {ref('com.noisefit.noisefit_creek.handler.CreekUpdateDeviceUnitsHandler','.method public P1(')}.
- {ref('com.noisefit_nav_plus.handler.NavPlusUpdateDeviceUnitsHandler','.method public P1(')} and {ref('com.noisefit_nav_plus.handler.NavPlusUpdateDeviceUnitsHandler$updateFirmware$1')}.
- {ref('com.noisefit.hybrid.handler.NFHUpdateDeviceUnitsHandler','.method public P1(')}.

## CommonPt package and protocol boundary

The CommonPt adapter reports an error for a missing local file or empty extraction result. It scans the extraction directory for `config.json` and `.res` files, sets `FirmwareUpdate.version`, `resFull` and `bytes`, then calls `DeviceService.updateFirmware`. The inspected adapter does not itself show a signature check; validation may occur below the service or in the device. Some malformed/incomplete config cases are not comprehensively handled at this adapter boundary.

The generated protobuf `NPBFirmware.FirmwareStart` declares field numbers: `version = 1`, `res_full = 2`, `length = 3`, `md5 = 4`. This establishes a transfer metadata schema. It does not establish MD5 as a signature or demonstrate that arbitrary firmware would be accepted.

Source: {ref('com.noise.wear.protocol.protobuf.entity.NPBFirmware$FirmwareStart')}.

## Embedded Python OTA is another boundary

The package also includes Realthread/PersimWear Java bindings to Python `service_ota_*` functions and the corresponding readable Python upgrade implementation. This is analyzed separately in chapter 09. Its presence and Java bridge are confirmed; it should not be assigned to Luna Band without tracing that model's selected runtime SDK path.

## Update-security conclusions that this sample does not support

Checksums, file MD5, app authentication, signed firmware and bootloader enforcement are different mechanisms. This report establishes several client-side integrity/preparation fields, but cannot conclude either that firmware is authenticated or that unsigned/downgraded images are accepted. It also does not establish rollback resilience, flash layout, recovery pinouts or safe interruption behavior for the physical band.
''')
write('07-backend-and-apis.md',f'''# Backend servers and API surface

## Network policy for this research

All findings are local static evidence. No host below was resolved, probed or requested as part of application analysis. A literal URL establishes a reference; only client construction and call sites make a stronger case that it is an intended integration. Server internals, deployment status and current behavior are unknown.

## Configured clients and other host references

| Host/base | Evidence level | Intended or likely role |
| --- | --- | --- |
| `https://app-eks.gonoise.com` | Explicit main and token-refresh Retrofit base; many concrete calls | Primary identity, device catalog, health sync, firmware discovery/tracking, subscriptions and app configuration |
| `https://pre-order.gonoise.com` | Explicit shop Retrofit base | Commerce/shop integration |
| `http://api.weatherapi.com` | Explicit weather/sport client base | Weather and sports data for phone/device features |
| `https://api.twelvedata.com` | Explicit stock client base | Quotes, symbol search and stocks |
| `https://www.strava.com` | Explicit Retrofit base and concrete URLs | OAuth/token and activity integration |
| `https://p360.tvsmotor.com/gapi` | Apollo server URL | TVS GraphQL integration |
| `https://queue.fal.run/` | Explicit Flux client base | AI image/watch-face generation queue |
| `https://api.replicate.com` | App URL literal | Alternative image-generation path; not proof used in every session |
| `http://localhost/` | Download Retrofit placeholder with dynamic `@Url` | Base required to construct generic downloader; actual file URL is supplied separately |
| `https://app.gonoise.com` | App URL literals | Additional web/content/wellbeing links; do not assume same API deployment as main host |
| `https://noise-connect.gonoise.com`, `https://engage.gonoise.com` | App URL literals | Support/engagement endpoints or links; inspect corresponding call sites |
| `https://backend.gonoise.com/devices/file/link` | App literal/call-site lead | Device file-link integration |
| `http://app-micro-staging.gonoise.com/devices/file/link` | Staging literal | Environment-specific or legacy path; presence does not prove production traffic |
| `images.gonoise.com`, `watchfaces-cdn.gonoise.com`, `user-detail-service-cdn.gonoise.com`, `noise-images.s3.ap-south-1.amazonaws.com` | App asset/content URLs | Images, instructional media, watch face and QR resources; not verified firmware hosts |
| `http://veryfitproapi.veryfitplus.com/dailPlate/...` | Vendor integration URLs | IDO/VeryFit dial catalog |
| `http://offline-live1.services.u-blox.com/GetOfflineData.ashx` | AGPS call-site literal | GNSS assistance download |
| Sentry ingest host | App DSN literal | Error/diagnostic telemetry configuration |
| Firebase/Google, Facebook, Huawei, MoEngage and other SDK references | Packaged libraries and manifest | SDK integration/analytics/push/authentication capabilities; not a complete observed destination list |
| `https://open.creekcould.com`, `/v1/route/gpx` | Printable strings in Flutter `libapp.so` | Possible Creek route backend; AOT call flow not decompiled |
| `https://api.cognitive.microsofttranslator.com`, `https://api.country.is` | Printable strings in Flutter `libapp.so` | Translation / country detection references; execution unresolved |

Main source: {ref('com.noisefit.di.NetworkModule')}. Additional literal sources and call sites are linked individually in [app URL literals](catalogs/app-url-literals.md), [dynamic call-site candidates](catalogs/dynamic-url-callsites.md), and [native URL strings](../analysis/native-url-literals.json). Native strings can contain diagnostic/docs URLs and must not all be treated as live integrations.

## What the primary backend appears responsible for

Endpoint families and repository payloads support these client-side roles:

| Area | Examples of paths or literal prefixes | What is established / inferred |
| --- | --- | --- |
| Identity and account | `/users/auth/sign_up`, `/auth_v2/refresh-token`, `/users/auth/update_mobile`, `/user_detail/profile/update` | Authentication/profile operations are declared; token headers and refresh flow are present |
| Device registration and capabilities | `/user_detail/watch/devices/create`, `/user_detail/watch/devices/list`, `/user_detail/watch/device_features`, `/user_detail/watch/watch-token` | Cloud device records/capabilities and watch tokens; exact ownership policy is server-side |
| Firmware | `/core/watch/firmware_versions`, `/firmware-versions/v3/recent`, `/user_detail/user/firmware/tracking` | Discovery/version selection and completion tracking; server-side rollout rules inferred, not recovered |
| Download links | `/user_detail/watch/file/link`, `/devices/file/link` on other referenced environments | Obtain file links; filenames/hosts may be response-driven |
| Health sync | `/multisync/v2/create`, `/multisync/v2/health-events`, `/watch/heart_rates/v2/history`, `/watch/blood_oxygen/v2/history`, `/watch/stress/v2/history` | Upload and historical retrieval/aggregation capabilities |
| Sleep and recovery | `/sleep_activities/v3/rewamp/create`, `/watch/sleep/v1/history`, `/watch/sleep/v2/recovery/calendar`, `/multisync/v2/sleep-planner/create` | Sleep records and derived views; exact algorithms are not recoverable from paths |
| AI health analysis | `/multisync/ai/health/analysis/list/`, `/multisync/ai/health/analysis/detail/` | Analysis listing/detail retrieval; do not infer server model or pipeline |
| Watch faces | `/cloud_watch_faces/v3/dial_plate/info`, `/watch_faces/v3/current` | Catalog/current-face tracking and downloadable resources |
| Social/challenges | `/activity_challenge/v3/...`, `/trophies/v3/recent`, `/buddies/profile` | Challenge membership/progress/social profile operations |
| App release/config | `/core/watch/app_version/check`, `/core/watch/app_version/config` | App version/configuration; separate from band firmware |
| Support/diagnostics | `/logging/falcon/upload_logs`, `/user_detail/user/device/complaint/logs`, `/user_detail/feedback/create`, `/user_detail/upload_crash_report` | Feedback and logs, including device/firmware/RRI logs where supplied |
| Warranty, commerce, subscriptions | `/warranty/v3/...`, `/core/shopify/token`, subscription-related literal paths | Product/account entitlements and purchase integrations |
| eSIM and voice bridge | `/auth_v2/watch/esim/send-otp`, `/auth_v2/watch/esim/verify-otp`, `/watch/ai-bridge/data/voice-ai` | Specialized phone/watch backend functions; model-dependent |

Sources: {ref('com.noisefit.data.remote.abstraction.NetworkService')}, {ref('com.noisefit.data.repository.implementation.DeviceRepositoryImpl')}, {ref('com.noisefit.data.repository.implementation.SyncRepositoryImpl$postDataToServer$2')}, and the catalogs. Path examples retain the APK's spelling, including `rewamp`.

## API inventory and its completeness boundary

[retrofit-endpoints.md](catalogs/retrofit-endpoints.md) enumerates **411 HTTP method declarations** across app-owned interfaces with parameters and source locations. Many use `@Url`, so the declaration does not identify a fixed path. [dynamic-url-callsites.md](catalogs/dynamic-url-callsites.md) adds **288** dynamic call sites with literal candidates in the same method. [app-url-literals.md](catalogs/app-url-literals.md) lists **416 unique literals** from the app/adapters/common protocol. These counts overlap and must not be added as a count of unique APIs.

The dynamic catalog is a co-occurrence index; concatenation and branch-specific argument assignment still need source inspection. URLs returned by servers, native/Flutter networking, GraphQL operations, dynamically assembled strings and SDK-only endpoints are not all represented as Retrofit rows. Raw app URL occurrence data is in [url-literals.json](../analysis/url-literals.json); it also retains third-party DEX references. Query values are omitted from rendered URL tables because literals can include integration tokens; parameter names remain available in declarations/source.

## Main request headers and token handling

`NetworkConnectionInterceptor.s()` constructs headers including:

```text
content-type: application/json
version: 876
version-name: 5.4.6
Accept-Encoding: gzip
user-agent: <constructed client agent>
device-model: <Android Build.MODEL>
device-manufacturer: <Android Build.BRAND>
os-version: <Android version>
platform: android
sub-wearable-type: <selected type, or band/watch fallback>
country: <country>
accept-language: <app language>
epoch-time: <current time>
access-token: Bearer <stored access token>   [when available]
```

The access token is carried under **`access-token`** in this inspected main client, rather than assuming a standard `Authorization` header. Other clients can use different interceptors. Later branches add device-specific context; inspect the complete method before constructing any future authorized request. Token-refresh API declarations include `refresh-token`, `wearable-type` and `user-agent` headers. Runtime tokens were not acquired or exposed.

Sources: {ref('com.noisefit.data.remote.NetworkConnectionInterceptor','.method public final s(')}, {ref('com.noisefit.data.remote.abstraction.TokenRefreshApi')}, {ref('com.noisefit.data.remote.NetworkConnectionInterceptor$getUpdatedToken$2')}.

## An ambiguous external firmware interface

`ExternalFirmwareService` declares `GET /account/login` and `GET /device/queryFirmwareVersion`, each with a body parameter. Standard Retrofit GET-body validation makes this declaration unusual. The inspected `ExternalModule` supplies a repository taking this service, but no concrete base URL for this interface was established. Treat it as a packaged integration requiring validation, not a confirmed additional live firmware backend.

Source: {ref('com.noisefit.data.remote.abstraction.ExternalFirmwareService')}, {ref('com.noisefit.di.ExternalModule')}.

## Server implementation remains unknown

Host names and route prefixes are not proof of AWS EKS deployment, microservice boundaries, databases, object storage for firmware, specific cloud vendors, rollout cohorts or signing services. Those are plausible interpretations only. The APK establishes the client contracts, and current production responses were intentionally not queried.
''')
write('08-ble-protocol-evidence.md',f'''# BLE protocol evidence

## Multiple transport/protocol families

There is no single NoiseFit GATT service common to every supported device in this sample. Vendor selection and `protocolName` choose different stacks. ZH itself contains standard/protobuf, Berry, Berry ring, large-file and SPP-related paths. IDO, Realtek, TouchGUI and other vendor DFU implementations have their own UUIDs and framing. The [UUID catalog](catalogs/uuid-literals.md) records 149 unique literal UUIDs across all DEX code, including unrelated examples and SDK constants.

The values below are confirmed **SDK constants**, not the services observed on the physical band. Actual advertising/service discovery was not performed.

## Interpreted ZH UUID constants

For rows using short values, expand with suffix `-0000-1000-8000-00805f9b34fb`, padding the first group to eight hexadecimal digits. The protobuf family has a different suffix and is shown in full.

| SDK constant(s) | UUID(s) | Meaning from code |
| --- | --- | --- |
| `SCAN_RECORD` | `0000fe78-0000-1000-8000-00805f9b34fb` | Advertising/scan UUID constant |
| `UUID_CHARACTERISTIC_UPDATE_NOTIFICATION_DESCRIPTOR` | `00002902-0000-1000-8000-00805f9b34fb` | Notification descriptor (CCCD) |
| `UUID_BASE_SERVICE`, `UUID_BASE_WRITE`, `UUID_BASE_READ` | `00000001`, `00000002`, `00000003` + suffix | SDK base channel |
| `UUID_PROTOBUF_SERVICE` | `16186f00-0000-1000-8000-00807f9b34fb` | Protobuf service |
| `CHAR_PROTOBUF_UUID_01` … `_05` | `16186f01` … `16186f05` with `-0000-1000-8000-00807f9b34fb` | Multiplexed protobuf characteristics; several have write/notification handling |
| `UUID_BIG_SERVICE`, `CHAR_BIG_UUID_02`, `_03` | `00002001`, `00002002`, `00002003` + suffix | Dedicated large-data channel constants |
| `UUID_AA01_SERVICE`, write/read, extra write/read | `0000aa01` … `0000aa05` + suffix | Alternate AA01 channel family |
| `UUID_ECG_SERVICE`, `UUID_ECG_READ` | `00003e01`, `00003e03` + suffix | ECG channel constants |
| `UUID_PPG_SERVICE`, `UUID_PPG_READ` | `00002c01`, `00002c03` + suffix | PPG channel constants |
| `UUID_THEME_SERVICE`, write/read | `00001601`, `00001602`, `00001603` + suffix | Theme/resource channel |
| `UUID_LOG_SERVICE`, `UUID_LOG_READ` | `00001701`, `00001703` + suffix | Log channel |
| `UUID_IMAGER_SERVICE`, `UUID_IMAGER_WRITE` | `00003d01`, `00003d02` + suffix | Image-related channel |
| Berry ring service, protocol read, data read/write | `00006666`, `00000050`, `0000005e`, `0000005f` + suffix | Berry ring-specific constants; not evidence the band is a ring |
| `UUID_SPP` | `00001101-0000-1000-8000-00805f9b34fb` | Bluetooth classic serial profile constant |

Source: {ref('com.zhapp.ble.utils.UuidUtils')}. `BluetoothService` uses `BluetoothGatt.setCharacteristicNotification`, resolves the protobuf characteristics and writes through `BluetoothGatt.writeCharacteristic`. Some channel selection is protocol-dependent; the table deliberately does not infer a universal write/read direction solely from a characteristic number.

Source: {ref('com.zhapp.ble.BluetoothService')}.

## Protobuf schemas recovered from generated classes

ZH `WearProtos.WearPacket` exposes field-number constants. Selected envelope fields:

| Field | Number |
| --- | --- |
| `type` | 1 |
| `id` | 2 |
| `account` | 3 |
| `system` | 4 |
| `watch_face` | 6 |
| `nfc` | 7 |
| `notification` | 9 |
| `fitness` | 10 |
| `lpa` | 11 |
| `weather` | 12 |
| `stock` | 13 |
| `error_code` | 100 |

Corresponding `Type` enum values include `ACCOUNT = 1`, `SYSTEM = 2`, `WATCH_FACE = 4`, `NOTIFICATION = 7`, `FITNESS = 8`, `LPA = 9`, `WEATHER = 10`, `STOCK = 11` and additional types. **Enum values and protobuf field numbers differ** and should not be conflated with GATT characteristic numbers.

Sources: {ref('com.zh.wear.protobuf.WearProtos$WearPacket')}, {ref('com.zh.wear.protobuf.WearProtos$WearPacket$Type')}.

ZH OTA preparation fields:

| Message | Field/enum | Number/value |
| --- | --- | --- |
| `SystemProtos.PrepareOta.Request` | `force` | field 1 |
| Same | `type` | field 2 |
| Same | `firmware_version` | field 3 |
| Same | `file_md5` | field 4 |
| `PrepareOta.Response` | `prepare_status` | field 1 |
| `PrepareOta.Type` | `ALL`, `ROM`, `RES` | enum values 0, 1, 2 |

Sources: {ref('com.zh.wear.protobuf.SystemProtos$PrepareOta$Request')}, {ref('com.zh.wear.protobuf.SystemProtos$PrepareOta$Response')}, {ref('com.zh.wear.protobuf.SystemProtos$PrepareOta$Type')}.

The separate CommonPt protocol has `NPBFirmware.FirmwareStart` fields `version=1`, `res_full=2`, `length=3`, `md5=4`. It belongs to a different namespace/service and should not be encoded as a ZH `PrepareOta` message.

Source: {ref('com.noise.wear.protocol.protobuf.entity.NPBFirmware$FirmwareStart')}.

## Transfer behavior and unresolved wire details

Berry large-file code provides explicit slice/index/timeout/resume state. The exact end-to-end frame construction still depends on service code and native serialization/crypto boundaries. Internal manager headers and payload multiples from chapter 06 are not a recipe to send an OTA packet.

A complete interoperable client would require confirming service discovery, characteristic properties, descriptor setup, MTU negotiation, fragmentation/reassembly, sequence/acknowledgment semantics, checksums/encryption, binding credentials, retries, reconnect behavior and post-update identity for the specific model. This research identifies the source locations for those questions, but no wire capture or native decryption audit was performed.
''')
write('09-python-wearable-sdk.md',f'''# Bundled Python wearable SDK

## Why this is useful

The base APK contains readable `.py` source alongside `.pyc`, so part of the embedded wearable SDK can be studied directly. Its README says the SDK Python is separated to keep Android and iOS implementations synchronized. The surrounding native split includes `libpython3.11.so` and `libpersimwear.so`. Java `com.realthread.persimwear.api.Firmware` calls named Python services through `ExecService.execPyLpc`.

Sources: [SDK README](../analysis/base/assets/python/README.md), [Python asset root](../analysis/base/assets/python/), {ref('com.realthread.persimwear.api.Firmware')}, [native inventory](../analysis/native-inventory.txt).

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
{{
  "project": "<device project>",
  "version": "<package version>",
  "deviceNeedReboot": true,
  "allowQuitHalfway": false,
  "steps": [{{"uses": "<registered upgrade step>", "type": "<step type>"}}]
}}
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
''')
write('10-storage-and-open-questions.md',f'''# Storage, integrations and open questions

## Local and cloud data paths

The app packages Room/database modules, local data sources, preference/data-store contracts and repository sync code. `WatchDataStore` exposes firmware version and per-device/session state; `DataStoredInterface` exposes the selected device and authentication state. User health repositories and database abstractions separate local records from remote uploads. The exact on-device encryption state cannot be determined merely from these interfaces.

Sources: {ref('com.noisefit.di.RoomModule')}, {ref('com.noisefit_commans.data.local.abstraction.WatchDataStore')}, {ref('com.noisefit.data.local.dataStored.abstraction.DataStoredInterface')}, {ref('com.noisefit.data.repository.implementation.SyncRepositoryImpl$postDataToServer$2')}.

The APK includes a Health Connect manager and a sync worker, plus requested Health Connect write permissions for heart rate, steps, exercise, calories, sleep, distance, resting heart rate, respiratory rate, hydration, temperature, height, weight, oxygen saturation and HRV. These are potential integrations, not proof every record type was written. Google Fit and Strava integration code also exists.

Sources: {ref('com.noisefit.util.health.HealthConnectManager')}, {ref('com.noisefit.receiver.workManager.HealthConnectSyncWork')}, [manifest](../analysis/AndroidManifest.xml).

## Diagnostics data

The Falcon log upload path can add app logs, firmware logs and RRI logs, and uses `POST /logging/falcon/upload_logs`. Device complaint and crash-report APIs also exist. The inspected repository chooses which available files to attach. This establishes a capability to upload device diagnostics; the analysis did not inspect or upload any user's diagnostic files.

Source: {ref('com.noisefit.data.repository.implementation.DeviceRepositoryImpl','const-string v12, "appLogs.txt"')} and [API catalogs](catalogs/retrofit-endpoints.md).

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
''')
write('11-colorfit-pulse-2.md',f'''# ColorFit Pulse 2 — model-specific findings

## Identity and confidence

The user identifies the available device as **ColorFit Pulse 2**. The supplied APK has an exact model match:

| Property | Static evidence |
| --- | --- |
| Enum | `DeviceType.COLORFIT_PULSE_2` |
| Model name | `ColorFit Pulse 2` |
| Device key | `colorfit_pulse_2` |
| Integrated family indicated by model-specific code | `com.noisefit_evolve2`, backed by `com.touchgui.sdk` |
| Corresponding SDK selector | `EVOLVE` → `SDK_EVOLVE` |
| Default firmware ID used by explicit Pulse 2 branches | `2109` (`0x83d`) |

Sources: {ref('com.noisefit_commans.models.DeviceType','const-string v1, "ColorFit Pulse 2"')}, {ref('com.noisefit_evolve2.handler.Evolve2QueryDeviceUnitsHandler$queryFirmwareVersion$1','DeviceType;->COLORFIT_PULSE_2:')}, {ref('com.noisefit.ui.onboarding.pairing.pair.PairDeviceViewModel','DeviceType;->COLORFIT_PULSE_2:')}, {ref('com.noisefit_commans.constants.WatchInfoGlobals','.method static constructor <clinit>()')}, {ref('com.noisefit.watch.WatchesSDK','.method public final n(')}.

This static integration is now corroborated by user-supplied logs: they identify `colorfit_pulse_2`, record initialization of the Evolve SDK and log Evolve connection actions. See [device log findings](14-device-log-findings.md). No private selected-device record, service discovery or Bluetooth traffic capture was supplied. `WatchInfoGlobals.l()` reads a mutable field initialized to 2109; it is a firmware catalog identifier, **not** the installed firmware version, hardware revision or BLE opcode.

Other model keys are separate: Pulse 2 Max is `pulse_2_max`, Pulse 2 Buzz is `pulse_2_buzz`, and Pulse 2 Pro is `pulse2_pro`. Do not substitute those when following this device's backend or firmware path. The earlier Luna/ZH details concern different supported models.

## Model-specific version and pairing behavior

The TouchGUI firmware-version callback receives `TGVersionInfo`, checks for `COLORFIT_PULSE_2`, reads `WatchInfoGlobals.l()` and writes that value to the shared firmware-ID global through `x(int)`. It also processes the firmware version string, extracts a numeric suffix for the shared numeric version state, and stores the full version string.

The pairing ViewModel separately has a Pulse 2 branch that adds:

```text
version: <method input integer>
isOTARequired: true
firmware_id: <WatchInfoGlobals.l(), initially 2109>
device_type: colorfit_pulse_2
```

This is a reconstruction of that branch's object additions, not a captured response or a complete universal request schema. The ordinary update screen has its own request builders documented in chapter 05. A hardcoded catalog ID should not replace an observed runtime value if the app has changed it.

Sources: {ref('com.noisefit_evolve2.handler.Evolve2QueryDeviceUnitsHandler$queryFirmwareVersion$1')}, {ref('com.noisefit.ui.onboarding.pairing.pair.PairDeviceViewModel','.method public final x(')}, {ref('com.noisefit_commans.constants.WatchInfoGlobals','.method public final l()I')}.

## Firmware path to prioritize

```mermaid
flowchart TD
    Q[TouchGUI firmware version and battery queries] --> API[NoiseFit firmware check]
    API --> URL[UpdateResponse supplies selected file URL]
    URL --> File[Download to phone cache]
    File --> Action[UpdateFirmware local URI]
    Action --> E[Evolve2UpdateDeviceUnitsHandler.P1]
    E --> Proxy[TGOTAManagerProxy]
    Proxy --> Unzip[TouchGUI OTA manager unpacks ZIP]
    Unzip --> Filter[Recognize and sort component files]
    Filter --> Transfer[TGFileTransfer implementation sends each component]
    Transfer --> Reboot[Vendor reboot command]
    Reboot --> Callback[OTA completion callback]
    Callback --> Verify[App tracking and later firmware version query]
```

The general backend and UI guards still matter: firmware check endpoints on `app-eks.gonoise.com`, response-driven download URL, ordinary manual-path battery guard rejecting values at or below 30, connection/DFU checks, and completion tracking. Those are app-side behaviors, not proof of device-side enforcement.

### Adapter handoff

`Evolve2UpdateDeviceUnitsHandler.P1(String)` splits the local URI on `"///"`, takes the last segment, obtains `TGClient.w()` (`TGOTAManager`), installs a callback, then calls `a(filePath, false)`. This is the observed code rather than a general URI conversion contract.

The false argument matters: `TGOTAManagerProxy.a(String, boolean)` has an optional device-info-dependent branch for true; the app's inspected adapter passes false and enters its ordinary package-processing path. The proxy uses an atomic in-progress flag to reject an overlapping OTA and creates a `TGOTA<timestamp>` directory in the app's internal cache.

Sources: {ref('com.noisefit_evolve2.handler.Evolve2UpdateDeviceUnitsHandler','.method public P1(')}, {ref('com.touchgui.sdk.TGOTAManagerProxy','.method public a(')}.

### Package processing and component transfer

The underlying `com.touchgui.sdk.h` manager calls `internal.tb.a(packagePath, extractionPath)`, whose implementation uses `ZipInputStream`. It enumerates extracted top-level files, checks names against `internal.u3`, logs unknown files, sorts the selected list and starts file transfer. Optional component-selection filtering exists, but the inspected false branch passes no selection list. The transfer loop derives a file type from the filename and calls `com.touchgui.sdk.k.g(File, filename, type)` for each component. Progress combines earlier completed bytes and current-file bytes against an extracted-size total.

The SDK recognizes names including:

```text
a.bin, b.bin, apollo_boot.bin, st_boot.bin, boot.bin
res01.bin ... res05.bin, fonts.bin, Ftable.bin, Dfonts, Sfonts.bin
r_watch30.bin, r_watch40.bin, pkg.ota, update.bin
picture.watch, cfg_res.watch
lle_bds.lle, lle_glo.lle, lle_gps.lle, agps.bin, LTO2.bin, LTO7.bin
```

Additional regex matches include `copy_res.*` and `cfg_res.watch.*`. This is a **shared TouchGUI allowlist**, not a recovered Pulse 2 package manifest. It includes resources and GNSS data for other devices. It does not establish that Pulse 2 uses any particular boot image, MCU or assistance file.

Sources: {ref('com.touchgui.sdk.h','.method public final i(')}, {ref('com.touchgui.sdk.h','.method public final f()V')}, {ref('com.touchgui.sdk.internal.tb')}, {ref('com.touchgui.sdk.internal.u3')}, {ref('com.touchgui.sdk.k')}.

### Reboot and completion

After its transfer list is exhausted, the manager schedules a reboot operation. `h.k()` logs `reboot device` and invokes a vendor command through `internal.l9.f()`. Its `internal.q6` callback logs `OTA completed`, deletes the extraction directory, clears the in-progress flag and invokes `TGOTACallback.a()`. The Evolve2 callback maps this to shared `COMPLETED`, errors to `ERROR`, and progress to `PROGRESS`.

This is more precise than calling every progress event a firmware flash percentage: the code reports transfer progress and then vendor command completion. It does not independently confirm successful boot into the requested version. The later app firmware query remains relevant.

Sources: {ref('com.touchgui.sdk.h','.method public final k()V')}, {ref('com.touchgui.sdk.internal.q6')}, {ref('com.noisefit_evolve2.handler.Evolve2UpdateDeviceUnitsHandler$updateFirmware$1')}.

## Bluetooth evidence relevant to this family

TouchGUI's connection service code contains these service candidates:

```text
00000af0-0000-1000-8000-00805f9b34fb
000027f0-0000-1000-8000-00805f9b34fb
00002760-0000-1000-8000-00805f9b34fb
```

Its characteristic selection/notification handling also references `0af1`, `0af6`, `27f1`, `27f6`, `2761`, `2762` and `2763`, with the same Bluetooth base suffix. These are **TouchGUI SDK candidates**, not a measured Pulse 2 GATT table. The correct service/characteristic set, write properties and negotiated MTU require local discovery/capture from the actual unit. Do not use ZH `16186f..` UUIDs as this model's default.

Sources: {ref('com.touchgui.sdk.internal.g')}, {ref('com.touchgui.sdk.internal.l')}, {ref('com.noisefit_evolve2.handler.connect.Evolve2ConnectHandler')}.

## Configuration and data communication

Use the `Evolve2` column of the main coverage catalogs, or the [focused TouchGUI action catalog](catalogs/colorfit-pulse-2-touchgui-actions.md). It links shared actions to Evolve2 query/update/activity methods and their directly observed vendor calls. The catalog distinguishes a method with code from an empty/inherited implementation and does not promise physical-model support.

The relevant source families are:

- {ref('com.noisefit_evolve2.handler.connect.Evolve2ConnectHandler')}: connection and listeners through `TGClient`.
- {ref('com.noisefit_evolve2.handler.Evolve2QueryDeviceUnitsHandler')}: queries and callback conversion.
- {ref('com.noisefit_evolve2.handler.Evolve2UpdateDeviceUnitsHandler')}: settings, notifications, watch faces and firmware.
- {ref('com.noisefit_evolve2.handler.Evolve2UserActivityHandler')}: activity/history synchronization and related operations.

## Remaining model-specific unknowns

The user reports installed version `5.4.328.26`; an authorized check later returned matching version metadata and an `images.gonoise.com` URL, documented in [chapter 16](16-returned-pulse-2-firmware.md). The returned ZIP has now been recovered and contains one `a.bin` code component; see [chapter 17](17-recovered-firmware-analysis.md). Exact hardware revision, observed BLE table, full-image/base-version dependencies, device-side signature/anti-rollback policy and interruption recovery remain unknown. No device communication, firmware download or backend request was performed to fill those gaps. The identified default catalog ID and SDK allowlist are research evidence, not instructions to flash a guessed image.
''')
coverage=json.loads((R/'analysis/handler-coverage.json').read_text())
focused='# ColorFit Pulse 2 — Evolve2/TouchGUI action evidence\n\nThe exact model has explicit version/pairing branches in the Evolve2 integration. Rows below filter the existing dispatcher/handler analysis to that adapter. `code` indicates calls or state changes, `empty` an override without such work, and `inherited` no matching override in that class. This does not establish support on the physical Pulse 2, successful device execution, or wire opcodes. Vendor calls are direct calls in that method; work delegated to helpers/coroutines may not appear here.\n'
for family in ['QueryAction','UpdateDeviceAction','UserActivityAction']:
 focused+='\n## '+family+'\n\n| Shared action | Handler method | Status | Direct vendor calls | Evidence |\n| --- | --- | --- | --- | --- |\n'
 for row in coverage:
  if row['family']!=family:continue
  e=row['handlers'].get('Evolve2',{'status':'unresolved'})
  calls='<br>'.join('`'+c.replace('|','\\|')+'`' for c in e.get('vendor_calls',[]))
  evidence=f"[handler](../../{e['source']})" if 'source' in e else '—'
  focused+=f"| {row['action']} | `{row['signature']}` | {e['status']} | {calls} | {evidence} |\n"
(D/'catalogs/colorfit-pulse-2-touchgui-actions.md').write_text(focused)
write('12-firmware-recovery-from-android.md',f'''# Recovering Pulse 2 firmware from an existing Android installation

## Discovery authentication and binary download are separate

The main API client attaches `access-token: Bearer <stored token>`. Firmware discovery routes include `POST /core/watch/firmware_versions` and `POST /firmware-versions/v3/recent`; they return firmware metadata and URLs. This establishes that the app sends authentication, not independent proof of the server's enforcement.

The generic firmware downloader uses a separate `HttpClientDownload` built without the main authentication interceptor. Its Retrofit service accepts a dynamic URL, optionally an `accept-encoding` header, and streams a response body. No NoiseFit bearer header is added by the inspected download client. Therefore the binary URL might be public, signed/expiring, tokenized in the query/path or otherwise protected independently. The exact live policy remains unknown without an existing response or network interaction. Merely possessing a URL does not provide its bytes offline.

Sources: {ref('com.noisefit.di.NetworkModule','.method public final l()')}, {ref('com.noisefit.data.remote.abstraction.DownloadService')}, {ref('com.noisefit.data.remote.NetworkConnectionInterceptor','.method public final s(')}.

## Offline recovery routes, in priority order

| Route | What could be recovered | Access / limitations |
| --- | --- | --- |
| App external cache | Original downloaded archive, incomplete downloads or old copies | Ordinary ADB may read it, depending on Android/device restrictions |
| App private cache | TouchGUI `TGOTA<timestamp>` extraction directories and component files | Usually requires existing root access or a debuggable app permitting `run-as` |
| Existing app files, saved state and logs | Previous update response, filename, URL, firmware ID/version, and occasionally copied packages | Private app data normally needs the same additional access; URL/metadata alone is not firmware |
| Existing backups or copied update files | Previously preserved archive or components | No backend access required; must verify the model and package completeness |
| Readout from the wearable | Potential installed image | No generic firmware-readback API established; ADB access to the phone alone does not provide this |

For Android user 0, candidate paths derived from the inspected APIs are:

```text
/storage/emulated/0/Android/data/com.noisefit/cache/
/data/user/0/com.noisefit/cache/TGOTA<timestamp>/
/data/user/0/com.noisefit/files/
/data/user/0/com.noisefit/shared_prefs/
/data/user/0/com.noisefit/databases/
```

These are expected Android path mappings, not observed directories on the user's device. `/data/data/com.noisefit/` can be an alias; secondary users/work profiles use different IDs. A cache package need not end in `.zip`: the app derives its filename from the URL, and TouchGUI parses the content with `ZipInputStream`.

Sources: {ref('com.noisefit.ui.myDevice.manage.CheckForUpdatesFragment','.method public final p2()')}, {ref('com.touchgui.sdk.TGOTAManagerProxy','.method public a(')}, {ref('com.touchgui.sdk.internal.tb')}.

## Why an old completed update might no longer be available

TouchGUI deletes its extracted directory after its completion callback and in its handled OTA failure path. The app also attempts to delete its downloaded file on cleanup. Abrupt termination, failed cleanup, copies or other entry points could leave material, so offline inspection is worthwhile, but there is no guarantee a previous firmware package survives.

Sources: {ref('com.touchgui.sdk.internal.q6')}, {ref('com.touchgui.sdk.h','.method public final l(')}, {ref('com.noisefit.ui.myDevice.manage.CheckForUpdatesViewModel','.method public final y()V')}.

## Preservation-first ADB workflow

Before opening or refreshing the app, disable its Internet connectivity (Wi-Fi, mobile data and any Ethernet/VPN network path). A read-only investigation should first identify the actual installed package/version and device user, preserve accessible caches, then inspect private data only if access is already available. A band connection is unnecessary for reading files already stored on the phone.

Do not clear storage/cache, uninstall/reinstall, trigger an update, unlock the bootloader or start a rooting procedure to pursue this cache. Bootloader unlocking can wipe the data being sought. Ordinary `adb pull` cannot bypass private app storage permissions. The supplied APK declares `allowBackup=false`, so legacy ADB backup should not be relied upon for private-data extraction.

Recovered candidates should be copied to the workspace, hashed, checked for archive integrity and inspected offline. Match model identifiers (`colorfit_pulse_2`), firmware catalog context (default ID 2109), version and component metadata; avoid assuming every `.bin` is firmware, because watch faces and other resources coexist. Partial files or an unrelated model package are not a verified usable firmware image.

No ADB device inspection, cache extraction or network request has been performed for this chapter. If no firmware bytes remain in accessible storage or an existing backup, ADB cannot recreate a deleted package from its URL; acquiring it would then require another source or relaxing the no-network constraint.
''')
p=D/'12-firmware-recovery-from-android.md'
p.write_text(p.read_text()+f'''
## What an authenticated backend check could establish

The APK contains `POST /auth_v2/watch/login`, `POST /auth_v2/watch/send-otp`, `POST /auth_v2/watch/verify-otp` and a refresh-token flow. `LoginRequest` has `login_type`, `value`, `password`, `token` and `image_url` fields; which are required depends on the actual login mode. These declarations do not prove every mode is currently enabled. A screen displaying an account identity is not itself an API credential. A valid existing session or a successful normal login would provide the authentication context, alongside actual device metadata for the firmware query.

Sources: {ref('com.noisefit.data.repository.implementation.AuthenticationRepositoryImpl$loginUser$2')}, {ref('com.noisefit.data.remote.request.LoginRequest')}, [dynamic API call sites](catalogs/dynamic-url-callsites.md).

The manual update success collector obtains nullable `BaseApiResponseData.data` and passes it to `CheckForUpdatesViewModel.n0(UpdateResponse?, boolean)`. That method explicitly handles a null update by setting the update-available state false and returning. The package URL in `UpdateResponse` is also nullable. Therefore the client is designed to tolerate a successful request without usable firmware metadata; static analysis cannot promise that the backend always supplies a package, including when already current. The exact no-update payload, whether an identical-version package is offered, eligibility/rollout rules and any separate reinstall facility remain server-side unknowns. `isOTARequired` is a client flag, not proof of a server override or guaranteed download.

Sources: {ref('com.noisefit.ui.myDevice.manage.CheckForUpdatesViewModel$checkForUpdates$1$1')}, {ref('com.noisefit.ui.myDevice.manage.CheckForUpdatesViewModel','.method public final n0(')}, {ref('com.noisefit.data.remote.response.UpdateResponse')}.

Offline cache recovery is the first choice under the user's no-request constraint and may recover the exact previously delivered package. It cannot answer current server policy. An authenticated check could answer what this account/device/version is offered now, but would require relaxing that constraint and might still return no package. No such query has been performed.
''')
