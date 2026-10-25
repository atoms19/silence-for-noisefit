# TouchGUI bind handshake (Silence 0.3)

Silence's own client for ColorFit Pulse 2, replacing the blocked NoiseFit editor handoff. Built from static analysis of NoiseFit 5.4.6.

**Verified on a Pulse 2 (user-reported, 2026-10-25):** the sequence below binds the watch and moves it off the QR screen. The notification setup, MTU request, device-info query and `04 01 F3 00 00 00` bind packet worked as implemented. The raw protocol log was not captured for this note, so reply byte layouts remain as read from the bytecode.

## Sequence implemented (`TouchGuiSession.kt`)

1. Pick service `000027f0` (else `00000af0`). Commands are written to its `27f1` (else `0af1`) characteristic, write-without-response, as raw bytes with no extra framing. Source: `internal/g.smali` `j(I[B)Z`; commands use channel 2 (`internal/z8` default).
2. Enable notifications (CCCD `0x0100`) on every notify-capable characteristic of services `27f0`, `0af0` and `2760`, one at a time, each confirmed by `onDescriptorWrite` (`internal/g.smali` `e()`).
3. Request MTU 247 (`0xf7`).
4. Device-info query: `02 01`. Reply parsed little-endian after the two command bytes (`internal/b7`). The SDK uses its fields to choose the protocol variant.
5. Bind: `04 01 F3 00 00 00` (`internal/e`). The alternative `0B 01 F3 00 00 00` (`internal/m6`) is chosen only when the SDK's protocol field equals 1; analysis of `internal/u` suggests that value is either 0 or at least 500, so the `04 01` form should apply. This is unconfirmed.
6. Reply `04 01 <state> ...`. NoiseFit treats `state == 0` as bound (`TGBindResult.c() == 0` in `Evolve2ConnectHandler...onReady$2`). Any other value is a failure.

If the device-info reply never arrives (6 s), Silence sends the bind anyway and logs that it did. Every transmitted and received packet appears in the app's protocol log with a Copy button.

## Still unconfirmed

- Whether `27f1` is the right command characteristic and whether replies arrive on it.
- Whether the watch needs a tap on its screen to accept the bind.
- What a non-zero bind state means.
- Whether NoiseFit can re-bind afterwards without resetting the watch to the QR screen. Use **Unpair / release watch**, then add the device in NoiseFit; report what the watch does.

## Not implemented

Battery/version queries, watchface transfer (`TGDialManager`, `zipBmp16`, `lz4_compress`), health data, and an unbind command.
