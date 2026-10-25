# Findings from the supplied phone logs

The user copied `appLogs/logs.txt` from the existing NoiseFit installation into this workspace. An offline scan inspected all 4,410 lines (345,623 bytes), spanning timestamps **2026-10-17 21:45:17.771 through 2026-10-24 23:54:09.235**, as recorded by the app. Timestamp timezone accuracy was not independently established.

## Model and SDK are corroborated by runtime logs

The supplied log records:

- Line 8: discovery of `ColorFit Pulse 2`.
- Line 10: `Init Evolve SDK`.
- Lines 12 and 18: connection data actions for the Evolve SDK.
- Line 15: a newly paired device identified as `colorfit_pulse_2` (MAC address omitted).
- Line 19 and later: Evolve SDK watch-type processing.

This corroborates the Evolve2/TouchGUI integration inferred from APK code. It does not establish a firmware version, actual GATT services, hardware revision or bootloader behavior. Additional numeric values in pairing logs were not assumed to be a firmware catalog ID or version.

## Firmware search results

| Search group | Matching log lines |
| --- | --- |
| Firmware / firmware ID / firmware-version markers | 0 |
| OTA / TGOTA / updateFirmware / firmware endpoint markers | 0 |
| Download / ZIP / BIN / OTA filename markers | 0 |
| Version text | 0 |
| Evolve SDK text | 175 |
| Exact Pulse 2 name/key | 2 |

All 35 HTTP(S) URL occurrences reference `api.weatherapi.com/v1/forecast.json`. Query values are deliberately excluded from the report. No firmware URL or firmware package filename was recovered from this file.

Absence of these strings does not prove that no update ever occurred. The log may be incomplete, rotated, filtered or omit OTA events. It also does not establish whether the private cache still contains files. No request to any URL was made.

## Preserved evidence and reproduction

[log-inspection.json](../analysis/device-cache/log-inspection.json) records the SHA-256 hash, timestamps, counts and evidence line numbers without reproducing MAC addresses, account information or URL query values. The source log remains local; this report avoids copying unrelated health/account data into Markdown.

Reproduce the scan with:

```sh
python3 analysis/tools/inspect_device_logs.py
```

## Remaining accessible location

The user subsequently supplied an ADB listing of `/sdcard/Android/data/com.noisefit/files/` containing only `.` and `..`: the external files directory is empty. The external cache contains a watch-face resource and app logs, as documented in [chapter 13](13-device-cache-inspection.md). Neither supplied artifact contains an identifiable firmware package or a firmware download URL.

The private cache remains inaccessible through `run-as` because the installed package is not debuggable; its contents are unknown. Firmware recovery from the accessible app directories and supplied artifacts has not succeeded. Existing root access could permit private-cache inspection, but root access has not been established. No rooting, bootloader unlocking, backend request or wearable readout has been performed. Ordinary ADB cannot bypass these private-storage restrictions.
