# NoiseFit 5.4.6 — offline reverse engineering

This research covers the supplied `NoiseFit_+Health+&+Fitness_5.4.6_APKPure.xapk` (`com.noisefit`, build 876). All 18 DEX files were disassembled, the manifest and network security configuration decoded, assets extracted, and ARM64 native libraries inventoried and scanned for URL strings. **The initial APK analysis was entirely offline.** The user later authorized and ran two firmware-metadata requests; those results are documented in chapters 15–16. The APK was not installed or executed by this analysis environment, and no firmware write was attempted.

The central finding is that NoiseFit is a multi-vendor companion platform with **11 SDK families**, rather than a single BLE protocol. The app selects adapters from device metadata, then performs configuration, data synchronization and firmware installation through the selected vendor. A firmware check and download are cloud-facing; the final transfer is device-facing. Download hosts can be returned dynamically by the backend.

## Your device: ColorFit Pulse 2

The supplied model name matches `COLORFIT_PULSE_2` / `colorfit_pulse_2`. Explicit firmware-version and pairing branches identify the Evolve2/TouchGUI integration and default firmware ID 2109. A subsequent authorized backend check returned a same-version package, now downloaded and extracted locally: see [17 — Recovered firmware analysis](17-recovered-firmware-analysis.md). Start with [11 — ColorFit Pulse 2](11-colorfit-pulse-2.md); the earlier ZH/Luna chapters remain general coverage of other devices. User-supplied phone logs now corroborate the Evolve SDK selection; see [14 — Device log findings](14-device-log-findings.md). Private runtime metadata and hardware have not been inspected.

## Firmware UI and OS deep dive

The [dedicated ColorFit Pulse 2 firmware folder](firmware/README.md) covers the RTOS/task structure, 40 recovered screen registrations, GUI lifecycle, watchface parser and container, decoded cached images, and missing external resources. It distinguishes verified findings from unresolved screen identities.

## Silence OS build plan

The [Silence OS project plan](silence-os/README.md) defines the Android companion, watchface installer/builder, visual firmware milestones, architecture, and device validation gates.

## Reading guide

| Document | Scope |
| --- | --- |
| [01 — Evidence and reproduction](01-evidence-and-method.md) | Artifact hashes, toolchain, generated files, confidence and limitations |
| [02 — Application architecture](02-app-architecture.md) | Android components, modules, state and data flow |
| [03 — SDKs and device routing](03-device-routing.md) | Vendor families, metadata selection and Luna band identifiers |
| [04 — Band/app communication](04-band-communication.md) | Use-case matrix, pairing, configuration, measurements, notifications and files |
| [05 — Firmware update orchestration](05-firmware-update-flow.md) | Check requests, response fields, downloads, guards, progress and reporting |
| [06 — Vendor firmware implementations](06-vendor-firmware-paths.md) | ZH/Berry/SiFli details and other vendor paths |
| [07 — Backend and APIs](07-backend-and-apis.md) | Configured hosts, endpoint roles, headers, unknowns and call-site catalogs |
| [08 — BLE protocol evidence](08-ble-protocol-evidence.md) | GATT UUIDs, protobuf fields and transfer behavior |
| [09 — Bundled Python wearable SDK](09-python-wearable-sdk.md) | File/RPC protocol and OTA package processing |
| [10 — Storage, integrations and open questions](10-storage-and-open-questions.md) | Local/cloud data, security observations, unresolved boundaries |
| [11 — ColorFit Pulse 2](11-colorfit-pulse-2.md) | Your model: TouchGUI routing, firmware ID, OTA package flow and BLE evidence |
| [12 — Recover firmware from Android](12-firmware-recovery-from-android.md) | Authentication boundary, cache locations, ADB access and offline recovery limits |
| [13 — Device cache inspection](13-device-cache-inspection.md) | Actual copied watch-face file and private-cache access result |
| [14 — Device log findings](14-device-log-findings.md) | Runtime model/SDK confirmation and firmware search results |

## Searchable catalogs

- [All shared actions and callback events](catalogs/band-actions.md).
- [Update/configuration handler coverage](catalogs/UpdateDeviceAction-handler-coverage.md), [query handler coverage](catalogs/QueryAction-handler-coverage.md), [activity handler coverage](catalogs/UserActivityAction-handler-coverage.md). These distinguish overrides with code, empty overrides and inherited methods; they do not assert support on a physical model.
- [411 app-owned Retrofit declarations](catalogs/retrofit-endpoints.md), including dynamically supplied `@Url` declarations.
- [Dynamic URL call-site candidates](catalogs/dynamic-url-callsites.md) and [416 unique app-owned URL literals](catalogs/app-url-literals.md). Counts represent declarations/literals, not distinct live APIs or observed requests.
- [149 unique UUID literals](catalogs/uuid-literals.md), including unrelated SDK values.

Raw evidence is retained in [analysis](../analysis/), including [smali](../analysis/smali/), [decoded manifest](../analysis/AndroidManifest.xml), [hashes](../analysis/hashes.json), JSON catalogs and the original extracted assets. Start with chapters 05 and 06 for firmware work.

## Confidence rules

**Confirmed static** means directly present in bytecode, resources or assets. **Inferred** means a role or sequence deduced from those references. **Unresolved** means it needs a specific band, runtime observation, a downloaded package, or deeper native analysis. Static presence does not prove execution, server availability, device support, or effective security controls. No complete wire-compatible replacement client or firmware image was produced.
