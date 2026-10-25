# BLE protocol evidence

## Multiple transport/protocol families

There is no single NoiseFit GATT service common to every supported device in this sample. Vendor selection and `protocolName` choose different stacks. ZH itself contains standard/protobuf, Berry, Berry ring, large-file and SPP-related paths. IDO, Realtek, TouchGUI and other vendor DFU implementations have their own UUIDs and framing. The [UUID catalog](catalogs/uuid-literals.md) records 149 unique literal UUIDs across all DEX code, including unrelated examples and SDK constants.

The values below are confirmed **SDK constants**, not the services observed on the physical band. Actual advertising/service discovery was not performed.

## Interpreted ZH UUID constants

For rows using short values, expand with suffix `-0000-1000-8000-00805f9b34fb`, padding the first group to eight hexadecimal digits. The protobuf family has a different suffix and is shown in full.

| SDK constant(s) | UUID(s) | Meaning from code |
| --- | --- | --- |
| `SCAN_RECORD` | `0000fe78-0000-1000-8000-00805f9b34fb` | Advertising/scan UUID constant |
| `UUID_CHARACTERISTIC_UPDATE_NOTIFICATION_DESCRIPTOR` | `00002902-0000-1000-8000-00805f9b34fb` | Notification descriptor (CCCD) |
| `UUID_BASE_SERVICE`, `UUID_BASE_WRITE`, `UUID_BASE_READ` | `00000001`, `00000002`, `00000003` + suffix | SDK base channel |
| `UUID_PROTOBUF_SERVICE` | `16186f00-0000-1000-8000-00807f9b34fb` | Protobuf service |
| `CHAR_PROTOBUF_UUID_01` … `_05` | `16186f01` … `16186f05` with `-0000-1000-8000-00807f9b34fb` | Multiplexed protobuf characteristics; several have write/notification handling |
| `UUID_BIG_SERVICE`, `CHAR_BIG_UUID_02`, `_03` | `00002001`, `00002002`, `00002003` + suffix | Dedicated large-data channel constants |
| `UUID_AA01_SERVICE`, write/read, extra write/read | `0000aa01` … `0000aa05` + suffix | Alternate AA01 channel family |
| `UUID_ECG_SERVICE`, `UUID_ECG_READ` | `00003e01`, `00003e03` + suffix | ECG channel constants |
| `UUID_PPG_SERVICE`, `UUID_PPG_READ` | `00002c01`, `00002c03` + suffix | PPG channel constants |
| `UUID_THEME_SERVICE`, write/read | `00001601`, `00001602`, `00001603` + suffix | Theme/resource channel |
| `UUID_LOG_SERVICE`, `UUID_LOG_READ` | `00001701`, `00001703` + suffix | Log channel |
| `UUID_IMAGER_SERVICE`, `UUID_IMAGER_WRITE` | `00003d01`, `00003d02` + suffix | Image-related channel |
| Berry ring service, protocol read, data read/write | `00006666`, `00000050`, `0000005e`, `0000005f` + suffix | Berry ring-specific constants; not evidence the band is a ring |
| `UUID_SPP` | `00001101-0000-1000-8000-00805f9b34fb` | Bluetooth classic serial profile constant |

Source: [UuidUtils:1](../analysis/smali/classes9/com/zhapp/ble/utils/UuidUtils.smali#L1). `BluetoothService` uses `BluetoothGatt.setCharacteristicNotification`, resolves the protobuf characteristics and writes through `BluetoothGatt.writeCharacteristic`. Some channel selection is protocol-dependent; the table deliberately does not infer a universal write/read direction solely from a characteristic number.

Source: [BluetoothService:1](../analysis/smali/classes9/com/zhapp/ble/BluetoothService.smali#L1).

## Protobuf schemas recovered from generated classes

ZH `WearProtos.WearPacket` exposes field-number constants. Selected envelope fields:

| Field | Number |
| --- | --- |
| `type` | 1 |
| `id` | 2 |
| `account` | 3 |
| `system` | 4 |
| `watch_face` | 6 |
| `nfc` | 7 |
| `notification` | 9 |
| `fitness` | 10 |
| `lpa` | 11 |
| `weather` | 12 |
| `stock` | 13 |
| `error_code` | 100 |

Corresponding `Type` enum values include `ACCOUNT = 1`, `SYSTEM = 2`, `WATCH_FACE = 4`, `NOTIFICATION = 7`, `FITNESS = 8`, `LPA = 9`, `WEATHER = 10`, `STOCK = 11` and additional types. **Enum values and protobuf field numbers differ** and should not be conflated with GATT characteristic numbers.

Sources: [WearProtos$WearPacket:1](../analysis/smali/classes9/com/zh/wear/protobuf/WearProtos$WearPacket.smali#L1), [WearProtos$WearPacket$Type:1](../analysis/smali/classes9/com/zh/wear/protobuf/WearProtos$WearPacket$Type.smali#L1).

ZH OTA preparation fields:

| Message | Field/enum | Number/value |
| --- | --- | --- |
| `SystemProtos.PrepareOta.Request` | `force` | field 1 |
| Same | `type` | field 2 |
| Same | `firmware_version` | field 3 |
| Same | `file_md5` | field 4 |
| `PrepareOta.Response` | `prepare_status` | field 1 |
| `PrepareOta.Type` | `ALL`, `ROM`, `RES` | enum values 0, 1, 2 |

Sources: [SystemProtos$PrepareOta$Request:1](../analysis/smali/classes9/com/zh/wear/protobuf/SystemProtos$PrepareOta$Request.smali#L1), [SystemProtos$PrepareOta$Response:1](../analysis/smali/classes9/com/zh/wear/protobuf/SystemProtos$PrepareOta$Response.smali#L1), [SystemProtos$PrepareOta$Type:1](../analysis/smali/classes9/com/zh/wear/protobuf/SystemProtos$PrepareOta$Type.smali#L1).

The separate CommonPt protocol has `NPBFirmware.FirmwareStart` fields `version=1`, `res_full=2`, `length=3`, `md5=4`. It belongs to a different namespace/service and should not be encoded as a ZH `PrepareOta` message.

Source: [NPBFirmware$FirmwareStart:1](../analysis/smali/classes17/com/noise/wear/protocol/protobuf/entity/NPBFirmware$FirmwareStart.smali#L1).

## Transfer behavior and unresolved wire details

Berry large-file code provides explicit slice/index/timeout/resume state. The exact end-to-end frame construction still depends on service code and native serialization/crypto boundaries. Internal manager headers and payload multiples from chapter 06 are not a recipe to send an OTA packet.

A complete interoperable client would require confirming service discovery, characteristic properties, descriptor setup, MTU negotiation, fragmentation/reassembly, sequence/acknowledgment semantics, checksums/encryption, binding credentials, retries, reconnect behavior and post-update identity for the specific model. This research identifies the source locations for those questions, but no wire capture or native decryption audit was performed.
