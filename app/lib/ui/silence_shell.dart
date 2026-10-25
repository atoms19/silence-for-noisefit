import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controller/silence_controller.dart';
import 'silence_theme.dart';
import '../studio/artwork.dart';
import 'notification_demo.dart';
import 'studio_page.dart';
import 'watch_card.dart';
import 'widgets.dart';

class SilenceShell extends StatelessWidget {
  const SilenceShell({
    super.key,
    required this.controller,
    required this.artwork,
    this.pickPhoto = pickPhotoFromGallery,
  });
  final SilenceController controller;
  final ArtworkController artwork;
  final PhotoPicker pickPhoto;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(controller: controller),
                  const SizedBox(height: 34),
                  if (controller.demoMode) ...[
                    SilenceNotice(
                      icon: Icons.science_outlined,
                      title: 'Design preview mode',
                      body:
                          'Devices and connection results are simulated. Your watch is not contacted.',
                      action: TextButton(
                        onPressed: () => controller.setDemoMode(false),
                        child: const Text('Exit preview'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (controller.error != null) ...[
                    SilenceNotice(
                      icon: Icons.info_outline,
                      title: 'Something needs attention',
                      body: controller.error!,
                      action: IconButton(
                        tooltip: 'Dismiss message',
                        onPressed: controller.clearError,
                        icon: const Icon(Icons.close, size: 19),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (controller.developerMode && controller.selectedTab == 0)
                    _DevicePage(controller: controller)
                  else
                    StudioPage(
                      controller: controller,
                      artwork: artwork,
                      pickPhoto: pickPhoto,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      persistentFooterButtons: controller.developerMode
          ? [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: controller.releasing
                      ? null
                      : () => _releaseWatch(context),
                  icon: const Icon(Icons.link_off),
                  label: Text(
                    controller.releasing
                        ? 'Releasing watch…'
                        : 'Unpair / release watch',
                  ),
                ),
              ),
            ]
          : null,
      bottomNavigationBar: controller.developerMode
          ? NavigationBar(
              selectedIndex: controller.selectedTab,
              onDestinationSelected: controller.selectTab,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.watch_outlined),
                  selectedIcon: Icon(Icons.watch),
                  label: 'Device',
                ),
                NavigationDestination(
                  icon: Icon(Icons.dashboard_customize_outlined),
                  selectedIcon: Icon(Icons.dashboard_customize),
                  label: 'Studio',
                ),
              ],
            )
          : null,
    ),
  );

  Future<void> _releaseWatch(BuildContext context) =>
      releaseWatchWithDialog(context, controller);
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});
  final SilenceController controller;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: SilenceColors.accent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: const Icon(
          Icons.graphic_eq_rounded,
          size: 22,
          color: SilenceColors.background,
        ),
      ),
      const SizedBox(width: 11),
      const Text(
        'silence',
        style: TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.w600,
          letterSpacing: -1,
        ),
      ),
      const Spacer(),
      if (MediaQuery.sizeOf(context).width >= 390 &&
          MediaQuery.textScalerOf(context).scale(1) <= 1.2)
        SilenceTag(
          label: controller.demoMode ? 'PREVIEW' : 'EARLY ACCESS',
          color: SilenceColors.muted,
        ),
      const SizedBox(width: 4),
      IconButton(
        tooltip: 'About Silence',
        icon: const Icon(
          Icons.info_outline,
          size: 20,
          color: SilenceColors.muted,
        ),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (context) => ListenableBuilder(
            listenable: controller,
            builder: (context, _) => AlertDialog(
              title: const Text('A quieter kind of companion.'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Silence designs watch faces for ColorFit Pulse 2 and sends them straight to the watch.\n\nHealth data, notifications and firmware updates stay with NoiseFit. Release the watch here before using NoiseFit.',
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Connect on launch'),
                      subtitle: const Text(
                        'Reconnect to your last watch when Silence opens. While connected, NoiseFit cannot reach the watch.',
                      ),
                      value: controller.autoConnect,
                      onChanged: controller.setAutoConnect,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Developer tools'),
                      subtitle: const Text(
                        'Bluetooth inspector. Connecting it can stop NoiseFit from reaching the watch.',
                      ),
                      value: controller.developerMode,
                      onChanged: controller.setDeveloperMode,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it'),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

class _DevicePage extends StatelessWidget {
  const _DevicePage({required this.controller});
  final SilenceController controller;
  @override
  Widget build(BuildContext context) {
    final connected = controller.connectedDevice;
    final compact =
        MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SilenceEyebrow('YOUR EVERYDAY, REFINED'),
        const SizedBox(height: 12),
        Text(
          connected == null
              ? compact
                    ? 'A little less.\nA little more.'
                    : 'A little less noise.\nA little more you.'
              : compact
              ? 'Connected.\nMake it yours.'
              : 'A connection.\nNew possibilities.',
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(fontSize: compact ? 28 : null),
        ),
        const SizedBox(height: 15),
        const Text(
          'A thoughtful companion for ColorFit Pulse 2.',
          style: TextStyle(color: SilenceColors.muted, height: 1.6),
        ),
        const SizedBox(height: 28),
        SilencePanel(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 430;
              final info = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SilenceTag(
                    label: connected == null
                        ? 'LET’S GET CONNECTED'
                        : 'DEVICE CONNECTED',
                  ),
                  const SizedBox(height: 18),
                  Text(
                    connected?.name.isNotEmpty == true
                        ? connected!.name
                        : 'ColorFit Pulse 2',
                    style: Theme.of(context).textTheme.headlineMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 9),
                  Text(
                    connected == null
                        ? 'Find your watch and make\nyourself at home.'
                        : controller.demoMode
                        ? 'Preview connection · simulated device'
                        : 'Bluetooth link only · NoiseFit completes pairing',
                    style: const TextStyle(
                      color: SilenceColors.muted,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (connected == null)
                    FilledButton.icon(
                      onPressed: controller.scanning || controller.busy
                          ? null
                          : controller.scan,
                      icon: controller.scanning
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.bluetooth_searching, size: 19),
                      label: Text(
                        controller.scanning
                            ? 'Finding your watch…'
                            : 'Find my watch',
                      ),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: controller.busy ? null : controller.disconnect,
                      icon: const Icon(Icons.bluetooth_disabled, size: 17),
                      label: const Text('Disconnect'),
                    ),
                ],
              );
              final watch = const Padding(
                padding: EdgeInsets.all(4),
                child: _WatchPreview(style: 0, width: 124),
              );
              return narrow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        info,
                        const SizedBox(height: 26),
                        const Center(
                          child: _WatchPreview(style: 0, width: 124),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: info),
                        watch,
                      ],
                    );
            },
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 3),
              child: Icon(
                Icons.bluetooth,
                size: 15,
                color: SilenceColors.muted,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                controller.status,
                style: const TextStyle(
                  fontSize: 12,
                  color: SilenceColors.muted,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        if (connected != null && !controller.demoMode) ...[
          _PairingPanel(controller: controller),
          const SizedBox(height: 30),
          NotificationDemoPanel(controller: controller),
          const SizedBox(height: 30),
        ],
        if (connected != null) ...[
          SilenceSectionTitle(
            'Connection details',
            trailing: TextButton.icon(
              onPressed: controller.busy ? null : controller.refreshServices,
              icon: const Icon(Icons.refresh, size: 17),
              label: const Text('Refresh'),
            ),
          ),
          const SizedBox(height: 12),
          SilencePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SilenceEyebrow('DEVICE ADDRESS'),
                const SizedBox(height: 7),
                SelectableText(
                  connected.id,
                  style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 22),
                Text(
                  '${controller.services.length} Bluetooth services',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 7),
                const Text(
                  'Service discovery is available. Device-specific queries are still being verified.',
                  style: TextStyle(fontSize: 12, color: SilenceColors.muted),
                ),
                for (final service in controller.services) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 13),
                  SelectableText(
                    service.uuid,
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      height: 1.5,
                    ),
                  ),
                  Text(
                    '${service.characteristicCount} characteristics',
                    style: const TextStyle(
                      fontSize: 12,
                      color: SilenceColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ] else ...[
          SilenceSectionTitle(
            'Nearby devices',
            trailing: Text(
              controller.scanning
                  ? 'SCANNING'
                  : '${controller.devices.length} FOUND',
              style: const TextStyle(
                fontSize: 10,
                letterSpacing: 1.4,
                color: SilenceColors.muted,
              ),
            ),
          ),
          const SizedBox(height: 13),
          if (controller.devices.isEmpty)
            SilencePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    controller.scanning ? Icons.radar : Icons.waves,
                    color: SilenceColors.muted,
                    size: 30,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    controller.scanning
                        ? 'Listening for your watch.'
                        : 'Your watch belongs here.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Keep your watch nearby. Do not unpair it in NoiseFit just to scan here. Silence cannot complete watch pairing.',
                    style: TextStyle(
                      color: SilenceColors.muted,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            )
          else
            ...controller.devices.map(
              (device) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SilencePanel(
                  padding: const EdgeInsets.all(17),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: SilenceColors.elevated,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.watch_outlined,
                          color: SilenceColors.accent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              device.name.isEmpty
                                  ? 'Unnamed Bluetooth device'
                                  : device.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${device.rssi} dBm · ${device.id}',
                              maxLines: 2,
                              style: const TextStyle(
                                fontSize: 10,
                                color: SilenceColors.muted,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Connect to ${device.name}',
                        onPressed: controller.busy || controller.scanning
                            ? null
                            : () => controller.connect(device),
                        icon: const Icon(
                          Icons.arrow_forward_rounded,
                          color: SilenceColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (!controller.demoMode) ...[
            const SizedBox(height: 18),
            Center(
              child: TextButton(
                onPressed: controller.busy || controller.scanning
                    ? null
                    : () => controller.setDemoMode(true),
                child: const Text(
                  'Just looking? Explore a demo',
                  style: TextStyle(color: SilenceColors.muted, fontSize: 12),
                ),
              ),
            ),
          ],
        ],
        const SizedBox(height: 30),
        SilencePanel(
          color: const Color(0xFF20271A),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.spa_outlined,
                color: SilenceColors.accent,
                size: 23,
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Room for what matters.',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Your health stays with NoiseFit for now. Silence is your space for a more personal watch.',
                      style: TextStyle(
                        color: SilenceColors.muted,
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

const _conceptNames = ['Essential', 'Analog', 'Activity'];

class _WatchPreview extends StatelessWidget {
  const _WatchPreview({required this.style, required this.width});
  final int style;
  final double width;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '${_conceptNames[style]} watchface concept, showing sample values',
    image: true,
    child: Container(
      width: width,
      height: width * 1.23,
      padding: EdgeInsets.all(width * .045),
      decoration: BoxDecoration(
        color: const Color(0xFF090B09),
        borderRadius: BorderRadius.circular(width * .22),
        border: Border.all(color: const Color(0xFF46503C), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(65),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(width * .17),
        child: CustomPaint(painter: _FacePainter(style)),
      ),
    ),
  );
}

class _FacePainter extends CustomPainter {
  _FacePainter(this.style);
  final int style;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 240, size.height / 280);
    final paint = Paint();
    paint.shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF283923), Color(0xFF11190F)],
    ).createShader(const Rect.fromLTWH(0, 0, 240, 280));
    canvas.drawRect(const Rect.fromLTWH(0, 0, 240, 280), paint);
    paint.shader = null;
    if (style == 1) {
      final center = const Offset(120, 137);
      paint.color = const Color(0xFF768466);
      paint.strokeWidth = 2;
      for (var i = 0; i < 12; i++) {
        final angle = i * math.pi / 6 - math.pi / 2;
        final r = i % 3 == 0 ? 89.0 : 94.0;
        canvas.drawLine(
          center + Offset(math.cos(angle), math.sin(angle)) * r,
          center + Offset(math.cos(angle), math.sin(angle)) * 100,
          paint,
        );
      }
      _text(
        canvas,
        'SILENCE',
        const Offset(0, 66),
        11,
        SilenceColors.muted,
        width: 240,
        spacing: 3,
      );
      paint.color = SilenceColors.ink;
      paint.strokeWidth = 6;
      paint.strokeCap = StrokeCap.round;
      canvas.drawLine(center, const Offset(75, 101), paint);
      paint.color = SilenceColors.accent;
      paint.strokeWidth = 4;
      canvas.drawLine(center, const Offset(174, 84), paint);
      paint.color = SilenceColors.ink;
      canvas.drawCircle(center, 5, paint);
      _text(
        canvas,
        'FRI  23',
        const Offset(0, 198),
        13,
        SilenceColors.muted,
        width: 240,
      );
    } else if (style == 2) {
      _text(
        canvas,
        'FRIDAY 23',
        const Offset(25, 30),
        11,
        SilenceColors.muted,
        spacing: 2,
      );
      _text(
        canvas,
        '08:24',
        const Offset(22, 53),
        54,
        SilenceColors.ink,
        weight: FontWeight.w300,
      );
      _text(canvas, '6,280', const Offset(25, 133), 30, SilenceColors.accent);
      _text(
        canvas,
        'STEPS / SAMPLE',
        const Offset(26, 170),
        9,
        SilenceColors.muted,
        spacing: 1.5,
      );
      paint.strokeCap = StrokeCap.round;
      paint.strokeWidth = 9;
      for (var i = 0; i < 9; i++) {
        paint.color = i < 6 ? SilenceColors.accent : const Color(0xFF3A4832);
        final x = 30.0 + i * 22;
        canvas.drawLine(
          Offset(x, 233),
          Offset(
            x,
            233 - const <double>[16, 25, 33, 23, 41, 32, 22, 28, 17][i],
          ),
          paint,
        );
      }
    } else {
      _text(
        canvas,
        'FRI, OCT 23',
        const Offset(27, 35),
        12,
        SilenceColors.muted,
        spacing: 1.4,
      );
      _text(
        canvas,
        '08',
        const Offset(20, 65),
        81,
        SilenceColors.ink,
        weight: FontWeight.w300,
      );
      _text(
        canvas,
        '24',
        const Offset(20, 140),
        81,
        SilenceColors.accent,
        weight: FontWeight.w300,
      );
      paint.color = SilenceColors.accent;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(28, 245, 25, 3),
          const Radius.circular(2),
        ),
        paint,
      );
      _text(
        canvas,
        'SILENCE',
        const Offset(65, 238),
        10,
        SilenceColors.muted,
        spacing: 2.5,
      );
    }
    canvas.restore();
  }

  void _text(
    Canvas canvas,
    String value,
    Offset position,
    double size,
    Color color, {
    double? width,
    double spacing = 0,
    FontWeight weight = FontWeight.w400,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontFamily: 'SilenceSans',
          fontSize: size,
          height: 1.05,
          fontWeight: weight,
          color: color,
          letterSpacing: spacing,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: width == null ? TextAlign.left : TextAlign.center,
    )..layout(minWidth: width ?? 0, maxWidth: width ?? 240);
    painter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _FacePainter oldDelegate) =>
      oldDelegate.style != style;
}

/// Bind handshake controls and raw protocol log for the connected watch.
class _PairingPanel extends StatelessWidget {
  const _PairingPanel({required this.controller});
  final SilenceController controller;

  @override
  Widget build(BuildContext context) {
    final log = controller.protocolLog;
    return SilencePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SilenceEyebrow('PAIR WITH THIS WATCH'),
          const SizedBox(height: 10),
          const Text(
            'Sends the companion bind request so the watch leaves the QR screen. Silence then owns the watch until you press Unpair / release watch and re-add it in NoiseFit.',
            style: TextStyle(
              fontSize: 12,
              height: 1.6,
              color: SilenceColors.muted,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed:
                controller.pairing ||
                    controller.busy ||
                    controller.services.isEmpty
                ? null
                : controller.pairWatch,
            icon: controller.pairing
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.link, size: 18),
            label: Text(controller.pairing ? 'Pairing…' : 'Pair watch'),
          ),
          if (controller.pairStatus != null) ...[
            const SizedBox(height: 14),
            Text(
              controller.pairStatus!,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: controller.pairSuccess == false
                    ? Colors.redAccent
                    : SilenceColors.ink,
              ),
            ),
          ],
          if (log.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(child: SilenceEyebrow('PROTOCOL LOG')),
                TextButton(
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: log.join('\n'))),
                  child: const Text('Copy'),
                ),
              ],
            ),
            SelectableText(
              log.join('\n'),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10.5,
                height: 1.5,
                color: SilenceColors.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
