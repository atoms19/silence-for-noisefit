# Flutter app: transport discovery and TouchGUI protocol boundary

This chapter separates the initial Flutter app's intended transport functions from the device protocol still being researched. It is based on the locally disassembled APK; no server or watch request was made for this review. Build and device-test status belongs in the application's README.

## Initial application boundary

The first Flutter implementation targets Android BLE discovery, explicit connection/disconnection, GATT service enumeration, connection/error display and local watchface design previews. Bluetooth activity starts from a user action. It does not establish TouchGUI session readiness, read health records, report verified live battery/firmware values, or transfer firmware/watchfaces.

A generic Android `STATE_CONNECTED` event means the Bluetooth transport connected. Successful service discovery supplies the observed service table. Neither event, by itself, proves that the watch has initialized its vendor command channel or accepted this app as its companion.

Watchface design previews must not be presented as device-compatible compiled binaries until the export/transfer milestones are verified.

## Verified model integration

The APK's exact `colorfit_pulse_2` branch uses Evolve2/TouchGUI. Its firmware catalog default `2109` is metadata, not a GATT service, BLE command or observed hardware revision. See the [model investigation](../11-colorfit-pulse-2.md).

The Evolve application handler obtains a `TGClient` through `TGBleClient.Builder`, while query handlers obtain a `TGCommandBuilder` through `TGClient.s()`. Sources: [Evolve2ApplicationHandler](../../analysis/smali/classes5/com/noisefit_evolve2/base/Evolve2ApplicationHandler.smali#L181), [query adapter](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2QueryDeviceUnitsHandler.smali#L912).

## GATT candidates from the bundled SDK

All UUIDs below use suffix `-0000-1000-8000-00805f9b34fb`:

| Service prefix | Characteristic candidates | Evidence boundary |
| --- | --- | --- |
| `00000af0` | `00000af1`, `00000af6` | Shared TouchGUI service/channel selection |
| `000027f0` | `000027f1`, `000027f6` | Shared TouchGUI alternative service/channel selection |
| `00002760` | `00002761`, `00002763` | Other SDK channel branches; notification handling also references `2762` |

The branch chooses services and channels using an internal operation/channel argument. These values are **not a measured ColorFit Pulse 2 profile**, and their presence in another advertisement is not sufficient to assert an exact model match. Device name matching is similarly a hint rather than confirmed hardware identity.

Source: [service and write-channel selection](../../analysis/smali/classes5/com/touchgui/sdk/internal/g.smali#L560).

After service discovery, the SDK's callback iterates candidate services and characteristics, tests the notification property bit `0x10`, calls `setCharacteristicNotification`, collects descriptors and starts its descriptor-processing routine. Consequently future protocol support needs notification/descriptor setup and serialized asynchronous GATT operations, rather than merely selecting a UUID and writing a guessed payload.

Source: [onServicesDiscovered](../../analysis/smali/classes5/com/touchgui/sdk/internal/l.smali#L861).

The initial transport inspector deliberately does not duplicate those vendor initialization writes. Exact channel choice, descriptor handling, framing, capabilities/session initialization, timeouts and successful readiness criteria remain follow-up protocol work.

## Battery and firmware are vendor queries in the inspected adapter

| Query | Verified Android path | Why a generic Bluetooth read is insufficient evidence |
| --- | --- | --- |
| Battery | `Evolve2QueryDeviceUnitsHandler.H0()` → `TGCommandBuilder.getBatteryInfo()` → command/parser `internal.b8` | The adapter executes a vendor command and receives a `TGBatteryInfo` object |
| Firmware version | `Evolve2QueryDeviceUnitsHandler.K0()` → `TGCommandBuilder.i0()` → command/parser `internal.a8` | The adapter receives structured `TGVersionInfo`, then applies model-specific version conversion |

Sources: [battery adapter](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2QueryDeviceUnitsHandler.smali#L912), [version adapter](../../analysis/smali/classes5/com/noisefit_evolve2/handler/Evolve2QueryDeviceUnitsHandler.smali#L962), [battery command builder](../../analysis/smali/classes5/com/touchgui/sdk/internal/l9.smali#L2401), [battery parser](../../analysis/smali/classes5/com/touchgui/sdk/internal/b8.smali), [version parser](../../analysis/smali/classes5/com/touchgui/sdk/internal/a8.smali).

The parser constructors use command identifier byte pairs `(0x02, 0x05)` for battery and `(0x02, 0x11)` for version. These are protocol research leads, **not complete transport packets or a validated send recipe**. Their parsers start reading after two command bytes and use little-endian fields; transport framing and operation setup must still be traced independently.

Do not populate live battery or version UI from the user's earlier reported version or cached/demo values. If standard Battery/Device Information services happen to appear in real discovery, their readable characteristics could be evaluated separately; the current evidence neither proves their presence nor establishes that they replace the vendor query path.

## Next implementation evidence

1. Record actual service UUIDs and characteristic properties from the available Pulse 2, with the original app's connection released.
2. Trace the vendor readiness sequence from notification/descriptor completion through capability/device-info initialization. Distinguish bonding/binding from temporary transport connection.
3. Recover full request framing and response matching for one query, then validate it against an observed command/response exchange.
4. Implement that verified query behind a Pulse 2 adapter, with bounded response parsing and serialized operations.
5. Trace watchface preparation, transfer, verification and activation as its own protocol before enabling installation UI.

These steps preserve a useful read-only transport inspector while making the remaining protocol work explicit.


## User-observed connection ownership and recovery

After the user unpaired in NoiseFit and connected with Silence, the watch remained on its QR screen and could not pair through NoiseFit while Silence held the BLE connection. The user then force-stopped Silence, observed that its Bluetooth connection broke, and confirmed that pairing through NoiseFit worked again. This is user-reported runtime evidence, not an instrumented packet capture.

This supports a connection-ownership problem rather than a persistent watch lock. It does not establish that the watch stopped advertising, that every QR-screen condition has the same cause, or that firmware state was damaged. Silence's generic GATT connection did not complete the companion bind handshake.

The inspected original adapter's connector-ready callback runs `TGCommandBuilder.b0()` and checks `TGBindResult` before declaring connection success. That handshake is absent from the initial Silence build. Closing GATT, removing an Android bond and vendor unbinding are separate actions; copying an unverified unbind packet is not required for the recovery observed here.

Silence 0.1.1 therefore adds an always-visible **Unpair / release watch** control. It cancels native pending permission operations/scans/connections, closes GATT, clears local scan/service/device state and rejects late callbacks. It remains available while connecting or discovering services. It also offers Android Bluetooth settings for system-level Forget/Unpair if a bond exists. It does not remove a system bond itself, reset the watch or claim to exit the QR screen.

Do not unpair through NoiseFit merely to make Silence's discovery list populate. Release Silence's connection before returning to NoiseFit. Future connection UI must distinguish transport-connected from companion-ready, and coexistence/handoff testing is a prerequisite for the first usable device release.
