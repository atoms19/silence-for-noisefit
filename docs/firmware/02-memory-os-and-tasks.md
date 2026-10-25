# Memory, operating system and task structure

## Platform and execution model

The binary's Goodix SDK banner identifies the **GR551x family**. Thumb instructions, floating-point operations, vector pointers and RAM references fit an ARM microcontroller firmware. The Cortex-M4 disassembly setting is an analysis choice consistent with this code; it does not identify the exact chip fitted to this particular watch.

FreeRTOS-family evidence includes `pvPortMalloc`, `vApplicationMallocFailedHook`, `vApplicationStackOverflowHook`, and `Tmr Svc`. A reviewed task creation loop at `0x010adb10` consumes nine descriptors with function, name, stack-depth and priority arguments. This combination is substantially stronger evidence than an isolated RTOS string. The exact RTOS version and configuration remain unresolved.

The watch's apparent “apps” are best understood as screens and feature modules in this compiled image. We found no separate installable app package format or process isolation for them. Watchface resource parsing is a separate mechanism and is not evidence for installing arbitrary application code.

## Application task descriptors

The table starts at `0x010bf628`, with 16-byte entries. The creator reads the function/name pair, a halfword at +8, and a word at +12, then passes them to the task creation routine at `0x010bbcac`. The arguments are consistent with FreeRTOS task creation. Stack values below are the raw depth arguments, **not measured RAM consumption or guaranteed byte counts**.

| Task name | Entry address | Stack-depth argument | Priority argument | Inferred responsibility |
| --- | --- | ---: | ---: | --- |
| ELX_DRV_TASK | `0x010616b0` | 1024 | 11 | Driver/service events |
| PM_Task | `0x01090ce4` | 1024 | 7 | Power and charging management |
| ELX_TIMER | `0x0105c28c` | 1536 | 3 | Application timers |
| Sync_Task | `0x01066554` | 1536 | 10 | Companion/device data synchronization |
| Service_Task | `0x01064f60` | 2048 | 5 | Shared application services |
| HRM_TASK | `0x01063050` | 2560 | 6 | Optical measurement processing |
| GUI_TASK | `0x01079efc` | 1024 | 4 | Screen lifecycle, input and redraw |
| ALG_TASK | `0x0105caac` | 1024 | 8 | Activity/sensor algorithms |
| BLE_TASK | `0x0105f978` | 1024 | 12 | Bluetooth execution |

Sources: [raw descriptors](../../analysis/firmware/colorfit-pulse-2/deep-dive/task-descriptors.json), [creation loop](../../analysis/firmware/colorfit-pulse-2/deep-dive/evidence/task-create.txt), and [GUI task](../../analysis/firmware/colorfit-pulse-2/deep-dive/evidence/gui-task.txt).

These are nine application descriptors, not a claim of exactly nine total RTOS tasks: idle, timer-service and dynamically created tasks can exist independently.

## Memory regions relevant to the UI

| Address / region | Static evidence | Interpretation |
| --- | --- | --- |
| `0x01023000`–`0x010f5a20` | Vector/header/footer and coherent references | Recovered application image mapping |
| `0x00836394` | Input/render callback dispatch accesses | Global GUI callback structure |
| `0x008363e8` | Root getter returns this address | Page lifecycle and event state |
| `0x00806abc` | Registration stubs store 16-bit screen ID | Current/requested screen identifier state; precise transition timing requires runtime validation |
| `0x00806b24` | Startup and callback setters store function pointers | GUI create and auxiliary callback state |
| `0x00806698` | Watchface count/index/buffer accesses | Watchface builder state |
| `0x01102000` and higher resource regions | Resource initialization and OTA filename dispatch | Resources outside the recovered image |
| `0x018c0000` | `a.bin` OTA destination selection | Application update staging destination; not the running image base |

Addresses in this firmware use both `0x0080xxxx` and `0x0083xxxx` RAM ranges; retain every digit when importing labels. See [resource map](06-resources-and-ota.md) for the reviewed flash destinations.

## Hardware-facing leads

Diagnostic strings reference `jd9851`, LCD module IDs `9851`/`9307`, accelerometers `msa310`/`STK832x`, touch identification and versions, and optical HRM/SpO2/stress processing. Their presence establishes compiled support paths, not which hardware variant this physical unit selects. No claim of GPS hardware follows from the sports code's outdoor/GPS-related names; phone-assisted and no-GPS branches also exist.
