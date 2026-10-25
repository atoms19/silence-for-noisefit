import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silence_app/studio/artwork.dart';
import 'package:silence_app/studio/clock_style.dart';
import 'package:silence_app/ui/color_picker.dart';
import 'package:silence_app/ui/silence_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('SilenceSans')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Roboto-Regular.ttf').readAsBytesSync(),
          ),
        ),
      );
    await loader.load();
  });

  test('Hex parsing accepts 6 digits with or without #', () {
    expect(parseHexColor('#FF8A75'), const Color(0xFFFF8A75));
    expect(parseHexColor('ff8a75'), const Color(0xFFFF8A75));
    expect(parseHexColor(' 00ff00 '), const Color(0xFF00FF00));
    expect(parseHexColor('fff'), isNull);
    expect(parseHexColor('GGGGGG'), isNull);
    expect(colorToHex(const Color(0xFF0A0B0C)), '#0A0B0C');
  });

  test('Clock colors carry across style changes', () {
    final art = ArtworkController()..setClock(clockStyles.first);
    addTearDown(art.dispose);
    art.setClockColors(
      hours: const Color(0xFF112233),
      minutes: const Color(0xFFFF0000),
    );
    expect(art.clock!.colors, [
      const Color(0xFF112233),
      const Color(0xFF112233),
      const Color(0xFFFF0000),
      const Color(0xFFFF0000),
    ]);
    art.setClock(clockStyles.last);
    expect(art.clock!.id, clockStyles.last.id);
    expect(art.clock!.accent, const Color(0xFFFF0000));
  });

  testWidgets('Baked minute digits use the chosen color', (tester) async {
    final art = ArtworkController()..setClock(clockStyles.first);
    addTearDown(art.dispose);
    art.setClockColors(minutes: const Color(0xFFFF0000));
    final background = (await tester.runAsync(
      () => art.renderBackground(240, 280),
    ))!;
    final rgba = (await tester.runAsync(
      () => renderBakedDigit(background, art.clock!, 2, '8'),
    ))!;
    var red = 0;
    for (var i = 0; i < rgba.length; i += 4) {
      if (rgba[i] > 200 && rgba[i + 1] < 60 && rgba[i + 2] < 60) red++;
    }
    expect(red, greaterThan(100));
    background.dispose();
  });

  testWidgets('Picker returns a typed hex color and rejects bad input', (
    tester,
  ) async {
    Color? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildSilenceTheme(),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showColorPicker(
              context,
              initial: const Color(0xFFD0F58B),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(find.text('Use 6 hex digits'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.enterText(find.byType(TextField), '#3366FF');
    await tester.pump();
    await tester.tap(find.text('Use color'));
    await tester.pumpAndSettle();
    expect(result, const Color(0xFF3366FF));
    expect(tester.takeException(), isNull);
  });

  test('Gradient angle maps to edge-to-edge alignments', () {
    final diagonal = gradientAlignments(45);
    expect(diagonal.begin.x, closeTo(-1, 1e-9));
    expect(diagonal.begin.y, closeTo(-1, 1e-9));
    expect(diagonal.end.x, closeTo(1, 1e-9));
    final down = gradientAlignments(90);
    expect(down.begin.y, closeTo(-1, 1e-9));
    expect(down.begin.x, closeTo(0, 1e-9));
    expect(down.end.y, closeTo(1, 1e-9));
  });

  test('Custom gradients track presets, swap and wrap angles', () {
    final art = ArtworkController();
    addTearDown(art.dispose);
    expect(art.presetIndex, 0);
    art.setGradient(start: const Color(0xFF123456));
    expect(art.presetIndex, -1);
    art.selectPreset(3);
    expect(art.presetIndex, 3);
    final start = art.gradientStart;
    final end = art.gradientEnd;
    art.swapGradientColors();
    expect((art.gradientStart, art.gradientEnd), (end, start));
    art.setGradient(angle: 450);
    expect(art.gradientAngle, 90);
    art.setGradient(angle: -90);
    expect(art.gradientAngle, 270);
  });

  testWidgets('Gradient colors and angle reach the exported pixels', (
    tester,
  ) async {
    final art = ArtworkController();
    addTearDown(art.dispose);
    art.setGradient(
      start: const Color(0xFFFF0000),
      end: const Color(0xFF0000FF),
      angle: 0,
    );
    art.setDim(0);
    final rgba = (await tester.runAsync(() => art.exportRgba(240, 280)))!;
    int px(int x, int y) => (y * 240 + x) * 4;
    expect(rgba[px(1, 140)], greaterThan(240));
    expect(rgba[px(1, 140) + 2], lessThan(20));
    expect(rgba[px(238, 140)], lessThan(20));
    expect(rgba[px(238, 140) + 2], greaterThan(240));
  });
}
