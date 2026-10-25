# Recovered Pulse 2 firmware: package and binary inspection

## Recovery succeeded

The user downloaded the exact URL returned by the authorized true-flag metadata check and ran the prepared extraction script. The package and extracted binary are present in the workspace. Independent local hashing matches the download/extraction report, and ZIP CRC verification passed. No image was flashed or executed.

| Artifact | Size | SHA-256 |
| --- | --- | --- |
| `ColorFitPulse2V26diffa.zip` | 500,177 bytes | `891d18c1ed860ca941db1f72bfa64be2e1245dfba5a3ffe9b7b169b92b937f1d` |
| Extracted `a.bin` | 862,752 bytes | `02f3c2637766116c44918b4214c2e872a26f54416037b4fe74d35a28a13c06fd` |

The ZIP contains exactly one entry, `a.bin`, compressed to 500,069 bytes with ZIP CRC32 `3ace5e10`. It does not contain a separate bootloader, resource image, package manifest or signing-certificate file as additional archive entries. This statement describes the ZIP inventory; those materials could still be embedded in the binary or already installed on the watch.

Artifacts: [original ZIP](../analysis/firmware/colorfit-pulse-2/ColorFitPulse2V26diffa.zip), [extracted a.bin](../analysis/firmware/colorfit-pulse-2/extracted-891d18c1ed86/a.bin), [package inspection](../analysis/firmware/colorfit-pulse-2/package-inspection.json), [binary triage](../analysis/firmware/colorfit-pulse-2/a-bin-triage.json).

## Model and SDK identification

The binary contains the product strings `ColorFit Pulse 2` and `Noise Pulse 2`, plus `Goodix GR551x SDK V%d.%d.%02d (commit %d)`. These directly support the product association and use of the GR551x SDK family. The banner is a formatting string, not a populated SDK version. Exact silicon variant and hardware revision are not established by it.

Firmware also contains BLE stack assertions, UI/health/activity strings, source-path strings, OTA handlers and boot-information diagnostics. These support classification as a substantial firmware code component, rather than the watch-face resource previously recovered. The earlier firmware filename's `diffa` substring alone does not establish a conventional binary-delta patch format.

## Header and candidate load address

The first little-endian words are consistent with an ARM Cortex-M-style vector table:

| Position | Observed value | Interpretation |
| --- | --- | --- |
| Word 0 | `0x00840000` | Candidate initial stack pointer |
| Word 1 | `0x01023389` | Candidate Thumb reset entry |
| Word 2 | `0x01023395` | Candidate exception entry |
| Later words | Several `0x008075xx` values and zeroes | Possible RAM-resident handlers / reserved vectors |

A structured 48-byte trailer begins at file offset `0xD29F0`. Its first bytes are `44 47 26 00`; the following 32-bit word is `0x000D29F0`, exactly matching the file size excluding this trailer. Other trailer words include `0x01023000` twice, and its text name is `oy07_app_fw`.

Using `0x01023000` as a **candidate** image base maps the reset address to file offset `0x388`, where the bytes are consistent with short Thumb call/branch sequences. This correspondence supports the proposed mapping. It is not a recovered linker map, complete memory layout, or a verified flashing address. Trailer checksum/signature field meanings have not been established.

## Relationship to the app's transfer protocol

The TouchGUI filename map `internal.u3` assigns `a.bin` file type **`0x23` (35)**. The OTA manager recognizes it, sorts selected package files and passes each to the vendor transfer implementation. `internal.t3.a(type, size, filename)` constructs a little-endian request payload containing a type byte, 32-bit file length, zero byte and UTF-8 filename. For this file that payload is:

```text
23 20 2a 0d 00 00 61 2e 62 69 6e
```

This is the inner file-initiation payload reconstructed from the Java code, **not a complete BLE frame**. Transport envelope, commands, characteristic selection, acknowledgments, checksums and device state still matter. No payload was sent to the watch.

Sources: [u3 filename/type map](../analysis/smali/classes5/com/touchgui/sdk/internal/u3.smali), [t3 request builder](../analysis/smali/classes5/com/touchgui/sdk/internal/t3.smali), [file transfer implementation](../analysis/smali/classes5/com/touchgui/sdk/k.smali).

## Selected binary strings

Offsets are byte offsets in the extracted `a.bin`; these are local binary evidence, not URLs to query or commands to execute.

| File offset | String |
| --- | --- |
| `0x41cc` | `NSW-26` |
| `0x1b440` | `%s: version mismatch: RES_1_ADDRESS` |
| `0x1b490` | `%s: version mismatch: FONTS_ADDRESS` |
| `0x1b4e0` | `%s: version mismatch: RES_2_ADDRESS` |
| `0x2d3c0` | `Goodix GR551x SDK V%d.%d.%02d (commit %d)` |
| `0x41528` | `%s elx_ota_flash_write1: failed: %d/%d` |
| `0x47a78` | `Noise Pulse 2` |
| `0x4901c` | `%s now_boot_info.load_addr =0x%08x bin_size =0x%x` |
| `0x4906c` | `Bootloader[%d] version =%d` |
| `0x69d7c` | `[Error]:OTA length != 38` |
| `0x69e5c` | `send MSG_ID_GR_OTA_CMD failed` |
| `0x85770` | `ColorFit Pulse 2` |
| `0x85788` | `NSW-26` |
| `0x9d22c` | `elx_ota_1s_check` |
| `0x9f325` | `elx_ota_erase_schedule` |
| `0x9f33c` | `elx_ota_program_schedule` |
| `0x9f355` | `elx_ota_write_data_to_buffer` |
| `0xcab00` | `%s: ota_file_type =0x%x, ota_file_size =%d compression_type =0x%x filename =%s` |
| `0xd2a0c` | `oy07_app_fw` |

The binary's `OTA length != 38` diagnostic describes a firmware handler's expected input size, but does not establish how to construct that command. Strings mentioning bootloaders, flash writing, erase/program scheduling and resource-version mismatches identify useful next reverse-engineering targets; their mere presence does not establish secure boot, downgrade acceptance or recovery safety.

## What is established and what remains open

We have recovered and extracted the package offered for `V5.4.328.26`, matching the user-reported installed version. It contains recognizable firmware code/data and model/SDK evidence. Package acquisition no longer depends on accessing the phone's private cache.

Whether this is a self-contained application image, a component requiring installed resources, or part of a differential update workflow remains unresolved. It must not be treated as a complete device-flash backup. Hardware compatibility, required base version, bootloader state, publisher authentication and signature enforcement also remain unverified. ZIP CRC/SHA-256 establish local integrity/identity, not those policies.

Reproduce the offline binary inventory with:

```sh
python3 analysis/tools/inspect_pulse2_firmware.py
```

The script hashes and reads the file, inventories strings, and records header/trailer observations without executing firmware or contacting any server.
