import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silence_app/studio/artwork.dart';
import 'package:silence_app/studio/clock_style.dart';
import 'package:silence_app/studio/digital_face.dart';
import 'package:silence_app/studio/watch_face.dart';

/// Reads a container the way `internal/z2.a(File)` does.
({
  Map<String, dynamic> json,
  Map<int, (int, int, int)> images,
  int dataStart,
  int dataLength,
})
parse(Uint8List file) {
  final view = ByteData.sublistView(file);
  expect(view.getUint32(0, Endian.little), 0x00ffaa22);
  final jsonStart = 4 + view.getUint32(4, Endian.little);
  final jsonLength = view.getUint32(8, Endian.little);
  final indexStart = 4 + view.getUint32(12, Endian.little);
  final indexLength = view.getUint32(16, Endian.little);
  final dataStart = 4 + view.getUint32(20, Endian.little);
  final dataLength = view.getUint32(24, Endian.little);
  expect(jsonLength % 4, 0);
  expect(jsonStart + jsonLength, indexStart);
  expect(indexStart + indexLength, dataStart);
  expect(dataStart + dataLength, file.length);
  var end = jsonStart;
  while (file[end] != 0) {
    end++;
  }
  final json =
      jsonDecode(latin1.decode(file.sublist(jsonStart, end)))
          as Map<String, dynamic>;
  final count = view.getUint32(indexStart, Endian.little);
  expect(indexLength, 4 + count * 16);
  final images = <int, (int, int, int)>{};
  for (var i = 0; i < count; i++) {
    final at = indexStart + 4 + i * 16;
    final w = view.getUint16(at + 2, Endian.little);
    final h = view.getUint16(at + 4, Endian.little);
    final offset = view.getUint32(at + 12, Endian.little);
    expect(view.getUint16(at + 6, Endian.little), 0);
    expect(offset + w * h * 2 <= dataLength, isTrue);
    images[view.getUint16(at, Endian.little)] = (w, h, offset);
  }
  return (
    json: json,
    images: images,
    dataStart: dataStart,
    dataLength: dataLength,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    Future<ByteData> load(String name) async =>
        ByteData.sublistView(await File('assets/fonts/$name').readAsBytes());
    final loader = FontLoader('SilenceSans')
      ..addFont(load('Roboto-Regular.ttf'))
      ..addFont(load('Roboto-Medium.ttf'));
    await loader.load();
  });

  test(
    'Container writer lays out header, index and raw bank like the SDK reader',
    () {
      final a = Uint8List(4 * 2 * 2)..fillRange(0, 16, 1);
      final b = Uint8List(2 * 3 * 2)..fillRange(0, 12, 2);
      final file = buildWatchContainer(
        json: '{"a":1}',
        images: [WatchImage(0, 4, 2, a), WatchImage(7, 2, 3, b)],
      );
      final parsed = parse(file);
      expect(parsed.json, {'a': 1});
      expect(parsed.images[0], (4, 2, 8));
      expect(parsed.images[7], (2, 3, 24));
      expect(parsed.dataLength, 8 + 16 + 12);
      expect(file.sublist(parsed.dataStart + 8, parsed.dataStart + 24), a);
    },
  );

  testWidgets('Digital faces carry 42 images and a consistent description', (
    tester,
  ) async {
    for (final style in clockStyles) {
      final art = ArtworkController();
      addTearDown(art.dispose);
      final file = (await tester.runAsync(() => buildDigitalFace(art, style)))!;
      final parsed = parse(file);
      expect(parsed.images.length, 42, reason: style.id);
      expect(parsed.images[0]!.$1, 240);
      expect(parsed.images[1]!.$1, 184);
      for (var slot = 0; slot < 4; slot++) {
        for (var digit = 0; digit < 10; digit++) {
          final entry = parsed.images[digitSetStart(slot) + digit];
          expect(
            entry,
            isNotNull,
            reason: '${style.id} slot $slot digit $digit',
          );
          expect(entry!.$1, style.digitWidth);
          expect(entry.$2, style.digitHeight);
        }
      }
      final clock =
          (parsed.json['WATCH'] as Map)['multiple_image_clock'] as Map;
      expect(clock['id1_start_time'], 2);
      expect(clock['id4_start_time'], 32);
      expect(
        art.clock,
        isNull,
        reason: 'builder must restore the artwork state',
      );
    }
  });

  testWidgets('Writes preview PNGs when SILENCE_PREVIEW_DIR is set', (
    tester,
  ) async {
    final dir = Platform.environment['SILENCE_PREVIEW_DIR'];
    if (dir == null) return;
    for (final style in clockStyles) {
      final art = ArtworkController()..setClock(style);
      addTearDown(art.dispose);
      await tester.runAsync(() async {
        final rgba = await art.exportRgba(
          240,
          280,
          decorate: true,
          sample: true,
        );
        final completer = ui.ImmutableBuffer.fromUint8List(rgba);
        final buffer = await completer;
        final descriptor = ui.ImageDescriptor.raw(
          buffer,
          width: 240,
          height: 280,
          pixelFormat: ui.PixelFormat.rgba8888,
        );
        final codec = await descriptor.instantiateCodec();
        final image = (await codec.getNextFrame()).image;
        final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        await File(
          '$dir/${style.id}.png',
        ).writeAsBytes(png.buffer.asUint8List());
      });
    }
  });
}
