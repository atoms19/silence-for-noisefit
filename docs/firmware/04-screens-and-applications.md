# Screen registry and application feature code

## What “applications” means in this image

Screen callbacks, feature logic and shared services are linked into the application binary. The recovered code does not show separate executables for weather, sports, music or health screens. A screen identifier is a navigation/state value, not an Android package ID. One feature can span several registered screens; a single registered screen can contain multiple child pages.

## Recovered registrations

The following **40** entries match reviewed raw Thumb registration stubs. All addresses are runtime code entries with the Thumb pointer bit removed. Their raw pointer values, pattern and string/call candidates are preserved in the [machine-readable registry](../../analysis/firmware/colorfit-pulse-2/deep-dive/screen-registry.json).

“Unresolved” is an actual research boundary: it is not evidence that the feature is absent or inaccessible. Numeric gaps do not establish nonexistent screens; other registration patterns may not match this extractor. The semantic descriptions below deliberately separate raw pointers from the interpretation of the callback code.

| ID | Registration stub | Create | Destroy | Identification / evidence |
| ---: | --- | --- | --- | --- |
| 1 | `0x010789e0` | `0x010912cc` | `0x010913c0` | **Pairing / QR**. Strong: two-page flow calls QR builder with Noise URL, MAC, SN and TYPE. |
| 2 | `0x010789b0` | `0x0109108c` | `0x0109111c` | **Power/binding view**. Diagnostic: power_bind_screen. |
| 3 | `0x01078bf0` | `0x0109c394` | `0x0109c558` | **Unresolved**. Callback addresses recovered; feature name not established. |
| 4 | `0x01078920` | `0x0108ab0c` | `0x0108ab5c` | **Unresolved**. Callback addresses recovered; feature name not established. |
| 5 | `0x01078b60` | `0x0109c120` | `0x0109c220` | **Unresolved**. Callback addresses recovered; feature name not established. |
| 6 | `0x01078b00` | `0x0109bfb8` | `0x0109c03c` | **Unresolved**. Callback addresses recovered; feature name not established. |
| 7 | `0x01078c20` | `0x0109cb0c` | `0x0109cb44` | **Unresolved**. Callback addresses recovered; feature name not established. |
| 8 | `0x01078b30` | `0x0109c094` | `0x0109c0c4` | **Unresolved**. Callback addresses recovered; feature name not established. |
| 9 | `0x01078ad0` | `0x0109be98` | `0x0109bec8` | **Unresolved**. Callback addresses recovered; feature name not established. |
| 10 | `0x01078b90` | `0x0109c2a4` | `0x0109c318` | **Unresolved**. Callback addresses recovered; feature name not established. |
| 11 | `0x01078aa0` | `0x0109be48` | `0x0109be78` | **Unresolved**. Callback addresses recovered; feature name not established. |
| 12 | `0x01078710` | `0x0104db28` | `0x0104e0d0` | **Unresolved**. Callback addresses recovered; feature name not established. |
| 13 | `0x010788f0` | `0x01088678` | `0x010889fc` | **Seven-page viewer; names unresolved**. Structural: seven child pages and templates. |
| 14 | `0x010788c0` | `0x0104b7cc` | `0x0104b8d4` | **Unresolved**. Callback addresses recovered; feature name not established. |
| 15 | `0x01078a70` | `0x0109f384` | `0x0109f4c8` | **Unresolved**. Callback addresses recovered; feature name not established. |
| 16 | `0x01078d70` | `0x0104d110` | `0x0104d334` | **Unresolved**. Callback addresses recovered; feature name not established. |
| 17 | `0x01078e00` | `0x010b8b84` | `0x010b8c7c` | **Unresolved**. Callback addresses recovered; feature name not established. |
| 18 | `0x01078c50` | `0x0109dcfc` | `0x0109de14` | **Unresolved**. Callback addresses recovered; feature name not established. |
| 19 | `0x010787a0` | `0x01052e74` | `0x01053000` | **Unresolved**. Callback addresses recovered; feature name not established. |
| 20 | `0x01078890` | `0x0109000c` | `0x010901e4` | **Unresolved**. Callback addresses recovered; feature name not established. |
| 21 | `0x01078770` | `0x01051264` | `0x010512d8` | **Unresolved**. Callback addresses recovered; feature name not established. |
| 22 | `0x01078830` | `0x01067e48` | `0x01067fe4` | **Factory diagnostics**. Direct diagnostic: factory_screen. |
| 24 | `0x010786e0` | `0x0104ce14` | `0x0104d080` | **Unresolved**. Callback addresses recovered; feature name not established. |
| 25 | `0x01078ce0` | `0x010a53c4` | `0x010a541e` | **Unresolved**. Callback addresses recovered; feature name not established. |
| 26 | `0x01078d40` | `0x010aa234` | `0x010aa43c` | **Unresolved**. Callback addresses recovered; feature name not established. |
| 27 | `0x01078dd0` | `0x010aea98` | `0x010aeaec` | **Unresolved**. Callback addresses recovered; feature name not established. |
| 28 | `0x010786b0` | `0x01042958` | `0x010429a8` | **Unresolved**. Callback addresses recovered; feature name not established. |
| 29 | `0x01078950` | `0x0108bc6c` | `0x0108bdec` | **Music controls**. Create calls nearby music builder; associated music_screen_update diagnostic. |
| 30 | `0x01078d10` | `0x010a6fb4` | `0x010a6fe4` | **Unresolved**. Callback addresses recovered; feature name not established. |
| 31 | `0x01078a40` | `0x01098ac4` | `0x01098bdc` | **Resource mismatch error**. Create loads explicit Resources do not match message. |
| 32 | `0x01078800` | `0x01066e5c` | `0x01067138` | **Information/diagnostic view candidate**. Unresolved: text buffers and MAC-format lead; not established as consumer About screen. |
| 33 | `0x01078860` | `0x0104afa0` | `0x0104b176` | **Unresolved**. Callback addresses recovered; feature name not established. |
| 34 | `0x01078bc0` | `0x0109c5bc` | `0x0109c5ec` | **Unresolved**. Callback addresses recovered; feature name not established. |
| 35 | `0x01078740` | `0x01091160` | `0x010911b0` | **Unresolved**. Callback addresses recovered; feature name not established. |
| 36 | `0x010787d0` | `0x010534f0` | `0x010535d0` | **Unresolved**. Callback addresses recovered; feature name not established. |
| 37 | `0x01078980` | `0x0104bfe4` | `0x0104c1a8` | **Five-page menu-like view**. Direct menu_chose_index diagnostic and child construction. |
| 41 | `0x01078cb0` | `0x010a54a4` | `0x010a54d4` | **Sports selection**. Destroy callback contains sport_select_screen_tear. |
| 42 | `0x01078c80` | `0x010a0438` | `0x010a06a8` | **Sports selection/delete**. Destroy callback contains sport_delete_screen_tear and sport_select_delete.c. |
| 43 | `0x01078a10` | `0x01091454` | `0x010916cc` | **Conditional-layout view; name unresolved**. Two construction branches; resource labels missing. |
| 45 | `0x01078da0` | `0x010a6ccc` | `0x010a6da0` | **Sports summary detail**. Direct diagnostic: sport_summary_detail_screen error. |

## Identifiable feature clusters beyond screen IDs

These clusters have useful code/string evidence even where the entry screen ID has not been assigned. Diagnostic names below are embedded strings, not recovered symbol-table declarations.

| Feature | Evidence in the recovered image | What remains unresolved |
| --- | --- | --- |
| Pairing and companion connection | QR builder `0x01092fd4`; Noise QR URL, `MAC:`, `SN:` and `TYPE:OY%s`; two-page registered flow | Complete binding state machine and every failure screen |
| Watchface / clock | JSON node parser `0x01044600`; HEAD parser `0x0104a420`; JSON section walker `0x0106e2d2`; cached layout matches keys | Exact home-screen registration and all built-in face resources |
| Music control | Screen 29 create `0x0108bc6c`; builder `0x0108bcb4`; diagnostic `music_screen_update` at `0x0108be54` | Every transport command/event and all text/icon assets |
| Sports selection and activity | `sport_list`, `sport_menu_deal`, `sport_pause`, `sport_resume`, `sport_stop`; source paths for sport_select_screen, sport_select_details, sport_select_delete and sport_list | Full mode enumeration, each mode's screen layout and model/hardware availability |
| Sports live view | Function-associated string `sport_going_screen_create` loaded at `0x010a172e`; sports-ready create/tear messages | Complete relation between live view, pause/ready, summary and registered IDs |
| Sports summary | Screen 45 create `0x010a6ccc`; summary-detail diagnostic; distance, pace, time and energy formatting | Full field semantics, units configuration and page contents |
| Health measurements | HRM_TASK and ALG_TASK; `SINGLE_HRM`, `SINGEL_SPO2`, `SINGEL_STRESS`, `SPORT_HRM`, `AUTO_HRM` diagnostic; `Please keep still` | Which registered IDs correspond to HR/SpO2/stress, complete UI and physical sensor variant |
| Daily activity and sleep | Daily steps/calorie/distance processing; sleep merging/storage diagnostics, deep/light/wake/eye-movement fields | Accuracy, whether every field is displayed, sleep screen mapping |
| Weather | WEATHER_SWITCH_CHANGED handling; `weather_section` and `image_weather` in face builder | Dedicated weather screen mapping and complete weather data format |
| Notifications | Embedded sender/type names: Message, Instagram, WhatsApp, Outlook, Telegram, Facebook, WeChat and others | Full icon mapping, truncation/scroll behavior and supported app notifications on this unit |
| Alarm/reminders | `remind_alarm_push`, `alarm_snoozed_blank`, time formatting and reminder routines | All alarm screens, snooze state machine and user settings |
| Update/status UI | Installing, update-success, synchronizing, synchronization-success/failure strings | Which status widgets share screen IDs and precise progress timing |
| Factory/system information | Screen 22; `factory_burn_create`; `page_version_init`, `Screen supplier:`, boot/resource/font version text; product/model strings | Consumer access paths and any hidden entry gesture |

The social-app names refer to notification classification; they do **not** mean Instagram, WhatsApp or other third-party apps execute on the watch. The presence of health/stress/sports code also does not prove every compiled mode is exposed on this model.

## Selected code-level observations

The pairing QR payload starts from `https://noise-images.s3.ap-south-1.amazonaws.com/qr_code/dafit.html?mac=&sn=&type`, then code formats device identifiers. This is data rendered into a QR code, not evidence that the firmware itself performs an HTTP request. The URL was not requested during this investigation.

Sports selection has distinct teardown diagnostics and source filenames, so there is more evidence here than a generic list of strings. Screen 41's destroy callback starts at `0x010a54d4`, screen 42's at `0x010a06a8`. The summary-detail handler at `0x010a6ccc` checks activity type and emits a specific error path. These support separate feature modules without implying separate processes.

The resource mismatch view at `0x01098ac4` displays “Resources do not match please connect APP to upgrade again.” This directly connects the UI to separate versioned resources and explains why a code-only update can leave much of its appearance outside the downloaded package.

Sources: [pairing QR excerpt](../../analysis/firmware/colorfit-pulse-2/deep-dive/evidence/pairing-qr.txt), [music create excerpt](../../analysis/firmware/colorfit-pulse-2/deep-dive/evidence/music-create.txt), [sports summary excerpt](../../analysis/firmware/colorfit-pulse-2/deep-dive/evidence/sports-summary.txt), [factory excerpt](../../analysis/firmware/colorfit-pulse-2/deep-dive/evidence/factory-create.txt), [resource error excerpt](../../analysis/firmware/colorfit-pulse-2/deep-dive/evidence/resource-error-screen.txt), [all string-reference candidates](../../analysis/firmware/colorfit-pulse-2/deep-dive/string-code-references.json).
