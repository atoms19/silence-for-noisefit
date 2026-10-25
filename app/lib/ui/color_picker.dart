/// Color presets, hex parsing and a compact HSV picker dialog.
library;

import 'package:flutter/material.dart';

import 'silence_theme.dart';

const clockPalette = <(String, Color)>[
  ('Lime', Color(0xFFD0F58B)),
  ('Mint', Color(0xFF7FF0C0)),
  ('Sky', Color(0xFF8AD4FF)),
  ('Blue', Color(0xFF7C9CFF)),
  ('Violet', Color(0xFFC3A6FF)),
  ('Pink', Color(0xFFFF9EC7)),
  ('Coral', Color(0xFFFF8A75)),
  ('Amber', Color(0xFFFFC857)),
  ('White', Color(0xFFF3F1E9)),
  ('Silver', Color(0xFFA5AD9C)),
];

/// Swatches for gradient endpoints, from near-black through vivid.
const gradientPalette = <(String, Color)>[
  ('Black', Color(0xFF000000)),
  ('Charcoal', Color(0xFF14161A)),
  ('Navy', Color(0xFF0B1B3A)),
  ('Forest', Color(0xFF0F2A1C)),
  ('Plum', Color(0xFF2A1238)),
  ('Burgundy', Color(0xFF3A0F1C)),
  ('Teal', Color(0xFF14605A)),
  ('Blue', Color(0xFF2F5BD8)),
  ('Violet', Color(0xFF6C47D9)),
  ('Magenta', Color(0xFFC03A8C)),
  ('Orange', Color(0xFFE2692F)),
  ('Gold', Color(0xFFE2B33B)),
  ('Lime', Color(0xFF9CD13B)),
  ('White', Color(0xFFF3F1E9)),
];

/// Parses `RRGGBB` or `#RRGGBB`; returns null when invalid.
Color? parseHexColor(String text) {
  final hex = text.trim().replaceFirst('#', '');
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) return null;
  return Color(0xFF000000 | int.parse(hex, radix: 16));
}

String colorToHex(Color color) =>
    '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// Shows the picker; returns the chosen color or null if cancelled.
Future<Color?> showColorPicker(
  BuildContext context, {
  required Color initial,
  String title = 'Pick a color',
}) => showDialog<Color>(
  context: context,
  builder: (context) => _PickerDialog(initial: initial, title: title),
);

class _PickerDialog extends StatefulWidget {
  const _PickerDialog({required this.initial, required this.title});
  final Color initial;
  final String title;

  @override
  State<_PickerDialog> createState() => _PickerDialogState();
}

class _PickerDialogState extends State<_PickerDialog> {
  late HSVColor _hsv = HSVColor.fromColor(widget.initial);
  late final TextEditingController _hex = TextEditingController(
    text: colorToHex(widget.initial),
  );
  bool _invalid = false;

  void _set(HSVColor value) {
    setState(() {
      _hsv = value;
      _invalid = false;
      _hex.text = colorToHex(value.toColor());
    });
  }

  void _typed(String text) {
    final color = parseHexColor(text);
    setState(() {
      _invalid = color == null && text.isNotEmpty;
      if (color != null) _hsv = HSVColor.fromColor(color);
    });
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SingleChildScrollView(
      child: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 170,
              child: LayoutBuilder(
                builder: (context, box) {
                  void pick(Offset p) => _set(
                    _hsv
                        .withSaturation((p.dx / box.maxWidth).clamp(0, 1))
                        .withValue(1 - (p.dy / box.maxHeight).clamp(0, 1)),
                  );
                  return GestureDetector(
                    onPanDown: (d) => pick(d.localPosition),
                    onPanUpdate: (d) => pick(d.localPosition),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white,
                                    HSVColor.fromAHSV(
                                      1,
                                      _hsv.hue,
                                      1,
                                      1,
                                    ).toColor(),
                                  ],
                                ),
                              ),
                              child: const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.transparent, Colors.black],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: _hsv.saturation * box.maxWidth - 9,
                          top: (1 - _hsv.value) * box.maxHeight - 9,
                          child: IgnorePointer(
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black54,
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 12,
                trackShape: const _HueTrack(),
                thumbColor: HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor(),
              ),
              child: Slider(
                value: _hsv.hue,
                min: 0,
                max: 359.9,
                onChanged: (v) => _set(_hsv.withHue(v)),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _hsv.toColor(),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SilenceColors.line),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _hex,
                    onChanged: _typed,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Hex',
                      errorText: _invalid ? 'Use 6 hex digits' : null,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _invalid
            ? null
            : () => Navigator.pop(context, _hsv.toColor()),
        child: const Text('Use color'),
      ),
    ],
  );
}

class _HueTrack extends SliderTrackShape {
  const _HueTrack();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final height = sliderTheme.trackHeight ?? 12;
    return Rect.fromLTWH(
      offset.dx + 12,
      offset.dy + (parentBox.size.height - height) / 2,
      parentBox.size.width - 24,
      height,
    );
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
    );
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          for (var h = 0; h <= 360; h += 60)
            HSVColor.fromAHSV(1, h.toDouble() % 360, 1, 1).toColor(),
        ],
      ).createShader(rect);
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      paint,
    );
  }
}
