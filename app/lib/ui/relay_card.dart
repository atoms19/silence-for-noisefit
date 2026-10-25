/// Phone notification relay controls: permission, switches, filters and a log.
library;

import 'package:flutter/material.dart';

import '../controller/silence_controller.dart';
import '../services/phone_notifications.dart';
import 'silence_theme.dart';
import 'widgets.dart';

class RelayCard extends StatelessWidget {
  const RelayCard({super.key, required this.controller});
  final SilenceController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final c = controller;
      final ready = c.connectedDevice != null && c.pairSuccess == true;
      return SilencePanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!c.accessGranted) ...[
              const Text(
                'Silence needs notification access to read your phone notifications and show them on the watch. They are only sent to your watch, never uploaded.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.6,
                  color: SilenceColors.muted,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: c.openNotificationAccessSettings,
                icon: const Icon(Icons.notifications_outlined, size: 18),
                label: const Text('Grant notification access'),
              ),
              const SizedBox(height: 10),
              const Text(
                'If Android says the setting is restricted for this app: Settings > Apps > Silence > ⋮ > Allow restricted settings, then try again.',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  color: SilenceColors.muted,
                ),
              ),
            ] else ...[
              _switchRow(
                'Send phone notifications to the watch',
                ready
                    ? 'Relaying while Silence is connected to your watch.'
                    : 'Connect your watch first.',
                c.relayEnabled,
                c.setRelayEnabled,
              ),
              const SizedBox(height: 12),
              _switchRow(
                'Include message text',
                'Off sends only the app name.',
                c.includeText,
                c.setIncludeText,
              ),
              const SizedBox(height: 16),
              const SilenceEyebrow('APPS'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final package in {...knownApps.keys, ...c.seenApps})
                    if (!ignoredPackages.contains(package))
                      FilterChip(
                        label: Text(
                          knownApps[package]?.label ?? package.split('.').last,
                        ),
                        selected: !c.disabledApps.contains(package),
                        onSelected: (v) => c.setAppEnabled(package, v),
                      ),
                ],
              ),
              if (c.relayLog.isNotEmpty) ...[
                const SizedBox(height: 16),
                const SilenceEyebrow('RECENT'),
                const SizedBox(height: 8),
                for (final e in c.relayLog.take(6))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${e.app} · ${e.title.isEmpty ? '(no title)' : e.title} · ${e.outcome}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: SilenceColors.muted,
                      ),
                    ),
                  ),
              ],
            ],
          ],
        ),
      );
    },
  );

  Widget _switchRow(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: SilenceColors.muted),
            ),
          ],
        ),
      ),
      Switch(value: value, onChanged: onChanged),
    ],
  );
}
