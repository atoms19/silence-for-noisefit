# Notification (message) protocol

How NoiseFit's TouchGUI SDK pushes a notification to a ColorFit Pulse 2, recovered from NoiseFit 5.4.6 smali. **Verified on a Pulse 2 (user-reported, 2026-10-25)** with the developer test panel; see "Hardware results". Paths under `analysis/smali/classes5/com/touchgui/sdk/`.

## Command

`TGCommandBuilder.A(TGMessage)` -> `internal/l9.A` -> `internal/d2.a(String,String,String,int)` -> parser `internal/a6` (command id `0x000B`, base class `internal/h5`).

NoiseFit fills the message from an `AppNotification` (`noisefit_evolve2/handler/Evolve2UpdateDeviceUnitsHandler`, ~line 836): `name` goes to the first string, `number` to the second, `message` to the third, and the app type code is mapped from the application type.

### Body (`a6.f`, little-endian)

```
00 00 | hasName hasNumber hasContent | type | 00 |
  [00 | len32 | name utf8]  [00 | len32 | number utf8]  [00 | len32 | content utf8]
```

Each field is present only when non-empty. Content is cut (whole characters) so it fits within `0x2ed - headerBytes`; the content's own 5-byte header is not counted, so the body can reach 754 bytes. If device capability `0x2090802` is set, every string's bytes are bitwise inverted (`internal/s.g`); the Pulse 2's value is unknown, so the demo panel has an "Invert text bytes" switch.

### Type adjustment

If the device protocol field (`a0.c`) is below `0x300` and the type is `>= 0x30` or in `0x1a..0x1f`, the SDK replaces the type with `0x80` (`d2.smali:~23`). The codes used by NoiseFit's mapping: SMS 1, WeChat 3, Facebook/Messenger 6, Twitter 7, WhatsApp 8, Instagram 0xa, LinkedIn 0xb, Calendar 0xc, Skype 0xd, Viber 0x12, Gmail 0x14, Outlook 0x15, Snapchat 0x16, Telegram 0x17, other 0x80. `TGMessage` defines further codes up to `0x47`; their names are not recovered.

### Framing (`internal/h5.a(I)`)

```
DA AD DA AD | version=01 | len16 = bodyLen+11 | command id16 | sequence16 | body | crc16
```

- Little-endian throughout; total length = body + 13.
- Sequence: `(counter++ % 0xFFFE) + 1`.
- CRC-16 over every byte before it: init `0xFFFF`; per byte `crc = (crc>>8 | crc<<8) & 0xFFFF; crc ^= b; crc ^= (crc & 0xFF) >> 4; crc ^= (crc << 12) & 0xFFFF; crc ^= ((crc & 0xFF) << 5) & 0xFFFF` (`internal/a.a`). This is CRC-16/CCITT-FALSE; the check value for `123456789` is `0x29B1` (tested).

### Transport

- Channel 1 (`27f6`, or `0af6` on service `0af0`): `h5.c()` returns 1.
- Fragmentation: every packet is `0x33` followed by up to `mtu - 4` message bytes (SDK: packet size `mtu - 3`, minus the `0x33`). No acknowledgement between fragments; after the last one the SDK waits for the reply.
- Reply: a notification that starts `33 DA AD DA AD`; the byte at index 11 is the status.

## Hardware results (Pulse 2)

- Works: the command, framing, CRC and fragmentation as implemented. Text is readable with **byte inversion off**; inverting produced nothing legible, so the capability bit is not set for this watch.
- App types that display: SMS (the watch offers quick replies), WhatsApp, Gmail, Telegram, Instagram and the other tested types.
- Type `0x0b` (LinkedIn) and `0x0c` (Calendar) show nothing; Calendar sometimes appeared with a messaging look. Type `0x80` (other) displays like an SMS-style message. Silence therefore sends LinkedIn and Calendar notifications as `other`.
- Not yet examined: what the watch sends back when a quick reply is chosen.

## In Silence

- `services/touchgui_notification.dart` builds the message (unit-tested); `TouchGuiSession.sendLongCommand` fragments and writes it; replies appear as status text and in the protocol log.
- Developer tools > **Notification test** (after a successful bind) sends presets or custom text. Nothing is read from the phone yet.

## Not covered

Incoming-call and missed-call notifications (separate commands), per-app enable lists on the watch, notification icons, dismiss/clear commands, reading phone notifications (Android `NotificationListenerService`).

## Live relay (Silence 0.9, verified on a Pulse 2)

`SilenceNotificationListener` (an Android `NotificationListenerService`) forwards notifications to the running app; `SilenceController` maps them (`services/phone_notifications.dart`), de-duplicates identical ones within 5 s, queues them one at a time (1.5 s apart, at most 10) and sends each with the same message command. Skipped: the app's own notifications, ongoing and group-summary notifications, empty ones, and system, call and dialer packages (calls use a separate command). Unknown apps are sent as `other` with the app name in the second field. Users can switch the relay off, hide message text (only the app name is sent) and disable apps individually.

### Background operation (Silence 0.10)

- `SilenceApp` (the `Application`) creates one Flutter engine and one `BleHost` per process and caches the engine. `BleHost` owns scanning, the GATT connection and the TouchGUI session; `MainActivity` only shows the UI on the cached engine and lends itself to `BleHost` for permission dialogs.
- When a bind succeeds, `BleHost` starts `RelayService`, a foreground service of type `connectedDevice` with an ongoing "Silence is connected" notification (tap to open, **Release watch** action). It stops when the connection is released or lost. The service holds no Bluetooth state; it keeps the process, the engine and the Dart relay alive after the activity is closed or swiped away.
- The Dart controller is created in `main()`, not in a widget, so relaying works with no screen attached. If the notification listener is bound after a reboot, the process starts and, with **Connect on launch** enabled, reconnects to the last watch.
- Android 13+ asks for the notification permission once so the service notification is visible. Battery optimisation can still stop the app; exempting Silence in Android settings helps.
- Limits: a foreground service cannot always be started from the background (Android 12+), so a headless auto-reconnect keeps the connection but may run without the service notification. A hot restart in development cancels the event stream and releases the watch. Verified on a Pulse 2 (user-reported): relaying with the screen on and off, and with the app closed, works while the foreground service is running.
