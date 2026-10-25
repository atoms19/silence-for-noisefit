# Application, watchface tools and build architecture

The architecture below describes the intended product boundaries. An [initial Flutter implementation](05-flutter-foundation.md) now exists in `app/`; the larger module names below remain proposed and do not imply all those features have been implemented.

## Current direction

Prioritize the [NoiseFit-owned connection](06-noisefit-handoff-research.md): Flutter creates artwork, the user hands it to NoiseFit’s custom-face workflow, and NoiseFit performs the device transfer. The direct BLE architecture below remains useful for research and any future independent-client fallback. A stock NoiseFit generic upload API has not been established.

## Android application

Use Flutter for the UI and app state, with a small native Kotlin Android BLE bridge and a replaceable Pulse 2 protocol adapter. Keep editable projects, compiled watchfaces and firmware packages as distinct file types and operations.

| Proposed module | Responsibility | Boundary |
| --- | --- | --- |
| `app` | Navigation, Library, Editor, Device and operation progress UI | Does not construct raw Bluetooth commands |
| `device-core` | Device profile, capabilities, connection and operation state | Independent of a particular watch protocol |
| `pulse2-protocol` | Verified initialization, queries, watchface commands, responses and activation | Owns device-specific opcodes, framing and compatibility checks |
| `ble-transport` | Discovery, GATT I/O scheduling, notifications, negotiated connection parameters and reconnect behavior | Does not interpret UI widgets or package contents |
| `watchface-model` | Versioned editable scene, assets and supported widget definitions | Independent of the binary export format |
| `watchface-codec` | Container reader/writer, validation and deterministic export | No network or Bluetooth side effects |
| `watchface-preview` | Render scene/sample state with documented device constraints | Shared geometry/color rules with export; device comparison is still necessary |
| `project-storage` | Local project, asset and export persistence | Keep personal images and diagnostics local by default |
| `firmware-installer` — later | Validate supported Silence package, coordinate transfer, reconnect and verify | Separate from the ordinary watchface flow |

Start with these as clear code boundaries, not necessarily separate build modules on day one. Split only where reuse or isolation benefits the implementation.

## Device operation model

Use explicit state transitions:

```text
Disconnected -> Connecting -> Initializing -> Ready
Ready -> Preparing -> Transferring -> Finalizing -> Verifying -> Ready
Any active stage -> Failed / Disconnected, with stage-specific recovery
```

Only one transfer owns the device connection at a time. Serialize requests and associate responses with the appropriate operation. Treat negotiated MTU, chunk sizes, retry rules and resume behavior as protocol details to verify; never equate an Android write callback with completed device installation.

Watchface activation and firmware reboot have different completion semantics. The app must report the operation actually verified. A transfer can finish without the requested face being selected or the expected firmware booting.

For initial coexistence, test an explicit connection handoff: NoiseFit releases the watch, Silence performs its operation, Silence disconnects, and NoiseFit reconnects. Do not assume simultaneous connections or silently rebind/reset the watch. Keep device pairing and persistent BLE bonding changes separate from a temporary transfer session.

## Editable watchface project

Use a Silence-owned, versioned project format containing:

- Project schema version and target device profile.
- Canvas dimensions and supported rendering assumptions.
- Ordered elements, positions, dimensions, widget types, bindings and appearance.
- Referenced assets with content hashes and source/crop information.
- Preview sample values and compiler/export version.

Store source artwork and edit history separately from the device image encoding. Compile references into validated numeric image/font/widget IDs during export. The user should not have to edit GLX numeric IDs to design a face.

Proposed pipeline:

```text
Project + assets
    -> schema and capability validation
    -> crop/resize/color conversion
    -> font/widget/image resolution
    -> device encoding and container assembly
    -> independent structural inspection
    -> compiled watchface + preview + build report
```

Initially export only verified primitives. A capability matrix should control the editor, validator and compiler so unsupported widgets cannot appear as apparently functional options. RGB565 conversion, fonts and dynamic data formatting can make previews differ from the watch; document and progressively reduce those differences.

## Firmware modification pipeline

Keep immutable original components and a versioned patch recipe. A Silence build should be reproducible from identified input artifacts, replacement assets and the recipe. Do not modify the only recovered binary in place.

```text
Verified baseline components + asset sources + patch recipe
    -> resource decoding/repacking
    -> exact-offset or structure-aware modifications
    -> required integrity metadata
    -> package assembly
    -> independent inspection and compatibility report
```

Each binary patch must verify expected original bytes before applying. The build fails on a different baseline hash, unexpected component, range overflow, overlapping edits or unresolved required integrity field. Prefer a structure-aware resource packer to broad string/byte substitution.

Suggested package metadata includes Silence release ID, supported model/revision, baseline hashes, component hashes/sizes, tool/recipe versions and restore-package reference. Project-defined metadata does not establish that the watch's updater understands it; the APK must validate it and then supply the actual vendor-compatible payload.

Authenticating a Silence distribution and satisfying the watch's own image checks are separate requirements. Determine the latter before choosing a release installation scheme. Never label an independently checksummed file “publisher-signed” without the corresponding verification.

## Proposed repository additions

```text
app/                             Flutter app with native Android BLE bridge
watchface-tools/                 Reader, compiler and host-side inspection tools
silence-design/                  Design tokens, editable icon/face artwork, exports
firmware-build/                  Patch recipes and package assembly tools
fixtures/                       Small redistributable or generated test fixtures
analysis/                       Existing raw investigation and local artifacts
docs/silence-os/                 Product plan, architecture and release decisions
```

Use the same format specification and golden fixtures for the app and host tools. Avoid maintaining two unrelated encoders. Choose the production compiler location after the first accepted export: on-device export is the desired app experience; host tooling remains valuable for reproducibility and inspection.

## Distribution and data boundaries

The first releases work without a project backend or Noise cloud login. Cloud watchface sharing, account synchronization and remote catalogs can be added later if useful. Do not embed recovered Noise credentials or depend on undocumented cloud API access for local installation.

Prefer implementing the verified protocol behind our own adapter. If a vendor SDK becomes useful, evaluate its actual availability and redistribution terms before making it a release dependency. Decompiled APK code and bundled native libraries are research inputs, not automatically distributable app components.
