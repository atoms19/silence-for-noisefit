# Watch file transfer protocol (`.watch` upload)

How NoiseFit's TouchGUI SDK sends a finished `.watch` dial file to a ColorFit Pulse 2, recovered from static analysis of NoiseFit 5.4.6 smali. **Verified end to end on a Pulse 2 (user-reported, 2026-10-25):** Silence uploaded a face built as described below, both with a gradient preset and with a gallery photo, and the watch displayed it. The 5-byte start-dial form was accepted. Details not independently observed, because the protocol log was not captured: reply byte layouts, whether acknowledgement checksum/offset fields matched (Silence logs a mismatch but does not abort on one), and whether the upload activates the face without the `03 E6` apply command. Paths are under `analysis/smali/classes5/com/touchgui/sdk/` (SDK root, abbreviated `sdk/`). Framing facts from [07](07-touchgui-bind.md) still apply: commands are raw byte arrays `[cmdA, cmdB, payload...]`, replies are notifications starting with the same two bytes, integers are little-endian.

## Channels and write rules

| Channel | Service `27f0` | Service `0af0` | Used for |
| --- | --- | --- | --- |
| 1 | `27f6` | `0af6` | **File commands `D1 xx`** (start, window, data, verify, resume) |
| 2 | `27f1` | `0af1` | **Dial commands `03 xx`** and everything else (the bind/device-info path already implemented) |

Channel is the `c` field of the command's `z8` base class: default 2 (`internal/z8` ctor), `1` for `o3/p3/q3/r3/s3` (third ctor argument). Mapping: `sdk/internal/g.smali:521` (`j(I[B)Z`, lines ~700-760). All writes use write type 1 (no response) in a single `writeCharacteristic` per packet (`g.smali` `j`); a failed write is retried up to 3 times, 50 ms apart (`internal/d.smali:405` `l(I)V`). The SDK sends the next packet only after the previous write's `onCharacteristicWrite` (`internal/l.smali:340`), then waits for a reply only where noted below. Default per-command reply timeout is 15 000 ms (`internal/d.smali:26` field `a`=0x3a98).

Packet length cap: `mtu - 3` where `mtu` is the value stored by the SDK's MTU negotiation (`g.d`); `d.l` passes `mtu - 3` to `j(int)` (`d.smali:405`, `sub-int ... 0x3`). Silence requests 247, so packets are at most 244 bytes.

## Step order (dial upload)

All steps verified in bytecode unless marked *inferred*. `b` = `sdk/b.smali`, `k` = `sdk/k.smali`.

1. **Start dial** (channel 2): `03 E4 | mode(1) | id(LE32)`; mode **1**, `id` = `TGDial.a()` (NoiseFit's photo dial passes id **0**, because `TGPhotoDialBuilder.d()` is never called, `Evolve2UpdateDeviceUnitsHandler.smali:~3265-3360`). Built in `internal/u8.smali:77`; command bytes `03 E4` in `internal/o8.smali:7` (`-0x1c` = 0xE4). Called from `b.smali:291` (`d(TGDial)`). Reply `03 E4 | status`; **status must equal 1** or the transfer aborts with "set dail operate failure" (`internal/n2.smali:64`). *Inferred, unresolved:* when device capability flag `0x2090c80` is set and `TGDial.c() > 0`, the SDK sends a 14-byte payload instead (`mode(1 or 4) | id | kind(1/2/3) | fileLength(LE32) | dial.c()(LE32)`); `a0.e()` is a capability bitmap from device info, so Silence cannot tell which form Pulse 2 expects without trying the 5-byte form first.
2. **Start file** (channel 1): `D1 01 | type(1) | size(LE32) | 00 | name(UTF-8, no terminator)`. For the photo dial the file name is the literal **`cfg_res.watch`**, type **`0x13`** (`b.smali:96-125` const `cfg_res.watch`; `internal/u3.smali:17` maps `cfg_res.watch`→0x13, `picture.watch`→0x12, `a.bin`→0x23, `b.bin`→0x21, `fonts.bin`→0x11). Built in `internal/t3.smali:7`; command bytes `D1 01` in `internal/o3.smali:7` (`-0x2f` = 0xD1). Reply `D1 01 | s`: **s = 0 accepted**; **s = 0x7E** means the watch already has this file (treated as success/skip, `internal/v9.smali:88`); any other value is an error (`TGException.p(s)`).
3. **Window size** (channel 1): `D1 05 | 0A`. Reply `D1 05 | n`; if `n > 0` use `n`, otherwise default **10**. `n` is the number of data packets between acknowledgements (`internal/p3.smali:11,31`; `internal/w9.smali:32`).
4. **Data** (channel 1): repeated `D1 02 | 00 | chunk`, chunk = `mtu - 6` bytes read sequentially from the file (`internal/s3.smali:97` `a(I)`: buffer `new byte[mtu-3-3]`, packet = 3 header bytes + chunk). The byte at index 2 is always `00` in the sender. Every packet's bytes are added to a 32-bit running sum and an MD5 (`s3.smali:97+`). Packets in a window go back-to-back (each after its write callback); after every `n`th packet the sender stops and waits for an ack (`s3.smali:306` `b([B)I`: returns 2 = wait when `packetCount % n == 0`, 4 = keep sending, 0x808 = finished without waiting when the last packet is not on a window boundary). Scheduler flag meanings: `internal/h3.smali:121,383,457`; ack timeout 8000 ms for this command (`w9.smali:32`, const `0x1f40`).
5. **Window ack** (notification `D1 02 | status | ...`), parsed in `s3.smali:478` `c([B)I`:
   - `status 0x00`: `bytes[3..6]` = LE32 checksum, `bytes[7..10]` = LE32 offset. Both must match the sender (running sum and bytes sent so far) or the transfer fails with codes 0x101 (checksum) / 0x102 (offset).
   - `status 0x7E`: file complete; offset in `bytes[7..10]`.
   - `status 0x7F`: resume request; offset in `bytes[7..10]`; the sender rewinds, recomputes sum/MD5 from file start up to that offset (`s3.smali:767` `e(J)`) and continues.
   - any other non-zero: file transfer error.
6. **Verify** (channel 1), sent once all data has been sent and `TGFileResult` is success (`k.smali:630` `m`, `538` `k`): `D1 03 | sum32(LE32) | md5hex(32 ASCII chars, lowercase)`; timeout 30 000 ms. Reply `D1 03 | s`; **s = 0 is success** (`internal/x9.smali:26`), otherwise `TGException.l(s)`. `sum32` is the byte-sum of the whole file mod 2^32 (`s3.smali` accumulates `byte & 0xff` per byte).
7. **Finish dial** (channel 2): `03 E4 | 03 | id(LE32)` (same builder, mode 3; `b.smali:96` `b()` after the file queue empties; command timeout 60 000 ms). Reply `03 E4 | 1` = "sync dial completed" (`internal/o2.smali:26`); other values fail.
8. **Activate** (separate user action, channel 2): `03 E6 | id(LE32) | 14 zero bytes` (total 20 bytes: the SDK sends the whole 0x12-byte `ByteBuffer.array()`). Source: `sdk/j.smali:44` `a(I)`, command `internal/n8.smali:7` (`-0x1a` = 0xE6). Whether the uploaded photo dial becomes current automatically after step 7, or needs this command, is **not established**. Delete: `03 E4 | 02 | id` (`j.smali:369`, `u8.a(id, 2, null)`).

Resume request builder (`D1 04 | LE32 | LE32`, `internal/q3.smali`, `k.smali:630` `m` branch for 0x7F) exists but which of its two integers is the offset and which is the checksum is not resolved from the code read here.

## Checksum and packet reference

Little-endian, whole-file `sum32` (not a CRC), MD5 of the file as lowercase hex. Tested reference below; its vectors come from the smali semantics, **not from captured traffic**.

```python
"""Reference packet builders for the TouchGUI .watch file transfer (derived from NoiseFit 5.4.6 smali)."""
import hashlib
import struct

FILE_TYPE_CFG_RES = 0x13  # "cfg_res.watch"
FILE_NAME_CFG_RES = "cfg_res.watch"


def le32(v):
    return struct.pack("<I", v & 0xFFFFFFFF)


def start_dial(mode, dial_id):
    """03 E4 | mode | id  (channel 2). mode: 1 start, 2 delete, 3 finish."""
    return bytes([0x03, 0xE4, mode]) + le32(dial_id)


def apply_dial(dial_id):
    """03 E6 | id | 14 zero bytes (ByteBuffer capacity 0x12, whole array sent)."""
    return bytes([0x03, 0xE6]) + le32(dial_id) + bytes(14)


def start_file(size, name=FILE_NAME_CFG_RES, ftype=FILE_TYPE_CFG_RES):
    """D1 01 | type | size | 00 | name  (channel 1)."""
    return bytes([0xD1, 0x01, ftype]) + le32(size) + b"\x00" + name.encode()


def window_query():
    """D1 05 | 0A (channel 1)."""
    return bytes([0xD1, 0x05, 0x0A])


def data_packets(data, mtu=247):
    """D1 02 00 | chunk, chunk = mtu-6 bytes, each packet mtu-3 bytes (channel 1)."""
    chunk = mtu - 6
    return [bytes([0xD1, 0x02, 0x00]) + data[i:i + chunk] for i in range(0, len(data), chunk)]


def sum32(data):
    return sum(data) & 0xFFFFFFFF


def verify(data):
    """D1 03 | sum32 | md5 lowercase hex ASCII (channel 1)."""
    return bytes([0xD1, 0x03]) + le32(sum32(data)) + hashlib.md5(data).hexdigest().encode()


def check_ack(reply, sent, running_sum):
    """Window ack D1 02 | status | sum32 | offset. Returns 'ok', 'done', 'resume' or 'error'."""
    status = reply[2]
    if status == 0x7E:
        return "done"
    if status == 0x7F:
        return "resume"
    if status != 0:
        return "error"
    got_sum = struct.unpack_from("<I", reply, 3)[0]
    got_off = struct.unpack_from("<I", reply, 7)[0]
    return "ok" if got_sum == running_sum & 0xFFFFFFFF and got_off == sent else "error"
```

Self-check (passes):

```python
import hashlib
from touchgui_transfer import *

data = bytes(range(256)) * 3
assert start_dial(1, 0) == bytes.fromhex("03e4" "01" "00000000")
assert apply_dial(0) == bytes.fromhex("03e6" + "00000000" + "00" * 14) and len(apply_dial(0)) == 20
sf = start_file(len(data))
assert sf == bytes.fromhex("d101" "13" "00030000" "00") + b"cfg_res.watch"
assert window_query() == bytes.fromhex("d1050a")
pk = data_packets(data, 247)
assert [len(p) for p in pk] == [244, 244, 244, 48], [len(p) for p in pk]
assert all(len(p) <= 244 for p in pk) and b"".join(p[3:] for p in pk) == data
assert sum32(data) == 3 * sum(range(256)) == 97920
v = verify(data)
assert len(v) == 6 + 32 and v[6:].decode() == hashlib.md5(data).hexdigest()
assert sum32(b"\xff" * 20000) == (255 * 20000) & 0xFFFFFFFF
running = 0
sent = 0
for i, p in enumerate(pk[:2], 1):
    running += sum(p[3:]); sent += len(p) - 3
ack = bytes([0xD1, 0x02, 0x00]) + le32(running) + le32(sent)
assert check_ack(ack, sent, running) == "ok"
assert check_ack(bytes([0xD1, 0x02, 0x7E, 0, 0, 0, 0]) + le32(sent), sent, running) == "done"
assert check_ack(bytes([0xD1, 0x02, 0x7F, 0, 0, 0, 0]) + le32(0), sent, running) == "resume"
assert check_ack(ack[:3] + le32(running + 1) + le32(sent), sent, running) == "error"
print("all vectors pass")
```

## What goes into the file

The `.watch` file is not sent as the photo and a template: NoiseFit first builds it locally. `TGPhotoDialBuilder.a()` produces an `internal/ea` object (template path = `getBinFile()`, bitmap(s), colour `#ffffff`, position), and `b.g(ea, false)` (`b.smali:490`) uses `internal/s2.a(context, templateFile, deviceType)` to merge the bitmap into the template and write `<epoch-millis>.watch` in the app cache (`"%d.watch"`). The merge code (`s2`/`t2` implementations, natives `zipBmp16`, `lz4_compress`) was not traced here, so what bytes the finished file contains is the remaining blocker for sending our own wallpaper (see [firmware 05](../firmware/05-watchface-format-and-rendering.md) for the container layout seen in the cached face: magic `22 aa ff 00`, JSON layout, image index, raw RGB565 bank, encoded bank).

## Verified vs inferred

Verified in bytecode: command byte pairs (`03 E4`, `03 E6`, `D1 01..05`); all payload layouts above; file type/name; channel assignment; packet size rule; window/ack rules and ack field offsets; checksum and MD5 rules; success/failure status values in each reply handler; timeouts quoted.

Inferred or open: which form of Start dial (5 vs 14 bytes) Pulse 2 wants; whether MTU the SDK uses for sizing equals what Android actually negotiates (Silence must size packets from the real `onMtuChanged` value, minus 3, minus 3); whether the final ack is sent when the last packet is not on a window boundary (the SDK does not wait for one, `s3.smali:306`); the resume-command integer order; whether activation needs `03 E6`; the exact meaning of status `0x7E` beyond "file exists / complete"; error code tables; and the contents of the `.watch` file itself.


## Implementation in Silence

- `studio/watch_face.dart` builds the file: it overwrites the template's raw 240x280 background (image 0) and 184x210 preview (image 1) with big-endian RGB565 data and repoints the `WATCH.image` component's `id` at 0 (padded in place, so the file length is unchanged). The template is the face cached from the test watch, bundled for development only.
- `TouchGuiSession.kt` runs the transfer with a paced write queue (next write after `onCharacteristicWrite`), packets of `mtu - 6` data bytes, windows from the `D1 05` reply, and the timeouts quoted above. It uses the MTU Android actually reports.

## Generated digital faces (unverified on hardware)

`studio/digital_face.dart` writes a container from scratch (`buildWatchContainer`) instead of patching the template: raw images only, ids 0 (240x280 background with baked decorations), 1 (184x210 preview with a sample time) and 2-41 (four ten-image digit sets, each digit pre-rendered over the matching background region, so no transparency is needed).

The `WATCH` description uses `image` (id 0), `multiple_image_clock` and `text_date`. Key names (`x_hour_s/g`, `x_min_s/g`, `y_*`, `id1..4_start_time`, `use_sec`) come from the firmware parser's string table (`analysis/firmware/colorfit-pulse-2/deep-dive/evidence/watchface-node-parser.txt`). The slot meaning (hour tens, hour units, minute tens, minute units), top-left positioning, and `align` 0 meaning left are inferred. The date text uses font id 16 as in the cached face.
