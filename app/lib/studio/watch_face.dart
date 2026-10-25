/// Builds a `.watch` file from a template by swapping its raw wallpaper images.
library;

import 'dart:convert';
import 'dart:typed_data';

class WatchFaceException implements Exception {
  const WatchFaceException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Image entries the NoiseFit SDK overwrites for a photo face (`internal/z2.b(Bitmap)`).
const watchBackgroundId = 0;
const watchPreviewId = 1;

class _ImageRecord {
  const _ImageRecord(
    this.id,
    this.width,
    this.height,
    this.format,
    this.offset,
  );
  final int id, width, height, format, offset;
}

/// Replaces the raw background and preview images in [template] and points the
/// face's `image` component at the background. Output has the same length.
///
/// [background] and [preview] are big-endian RGB565 pixel data sized to the
/// template's image entries (see [watchImageSize]). Throws [WatchFaceException]
/// if the template does not match the layout recovered from the SDK.
Uint8List buildWatchFace({
  required Uint8List template,
  required Uint8List background,
  required Uint8List preview,
}) {
  final view = ByteData.sublistView(template);
  if (template.length < 28 || view.getUint32(0, Endian.little) != 0x00ffaa22) {
    throw const WatchFaceException('Template is not a watch face file.');
  }
  final jsonStart = 4 + view.getUint32(4, Endian.little);
  final jsonLength = view.getUint32(8, Endian.little);
  final indexStart = 4 + view.getUint32(12, Endian.little);
  final dataStart = 4 + view.getUint32(20, Endian.little);
  final dataLength = view.getUint32(24, Endian.little);
  if (jsonStart + jsonLength > template.length ||
      indexStart + 4 > template.length ||
      dataStart + dataLength > template.length) {
    throw const WatchFaceException('Template header points outside the file.');
  }

  final records = _readIndex(view, indexStart, template.length);
  final bg = records[watchBackgroundId];
  final pv = records[watchPreviewId];
  if (bg == null || pv == null || bg.format != 0 || pv.format != 0) {
    throw const WatchFaceException(
      'Template has no raw background/preview images.',
    );
  }
  _checkImage(bg, background, 'background', dataStart, dataLength);
  _checkImage(pv, preview, 'preview', dataStart, dataLength);

  final out = Uint8List.fromList(template);
  out.setRange(
    dataStart + bg.offset,
    dataStart + bg.offset + background.length,
    background,
  );
  out.setRange(
    dataStart + pv.offset,
    dataStart + pv.offset + preview.length,
    preview,
  );
  _pointBackgroundAtRawImage(out, jsonStart, jsonLength);
  return out;
}

/// Pixel size of the background and preview entries in [template].
({int width, int height}) watchImageSize(
  Uint8List template, {
  required bool preview,
}) {
  final view = ByteData.sublistView(template);
  final records = _readIndex(
    view,
    4 + view.getUint32(12, Endian.little),
    template.length,
  );
  final record = records[preview ? watchPreviewId : watchBackgroundId];
  if (record == null) {
    throw const WatchFaceException('Template image entry missing.');
  }
  return (width: record.width, height: record.height);
}

Map<int, _ImageRecord> _readIndex(
  ByteData view,
  int indexStart,
  int fileLength,
) {
  final count = view.getUint32(indexStart, Endian.little);
  if (count > 4096 || indexStart + 4 + count * 16 > fileLength) {
    throw const WatchFaceException('Template image index is invalid.');
  }
  final records = <int, _ImageRecord>{};
  for (var i = 0; i < count; i++) {
    final at = indexStart + 4 + i * 16;
    final id = view.getUint16(at, Endian.little);
    records[id] = _ImageRecord(
      id,
      view.getUint16(at + 2, Endian.little),
      view.getUint16(at + 4, Endian.little),
      view.getUint16(at + 6, Endian.little),
      view.getUint32(at + 12, Endian.little),
    );
  }
  return records;
}

void _checkImage(
  _ImageRecord record,
  Uint8List pixels,
  String name,
  int dataStart,
  int dataLength,
) {
  final size = record.width * record.height * 2;
  if (pixels.length != size) {
    throw WatchFaceException(
      'The $name image must be $size bytes, got ${pixels.length}.',
    );
  }
  if (record.offset + size > dataLength) {
    throw WatchFaceException(
      'The $name image does not fit in the template data.',
    );
  }
}

/// Rewrites `"image": { ... "id": N }` to id 0 in place, padding to keep the length.
void _pointBackgroundAtRawImage(Uint8List file, int jsonStart, int jsonLength) {
  var end = jsonStart;
  while (end < jsonStart + jsonLength && file[end] != 0) {
    end++;
  }
  final text = latin1.decode(file.sublist(jsonStart, end));
  final watch = text.indexOf('"WATCH"');
  final match = RegExp(
    r'"image"\s*:\s*\{[^}]*?"id"\s*:\s*(\d+)',
  ).firstMatch(text.substring(watch < 0 ? 0 : watch));
  if (match == null) {
    throw const WatchFaceException(
      'Template has no background image component.',
    );
  }
  final digits = match.group(1)!;
  final digitsAt = (watch < 0 ? 0 : watch) + match.end - digits.length;
  final replacement = '0'.padLeft(digits.length);
  file.setRange(
    jsonStart + digitsAt,
    jsonStart + digitsAt + digits.length,
    latin1.encode(replacement),
  );
}

/// Converts RGBA bytes to big-endian RGB565, the format of the watch's raw images.
Uint8List rgbaToRgb565Be(Uint8List rgba) {
  final out = Uint8List(rgba.length ~/ 2);
  for (var i = 0, o = 0; i + 3 < rgba.length; i += 4, o += 2) {
    final value =
        ((rgba[i] & 0xF8) << 8) |
        ((rgba[i + 1] & 0xFC) << 3) |
        (rgba[i + 2] >> 3);
    out[o] = value >> 8;
    out[o + 1] = value & 0xFF;
  }
  return out;
}

/// A raw RGB565 (big-endian) image entry for [buildWatchContainer].
class WatchImage {
  const WatchImage(this.id, this.width, this.height, this.pixels);
  final int id, width, height;
  final Uint8List pixels;
}

/// Writes a `.watch` container with only raw images, using the layout read by
/// the NoiseFit SDK (`internal/z2`) and observed in the cached face:
/// header, JSON (zero padded to 4 bytes), image index, then the raw bank.
Uint8List buildWatchContainer({
  required String json,
  required List<WatchImage> images,
}) {
  final jsonBytes = latin1.encode(json);
  final jsonLength = (jsonBytes.length + 1 + 3) ~/ 4 * 4;
  final indexLength = 4 + images.length * 16;
  var rawLength = 8;
  for (final image in images) {
    if (image.pixels.length != image.width * image.height * 2) {
      throw WatchFaceException('Image ${image.id} has the wrong size.');
    }
    rawLength += image.pixels.length;
  }

  const jsonOffset = 24;
  final indexOffset = jsonOffset + jsonLength;
  final dataOffset = indexOffset + indexLength;
  final out = Uint8List(4 + dataOffset + rawLength);
  final view = ByteData.sublistView(out);
  void u32(int at, int v) => view.setUint32(at, v, Endian.little);
  void u16(int at, int v) => view.setUint16(at, v, Endian.little);

  u32(0, 0x00ffaa22);
  u32(4, jsonOffset);
  u32(8, jsonLength);
  u32(12, indexOffset);
  u32(16, indexLength);
  u32(20, dataOffset);
  u32(24, rawLength);
  out.setRange(4 + jsonOffset, 4 + jsonOffset + jsonBytes.length, jsonBytes);

  final indexStart = 4 + indexOffset;
  final dataStart = 4 + dataOffset;
  u32(indexStart, images.length);
  u32(dataStart, 8);
  u32(dataStart + 4, rawLength);
  var cursor = 8;
  for (var i = 0; i < images.length; i++) {
    final image = images[i];
    final at = indexStart + 4 + i * 16;
    u16(at, image.id);
    u16(at + 2, image.width);
    u16(at + 4, image.height);
    u16(at + 6, 0);
    u32(at + 8, images.length);
    u32(at + 12, cursor);
    out.setRange(
      dataStart + cursor,
      dataStart + cursor + image.pixels.length,
      image.pixels,
    );
    cursor += image.pixels.length;
  }
  return out;
}
