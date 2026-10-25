/// Generates a digital-clock `.watch` face from artwork and a [ClockStyle].
library;

import 'dart:convert';
import 'dart:typed_data';

import 'artwork.dart';
import 'clock_style.dart';
import 'watch_face.dart';

const _previewWidth = 184;
const _previewHeight = 210;
const _firstDigitId = 2;

/// Image id of the first digit (0) in [slot]'s ten-image set.
int digitSetStart(int slot) => _firstDigitId + slot * 10;

/// The face description the firmware parses. Key names come from the parser's
/// string table; their meaning (one 0-9 set per digit slot) is inferred.
Map<String, Object?> digitalFaceJson(ClockStyle style) {
  Map<String, int> pos(int slot) => {
    'x': style.positions[slot].dx.round(),
    'y': style.positions[slot].dy.round(),
  };
  final date = style.date;
  return {
    'HEAD': {
      'WATCH_NUM': {'num': 10},
      'PREVIEW_NUM': {'num': 1},
    },
    'WATCH': {
      'image': {'visible': 1, 'x': 0, 'y': 0, 'id': 0},
      'multiple_image_clock': {
        'visible': 1,
        'x_hour_s': pos(0)['x'],
        'y_hour_s': pos(0)['y'],
        'x_hour_g': pos(1)['x'],
        'y_hour_g': pos(1)['y'],
        'x_min_s': pos(2)['x'],
        'y_min_s': pos(2)['y'],
        'x_min_g': pos(3)['x'],
        'y_min_g': pos(3)['y'],
        'id1_start_time': digitSetStart(0),
        'id2_start_time': digitSetStart(1),
        'id3_start_time': digitSetStart(2),
        'id4_start_time': digitSetStart(3),
        'use_sec': 0,
      },
      'text_date': {
        'visible': 1,
        'text_id': 16,
        'x': date.x,
        'y': date.y,
        'w': date.width,
        'h': date.height,
        'align': date.align,
        'x_spacing': 1,
        'color_r': (date.color.r * 255).round(),
        'color_g': (date.color.g * 255).round(),
        'color_b': (date.color.b * 255).round(),
      },
    },
    'PREVIEW': {
      'image': {'id1': 1, 'id2': 1},
    },
  };
}

/// Builds the face file: the artwork with the style's decorations as the
/// background, a sample-time preview, and forty digit images baked over the
/// artwork so no transparency is needed.
Future<Uint8List> buildDigitalFace(
  ArtworkController art,
  ClockStyle style,
) async {
  final saved = art.clock;
  art.clock = style;
  try {
    final background = await art.renderBackground(240, 280);
    try {
      final bgBytes = (await background.toByteData())!.buffer.asUint8List();
      final images = <WatchImage>[
        WatchImage(0, 240, 280, rgbaToRgb565Be(bgBytes)),
        WatchImage(
          1,
          _previewWidth,
          _previewHeight,
          rgbaToRgb565Be(
            await art.exportRgba(
              _previewWidth,
              _previewHeight,
              decorate: true,
              sample: true,
            ),
          ),
        ),
      ];
      for (var slot = 0; slot < 4; slot++) {
        for (var digit = 0; digit < 10; digit++) {
          images.add(
            WatchImage(
              digitSetStart(slot) + digit,
              style.digitWidth,
              style.digitHeight,
              rgbaToRgb565Be(
                await renderBakedDigit(background, style, slot, '$digit'),
              ),
            ),
          );
        }
      }
      final json = const JsonEncoder.withIndent(
        '\t',
      ).convert(digitalFaceJson(style));
      return buildWatchContainer(json: json, images: images);
    } finally {
      background.dispose();
    }
  } finally {
    art.clock = saved;
  }
}
