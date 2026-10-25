/// Background artwork model, painter and raw pixel export for watch faces.
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'clock_style.dart';

/// Logical canvas matching the Pulse 2 display aspect ratio.
const artworkCanvas = Size(240, 280);

@immutable
class ArtworkPreset {
  const ArtworkPreset(this.name, this.colors);
  final String name;
  final List<Color> colors;
}

const artworkPresets = [
  ArtworkPreset('Moss', [Color(0xFF283923), Color(0xFF11190F)]),
  ArtworkPreset('Forest', [Color(0xFF1F4D36), Color(0xFF07140D)]),
  ArtworkPreset('Tide', [Color(0xFF1E4A55), Color(0xFF07161A)]),
  ArtworkPreset('Ocean', [Color(0xFF1B3F7A), Color(0xFF060B1C)]),
  ArtworkPreset('Dusk', [Color(0xFF3B2F5C), Color(0xFF0E0B1A)]),
  ArtworkPreset('Plum', [Color(0xFF5A2A63), Color(0xFF14081A)]),
  ArtworkPreset('Rose', [Color(0xFF7A2C4A), Color(0xFF1A0811)]),
  ArtworkPreset('Ember', [Color(0xFF5C2B1E), Color(0xFF140A07)]),
  ArtworkPreset('Sunset', [Color(0xFFB4492F), Color(0xFF2A0F3D)]),
  ArtworkPreset('Gold', [Color(0xFF6B5320), Color(0xFF16110A)]),
  ArtworkPreset('Aurora', [Color(0xFF1F7A6B), Color(0xFF2B1B5E)]),
  ArtworkPreset('Steel', [Color(0xFF4A5560), Color(0xFF0D1014)]),
  ArtworkPreset('Graphite', [Color(0xFF3A3D40), Color(0xFF0C0D0E)]),
  ArtworkPreset('Ink', [Color(0xFF000000), Color(0xFF000000)]),
];

/// Default gradient direction: top-left to bottom-right.
const defaultGradientAngle = 45.0;

/// Gradient endpoints for [angle] degrees clockwise from left-to-right,
/// scaled so the gradient spans the canvas edge to edge.
({Alignment begin, Alignment end}) gradientAlignments(double angle) {
  final radians = angle * math.pi / 180;
  var dx = math.cos(radians);
  var dy = math.sin(radians);
  final scale = dx.abs() > dy.abs() ? dx.abs() : dy.abs();
  dx /= scale;
  dy /= scale;
  return (begin: Alignment(-dx, -dy), end: Alignment(dx, dy));
}

/// Where a cover-fitted image lands on the canvas for a given zoom/offset.
Rect coverRect(Size image, double zoom, Offset offset) {
  final base =
      artworkCanvas.width / image.width > artworkCanvas.height / image.height
      ? artworkCanvas.width / image.width
      : artworkCanvas.height / image.height;
  final size = Size(image.width * base * zoom, image.height * base * zoom);
  final maxX = (size.width - artworkCanvas.width) / 2;
  final maxY = (size.height - artworkCanvas.height) / 2;
  final clamped = Offset(
    offset.dx.clamp(-maxX, maxX).toDouble(),
    offset.dy.clamp(-maxY, maxY).toDouble(),
  );
  return Rect.fromCenter(
    center: artworkCanvas.center(Offset.zero) + clamped,
    width: size.width,
    height: size.height,
  );
}

/// Editable artwork state. Holds no watch state.
class ArtworkController extends ChangeNotifier {
  Color gradientStart = artworkPresets.first.colors.first;
  Color gradientEnd = artworkPresets.first.colors.last;
  double gradientAngle = defaultGradientAngle;
  ui.Image? photo;
  double zoom = 1;
  Offset offset = Offset.zero;
  double dim = 0.2;

  /// Digital clock layout, or null for the analog template face.
  ClockStyle? clock;
  Color hoursColor = clockInk;
  Color minutesColor = clockAccent;

  /// Index of the preset matching the current gradient, or -1 for a custom one.
  int get presetIndex => artworkPresets.indexWhere(
    (p) =>
        p.colors.first == gradientStart &&
        p.colors.last == gradientEnd &&
        gradientAngle == defaultGradientAngle,
  );

  void selectPreset(int index) {
    if (index < 0 || index >= artworkPresets.length) return;
    gradientStart = artworkPresets[index].colors.first;
    gradientEnd = artworkPresets[index].colors.last;
    gradientAngle = defaultGradientAngle;
    notifyListeners();
  }

  /// Sets any of the gradient's colors or angle; clears a photo background.
  void setGradient({Color? start, Color? end, double? angle}) {
    photo?.dispose();
    photo = null;
    gradientStart = start ?? gradientStart;
    gradientEnd = end ?? gradientEnd;
    gradientAngle = ((angle ?? gradientAngle) % 360 + 360) % 360;
    notifyListeners();
  }

  void swapGradientColors() =>
      setGradient(start: gradientEnd, end: gradientStart);

  /// Decodes [bytes] and uses the result as the background.
  Future<void> setPhotoBytes(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    photo?.dispose();
    photo = frame.image;
    zoom = 1;
    offset = Offset.zero;
    notifyListeners();
  }

  void clearPhoto() {
    photo?.dispose();
    photo = null;
    notifyListeners();
  }

  void setZoom(double value) {
    zoom = value.clamp(1, 4).toDouble();
    _clampOffset();
    notifyListeners();
  }

  /// Moves the photo by [delta] in canvas units.
  void pan(Offset delta) {
    if (photo == null) return;
    offset += delta;
    _clampOffset();
    notifyListeners();
  }

  void setClock(ClockStyle? value) {
    clock = value?.withColors(hoursColor, minutesColor);
    notifyListeners();
  }

  void setClockColors({Color? hours, Color? minutes}) {
    hoursColor = hours ?? hoursColor;
    minutesColor = minutes ?? minutesColor;
    clock = clock?.withColors(hoursColor, minutesColor);
    notifyListeners();
  }

  void setDim(double value) {
    dim = value.clamp(0, 0.7).toDouble();
    notifyListeners();
  }

  void _clampOffset() {
    final image = photo;
    if (image == null) return;
    final rect = coverRect(
      Size(image.width.toDouble(), image.height.toDouble()),
      zoom,
      offset,
    );
    offset = rect.center - artworkCanvas.center(Offset.zero);
  }

  /// Renders the artwork stretched to [width] x [height] as raw RGBA bytes.
  ///
  /// With a [clock] style, [decorate] bakes in its static artwork and [sample]
  /// adds a sample time (for previews).
  Future<Uint8List> exportRgba(
    int width,
    int height, {
    bool decorate = false,
    bool sample = false,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    ArtworkPainter(
      this,
      decorate: decorate,
      sample: sample,
    ).paint(canvas, Size(width.toDouble(), height.toDouble()));
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    picture.dispose();
    return data!.buffer.asUint8List();
  }

  /// Renders the decorated background (no clock digits) as an image.
  Future<ui.Image> renderBackground(int width, int height) async {
    final recorder = ui.PictureRecorder();
    ArtworkPainter(
      this,
      decorate: true,
    ).paint(Canvas(recorder), Size(width.toDouble(), height.toDouble()));
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    picture.dispose();
    return image;
  }

  @override
  void dispose() {
    photo?.dispose();
    super.dispose();
  }
}

/// Paints the artwork background only: no time, date or other live widgets.
class ArtworkPainter extends CustomPainter {
  ArtworkPainter(this.art, {this.decorate = false, this.sample = false})
    : super(repaint: art);
  final ArtworkController art;

  /// Paint the clock style's static artwork (needs [ArtworkController.clock]).
  final bool decorate;

  /// Paint a sample time over the artwork.
  final bool sample;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(
      size.width / artworkCanvas.width,
      size.height / artworkCanvas.height,
    );
    const full = Rect.fromLTWH(0, 0, 240, 280);
    canvas.clipRect(full);
    final image = art.photo;
    if (image != null) {
      final src = Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      );
      canvas.drawImageRect(
        image,
        src,
        coverRect(src.size, art.zoom, art.offset),
        Paint()..filterQuality = FilterQuality.high,
      );
    } else {
      final align = gradientAlignments(art.gradientAngle);
      canvas.drawRect(
        full,
        Paint()
          ..shader = LinearGradient(
            begin: align.begin,
            end: align.end,
            colors: [art.gradientStart, art.gradientEnd],
          ).createShader(full),
      );
    }
    if (art.dim > 0) {
      canvas.drawRect(
        full,
        Paint()..color = Colors.black.withValues(alpha: art.dim),
      );
    }
    final clock = art.clock;
    if (clock != null) {
      if (decorate || sample) clock.decorate(canvas, clock.accent);
      if (sample) paintSampleClock(canvas, clock);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ArtworkPainter oldDelegate) =>
      oldDelegate.art != art ||
      oldDelegate.decorate != decorate ||
      oldDelegate.sample != sample;
}
