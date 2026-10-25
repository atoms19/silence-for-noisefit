# Reviewed code map and remaining evidence

## Where to continue in a disassembler

All addresses use inferred base `0x01023000`. Names are analyst labels unless explicitly identified as diagnostic strings. A range described as a block is not necessarily a function entry.

| Address | Role established by review | Evidence |
| --- | --- | --- |
| `0x01079efc` | GUI task entry and startup mode branch | [GUI task](../../analysis/firmware/colorfit-pulse-2/deep-dive/evidence/gui-task.txt) |
| `0x01071b68` | Returns page-root pointer `0x008363e8` | Raw listing and registration stubs |
| `0x01076244` | Stores initial create/destroy state and invokes create | [Callback setup](../../analysis/firmware/colorfit-pulse-2/deep-dive/evidence/page-root-and-callbacks.txt) |
| `0x01076260` / `0x0107626c` | Store root callbacks at +0x14 / +0x1c | [Callback setup](../../analysis/firmware/colorfit-pulse-2/deep-dive/evidence/page-root-and-callbacks.txt) |
| `0x010786b0`–`0x01078e00` region | Repeated pending screen registrations; not every byte is code | [40 matched stubs](../../analysis/firmware/colorfit-pulse-2/deep-dive/screen-registry.json) |
| `0x01072e98` | Allocate/initialize window; optional 240 × 280 state | [Window constructor](../../analysis/firmware/colorfit-pulse-2/deep-dive/evidence/window-constructor.txt) |
| `0x01072d80` | Copy template bytes and store callback | [Template copy](../../analysis/firmware/colorfit-pulse-2/deep-dive/evidence/template-copy.txt) |
| `0x01073424` / `0x01073408` | Page container construction / child attachment, based on callers | [Pairing caller](../../analysis/firmware/colorfit-pulse-2/deep-dive/evidence/pairing-create.txt) |
| `0x0106e2d2` | Parse resource JSON section and invoke node callback | [Section walker](../../analysis/firmware/colorfit-pulse-2/deep-dive/evidence/json-section-walk.txt) |
| `0x0104a420` | HEAD/WATCH_NUM node handler | [HEAD handler](../../analysis/firmware/colorfit-pulse-2/deep-dive/evidence/watchface-head-parser.txt) |
| `0x01044600` | Watchface component-name dispatch and widget construction | [Large node parser](../../analysis/firmware/colorfit-pulse-2/deep-dive/evidence/watchface-node-parser.txt) |
| `0x01086948`–`0x01086a0c` block | Watchface state, HEAD/WATCH passes, widget allocation/copy | [Builder block](../../analysis/firmware/colorfit-pulse-2/deep-dive/evidence/widget-watchface-build.txt) |
| `0x010912cc` / `0x01092fd4` | Pairing screen / QR content builder | [Pairing](../../analysis/firmware/colorfit-pulse-2/deep-dive/evidence/pairing-create.txt), [QR](../../analysis/firmware/colorfit-pulse-2/deep-dive/evidence/pairing-qr.txt) |
| `0x0108bc6c` / `0x0108bcb4` | Music screen creation / child construction | [Music](../../analysis/firmware/colorfit-pulse-2/deep-dive/evidence/music-create.txt) |
| `0x01067e48` | Factory screen create | [Factory](../../analysis/firmware/colorfit-pulse-2/deep-dive/evidence/factory-create.txt) |
| `0x0104bfe4` | Five-view menu-like construction | [Menu](../../analysis/firmware/colorfit-pulse-2/deep-dive/evidence/five-page-menu.txt) |
| `0x01088678` | Seven-page viewer construction | [Viewer](../../analysis/firmware/colorfit-pulse-2/deep-dive/evidence/seven-page-viewer.txt) |
| `0x01098ac4` | Resource incompatibility error UI | [Error view](../../analysis/firmware/colorfit-pulse-2/deep-dive/evidence/resource-error-screen.txt) |
| `0x010a6ccc` | Sports summary detail construction | [Sports summary](../../analysis/firmware/colorfit-pulse-2/deep-dive/evidence/sports-summary.txt) |
| `0x01071e7c` / `0x01057964` | Resource initialization / resource version checking | [Initialization](../../analysis/firmware/colorfit-pulse-2/deep-dive/evidence/resource-init.txt), [checks](../../analysis/firmware/colorfit-pulse-2/deep-dive/evidence/resource-version-check.txt) |
| `0x010a88f8` | OTA incoming component header/filename dispatch | [OTA dispatch](../../analysis/firmware/colorfit-pulse-2/deep-dive/evidence/ota-header-dispatch.txt) |
| `0x010adb10` | Create nine application tasks from descriptor table | [Task loop](../../analysis/firmware/colorfit-pulse-2/deep-dive/evidence/task-create.txt) |

## Reusable analysis artifacts

| Artifact | Appropriate use |
| --- | --- |
| [Analyst-generated ELF](../../analysis/firmware/colorfit-pulse-2/deep-dive/analyst-wrapper.elf) | Load code at the inferred base; no original symbols or faithful segment map |
| [Linear Thumb listing](../../analysis/firmware/colorfit-pulse-2/deep-dive/linear-thumb-disassembly.txt) | Address search; validate code/data boundaries before trusting a decoded line |
| [22 bounded excerpts](../../analysis/firmware/colorfit-pulse-2/deep-dive/evidence/) | Follow the reviewed paths without searching the full listing |
| [String-to-code candidates](../../analysis/firmware/colorfit-pulse-2/deep-dive/string-code-references.json) | Find diagnostic and parser references; nearest prologue is heuristic |
| [Exact string-pointer occurrences](../../analysis/firmware/colorfit-pulse-2/deep-dive/string-pointer-occurrences.json) | Search data and literal references; occurrence is not necessarily an executed load |
| [Branch candidates](../../analysis/firmware/colorfit-pulse-2/deep-dive/branch-candidates.json) | Call-site leads; includes branches decoded from data |
| [Screen registry](../../analysis/firmware/colorfit-pulse-2/deep-dive/screen-registry.json) | Recovered IDs, create/destroy pointers and registration addresses |
| [Task descriptors](../../analysis/firmware/colorfit-pulse-2/deep-dive/task-descriptors.json) | Nine verified descriptor records and raw task arguments |
| [Watchface structure](../../analysis/firmware/colorfit-pulse-2/deep-dive/watchface/structure.json) | Header, bounds, banks and all 51 image entries |
| [Watchface layout](../../analysis/firmware/colorfit-pulse-2/deep-dive/watchface/layout.json) | Exact metadata from the supplied cache |
| [Validation report](../../analysis/firmware/colorfit-pulse-2/deep-dive/validation.json) | Artifact integrity, registration pointer bounds, task descriptors and watchface range checks |

The 22 excerpts are selected ranges, not 22 fully decompiled functions. Source code cannot be regenerated losslessly from this stripped binary.

## What this investigation establishes

| User question | Answer from the supplied artifacts |
| --- | --- |
| Can the firmware OS be identified? | Strong FreeRTOS-family evidence and Goodix GR551x association; exact versions/chip unresolved. |
| Are different watch “apps” discoverable? | Yes: shared feature modules and screen lifecycle code, with 40 registration stubs recovered. Many screen names remain unknown. |
| Can the home-screen layout be recovered? | One cached face's exact metadata and two actual images are recovered. A universal/current home layout and full gesture map are not established. |
| Is watchface code present? | Yes: JSON section walker, metadata handler, large component parser and widget-template attachment path. |
| Can all screen artwork be extracted from a.bin? | No: code explicitly depends on external resource/font regions absent from this package. |
| Are these installable applications? | No separate app format was found; evidence supports compiled feature/screens within shared tasks. |
| Can we build and flash a replacement from this? | Not established. We do not have original sources, full resources, bootloader behavior, authentication details or a validated build/flash procedure. |

## Evidence that would resolve the largest gaps

1. **Matching resource packs or an existing read-only flash dump:** recover `res01.bin`, `fonts.bin`, `res02.bin`, `res03.bin` and the relevant watchface/config resource. These could resolve numeric image/text IDs, built-in face choices, fonts and many currently unnamed screens. A compatible full OTA package already present locally would also be useful; none was requested remotely for this work.
2. **A short physical-watch screen/navigation record:** pair observed screen names and gestures with callback behavior. This would validate whether the seven-page and five-page views correspond to home cards, menu pages or controls. A phone ADB connection alone does not grant MCU flash access or observe its internal callback addresses.
3. **Further offline code work:** decode the complete 20-byte widget schema and custom encoded image records, trace root transition processing, follow key/touch handler event constants, and recover more resource lookup paths. These are feasible analysis tasks, but they are not completed or silently assumed in the current screen catalog.
4. **Bootloader and memory-map evidence:** needed for complete update/install reasoning, signature checks and any eventual firmware modification. Application-side incoming-file parsing alone cannot establish those properties.

No extra backend access, cloud credentials, watch reset, update installation or flash write was used to obtain the findings in this folder.
