# Separate UI resources and firmware update handling

## Why the firmware package does not contain every screen image

The recovered ZIP has one entry: `a.bin`. The application accesses resource addresses beyond its inferred image end `0x010f5a20`. At `0x01071e7c`, GUI resource initialization reads a structure at `0x01102014`, follows a resource offset, checks halfwords `0xaafa`, `0xbbf2`, `0xccf1`, `0xddf1`, and registers an image resource named `a_res.bin` with the GLX loader.

This is direct code evidence of a separate flash resource dependency. It does not mean that no image or glyph data at all exists inside `a.bin`; the narrower conclusion is that **the complete external resource set is absent from this ZIP**.

The routine associated with `check_res_version` at `0x01057964` references `RES_1_ADDRESS`, `FONTS_ADDRESS`, `RES_2_ADDRESS` and resource version/CRC diagnostics. The separate screen showing “Resources do not match please connect APP to upgrade again” confirms that resource compatibility is explicitly considered by the application.

Sources: [initialization and checkpoint](../../analysis/firmware/colorfit-pulse-2/deep-dive/evidence/resource-init.txt), [resource checks](../../analysis/firmware/colorfit-pulse-2/deep-dive/evidence/resource-version-check.txt), [mismatch view](../../analysis/firmware/colorfit-pulse-2/deep-dive/evidence/resource-error-screen.txt).

## Filename dispatch and flash destinations

The OTA handler at `0x010a88f8` is associated with `start_head_process`. It logs file type, size, compression type and filename. Reviewed comparisons select destinations and reject sizes exceeding component-specific limits:

| Incoming component | Selected address | Size ceiling observed in dispatch | Present in recovered ZIP? |
| --- | --- | --- | --- |
| `a.bin` | `0x018c0000` | `0x000dc000` | Yes |
| `res01.bin` | `0x01102000` | `0x00514000` | No |
| `fonts.bin` | `0x01616000` | `0x0000f000` | No |
| `res03.bin` | `0x01625000` | `0x00056000` | No |
| `res02.bin` | `0x0167b000` | `0x0002f000` | No |
| `cfg_res.watch` path | `0x016aa000` | `0x00155000` | No |

These are constants selected by this handler, **not a complete partition table or a recommendation to write those addresses**. Other states, file types and flags affect acceptance. In particular, the `cfg_res.watch` path checks current state before accepting the transfer. Component sizes do not prove the entire region is populated.

The code at `0x018c0000` is an application update destination selected during reception. The running application is mapped at `0x01023000`; these addresses serve different roles. Erase counts in this handler use 4 KB rounding. Full bootloader copy/install behavior, rollback, signature verification, image authentication and power-loss recovery have not been reconstructed from this application image.

Source: [OTA header dispatch excerpt, including literal constants](../../analysis/firmware/colorfit-pulse-2/deep-dive/evidence/ota-header-dispatch.txt).

## Relationship to the phone's updater

The Android TouchGUI updater recognizes `a.bin` as file type 35 (`0x23`). It extracts recognized component files, transfers them and requests reboot. The downloaded file being recognized on this path does not establish the safety or compatibility of a modified image. The [previous firmware chapter](../17-recovered-firmware-analysis.md) documents the phone's package handling and transport header.

The update/status code also contains strings for installing, successful update, checking for updates in the app, synchronizing, and sync success/failure. These are useful UI leads but do not establish that a particular text is displayed for every file type or failure condition.

## Consequences for UI reconstruction

We can recover widget construction, callbacks, IDs, state branches and some coordinates from the code. Exact built-in labels, icon artwork, localized strings, typefaces and face selections require following resource lookups and obtaining the corresponding resource contents.

The cached watchface supplies one independent face resource. It cannot replace the entire resource/font set. Its filename `watchface.zip` also does not make it equivalent to the `cfg_res.watch` component; that exact equivalence has not been verified.

No new backend query was made to search for absent resources. We also did not infer downloadable filenames by changing the returned URL: recognizing a component filename in code does not prove that a matching public artifact exists at an adjacent server path.
