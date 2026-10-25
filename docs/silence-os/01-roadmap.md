# Milestones and acceptance criteria

The next research milestone is now [NoiseFit-owned wallpaper handoff](06-noisefit-handoff-research.md): prove gallery artwork selection and the custom-face navigation route while NoiseFit retains its connection. The direct-connection release sequence below records the earlier plan; it is not a requirement to implement every step before the handoff approach.

Effort estimates for firmware work would be speculative until the resource and update-acceptance investigations finish. Schedule work by the evidence gates below, and estimate each implementation milestone after its prerequisites are met.

## M0 — Establish the device and protocol baseline

**Deliverables**

- A device profile recording model, observed hardware identifiers where available, firmware version, observed GATT services/characteristics, and supported queries. Keep device addresses/serials in local diagnostic records rather than public examples.
- A trace from the Android Evolve2 watchface action through TouchGUI initialization, preparation, transfer, verification and activation. Separate watchface commands from firmware OTA commands; a shared file-transfer transport does not make them interchangeable.
- A baseline checklist of current watch behavior: face selection, gestures, quick settings, music, notifications, measurements, activity history, charging and reconnection.
- A known-working watchface sample established through observed successful use on this watch. The cached face is a candidate, not automatically a validated transfer fixture.

**Acceptance:** enough protocol detail to implement read-only discovery and the first query without guessing UUIDs, session setup, checksums or command bytes. Missing protocol details are recorded with exact code references or captures needed to resolve them.

## M1 — Android connection proof: release 0.1

Build a Flutter application with an Android Kotlin BLE bridge. The user selected Flutter; the initial implementation and remaining M1 work are documented in [the Flutter foundation](05-flutter-foundation.md).

**First screens:** device discovery, device details, connection status and an exportable diagnostic view. Show observed model/version/battery only when supported by a verified command. Distinguish permission denial, unavailable Bluetooth, unavailable device, protocol initialization failure and disconnected state.

**Acceptance:** connect/query/disconnect works repeatedly on the available phone/watch; Bluetooth toggling and app background/foreground transitions recover cleanly. The app does not accidentally start a transfer during connection. Establish a practical NoiseFit-to-Silence connection handoff and return to NoiseFit afterward.

## M2 — Install a known-working face: release 0.2

Implement local file import, structural validation, preview where available, installation progress and transfer results. Use a single-operation coordinator so queries, watchface transfers and future OTA transfers cannot overlap incompatibly.

Before transferring, verify the selected device profile, file structure, supported dimensions/limits and device-specific battery/state requirements established in M0. Do not copy a battery threshold from an unrelated UI branch and call it a verified watchface requirement.

**Acceptance:** the fixture installs and activates on stock V5.4.328.26. Confirm activation separately from “all bytes sent.” Record behavior for disconnection, invalid input, duplicate submission and retries. Establish how to restore the known-working face and reconnect NoiseFit. Expose cancellation only at stages where cancellation semantics are understood.

## M3 — Decode and compile the face format

Turn the research extractor into a bounded reader, documented intermediate representation and writer.

**Deliverables**

- Container reader with explicit offset origins, index/bank handling and length checks.
- Resolution of the custom encoded image format, or a demonstrated supported export path using other accepted image entries. Do not assume raw images can replace encoded entries everywhere.
- Widget/property support matrix: font mapping, image IDs, allocation counters, alignment, color quantization, supported data fields and resource limits.
- Deterministic compiler: the same project and compiler version produce the same output bytes.
- Independent structural inspection and a preview renderer with documented deviations from the device.

**Acceptance:** semantic decode/export of a known-working sample preserves its meaningful contents, then a deliberately simple newly compiled face installs and renders correctly. Bit-identical round-trip is required only for fields/formats intended to be preserved verbatim. Compare watch output with the preview before adding more widget types.

## M4 — Watchface Studio: release 0.3

Start with a constrained editor: background import/crop, supported digital time, date, placement, color choices and one verified font path. Enable analog hands, battery/activity widgets and animation only after each underlying primitive is verified.

**App flow:** Library → New face → Editor → Preview/validation → Save or Install.

Use a separate editable project format; export the device binary as a build output. Support undo/redo, local save/load and project export. Surface unsupported combinations and asset limits in terms the user can act on.

**Acceptance:** a saved project reopens unchanged, exports deterministically and produces the expected face on the watch. Check image cropping, text bounds, edge placement, midnight/date rollover, 12/24-hour formats and the supported languages/glyphs. Preview sample values must be clearly distinguishable from live watch data.

## M5 — Establish the Silence visual language: release 0.4

Develop a shared visual specification for the watch and app: semantic colors, type scale, icon geometry, spacing, selected/disabled states and contrast. Bake gradients into raster assets where appropriate and validate RGB565 conversion on the display. Do not assume arbitrary transparency, scalable fonts or runtime gradient rendering.

Proposed first three faces:

| Face | Design purpose | Technical dependency |
| --- | --- | --- |
| Silence Essential | Clear digital time/date and restrained accents | Verified text clock, font and background path |
| Silence Analog | Refined dial with coordinated hands | Verified pointer-image encoding and time progression |
| Silence Activity | Time plus a compact activity/battery view | Verified data widget semantics and refresh behavior |

**Acceptance:** all three are visually reviewed on the physical watch. Check daylight readability, low brightness, boundaries, refresh behavior and asset/transfer size. Keep animation outside the initial collection unless its power and rendering effects have been measured.

## M6 — Firmware feasibility gate

Proceed alongside M1–M5: obtain matching resources from existing local artifacts or an established read-only recovery route, decode the required resource formats, and determine package integrity/authentication checks and restore options. Any additional remote acquisition is a separate explicit operation, not an automatic step in these build scripts.

**Acceptance:** a reproducible offline pipeline can rebuild the intended component, identify its target/version, explain required update checks, and has a demonstrated restore procedure for the test device. If modified packages cannot be accepted, keep releasing the app/watchface products while documenting the blocker; do not advertise a firmware installer as working.

## M7 — Silence OS visual firmware: release 1.0

Make one controlled icon/resource change first. After that succeeds and can be restored, iterate through the built-in watchface catalog, quick settings and music controls. Identify their actual screen callbacks before patching; the current five-page menu-like view has not been proven to be quick settings.

Change one subsystem per candidate build. Prefer resource substitution where it achieves the design; use executable/template changes when layout or interaction requires them. Keep each patch tied to the exact baseline hash.

**Acceptance:** all intended screens match the design, regression checks pass, installation and restore are repeatable, and the package manifest records exact device compatibility and provenance. Verify NoiseFit health history synchronization and update behavior after installation.

## M8 — Optional health companion

Decide scope after the visual product is usable. Start with battery/device status and current measurements, then daily summaries, then historical records and notifications. Each requires separate protocol validation. Porting the APK's behavior does not provide its backend services or automatically establish rights to redistribute SDK binaries.

**Acceptance:** local data storage, units, timestamps, deduplication and reconnect synchronization are independently validated. NoiseFit replacement remains optional until the chosen health functions work reliably. Cloud parity is a separate product decision.

## First implementation backlog

| Priority | Work item | Concrete output |
| --- | --- | --- |
| 1 | Trace exact Pulse 2 watchface transfer and session setup | Protocol document with command sequence, response/error states and source references |
| 2 | Record actual GATT/device baseline and NoiseFit handoff | Device profile and reproducible connection observations |
| 3 | Scaffold Android app and read-only connection layer | Installable 0.1 development APK |
| 4 | Validate one existing watchface end to end | Known-working fixture and transfer/activation record |
| 5 | Implement and verify first installation workflow | 0.2 development APK |
| Parallel | Recover matching UI resources and investigate image codec | Resource inventory, decoder findings and firmware feasibility report |

This planning task does not start device transfers, firmware writes or new backend calls.
