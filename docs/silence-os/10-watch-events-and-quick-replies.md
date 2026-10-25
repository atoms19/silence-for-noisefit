# Watch-to-phone events and quick replies

How the ColorFit Pulse 2 reports unsolicited events (quick reply chosen, music keys, call buttons, find-phone) and how NoiseFit's SDK configures and consumes them. Static analysis of NoiseFit 5.4.6 smali only; **nothing here has been sent to or received from a watch**. Paths are under `analysis/smali/classes5/com/`; `sdk/` = `touchgui/sdk/internal/`, `nf/` = `noisefit_evolve2/handler/`. Framing background: [07](07-touchgui-bind.md), [08](08-watch-file-transfer.md), [09](09-notification-protocol.md).

Legend: **V** = read directly from bytecode, **I** = inferred, **?** = unresolved.

## 1. How the SDK recognises unsolicited events

- Registration: `sdk/t9.smali:73` (`a()`) creates five persistent "listener commands" (`sdk/g6`, a `d` subclass whose `a(callback)` appends itself to `i3.b` instead of queueing, `sdk/d.smali:80`). Each pairs a parser with a callback: `i2`->`m9`, `j2`->`p9`, `k2`->`q9`, `l2`->`r9`, `v5`->`s9`. **V**
- Dispatch: `sdk/l.smali:23` (`onCharacteristicChanged`) offers every incoming notification to the in-flight command first, then walks `i3.b`: for each listener `parser.a(bytes)` (match) then `parser.c(bytes)`; a return value with bit `0x800` calls the callback (`d.p()`). **V** There is **no acknowledgement** sent back for events (`e8.b` returns 0, `e8.c` returns `0x808`, `sdk/e8.smali:23`). **V**
- All notify-capable characteristics are subscribed, so events can arrive on any of them; matching is by header bytes only. **I**

## 2. Event formats

### 2a. Short events: `07 <category> <payload>` (parsers extend `sdk/e8`, base ctor `(0x07, category)`)

Raw notification bytes, no framing, same style as the bind/device-info commands. Matching: `bytes[0] == 0x07 && bytes[1] == category` (`e8.a`, **V**).

| Category | Parser | Payload | Delivered as |
| --- | --- | --- | --- |
| `0x01` | `i2` | `byte[2]` = event code | `TGEventListener.b(code)` |
| `0x02` | `j2` | `byte[2]` | `TGEventListener.c(value)` (find phone) |
| `0x03` | `k2` | `byte[2]`, `byte[3]`, `byte[4] == 1` | `f(TGSportStatusEvent)` (sport state, GPS sports) |
| `0x40` | `l2` | `u16 LE at [2..3]`, flag byte `[4]` (bits 0,1,2,3 + whole byte), optional `[5]` (bit 0 + whole byte) | `TGDataUpdated`, mapped by `r9` to `b(0x301/0x302/0x303 ...)` (data-changed notifications) |

All **V** (`sdk/i2,j2,k2,l2.smali`, `sdk/q9`, `sdk/r9`).

#### Category `0x01` event codes (NoiseFit's reaction, `nf/Evolve2QueryDeviceUnitsHandler$tgEventListener$1.smali:34`)

| Code | NoiseFit action | Confidence |
| --- | --- | --- |
| `0x01` | Music **play** (`OnMusicEventChanged("play")`) | V |
| `0x02` | Music **pause** | V |
| `0x04` | Music **previous** | V |
| `0x05` | Music **next** | V |
| `0x08` | Volume **up** (`AudioManager.adjustStreamVolume(STREAM_MUSIC, ...)` then re-sync music info) | V for the call, direction I |
| `0x09` | Volume **down** | I |
| `0x0c` | `UpdateCallStatus(a=true, b=false)` -> `CallHandler.g(false)` -> `CallHandler.c()` which uses `TelecomManager.endCall` (reject/hang up) | V chain, meaning "reject/hang up button" I |
| `0x0d` | `UpdateCallStatus(false, false)`: same hang-up, but only if NoiseFit's own setting is on (`DataStoredInterface.F7()`) (`classes18/.../ConnectionService$queryCallback$1.smali:1021`) | V chain, meaning I |
| `0x0e` | `MuteDevice` -> `CallHandler` silences the ringer | V chain, meaning I |

Category `0x02`: `value == 0` means **open find-my-phone** (start ringing), non-zero means stop (`nf/...tgEventListener$1.smali:236`, `OpenFindMyPhoneActivity(bool)`). **V** for the mapping, polarity as read (`p1 == 0 -> true`).

`TGEventListener` also defines codes `0x110-0x127` and `0x301-0x303` (`sdk/TGEventListener.smali`); NoiseFit's listener only handles the ones above. `0x301-0x303` come from category `0x40`. Camera shutter and other codes: **?** (not routed through this listener).

### 2b. Long event: **quick reply**, command id `0x16` (parser `sdk/v5`, an `h5` long command)

Framing is the long-command format from doc 09 (`33`-prefixed packets, `DA AD DA AD`, version 1, len16, cmd16, seq16, body, crc16). Matching (`v5.a`, `sdk/v5.smali:21`): raw packet `[1..4] == DA AD DA AD`, version byte `[5] == 1`, `cmd16 [8..9] == 0x0016`, **and `seq16 [10..11] == 0`** (the parser's own sequence field never changes, so events must carry sequence 0). **V** Continuation fragments (no magic) are rejected by `v5.a`, so a quick reply must fit one packet. **V**

Once matched, `h5.c` (`sdk/h5.smali:458`) strips the `33` prefix, reassembles, checks the CRC-16 over the first `len16` bytes of the unprefixed message, and calls `v5.d` with the **unprefixed** message. Body offsets below are in the unprefixed message (payload starts at 11); in a raw notification add 1.

`v5.d` (`sdk/v5.smali:132`) **V**:

```
payload[0]            count    -> TGQuickReply.a   (number of presets configured; see 3)
payload[1] low nibble index    -> TGQuickReply.b   (1-based index of the chosen preset)
payload[1] high nibble 0xF     flag: a number field follows
payload[2]            textLen
[payload[3]           numberLen]        only if the flag nibble is 0xF
[number bytes]                          UTF-8, NUL terminated or numberLen
text bytes (textLen)                    UTF-8, NUL terminated or textLen   -> TGQuickReply.c
```

So the watch **returns the reply text itself**, not just an index. The number defaults to empty; `s9` (`sdk/s9.smali:26`) fills it from `a0.E` when the event carries none. `a0.E` is the number of the last **SMS-type message** (`d2.a`, type 1, only when capability `0x2020908` is set) or the last incoming-call push (`l9.j`, `sdk/l9.smali:2619`). **V**

## 3. Configuring the quick-reply presets: long command `0x15`

`TGCommandBuilder.m0(List<TGQuickReply>)` (`sdk/l9.smali:2985`) **V**:

- Up to **5** replies (a longer list only logs "Up to 5 messages"); the list is padded with empty replies to 5; each is given `index = position + 1` (`TGQuickReply.f`).
- `sdk/n1.smali:62` sends them **one command per reply, sequentially** (each waits for its reply before the next).
- Each command is an `h5` long command, id `0x15` (`sdk/u5.smali`, ctor `S = 0x15`), body (`u5.f`, `sdk/u5.smali:43`):

```
body[0] = count (reply list size after padding, i.e. 5)
body[1] = index (1..5)
body[2] = text byte length   (text is cut to 128 bytes)
body[3..] = text, platform default charset (UTF-8 on Android)
```

- Reply to each: long reply, `payload[0]` (index 11 of the unprefixed message) is the status (`u5.d`). Success value **?** (NoiseFit ignores it).
- NoiseFit builds the list from `CustomReplyData.CustomReply.getContent()` (`nf/Evolve2UpdateDeviceUnitsHandler.smali:~1225`, `updateCustomReply`). The default preset strings are not in the smali and were not found in extracted resources (**?**; they likely come from the app's UI/string resources or cloud). The watch's built-in defaults are also unknown.

## 4. How NoiseFit handles a quick reply

`tgEventListener$1.d(TGQuickReply)` (`nf/...tgEventListener$1.smali:267`) **V**:

1. If `android.permission.SEND_SMS` is not granted: emit `UpdateCallStatus(false, false)` and stop.
2. Else: emit `UpdateCallStatus(false, false)` (dismiss/hang up the ringing call) and send `SmsManager.getDefault().sendTextMessage(number, null, reply.getText(), null, null)` where `number` is `Evolve2UpdateDeviceUnitsHandler.Companion.b()`, the **incoming-call number** stored when NoiseFit pushed the call to the watch (`setIncomingCallInfo$1.smali`, `Companion.d(number)`). It does **not** use `TGQuickReply.d()`.

So NoiseFit's own quick reply is **"reject call with a text message"**. We observed the watch offering quick replies on SMS-type notifications; NoiseFit only wires replies to the call number, so replies to SMS notifications are probably never actually sent by NoiseFit (**I**). Which notification a reply refers to is not in the event (**?**).

## 5. Call push commands (for context; not part of this feature yet)

- Incoming call shown on the watch (`nf/Evolve2UpdateDeviceUnitsHandler.smali:521`, `E0(IncomingCall)`): `TGCommandBuilder.j(name, number)` -> short command **`05 01 | nameLen(1) | numberLen(1) | name | number`** (UTF-8, each cut to 64 bytes via `sdk/l6.smali:142`; bytes inverted if capability `0x2090802`). **V**
- Call ended/answered display: `TGCommandBuilder.C(code)` -> short command **`05 02 | code`** (NoiseFit sends code `2` when the call ends). **V** (`sdk/l9.smali:110`, `sdk/k6`)
- Replies to these are two-byte-echo replies like other short commands.

## 6. What Silence should implement

1. **Fix reply parsing first.** `TouchGuiSession.handleLongReply` reads the command id at `v[7..8]` and the status at `v[11]`, but a raw notification starts with the `33` prefix, so the real offsets are: len16 `[6..7]`, **cmd16 `[8..9]`, seq16 `[10..11]`, payload/status `[12]`**. The current values are shifted by one byte (the earlier demo "status" display was reading the wrong bytes; it still looked like a reply). Also stop treating every `33` packet as the answer to our last command: route by cmd id (`0x0B` = message reply, `0x15` = preset reply, `0x16` = quick reply event) and require seq to match for replies.
2. **Event dispatcher** in `onNotification` for the idle (non-upload) state: `[0]==0x07` short events (music, volume, find phone, call buttons, sport) and `33` packets with cmd `0x16`. Surface them to Dart as `watchEvent` events; no ACK is needed.
3. **Quick-reply flow:**
   - After bind, send the preset list (`0x15` x5) from user-editable strings in Studio (default e.g. "OK", "Can't talk now", "On my way", "Call you later", "Thanks"); keep each under 128 bytes.
   - On event `0x16`, surface `{index, text, number?}` to Dart.
   - Deliver the reply for **messaging notifications** through the original notification's reply action (`Notification.Action` with a `RemoteInput`, filled with `RemoteInput.addResultsToIntent` and fired through its `PendingIntent`); this works for WhatsApp, Telegram, Messages and others without SMS permission. The listener should remember, per relayed notification, its key and reply action, and apply the reply to the **most recently relayed** one (the event does not identify the notification).
   - For **calls** (later): `TelecomManager.endCall` plus `SmsManager.sendTextMessage` (needs `SEND_SMS` and a default-dialer-grade permission for `endCall`).
4. **Other events:** map music codes to a media-session / `AudioManager` key dispatch, volume codes to `AdjustVolume`, find-phone to a ringtone, `0x0c-0x0e` to the call controls once call relay exists.
5. **Probe before trusting:** log every unrecognised notification verbatim in the protocol log, and ask the user to press each watch control (music keys, reply, find phone) so the raw bytes can confirm the layouts in sections 2-3 and the success status of `0x15`.

## 7. Open questions

- Polarity/meaning of call codes `0x0c/0x0d/0x0e` and volume `0x08/0x09`.
- Whether the Pulse 2 sets the capability bits that change text encoding (`0x2090802`, already shown not set for messages) or that enable the number tracking (`0x2020908`).
- The success status of the preset command (`0x15`) and the watch's default presets.
- Whether the watch emits quick-reply events for SMS-type notifications that have no call context, and what `a`/`count` and the number field contain in practice.

## 8. Implemented in Silence 0.12

- `TouchGuiSession.handleLongPacket` now reads long replies at the correct offsets (cmd `[8..9]`, seq `[10..11]`, status `[12]`) and routes by command id: `0x0B` message reply, `0x15` preset reply, `0x16` quick-reply event (sequence 0). The status shown for the earlier notification demos was read one byte off; it still arrived as a reply.
- Short events `07 <category> <value>` are surfaced as watch events. Music codes 1, 2, 4, 5 and volume codes 8, 9 drive the phone (`mediaControl`, switchable). Find-phone and call-button events are only logged.
- Quick replies: five editable presets are sent with command `0x15` (one per message, 0.7 s apart). When the watch sends `0x16`, the text is delivered through the inline-reply action (`RemoteInput`) of the most recently relayed notification, remembered by `ReplyStore`. Apps without an inline reply action cannot be answered; those are reported as "nothing to reply to".
- Unverified on hardware: preset success status, the event layout, and which notification the watch means.

### Observation (user-reported, Pulse 2)

The watch shows the quick-reply button only on **SMS-type** (`0x01`) notifications; a WhatsApp-type (`0x08`) notification has none. Silence therefore has a switch (on by default) that sends any notification with an inline reply action as SMS type, with the app name in the second field, so replies are offered and the source stays visible. Notifications without a reply action keep their own type.
