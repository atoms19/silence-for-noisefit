/// Encoder for the TouchGUI "message" command (notifications shown on the watch).
///
/// Layout recovered from NoiseFit 5.4.6 (`internal/h5`, `internal/a6`,
/// `internal/d2`); see docs/silence-os/09-notification-protocol.md.
library;

import 'dart:convert';
import 'dart:typed_data';

/// Application categories with the SDK's type codes. On a Pulse 2, LinkedIn
/// and Calendar show nothing and `other` looks like an SMS-style message.
enum WatchAppType {
  sms('SMS', 0x01),
  weChat('WeChat', 0x03),
  messenger('Messenger', 0x06),
  twitter('Twitter', 0x07),
  whatsApp('WhatsApp', 0x08),
  instagram('Instagram', 0x0a),
  linkedIn('LinkedIn', 0x0b),
  calendar('Calendar', 0x0c),
  skype('Skype', 0x0d),
  viber('Viber', 0x12),
  gmail('Gmail', 0x14),
  outlook('Outlook', 0x15),
  snapchat('Snapchat', 0x16),
  telegram('Telegram', 0x17),
  other('Other', 0x80);

  const WatchAppType(this.label, this.code);
  final String label;
  final int code;
}

const _magic = [0xDA, 0xAD, 0xDA, 0xAD];
const messageCommandId = 0x000B;
const _protocolVersion = 1;

/// Maximum message body in bytes (`0x2ed`), counting field headers.
const _bodyLimit = 0x2ed;

/// CRC used by the long-command framing (`internal/a.a`), init 0xFFFF.
int touchGuiCrc16(List<int> data, [int? length]) {
  var crc = 0xFFFF;
  for (var i = 0; i < (length ?? data.length); i++) {
    crc = ((crc >> 8) | (crc << 8)) & 0xFFFF;
    crc ^= data[i] & 0xFF;
    crc ^= (crc & 0xFF) >> 4;
    crc ^= (crc << 12) & 0xFFFF;
    crc ^= ((crc & 0xFF) << 5) & 0xFFFF;
  }
  return crc & 0xFFFF;
}

/// Drops trailing characters until [text] fits in [maxBytes] of UTF-8
/// (`internal/s.a`).
String truncateUtf8(String text, int maxBytes) {
  var result = text;
  while (result.isNotEmpty && utf8.encode(result).length > maxBytes) {
    result = result.substring(0, result.length - 1);
  }
  return result;
}

/// Builds the message body: flags, type, then name, number and content as
/// zero byte + little-endian length + UTF-8 bytes. With [invert], each string
/// byte is bitwise inverted (the SDK does this when a device capability bit
/// is set; Pulse 2's setting is unknown).
Uint8List buildNotificationBody({
  required int type,
  String name = '',
  String number = '',
  String content = '',
  bool invert = false,
}) {
  List<int> encode(String s) {
    final bytes = utf8.encode(s);
    return invert ? [for (final b in bytes) ~b & 0xFF] : bytes;
  }

  final nameBytes = encode(name);
  final numberBytes = encode(number);
  var size = 7;
  if (nameBytes.isNotEmpty) size += 5 + nameBytes.length;
  if (numberBytes.isNotEmpty) size += 5 + numberBytes.length;
  final contentBytes = encode(truncateUtf8(content, _bodyLimit - size));

  final out = BytesBuilder();
  void field(List<int> bytes) {
    if (bytes.isEmpty) return;
    out.addByte(0);
    out.add(
      (ByteData(
        4,
      )..setUint32(0, bytes.length, Endian.little)).buffer.asUint8List(),
    );
    out.add(bytes);
  }

  out
    ..addByte(0)
    ..addByte(0)
    ..addByte(nameBytes.isNotEmpty ? 1 : 0)
    ..addByte(numberBytes.isNotEmpty ? 1 : 0)
    ..addByte(contentBytes.isNotEmpty ? 1 : 0)
    ..addByte(type & 0xFF)
    ..addByte(0);
  field(nameBytes);
  field(numberBytes);
  field(contentBytes);
  return out.toBytes();
}

/// Wraps [body] as a long command: magic, version, length, command id,
/// sequence, body, CRC-16 (all little-endian).
Uint8List frameLongCommand(
  Uint8List body, {
  required int commandId,
  required int sequence,
}) {
  final out = ByteData(body.length + 13);
  for (var i = 0; i < 4; i++) {
    out.setUint8(i, _magic[i]);
  }
  out.setUint8(4, _protocolVersion);
  out.setUint16(5, body.length + 0xB, Endian.little);
  out.setUint16(7, commandId, Endian.little);
  out.setUint16(9, sequence, Endian.little);
  final bytes = out.buffer.asUint8List();
  bytes.setRange(11, 11 + body.length, body);
  out.setUint16(
    11 + body.length,
    touchGuiCrc16(bytes, 11 + body.length),
    Endian.little,
  );
  return bytes;
}

/// The next sequence number the SDK would use (1..0xFFFE, never 0).
int nextSequence(int counter) => counter % 0xFFFE + 1;

/// Full message for a notification, ready for fragmentation and sending.
Uint8List buildNotificationMessage({
  required WatchAppType app,
  String name = '',
  String number = '',
  String content = '',
  required int sequence,
  bool invert = false,
}) => frameLongCommand(
  buildNotificationBody(
    type: app.code,
    name: name,
    number: number,
    content: content,
    invert: invert,
  ),
  commandId: messageCommandId,
  sequence: sequence,
);

/// Command id that sets one quick-reply preset on the watch.
const quickReplyPresetCommandId = 0x0015;

/// Longest preset text the SDK sends (bytes).
const quickReplyMaxBytes = 128;

/// Body for one preset: total count, 1-based index, text length, UTF-8 text.
Uint8List buildQuickReplyPresetBody({
  required int count,
  required int index,
  required String text,
}) {
  var bytes = utf8.encode(text);
  while (bytes.length > quickReplyMaxBytes) {
    text = text.substring(0, text.length - 1);
    bytes = utf8.encode(text);
  }
  return Uint8List.fromList([count, index, bytes.length, ...bytes]);
}

/// Full framed message for one quick-reply preset.
Uint8List buildQuickReplyPresetMessage({
  required int count,
  required int index,
  required String text,
  required int sequence,
}) => frameLongCommand(
  buildQuickReplyPresetBody(count: count, index: index, text: text),
  commandId: quickReplyPresetCommandId,
  sequence: sequence,
);
