/// Studio: design a watch background and clock, then send it to the watch.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../controller/silence_controller.dart';
import '../studio/clock_style.dart';
import '../studio/digital_face.dart';
import '../studio/watch_face.dart';
import '../studio/artwork.dart';
import 'color_picker.dart';
import 'notification_demo.dart';
import 'quick_reply_card.dart';
import 'relay_card.dart';
import 'weather_card.dart';
import 'silence_theme.dart';
import 'watch_card.dart';
import 'widgets.dart';

Future<Uint8List> _loadBundledTemplate() async => (await rootBundle.load(
  'assets/templates/pulse2_template.watch',
)).buffer.asUint8List();

typedef PhotoPicker = Future<Uint8List?> Function();

Future<Uint8List?> pickPhotoFromGallery() async {
  final file = await ImagePicker().pickImage(source: ImageSource.gallery);
  return file?.readAsBytes();
}

class StudioPage extends StatefulWidget {
  const StudioPage({
    super.key,
    required this.artwork,
    required this.controller,
    this.pickPhoto = pickPhotoFromGallery,
    this.loadTemplate = _loadBundledTemplate,
  });
  final SilenceController controller;
  final Future<Uint8List> Function() loadTemplate;
  final ArtworkController artwork;
  final PhotoPicker pickPhoto;

  @override
  State<StudioPage> createState() => _StudioPageState();
}

class _StudioPageState extends State<StudioPage> {
  bool _working = false;
  String? _message;

  ArtworkController get art => widget.artwork;

  Future<void> _run(Future<void> Function() action) async {
    if (_working) return;
    setState(() {
      _working = true;
      _message = null;
    });
    try {
      await action();
    } on PlatformException catch (e) {
      _message = e.message ?? e.code;
    } catch (e) {
      _message = '$e';
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _choosePhoto() => _run(() async {
    final bytes = await widget.pickPhoto();
    if (bytes != null) {
      await art.setPhotoBytes(bytes);
    }
  });

  Future<void> _sendToWatch() => _run(() async {
    final clock = art.clock;
    final Uint8List file;
    if (clock != null) {
      file = await buildDigitalFace(art, clock);
    } else {
      final template = await widget.loadTemplate();
      final bg = watchImageSize(template, preview: false);
      final pv = watchImageSize(template, preview: true);
      file = buildWatchFace(
        template: template,
        background: rgbaToRgb565Be(await art.exportRgba(bg.width, bg.height)),
        preview: rgbaToRgb565Be(await art.exportRgba(pv.width, pv.height)),
      );
    }
    await widget.controller.sendWatchFace(file);
  });

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: art,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SilenceEyebrow('WATCH BACKGROUND'),
        const SizedBox(height: 12),
        Text(
          'Make it yours.\nSend it straight over.',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 15),
        const Text(
          'Design a background and clock for your Pulse 2, then send it to the watch.',
          style: TextStyle(color: SilenceColors.muted, height: 1.6),
        ),
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 640;
            final preview = _Preview(art: art);
            final controls = _Controls(
              art: art,
              working: _working,
              onChoosePhoto: _choosePhoto,
            );
            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      preview,
                      const SizedBox(width: 28),
                      Expanded(child: controls),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: preview),
                      const SizedBox(height: 24),
                      controls,
                    ],
                  );
          },
        ),
        const SizedBox(height: 30),
        _WatchUploadPanel(
          controller: widget.controller,
          working: _working,
          onSend: _sendToWatch,
        ),
        const SizedBox(height: 30),
        const SilenceSectionTitle('Phone notifications'),
        const SizedBox(height: 13),
        RelayCard(controller: widget.controller),
        const SizedBox(height: 14),
        QuickReplyCard(controller: widget.controller),
        const SizedBox(height: 30),
        const SilenceSectionTitle('Weather'),
        const SizedBox(height: 13),
        WeatherCard(controller: widget.controller),
        if (widget.controller.developerMode) ...[
          const SizedBox(height: 30),
          NotificationDemoPanel(controller: widget.controller),
        ],
        if (_message != null) ...[
          const SizedBox(height: 16),
          Text(
            _message!,
            style: const TextStyle(
              fontSize: 12,
              height: 1.6,
              color: Colors.redAccent,
            ),
          ),
        ],
      ],
    ),
  );
}

class _Preview extends StatelessWidget {
  const _Preview({required this.art});
  final ArtworkController art;
  static const _width = 220.0;

  @override
  Widget build(BuildContext context) {
    const height = _width * 280 / 240;
    return Semantics(
      label: 'Watch background preview',
      image: true,
      child: GestureDetector(
        onPanUpdate: (d) => art.pan(d.delta * (240 / _width)),
        child: Container(
          width: _width + 12,
          height: height + 12,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF090B09),
            borderRadius: BorderRadius.circular(52),
            border: Border.all(color: const Color(0xFF46503C), width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(44),
            child: CustomPaint(
              painter: ArtworkPainter(art, decorate: true, sample: true),
            ),
          ),
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.art,
    required this.working,
    required this.onChoosePhoto,
  });
  final ArtworkController art;
  final bool working;
  final VoidCallback onChoosePhoto;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SilenceEyebrow('CLOCK'),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ChoiceChip(
            label: const Text('Analog'),
            selected: art.clock == null,
            onSelected: (_) => art.setClock(null),
          ),
          for (final style in clockStyles)
            ChoiceChip(
              label: Text(style.name),
              selected: art.clock?.id == style.id,
              onSelected: (_) => art.setClock(style),
            ),
        ],
      ),
      if (art.clock != null) ...[
        const SizedBox(height: 22),
        _ColorRow(
          label: 'HOURS',
          color: art.hoursColor,
          onChanged: (c) => art.setClockColors(hours: c),
        ),
        const SizedBox(height: 18),
        _ColorRow(
          label: 'MINUTES',
          color: art.minutesColor,
          onChanged: (c) => art.setClockColors(minutes: c),
        ),
      ],
      const SizedBox(height: 22),
      const SilenceEyebrow('BACKGROUND'),
      const SizedBox(height: 12),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (var i = 0; i < artworkPresets.length; i++)
            Tooltip(
              message: artworkPresets[i].name,
              child: InkResponse(
                onTap: () {
                  if (art.photo != null) art.clearPhoto();
                  art.selectPreset(i);
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: artworkPresets[i].colors,
                    ),
                    border: Border.all(
                      color: art.photo == null && art.presetIndex == i
                          ? SilenceColors.accent
                          : SilenceColors.line,
                      width: art.photo == null && art.presetIndex == i ? 2 : 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      if (art.photo == null) ...[
        const SizedBox(height: 22),
        _ColorRow(
          label: 'GRADIENT START',
          color: art.gradientStart,
          palette: gradientPalette,
          onChanged: (c) => art.setGradient(start: c),
        ),
        const SizedBox(height: 18),
        _ColorRow(
          label: 'GRADIENT END',
          color: art.gradientEnd,
          palette: gradientPalette,
          onChanged: (c) => art.setGradient(end: c),
        ),
        const SizedBox(height: 12),
        _SliderRow(
          label: 'Angle',
          value: art.gradientAngle.clamp(0, 360).toDouble(),
          min: 0,
          max: 360,
          onChanged: (v) => art.setGradient(angle: v.roundToDouble()),
        ),
        Row(
          children: [
            Text(
              '${art.gradientAngle.round()}\u00b0',
              style: const TextStyle(fontSize: 12, color: SilenceColors.muted),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: art.swapGradientColors,
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: const Text('Swap colors'),
            ),
          ],
        ),
      ],
      const SizedBox(height: 22),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          OutlinedButton.icon(
            onPressed: working ? null : onChoosePhoto,
            icon: const Icon(Icons.photo_outlined, size: 18),
            label: Text(art.photo == null ? 'Use a photo' : 'Change photo'),
          ),
          if (art.photo != null)
            TextButton(
              onPressed: art.clearPhoto,
              child: const Text('Remove photo'),
            ),
        ],
      ),
      if (art.photo != null) ...[
        const SizedBox(height: 14),
        _SliderRow(
          label: 'Zoom',
          value: art.zoom,
          min: 1,
          max: 4,
          onChanged: art.setZoom,
        ),
        const Text(
          'Drag the preview to reposition.',
          style: TextStyle(fontSize: 12, color: SilenceColors.muted),
        ),
      ],
      const SizedBox(height: 14),
      _SliderRow(
        label: 'Dim',
        value: art.dim,
        min: 0,
        max: 0.7,
        onChanged: art.setDim,
      ),
    ],
  );
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });
  final String label;
  final double value, min, max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 52,
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, color: SilenceColors.muted),
        ),
      ),
      Expanded(
        child: Slider(
          value: value.clamp(min, max).toDouble(),
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ),
    ],
  );
}

class _WatchUploadPanel extends StatelessWidget {
  const _WatchUploadPanel({
    required this.controller,
    required this.working,
    required this.onSend,
  });
  final SilenceController controller;
  final bool working;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final ready = controller.canUpload && !working;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SilenceSectionTitle('Send to your watch'),
          const SizedBox(height: 13),
          WatchCard(controller: controller),
          const SizedBox(height: 14),
          SilencePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sending replaces the watch face. Analog keeps the template\u2019s hands, date and weekday. Stack and Row draw a digital clock and the date, with the time shown in the preview as a sample.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: SilenceColors.muted,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: ready ? onSend : null,
                  icon: controller.uploading
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.watch_outlined, size: 18),
                  label: Text(
                    controller.uploading ? 'Sending…' : 'Send to watch',
                  ),
                ),
                if (controller.uploading) ...[
                  const SizedBox(height: 14),
                  LinearProgressIndicator(
                    value: controller.uploadPercent / 100,
                  ),
                ],
                if (controller.uploadStatus != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    '${controller.uploadStatus}'
                    '${controller.uploading ? ' ${controller.uploadPercent}%' : ''}',
                    style: TextStyle(
                      fontSize: 13,
                      color: controller.uploadSuccess == false
                          ? Colors.redAccent
                          : SilenceColors.ink,
                    ),
                  ),
                ],
                if (controller.uploadSuccess == true) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: controller.applyWatchFace,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Set as current face'),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    },
  );
}

/// Preset swatches plus a custom color (picker and hex entry).
class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.label,
    required this.color,
    required this.onChanged,
    this.palette = clockPalette,
  });
  final String label;
  final Color color;
  final ValueChanged<Color> onChanged;
  final List<(String, Color)> palette;

  @override
  Widget build(BuildContext context) {
    final preset = palette.any((p) => p.$2 == color);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: SilenceEyebrow(label)),
            Text(
              colorToHex(color),
              style: const TextStyle(fontSize: 11, color: SilenceColors.muted),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (name, value) in palette)
              Tooltip(
                message: name,
                child: InkResponse(
                  onTap: () => onChanged(value),
                  child: _swatch(value, selected: value == color),
                ),
              ),
            Tooltip(
              message: 'Custom color',
              child: InkResponse(
                onTap: () async {
                  final picked = await showColorPicker(
                    context,
                    initial: color,
                    title:
                        '${label[0]}${label.substring(1).toLowerCase()} color',
                  );
                  if (picked != null) onChanged(picked);
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const SweepGradient(
                      colors: [
                        Colors.red,
                        Colors.yellow,
                        Colors.green,
                        Colors.cyan,
                        Colors.blue,
                        Colors.purple,
                        Colors.red,
                      ],
                    ),
                    border: Border.all(
                      color: !preset ? SilenceColors.ink : SilenceColors.line,
                      width: !preset ? 2 : 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.colorize,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _swatch(Color value, {required bool selected}) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: value,
      shape: BoxShape.circle,
      border: Border.all(
        color: selected ? SilenceColors.ink : SilenceColors.line,
        width: selected ? 2.5 : 1,
      ),
    ),
  );
}
