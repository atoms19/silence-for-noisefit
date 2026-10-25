# Band and application communication use cases

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

Sources: [SessionManager:1](../analysis/smali/classes18/com/noisefit/session/SessionManager.smali#L1), [ConnectionService:1](../analysis/smali/classes18/com/noisefit/receiver/service/ConnectionService.smali#L1), [ServiceUtil:1](../analysis/smali/classes5/com/noisefit/util/ServiceUtil.smali#L1), [ZhQueryDeviceUnitsHandler:1](../analysis/smali/classes5/com/noisefit_zhsdk/handler/ZhQueryDeviceUnitsHandler.smali#L1), [ZhUserActivityHandler:1](../analysis/smali/classes5/com/noisefit_zhsdk/handler/ZhUserActivityHandler.smali#L1).

## Pairing and background behavior

ZH connection code explicitly distinguishes Berry behavior, binding/user-ID operations, existing-owner checks and reconnect reconciliation. Its reconciliation runnable is scheduled using `0x7d0` milliseconds (2 seconds). Do not equate a successful BLE connection with successful application binding. The shared state contracts include `DfuMode`, `AlreadyPaired`, `InvalidToken`, `BindFailure` and `WatchIsUnbind`.

Source: [ZhConnectHandler:2608](../analysis/smali/classes5/com/noisefit_zhsdk/handler/ZhConnectHandler.smali#L2608) and the [state catalog](catalogs/band-actions.md).

The manifest declares foreground service permissions and connected-device/data-sync/location service types. This supports maintaining device work while the UI is backgrounded, subject to Android permissions and runtime restrictions. Static declarations alone cannot establish actual reconnect frequency, battery impact or scheduling on a particular handset.

## Band-specific differences already visible

ZH query methods switch between generic watch APIs and names such as `getSWSPO2Monitor`, `getSWStressMonitor`, `getSWBRMonitor` and continuous-monitoring APIs. The `LUNA_BAND` checks also affect activity conversion. A replacement client should start with the band's selected protocol and actual supported settings, not the combined app-wide contract.

Firmware, watch faces, AGPS and local music can all involve “large files.” Their file-type identifiers, preparation and completion callbacks distinguish them. A byte stream sent to the wrong large-file type is not a valid firmware update even if the transport UUID is the same.
