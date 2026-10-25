/// Digital clock layouts for generated watch faces.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// One digit position: hours tens/units, then minutes tens/units.
enum ClockSlot { hourTens, hourUnits, minuteTens, minuteUnits }

@immutable
class ClockStyle {
  const ClockStyle({
    required this.id,
    required this.name,
    required this.digitWidth,
    required this.digitHeight,
    required this.positions,
    this.hours = clockInk,
    this.accent = clockAccent,
    required this.fontSize,
    required this.fontWeight,
    required this.date,
    required this.decorate,
  });

  final String id;
  final String name;
  final int digitWidth;
  final int digitHeight;

  /// Top-left corner of each digit in 240x280 canvas coordinates.
  final List<Offset> positions;

  /// Hour digit color and minute digit color (also used for decorations).
  final Color hours;
  final Color accent;
  List<Color> get colors => [hours, hours, accent, accent];

  ClockStyle withColors(Color hours, Color accent) => ClockStyle(
    id: id,
    name: name,
    digitWidth: digitWidth,
    digitHeight: digitHeight,
    positions: positions,
    hours: hours,
    accent: accent,
    fontSize: fontSize,
    fontWeight: fontWeight,
    date: date,
    decorate: decorate,
  );
  final double fontSize;
  final FontWeight fontWeight;

  /// Firmware-drawn date text.
  final ClockDate date;

  /// Static artwork baked into the background (colons, accents, tags).
  final void Function(Canvas canvas, Color accent) decorate;
}

@immutable
class ClockDate {
  const ClockDate({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.align,
    required this.color,
  });
  final int x, y, width, height, align;
  final Color color;
}

const clockInk = Color(0xFFF3F1E9);
const clockAccent = Color(0xFFD0F58B);
const _muted = Color(0xFFA5AD9C);

void _tag(Canvas canvas, Offset at, String text) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: const TextStyle(
        fontFamily: 'SilenceSans',
        fontSize: 10,
        letterSpacing: 2.5,
        color: _muted,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(canvas, at);
}

void _colon(Canvas canvas, Offset center, double gap, Color color) {
  final paint = Paint()..color = color;
  canvas.drawCircle(center - Offset(0, gap), 4, paint);
  canvas.drawCircle(center + Offset(0, gap), 4, paint);
}

final clockStyles = <ClockStyle>[
  ClockStyle(
    id: 'stack',
    name: 'Stack',
    digitWidth: 58,
    digitHeight: 92,
    positions: const [
      Offset(20, 52),
      Offset(80, 52),
      Offset(20, 148),
      Offset(80, 148),
    ],
    fontSize: 88,
    fontWeight: FontWeight.w400,
    date: const ClockDate(
      x: 20,
      y: 24,
      width: 200,
      height: 22,
      align: 0,
      color: _muted,
    ),
    decorate: (canvas, accent) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(24, 252, 25, 3),
          const Radius.circular(2),
        ),
        Paint()..color = accent,
      );
      _tag(canvas, const Offset(60, 246), 'SILENCE');
    },
  ),
  ClockStyle(
    id: 'row',
    name: 'Row',
    digitWidth: 50,
    digitHeight: 84,
    positions: const [
      Offset(14, 98),
      Offset(66, 98),
      Offset(126, 98),
      Offset(178, 98),
    ],
    fontSize: 80,
    fontWeight: FontWeight.w400,
    date: const ClockDate(
      x: 0,
      y: 62,
      width: 240,
      height: 22,
      align: 2,
      color: _muted,
    ),
    decorate: (canvas, accent) {
      _colon(canvas, const Offset(120, 140), 14, accent);
      _tag(canvas, const Offset(88, 214), 'SILENCE');
    },
  ),
];

/// Paints digit [char] for [slotIndex] onto a [style.digitWidth] x [style.digitHeight] canvas.
void paintDigit(Canvas canvas, ClockStyle style, int slotIndex, String char) {
  final painter = TextPainter(
    text: TextSpan(
      text: char,
      style: TextStyle(
        fontFamily: 'SilenceSans',
        fontSize: style.fontSize,
        fontWeight: style.fontWeight,
        color: style.colors[slotIndex],
        height: 1,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(
    canvas,
    Offset(
      (style.digitWidth - painter.width) / 2,
      (style.digitHeight - painter.height) / 2,
    ),
  );
}

/// Paints a sample time over the artwork so previews match the baked digits.
void paintSampleClock(Canvas canvas, ClockStyle style) {
  const sample = ['0', '8', '2', '4'];
  for (var i = 0; i < 4; i++) {
    canvas.save();
    canvas.translate(style.positions[i].dx, style.positions[i].dy);
    paintDigit(canvas, style, i, sample[i]);
    canvas.restore();
  }
  final date =
      TextPainter(
        text: TextSpan(
          text: 'FRI, OCT 23',
          style: TextStyle(
            fontFamily: 'SilenceSans',
            fontSize: 12,
            color: style.date.color,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: style.date.align == 2 ? TextAlign.center : TextAlign.left,
      )..layout(
        minWidth: style.date.width.toDouble(),
        maxWidth: style.date.width.toDouble(),
      );
  date.paint(canvas, Offset(style.date.x.toDouble(), style.date.y.toDouble()));
}

/// Renders digit [char] over the matching region of [background] as raw RGBA.
Future<Uint8List> renderBakedDigit(
  ui.Image background,
  ClockStyle style,
  int slotIndex,
  String char,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final at = style.positions[slotIndex];
  final w = style.digitWidth.toDouble();
  final h = style.digitHeight.toDouble();
  canvas.drawImageRect(
    background,
    Rect.fromLTWH(at.dx, at.dy, w, h),
    Rect.fromLTWH(0, 0, w, h),
    Paint(),
  );
  paintDigit(canvas, style, slotIndex, char);
  final picture = recorder.endRecording();
  final image = await picture.toImage(style.digitWidth, style.digitHeight);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List();
}
