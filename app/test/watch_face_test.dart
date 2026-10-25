import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:silence_app/studio/artwork.dart';
import 'package:silence_app/studio/watch_face.dart';

void main() {
  final template = File(
    'assets/templates/pulse2_template.watch',
  ).readAsBytesSync();

  test('Template reports the recovered image sizes', () {
    expect(watchImageSize(template, preview: false), (width: 240, height: 280));
    expect(watchImageSize(template, preview: true), (width: 184, height: 210));
  });

  test(
    'Builder swaps the two raw images, keeps length and repoints the background',
    () {
      final bg = Uint8List(240 * 280 * 2)..fillRange(0, 240 * 280 * 2, 0xAB);
      final pv = Uint8List(184 * 210 * 2)..fillRange(0, 184 * 210 * 2, 0xCD);
      final out = buildWatchFace(
        template: template,
        background: bg,
        preview: pv,
      );
      expect(out.length, template.length);
      final dataStart = 4 + 1688;
      expect(out.sublist(dataStart + 8, dataStart + 8 + 4), [
        0xAB,
        0xAB,
        0xAB,
        0xAB,
      ]);
      expect(out[dataStart + 134408], 0xCD);
      // Encoded images and the header stay untouched.
      expect(out.sublist(0, 28), template.sublist(0, 28));
      expect(
        out.sublist(dataStart + 211688),
        template.sublist(dataStart + 211688),
      );
      final json = String.fromCharCodes(out.sublist(28, 28 + 844));
      expect(RegExp(r'"image":\s*\{[^}]*"id":\s+0').hasMatch(json), isTrue);
      expect(RegExp(r'"id1":\s*1').hasMatch(json), isTrue);
    },
  );

  test('Wrong-size images and foreign files are rejected', () {
    expect(
      () => buildWatchFace(
        template: template,
        background: Uint8List(10),
        preview: Uint8List(10),
      ),
      throwsA(isA<WatchFaceException>()),
    );
    expect(
      () => buildWatchFace(
        template: Uint8List(64),
        background: Uint8List(0),
        preview: Uint8List(0),
      ),
      throwsA(isA<WatchFaceException>()),
    );
  });

  test('RGB565 conversion is big-endian', () {
    expect(rgbaToRgb565Be(Uint8List.fromList([255, 0, 0, 255])), [0xF8, 0x00]);
    expect(rgbaToRgb565Be(Uint8List.fromList([0, 255, 0, 255])), [0x07, 0xE0]);
    expect(rgbaToRgb565Be(Uint8List.fromList([0, 0, 255, 255])), [0x00, 0x1F]);
  });

  testWidgets('Artwork renders raw RGBA at the requested size', (tester) async {
    final art = ArtworkController();
    addTearDown(art.dispose);
    final rgba = (await tester.runAsync(() => art.exportRgba(184, 210)))!;
    expect(rgba.length, 184 * 210 * 4);
  });
}
