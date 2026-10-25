# Silence — Flutter companion

Initial Flutter implementation for the Silence OS project and ColorFit Pulse 2. Version **0.13.0+17** is a watch face studio and uploader for the Pulse 2. Firmware, health data and notifications stay with NoiseFit.

## Available now

- **Studio**: design a 240×280-aspect watch background from 14 gradient presets, a custom gradient (start/end colors from swatches, an HSV picker or hex, plus an angle and swap) or a gallery photo (zoom, drag to reposition, dim), with no fake clock. Export is a 480×560 PNG.
- **Send to watch**: builds a `.watch` file from the bundled Pulse 2 template (background and preview images swapped, see [transfer notes](../docs/silence-os/08-watch-file-transfer.md)) and uploads it over the bound connection. Verified on a Pulse 2.
- **Clock styles** (Studio): Analog (template hands), and generated digital faces **Stack** (hours over minutes, like the Silence concept) and **Row**. Digital faces bake each digit over your wallpaper; the watch only swaps images. Hour and minute colors come from a preset palette, a custom HSV picker or a hex code. Stack and Row are verified on a Pulse 2; custom colors are not.
- **Watch card** (Studio): Find/Connect to your watch, automatic pairing, one-tap reconnect to the last watch (remembered after a successful bind), and **Release watch**. Optional **Connect on launch** is in the About dialog; it is off by default because Silence holds the connection and NoiseFit cannot reach the watch until you release it.
- **Developer tools** (off by default; switch in the About dialog): the Android BLE scanner and GATT inspector, plus **Pair watch**, which runs the TouchGUI bind handshake ([notes](../docs/silence-os/07-touchgui-bind.md)) and shows a copyable protocol log, with the always-visible **Unpair / release watch** control and a demo mode. Connecting it can stop NoiseFit from reaching the watch, so it is a research tool, not part of the normal flow.
- **Phone notifications** (Studio): with Android notification access granted, relays your phone's notifications to the watch while Silence is connected: master switch, per-app filters, optional message text, a recent log, de-duplication and rate limiting ([notes](../docs/silence-os/09-notification-protocol.md)). The message command and the live relay, including background operation, are verified on a Pulse 2. While the watch is bound, a foreground service keeps the connection and relay running with the app closed.
- **Watch status**: after pairing, Silence syncs the watch clock and shows battery, firmware and last sync on the watch card, with Refresh and Sync time ([notes](../docs/silence-os/11-status-and-time.md)). Not yet verified on hardware.
- **Quick replies and watch controls**: editable preset replies are sent to the watch; a reply chosen on the watch is delivered through the original app's inline reply. The watch offers replies only on SMS-type notifications, so reply-capable apps are sent as SMS (switchable). Watch music and volume keys control the phone ([notes](../docs/silence-os/10-watch-events-and-quick-replies.md)). Not yet verified on hardware.
- **Weather**: pick a city (Open-Meteo, no key) and Silence sends current conditions and a four-day forecast to the watch, hourly while connected ([notes](../docs/silence-os/12-weather-protocol.md)). Not yet verified on hardware.
- **Notification test** (Developer tools): sends preset or custom test notifications to the watch.
- Browser design preview; watch connection and upload are Android-only.

Silence talks to the watch directly: NoiseFit's custom face editor is paywalled, so the earlier NoiseFit handoff (save to photos, open in NoiseFit) was removed. Pairing and upload are the only operations that write to the watch, and only on user action; both are verified on a Pulse 2. See the [handoff research](../docs/silence-os/06-noisefit-handoff-research.md).

## Run

Use Flutter with Dart 3.11 or later, an Android SDK and Java 17 or later. This workspace was checked using Flutter 3.47.7 / Dart 3.13.5. The Android project targets API 36, supports API 26+, and pins AGP 8.13.1 / Kotlin 2.2.20 / Gradle 8.14.

From this directory:

```sh
flutter pub get
flutter analyze
flutter test
flutter run -d <android-device-id>
```

To explore the UI without a phone:

```sh
flutter run -d chrome
```

Choose **“Just looking? Explore a demo”** on the Device page to simulate discovery/connection. Studio previews work without entering demo mode. Sample time/activity values in the artwork are illustrations.

For an Android development APK:

```sh
flutter build apk --debug
```

Expected output: `build/app/outputs/flutter-apk/app-debug.apk`. This environment has **not produced that APK**; see validation below. Release signing/distribution is not configured; the generated release configuration currently uses the development signing setup.

Do not unpair the watch in NoiseFit just to scan in Silence. Before returning to NoiseFit, use **Unpair / release watch**; then open NoiseFit and add/reconnect the device. If necessary, use the Bluetooth-settings shortcut to Forget a system bond. The user confirmed that force-stopping Silence also released its connection and allowed NoiseFit pairing again. Android 12+ requests Nearby devices access; older supported Android versions request location permission and require Location services for scanning. These requirements follow [Android's Bluetooth permission model](https://developer.android.com/develop/connectivity/bluetooth/bt-permissions). Discovery shows nearby BLE advertisements without assuming a confirmed Pulse 2 profile.

## Structure

| Path | Responsibility |
| --- | --- |
| `lib/ui/` | Theme, shared widgets, Studio page and developer Device screen |
| `lib/studio/` | Artwork model, painter and PNG export |
| `lib/controller/` | Observable operation state, demo isolation and stale-event filtering |
| `lib/services/` | BLE transport contract, settings store and Android channels |
| `android/app/src/main/kotlin/dev/silence/silence_app/` | `SilenceApp` (engine), `BleHost` (scan/connect/channels), `TouchGuiSession` (bind, upload, commands), `RelayService` (foreground service), `SilenceNotificationListener`, `MainActivity` (UI only) |
| `test/widget_test.dart` | Responsive, Studio, pairing, upload, demo and service-display tests (loads the bundled font so layout matches the device) |
| `tool/render_smoke.dart` | Socket-free controller and actual Flutter rendering checks |

The bridge uses [Flutter platform channels](https://docs.flutter.dev/platform-integration/platform-channels), keeping native Bluetooth behavior separate from the widget layer. It does not include a redistributed vendor SDK.

## Validation in this workspace

- Flutter static analysis and release web compilation passed during development; final check results are recorded in the [implementation note](../docs/silence-os/05-flutter-foundation.md).
- Native Kotlin BLE bridge compiled against the installed Android/Flutter artifacts; Android resources passed `aapt2 compile`.
- The standard widget suite compiled, but its execution is blocked here because this sandbox denies localhost socket binding. Gradle APK assembly is blocked by the same class of socket restriction before the build can start. These are not successful full-suite/APK results.
- A separate socket-free harness runs inside the actual Flutter engine with the VM service disabled. It checks discovery/deduplication, stale connection/service rejection, disconnect, demo isolation, eight layouts and preview open/close. It is useful additional coverage, not a replacement for the normal suite or real device testing.
- Bluetooth pairing and face upload were verified by hand on a Pulse 2; there are no automated hardware tests.

On Linux with a populated writable Flutter SDK and dependencies resolved:

```sh
bash tool/render_smoke.sh /path/to/flutter-sdk
```

It writes PNGs to `build/previews/`. Run the standard suite in an unrestricted development environment. Optional standard-test screenshot capture:

```sh
SILENCE_WRITE_PREVIEWS=1 flutter test test/widget_test.dart
```

## Next step

Persist the Studio design, add battery/version status from the documented query packets, and decode the encoded image format so digital faces can use hands and richer widgets. See [transfer notes](../docs/silence-os/08-watch-file-transfer.md).

Roboto font files are bundled from the installed Flutter SDK with their [Apache 2.0 license](assets/fonts/LICENSE.txt). Their license is separate from project code. Watchface concept artwork is drawn locally by the app; it is not a device-compatible binary export.
