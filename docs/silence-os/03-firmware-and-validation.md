# Firmware workflow, feasibility gates and validation

## Current evidence and what it permits

| Established from local research | Still required for the planned product |
| --- | --- |
| Model-specific Evolve2/TouchGUI integration | Live connection initialization and exact watchface operation sequence |
| Application image and inferred base | Exact physical hardware revision and full component compatibility |
| 40 screen registrations and GUI templates | Reliable identification of the target quick settings/music/home views |
| A cached watchface container, layout and two decoded images | Complete accepted export path, encoded images, fonts, counters and resource limits |
| Separate flash resource regions referenced by firmware | Matching resource contents and a working decoder/repacker |
| App-side OTA component transfer and reboot behavior | Device acceptance/authentication checks, installation/boot behavior and demonstrated restoration |

The watchface project and firmware modification project have separate feasibility gates. A successful watchface transfer does not validate an application-code update or recovery from a failed boot.

## Baseline and recovery work

Before a modified firmware installation, record the exact watch identity/version and hashes of every baseline component we possess. Determine whether restoring only `a.bin` would also restore altered resources; it may not. A same-version application ZIP is not, by itself, a complete backup.

Identify the available recovery mechanism and demonstrate it for the relevant test configuration. A normal OTA restore while the app still boots does not prove recovery after a boot failure. Document exactly what failures the method covers and what device access it needs. Prefer an additional test watch for experiments that could leave the only unit unusable; its revision still needs matching.

ADB helps inspect the Android side. It does not automatically provide watch flash readback, a microcontroller debugger, or a working bootloader recovery channel.

If recovery or modified-image acceptance remains unresolved, firmware outputs stay offline build/inspection artifacts. App and watchface development continues independently.

## Controlled firmware iteration

1. Decode matching resource structures and map IDs to actual assets and strings. Confirm target screen identities against physical behavior.
2. Repack an unchanged resource component and explain any byte differences. Verify offsets, sizes, alignment, version metadata and required integrity checks independently.
3. Determine how the target accepts modified components and what boot/install checks apply. Do not assume that modifying an app-side flag changes device-side authentication.
4. Make one small visual change with the original dimensions and resource slot constraints where possible. Keep a machine-readable patch manifest and original bytes.
5. Inspect the generated component and package before any device operation. Confirm the chosen restore procedure covers the changed component.
6. On the supported test device, validate installation, boot, the visible change and restoration. Only then expand to multiple icons, fonts or layout changes.
7. Add executable/template patches for the identified quick settings and music views only when resource replacement is insufficient. Record relocated code, branch/literal ranges and RAM/stack impacts if those become necessary.

The initial work targets appearance. Changes to health algorithms, BLE identity, sensor drivers, bootloader, flash partitioning or power policy require their own scope and validation.

## Meaningful software checks

| Area | Checks that establish useful behavior |
| --- | --- |
| Container reader | Truncated/oversized sections, invalid offset origins, overlapping records, missing assets, inconsistent dimensions and malformed metadata |
| Compiler | Deterministic outputs; independent reinspection; known fixture semantics; limits and invalid combinations rejected |
| Preview | Golden scenes for placement/color/cropping and comparison against actual watch output; font deviations recorded |
| BLE/session | Recorded command/response sequences, ordering, timeouts, notification handling, operation exclusivity and reconnect state |
| Transfer | Progress reflects acknowledged protocol state; failed activation differs from failed transfer; duplicate actions and retries are bounded |
| Firmware packer | Wrong baseline rejected; expected bytes checked; changes contained in intended components; output metadata/hashes verified independently |

Tests should target format and behavior boundaries rather than merely reproducing implementation logic. Hardware observations remain necessary even when all host-side checks pass.

## Physical device acceptance matrix

| Scenario | Expected evidence |
| --- | --- |
| Install an existing face | Device acknowledges required stages and visibly selects/renders it |
| Install a newly compiled face | Expected geometry, colors, fonts and data bindings on the actual watch |
| Time/date changes | Correct midnight, date, weekday and supported 12/24-hour behavior |
| Connection interruption | Known failure state and a demonstrated supported recovery; no false success |
| NoiseFit handoff | Reconnection, health history synchronization and expected settings still work |
| Notifications and music | Existing message delivery and music controls remain functional after changes |
| Health/activity | Baseline measurements, recording and history synchronization still operate; not a claim of medical accuracy |
| Power/display | Brightness, sleep/wake, charging, touch/button input and battery behavior compared under the same conditions |
| Modified firmware install | Correct package/device, expected boot and visible build change; post-boot checks recorded |
| Restore | The relevant original application/resources can be restored with documented limitations |

Avoid deliberate power-loss or broken-boot experiments on the sole device before an appropriate recovery route is established. Fault scenarios may initially be simulated at the app/transport layer.

## Firmware release checklist

A firmware release needs a declared device/revision scope, reproducible build recipe, component provenance/hashes, independently validated packaging, supported installation path, completed regression record, and an accurately described restore procedure. The APK installer should check package compatibility and report post-reconnect verification separately from transfer completion.

Inspect NoiseFit's behavior around firmware version comparisons, automatic update prompts and resource checks. Preserve protocol compatibility deliberately and document any upstream-update overwrite behavior we observe. Do not conceal the project's modifications by inventing an upstream version value.

For health migration, extend the validation plan before implementing data synchronization: timestamps, units, missing records, duplicates, reconnection and local retention all need explicit semantics. This is a later milestone, not a prerequisite for the visual firmware project.
