/// Connect, pair and release controls for the watch, shown in Studio.
library;

import 'package:flutter/material.dart';

import '../controller/silence_controller.dart';
import 'silence_theme.dart';
import 'widgets.dart';

Future<void> releaseWatchWithDialog(
  BuildContext context,
  SilenceController controller,
) async {
  final released = await controller.unpair();
  if (!context.mounted || !released) return;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        controller.demoMode
            ? 'Sample watch released'
            : 'Watch released from Silence',
      ),
      content: const SingleChildScrollView(
        child: Text(
          'Silence has stopped discovery and closed its Bluetooth connection.\n\n'
          'To return to NoiseFit, open NoiseFit and choose Add device. If the watch is listed in Android Bluetooth settings, Forget or Unpair it there, then retry in NoiseFit.\n\n'
          'This button releases Silence only. It does not factory-reset the watch, clear a watch-side binding, or complete NoiseFit pairing. The QR screen may remain until NoiseFit completes pairing.',
        ),
      ),
      actions: [
        if (!controller.demoMode)
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              controller.openBluetoothSettings();
            },
            child: const Text('Bluetooth settings'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Done'),
        ),
      ],
    ),
  );
}

class WatchCard extends StatelessWidget {
  const WatchCard({super.key, required this.controller});
  final SilenceController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final device = c.connectedDevice;
    final bound = device != null && c.pairSuccess == true;
    final working = c.busy || c.pairing;
    final children = <Widget>[];

    if (bound) {
      children
        ..add(_line(Icons.check_circle_outline, 'Paired with ${device.name}'))
        ..add(const SizedBox(height: 12))
        ..add(_status(c))
        ..add(const SizedBox(height: 14))
        ..add(
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: c.canQuery ? c.refreshWatchStatus : null,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
              ),
              OutlinedButton.icon(
                onPressed: c.canQuery ? c.syncWatchTime : null,
                icon: const Icon(Icons.schedule, size: 18),
                label: const Text('Sync time'),
              ),
              _release(context),
            ],
          ),
        );
    } else if (device != null && c.pairSuccess == false) {
      children
        ..add(_line(Icons.error_outline, c.pairStatus ?? 'Pairing failed.'))
        ..add(const SizedBox(height: 14))
        ..add(
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton(
                onPressed: c.pairWatch,
                child: const Text('Try again'),
              ),
              _release(context),
            ],
          ),
        );
    } else if (working) {
      children
        ..add(
          Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  c.pairing ? (c.pairStatus ?? 'Pairing…') : c.status,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        )
        ..add(const SizedBox(height: 14))
        ..add(_release(context));
    } else if (c.scanning || c.devices.isNotEmpty) {
      children.addAll([
        Text(
          c.scanning ? 'Looking for your watch…' : 'Choose your watch',
          style: const TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 10),
        for (final d in c.devices)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.watch_outlined,
              color: SilenceColors.accent,
            ),
            title: Text(
              d.name.isEmpty ? 'Unnamed device' : d.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text('${d.rssi} dBm'),
            onTap: () => c.connectAndPair(d),
          ),
        if (!c.scanning)
          TextButton(onPressed: c.scan, child: const Text('Scan again')),
      ]);
    } else {
      final last = c.lastDevice;
      children.addAll([
        const Text(
          'Connect your Pulse 2 to send backgrounds straight to it. Silence pairs with the watch while connected, so NoiseFit cannot reach it until you release it.',
          style: TextStyle(
            fontSize: 12,
            height: 1.6,
            color: SilenceColors.muted,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (last != null)
              FilledButton.icon(
                onPressed: () => c.connectAndPair(last),
                icon: const Icon(Icons.bluetooth_connected, size: 18),
                label: Text('Connect to ${last.name}'),
              ),
            if (last != null)
              OutlinedButton(
                onPressed: c.scan,
                child: const Text('Choose another'),
              )
            else
              FilledButton.icon(
                onPressed: c.scan,
                icon: const Icon(Icons.bluetooth_searching, size: 18),
                label: const Text('Find my watch'),
              ),
            if (last != null)
              TextButton(onPressed: c.forgetWatch, child: const Text('Forget')),
          ],
        ),
      ]);
    }

    return SilencePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _status(SilenceController c) {
    final parts = <String>[
      if (c.batteryLevel != null)
        'Battery ${c.batteryLevel}%${c.batteryMillivolts != null ? ' · ${(c.batteryMillivolts! / 1000).toStringAsFixed(2)} V' : ''}',
      if (c.firmwareDetail != null) 'Firmware ${c.firmwareDetail}',
      if (c.lastTimeSync != null)
        'Clock synced ${c.lastTimeSync!.hour.toString().padLeft(2, '0')}:${c.lastTimeSync!.minute.toString().padLeft(2, '0')}',
    ];
    final text = parts.isEmpty
        ? (c.statusMessage ?? 'Reading watch status…')
        : parts.join('\n');
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        height: 1.6,
        color: SilenceColors.muted,
      ),
    );
  }

  Widget _line(IconData icon, String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20, color: SilenceColors.accent),
      const SizedBox(width: 10),
      Expanded(
        child: Text(text, style: const TextStyle(fontSize: 13, height: 1.5)),
      ),
    ],
  );

  Widget _release(BuildContext context) => OutlinedButton.icon(
    onPressed: controller.releasing
        ? null
        : () => releaseWatchWithDialog(context, controller),
    icon: const Icon(Icons.link_off, size: 18),
    label: Text(controller.releasing ? 'Releasing…' : 'Release watch'),
  );
}
