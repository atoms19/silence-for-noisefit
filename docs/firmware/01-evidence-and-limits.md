# Evidence, address conventions and limitations

## Inputs

| Artifact | Size | SHA-256 |
| --- | ---: | --- |
| [Returned ZIP](../../analysis/firmware/colorfit-pulse-2/ColorFitPulse2V26diffa.zip) | 500,177 bytes | `891d18c1ed860ca941db1f72bfa64be2e1245dfba5a3ffe9b7b169b92b937f1d` |
| [Extracted a.bin](../../analysis/firmware/colorfit-pulse-2/extracted-891d18c1ed86/a.bin) | 862,752 bytes | `02f3c2637766116c44918b4214c2e872a26f54416037b4fe74d35a28a13c06fd` |
| [Phone's cached watchface.zip](../../analysis/device-cache/watchface.zip) | 578,740 bytes | `e414233eb7ce8559f393b724f27298683091372a7a0aaef97bf83a77c8cc3bb0` |

The backend returned version 26 / `V5.4.328.26`, matching the version reported by the user. Product strings include `Noise Pulse2` and `ColorFit Pulse 2`. This supports the intended model association; it is not a hardware compatibility or signature verification. The `diffa` filename alone does not establish whether this is a delta update. The contents clearly include executable code, but a complete flash image has not been obtained.

The watchface is a separate cached artifact. It was not a second member of the firmware ZIP. It is useful because its layout vocabulary directly matches the recovered firmware's parser. This does not establish that it is the currently selected watchface.

## Runtime addresses versus file offsets

Addresses in these chapters are inferred runtime addresses, using:

```text
image_base = 0x01023000
file_offset = runtime_address - image_base
Thumb function pointer = entry_address | 1
```

The initial stack pointer is `0x00840000`; reset pointer `0x01023389` resolves to Thumb code at file offset `0x388`. The footer repeats `0x01023000`, and PC-relative loads resolve to coherent strings and data under this mapping. This is strong static evidence, without debugger confirmation. The exclusive image end is `0x010f5a20`; a 48-byte footer begins at file offset `0x000d29f0` / runtime `0x010f59f0`.

For example, screen 1's create pointer `0x010912cd` means code entry `0x010912cc`, at file offset `0x0006e2cc`. ARM Thumb's low pointer bit is not part of that file offset.

## Tooling and confidence

An analyst-generated ELF wrapper lets LLVM disassemble the raw binary as Thumb/Cortex-M4 instructions. **This ELF is not an original firmware ELF, and contains no recovered original symbol table.** Source-like function names come from embedded diagnostic strings; other labels are analyst descriptions.

The full linear listing mixes executable instructions, strings, tables, literal pools and potentially other encoded data. Consequently its 317,612 decoded lines, 3,397 push/LR candidates and 38,569 branch candidates are **search leads, not verified instruction, function or call counts**. A missing direct call in that listing does not establish unreachable code. Indirect callbacks are common. Nearest-prologue string associations can cross function boundaries.

Reviewed findings use several independent observations: raw registration bytes, loaded callback pointers, nearby meaningful instructions, diagnostic references, valid file bounds and, for images, visual inspection. The 40 registry entries were matched against a repeated raw instruction pattern; they are not an exhaustive screen enumeration. The JSON extractor's byte offsets and image dimensions were checked against file boundaries and the actual decoded images.

Evidence categories used here:

- **Observed:** exact bytes, strings, pointers, instruction stores or decoded asset contents.
- **Inferred:** a subsystem role supported by those observations, but not checked on hardware.
- **Unresolved:** identity or behavior for which this image and static review are insufficient.

## Reproduce locally

Run from the project root with Python 3, Pillow and LLVM tools available:

```sh
python3 analysis/tools/firmware_deep_dive.py
python3 analysis/tools/firmware_screen_registry.py
python3 analysis/tools/decode_cached_watchface.py
python3 analysis/tools/build_firmware_evidence.py
python3 analysis/tools/validate_firmware_deep_dive.py
python3 analysis/tools/validate_research.py
```

[Raw analysis summary](../../analysis/firmware/colorfit-pulse-2/deep-dive/analysis-summary.json), [reviewed evidence index](../../analysis/firmware/colorfit-pulse-2/deep-dive/reviewed-evidence.json), and [bounded disassembly excerpts](../../analysis/firmware/colorfit-pulse-2/deep-dive/evidence/) preserve the findings. The scripts read local files; they do not contact servers or write to the watch.

No whole-system emulator, live debugger, sensor test, hardware register verification, bootloader analysis or signature validation was performed. We have disassembly and behavioral reconstruction of selected paths, not the original C source.
