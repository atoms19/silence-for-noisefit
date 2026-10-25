# Device routing and vendor adapters

## The selector

`WatchesSDK.n(ColorFitDevice)` reads the SDK type and compares lowercased strings. The accepted values correspond to eleven `SDKWatchType` values. Unsupported metadata reaches an `IllegalArgumentException` with the message `Unsupported connected device found`. Device features and protocol names introduce further branches inside each adapter.

Sources: [WatchesSDK:858](../analysis/smali/classes5/com/noisefit/watch/WatchesSDK.smali#L858), [SDKWatchType:1](../analysis/smali/classes5/com/noisefit/watch/SDKWatchType.smali#L1).

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

Sources: [ConnectionHandler:1](../analysis/smali/classes5/com/noisefit/watch/ConnectionHandler.smali#L1), [DeviceQueryHandler:1](../analysis/smali/classes5/com/noisefit/watch/DeviceQueryHandler.smali#L1), [UpdateDeviceHandler:1](../analysis/smali/classes5/com/noisefit/watch/UpdateDeviceHandler.smali#L1), [UpdateDeviceDataActions:1](../analysis/smali/classes5/com/noisefit_commans/interfaces/device_data/UpdateDeviceDataActions.smali#L1).

## Band-specific identifiers

The APK explicitly declares:

| Enum | Display/advertised-name string stored in enum | Device-type key |
| --- | --- | --- |
| `LUNA_BAND` | `Noise_REP` | `noise_band` |
| `LUNA_BAND_2` | `Luna_Band` | `luna_band` |

`WatchesSDK.v()` recognizes these as bands. The `LUNA_BAND` enum is referenced in ZH connection, query, update, activity and conversion handlers. That is strong evidence for a ZH integration for that type. It does **not** statically bind every device bearing the second enum to a fixed protocol or MCU; the `sdkType` and `protocolName` remain the decisive inputs.

Sources: [DeviceType:1859](../analysis/smali/classes5/com/noisefit_commans/models/DeviceType.smali#L1859), [WatchesSDK:1427](../analysis/smali/classes5/com/noisefit/watch/WatchesSDK.smali#L1427), [ZhConnectHandler:2526](../analysis/smali/classes5/com/noisefit_zhsdk/handler/ZhConnectHandler.smali#L2526), [ZhUpdateDeviceUnitsHandler:268](../analysis/smali/classes5/com/noisefit_zhsdk/handler/ZhUpdateDeviceUnitsHandler.smali#L268).

The user identified the available device as **ColorFit Pulse 2**. Its explicit branches point to Evolve2/TouchGUI; see [the model-specific guide](11-colorfit-pulse-2.md). ZH/Luna analysis above concerns other supported devices. No physical device or paired runtime state was inspected.

## What to record from an existing authorized pairing

For future local observation, record the selected `ColorFitDevice` values (`deviceType`, `sdkType`, `protocolName`, `mcuPlatform`, `firmwareId`), firmware version, advertised services and transfer callbacks. Those distinguish the correct path much more reliably than the marketing name. This report does not initiate pairing or collect these values from a live account.
