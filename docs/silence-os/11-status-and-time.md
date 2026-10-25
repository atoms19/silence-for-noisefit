# Watch status queries and time sync

Short commands on the command channel (`27f1`/`0af1`, write without response); replies are notifications starting with the same two command bytes, little-endian. Recovered from NoiseFit 5.4.6 smali. **Not yet verified on hardware.**

| Command | Bytes sent | Reply layout | Source |
| --- | --- | --- | --- |
| Device info (already used in the bind) | `02 01` | `02 01` + `id`(u16) `versionCode` `runMode` `batteryStatus` `battery%` `pairFlag` `rebootFlag` `hasDetailVersion` `bindConfirm` `platform` `resFlag` (u8 each) + `protocolVersion`(u16) + `btStatus`(u8) | `internal/b7`, `bean/TGDeviceInfo` (field names from its `toString`) |
| Battery | `02 05` | `02 05` + `type`(u8) `voltage`(u16, mV) `status`(u8) `level`(u8, %) + last-charge date: year(u16) month day hour minute second (u8 each; all zero means never) | `internal/b8`, `bean/TGBatteryInfo` |
| Version | `02 11` | `02 11` + `sdk` `hrAlgorithm` `sleepAlgorithm` `stepAlgorithm` `gestureAlgorithm` `pcbAlgorithm` (u8 each) + zero-terminated detail string from offset 8 | `internal/a8`, `bean/TGVersionInfo` |
| Sync time | `03 01` + 14 bytes: year(u16) month(1-12) day hour(0-23) minute second weekday(Mon=0..Sun=6) `00 00 00 00` timezone(u16) | `03 01 <status>` | `internal/l9.syncTime`, `internal/l8` |

Timezone: the SDK sends the offset in minutes (`rawOffset / 60000`) only when the protocol family is 3 (`protocolVersion >> 8 == 3`) or the device id is `0x1fa` (`internal/a0.o`); otherwise it sends 0. For protocol versions below `0x313` a non-positive offset has 1440 added. Silence follows this using the device-info reply.

Meaning of `status`, `batteryStatus` and `type` values (constants 0-3 in `TGBatteryInfo`) is not recovered; Silence shows level and voltage only.

## In Silence

After each successful bind Silence syncs the clock, then reads battery and version, and refreshes the battery every five minutes while bound. The watch card shows battery, firmware and last sync time, with **Refresh** and **Sync time** buttons (`TouchGuiSession.statusCommand`, `SilenceController`).
