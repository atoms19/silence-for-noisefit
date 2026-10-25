# Vendor firmware implementations

## ZH: the most relevant explicit band integration

`ZhUpdateDeviceUnitsHandler.P1(String)` selects among three paths. The first test is `I2()`, which compares `ColorFitDevice.protocolName` to `DeviceProtocol.BERRY`. Otherwise `DataConverter.T()` tests the integer exposed by `WatchInfoGlobals.g()` against 50,000 (`0xc350`) and chooses SiFli when it is at least that value. The global getter's meaning should be established from the concrete device initialization before treating this threshold as a universal MCU rule.

Sources: [ZhUpdateDeviceUnitsHandler:7209](../analysis/smali/classes5/com/noisefit_zhsdk/handler/ZhUpdateDeviceUnitsHandler.smali#L7209), [ZhUpdateDeviceUnitsHandler:4706](../analysis/smali/classes5/com/noisefit_zhsdk/handler/ZhUpdateDeviceUnitsHandler.smali#L4706), [DataConverter:3854](../analysis/smali/classes5/com/noisefit_zhsdk/handler/DataConverter.smali#L3854).

### Berry path

1. Parse the local firmware URI into a file and read its bytes.
2. Set the shared update-in-progress flag.
3. Call `ControlBleTools.getDeviceLargeFileStateByBerry(bytes, "ota", deviceType, firmwareVersion, listener)`; the latter metadata comes from `WatchInfoGlobals` getters.
4. The callback compares the returned status to `READY`.
5. On readiness call `startUploadBigDataByBerry("ota", bytes, uploadListener)`.
6. Convert upload progress, success and timeout to shared update callbacks.

Sources: [ZhUpdateDeviceUnitsHandler$updateFirmware$1:1](../analysis/smali/classes5/com/noisefit_zhsdk/handler/ZhUpdateDeviceUnitsHandler$updateFirmware$1.smali#L1), [ZhUpdateDeviceUnitsHandler$updateFirmware$1$onSuccess$1:1](../analysis/smali/classes5/com/noisefit_zhsdk/handler/ZhUpdateDeviceUnitsHandler$updateFirmware$1$onSuccess$1.smali#L1).

The packaged `BerryLargeFileManager` maintains send mode, current index, cached indices, slice length, resume-related state and unanswered transmission state. Its constants include a 1 MiB slice limit, 1 MiB unanswered-data limit, 20,000 ms unanswered timeout, 9-byte base header, 12-byte data header and 990-byte payload base multiple. These describe manager internals, **not** a universal BLE packet length or a complete wire format. There are both BLE and SPP-related transport hooks and separate ring-service paths; which is used depends on the connected device and protocol.

Source: [BerryLargeFileManager:1](../analysis/smali/classes9/com/zhapp/ble/manager/BerryLargeFileManager.smali#L1).

### SiFli path

The updater marks OTA in progress, registers its SiFli handling, derives a file list using `DiyHelperSdkSide.i(fileUri)`, calls `SifliDFUService.p0(context, address, files, 1, 0)`, then disconnects the normal `ControlBleTools` connection. That handoff explains why the ordinary BLE link can drop as part of an intended update.

The packaged manifest declares `com.sifli.siflidfu.SifliDFUService`; this is an actual adapter call into that implementation, not just a dormant service declaration. Packet-level SiFli DFU behavior and the exact component list require further tracing of that SDK/package.

Sources: [ZhUpdateDeviceUnitsHandler:7209](../analysis/smali/classes5/com/noisefit_zhsdk/handler/ZhUpdateDeviceUnitsHandler.smali#L7209), [DiyHelperSdkSide:1](../analysis/smali/classes5/com/noisefit_zhsdk/DiyHelperSdkSide.smali#L1), [manifest](../analysis/AndroidManifest.xml).

### Other ZH large-file path

The remaining branch constructs a local file and calls:

```text
getDeviceLargeFileState(true, "443", "1305828", listener)
READY -> startUploadBigData("ota", fileBytes, false, uploadListener)
```

Those two strings are hardcoded in this build. SDK logging labels the corresponding arguments as version and MD5, but their actual values and short length should not be interpreted as a validated package digest. The old preparation API explicitly rejects Berry protocol in SDK code; the app's earlier Berry branch avoids that route.

Sources: [ZhUpdateDeviceUnitsHandler$updateFirmware$2:1](../analysis/smali/classes5/com/noisefit_zhsdk/handler/ZhUpdateDeviceUnitsHandler$updateFirmware$2.smali#L1), [ControlBleTools:13823](../analysis/smali/classes9/com/zhapp/ble/ControlBleTools.smali#L13823).

Upload progress is computed as `sent * 100 / total`. Upload success clears the shared OTA flag and emits `COMPLETED`; timeout clears the flag and emits `ERROR`. Preparation not-ready and timeout paths also report failure. This callback does not by itself prove post-reboot firmware identity.

Source: [ZhUpdateDeviceUnitsHandler$updateFirmware$2$onSuccess$1:1](../analysis/smali/classes5/com/noisefit_zhsdk/handler/ZhUpdateDeviceUnitsHandler$updateFirmware$2$onSuccess$1.smali#L1).

The SDK's preparation status enum includes `READY`, `BUSY`, `DUPLICATED`, `LOW_STORAGE`, `LOW_BATTERY`, `DOWNGRADE`, device-ID and space errors, plus other resource-specific errors. These enum names establish that such status concepts exist; they do not establish every firmware's policy, or numeric on-wire values.

Source: [DeviceLargeFileStatusListener$PrepareStatus:1](../analysis/smali/classes9/com/zhapp/ble/callback/DeviceLargeFileStatusListener$PrepareStatus.smali#L1).

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

- [ProUpdateDeviceUnitsHandler:2569](../analysis/smali/classes16/com/noisefit/colorfit_pro/handler/ProUpdateDeviceUnitsHandler.smali#L2569).
- [CF2UpdateDeviceUnitsHandler:1288](../analysis/smali/classes5/com/noisefit_cf2/handler/CF2UpdateDeviceUnitsHandler.smali#L1288).
- [Evolve2UpdateDeviceUnitsHandler:1377](../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2UpdateDeviceUnitsHandler.smali#L1377).
- [RyeexUpdateDeviceUnitsHandler:994](../analysis/smali/classes5/com/noisefit_ryeex_sdk/handler/RyeexUpdateDeviceUnitsHandler.smali#L994).
- [DFutureUpdateDeviceUnitsHandler$updateFirmware$1:1](../analysis/smali/classes5/com/noisefit_sdk_dfuture/handler/DFutureUpdateDeviceUnitsHandler$updateFirmware$1.smali#L1).
- [CommonPtUpdateDeviceUnitsHandler:1134](../analysis/smali/classes13/com/common_protocol/handler/CommonPtUpdateDeviceUnitsHandler.smali#L1134).
- [TopstepUpdateDeviceUnitsHandler:3079](../analysis/smali/classes5/com/noisefit_topstep/handler/TopstepUpdateDeviceUnitsHandler.smali#L3079).
- [CreekUpdateDeviceUnitsHandler:7079](../analysis/smali/classes18/com/noisefit/noisefit_creek/handler/CreekUpdateDeviceUnitsHandler.smali#L7079).
- [NavPlusUpdateDeviceUnitsHandler:3791](../analysis/smali/classes5/com/noisefit_nav_plus/handler/NavPlusUpdateDeviceUnitsHandler.smali#L3791) and [NavPlusUpdateDeviceUnitsHandler$updateFirmware$1:1](../analysis/smali/classes5/com/noisefit_nav_plus/handler/NavPlusUpdateDeviceUnitsHandler$updateFirmware$1.smali#L1).
- [NFHUpdateDeviceUnitsHandler:1792](../analysis/smali/classes18/com/noisefit/hybrid/handler/NFHUpdateDeviceUnitsHandler.smali#L1792).

## CommonPt package and protocol boundary

The CommonPt adapter reports an error for a missing local file or empty extraction result. It scans the extraction directory for `config.json` and `.res` files, sets `FirmwareUpdate.version`, `resFull` and `bytes`, then calls `DeviceService.updateFirmware`. The inspected adapter does not itself show a signature check; validation may occur below the service or in the device. Some malformed/incomplete config cases are not comprehensively handled at this adapter boundary.

The generated protobuf `NPBFirmware.FirmwareStart` declares field numbers: `version = 1`, `res_full = 2`, `length = 3`, `md5 = 4`. This establishes a transfer metadata schema. It does not establish MD5 as a signature or demonstrate that arbitrary firmware would be accepted.

Source: [NPBFirmware$FirmwareStart:1](../analysis/smali/classes17/com/noise/wear/protocol/protobuf/entity/NPBFirmware$FirmwareStart.smali#L1).

## Embedded Python OTA is another boundary

The package also includes Realthread/PersimWear Java bindings to Python `service_ota_*` functions and the corresponding readable Python upgrade implementation. This is analyzed separately in chapter 09. Its presence and Java bridge are confirmed; it should not be assigned to Luna Band without tracing that model's selected runtime SDK path.

## Update-security conclusions that this sample does not support

Checksums, file MD5, app authentication, signed firmware and bootloader enforcement are different mechanisms. This report establishes several client-side integrity/preparation fields, but cannot conclude either that firmware is authenticated or that unsigned/downgraded images are accepted. It also does not establish rollback resilience, flash layout, recovery pinouts or safe interruption behavior for the physical band.
