/// Developer panel for testing how notifications look on the watch.
library;

import 'package:flutter/material.dart';

import '../controller/silence_controller.dart';
import '../services/touchgui_notification.dart';
import 'silence_theme.dart';
import 'widgets.dart';

class _Preset {
  const _Preset(this.label, this.app, this.name, this.number, this.content);
  final String label;
  final WatchAppType app;
  final String name, number, content;
}

const _presets = [
  _Preset(
    'SMS',
    WatchAppType.sms,
    'Alex',
    '+1 555 0100',
    'Running 5 min late, start without me.',
  ),
  _Preset(
    'WhatsApp',
    WatchAppType.whatsApp,
    'Priya',
    '',
    'Dinner at 8? I booked the corner table.',
  ),
  _Preset(
    'Gmail',
    WatchAppType.gmail,
    'Design team',
    'Weekly sync notes',
    'Notes and next steps are in the doc.',
  ),
  _Preset(
    'Telegram',
    WatchAppType.telegram,
    'Build bot',
    '',
    'Deploy finished: all checks passed.',
  ),
  _Preset(
    'Calendar',
    WatchAppType.calendar,
    'Standup',
    '10:00',
    'Starts in 5 minutes.',
  ),
  _Preset(
    'Long text',
    WatchAppType.sms,
    'Long message',
    '',
    'This message is deliberately long so you can see how the watch wraps, scrolls or truncates text. '
        'It keeps going with several sentences. The quick brown fox jumps over the lazy dog, again and again, '
        'until the limit near seven hundred bytes is reached and the tail gets cut off by the encoder.',
  ),
  _Preset(
    'Unicode',
    WatchAppType.other,
    'Ünïcode ✓',
    '',
    'Café, naïve, 日本語, Привет, emoji 🎉 test.',
  ),
];

class NotificationDemoPanel extends StatefulWidget {
  const NotificationDemoPanel({super.key, required this.controller});
  final SilenceController controller;

  @override
  State<NotificationDemoPanel> createState() => _NotificationDemoPanelState();
}

class _NotificationDemoPanelState extends State<NotificationDemoPanel> {
  WatchAppType _app = WatchAppType.sms;
  final _name = TextEditingController(text: 'Alex');
  final _number = TextEditingController();
  final _content = TextEditingController(text: 'Hello from Silence');
  bool _invert = false;

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    _content.dispose();
    super.dispose();
  }

  void _apply(_Preset p) => setState(() {
    _app = p.app;
    _name.text = p.name;
    _number.text = p.number;
    _content.text = p.content;
  });

  void _send() => widget.controller.sendDemoNotification(
    app: _app,
    name: _name.text,
    number: _number.text,
    content: _content.text,
    invert: _invert,
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final c = widget.controller;
      return SilencePanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SilenceEyebrow('NOTIFICATION TEST'),
            const SizedBox(height: 10),
            const Text(
              'Sends one test notification to the watch using the recovered message command. Nothing is read from your phone.',
              style: TextStyle(
                fontSize: 12,
                height: 1.6,
                color: SilenceColors.muted,
              ),
            ),
            if (!c.canNotify) ...[
              const SizedBox(height: 10),
              const Text(
                'Press Pair watch above first. Sending unlocks once the watch reports Bound.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: Colors.amber,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in _presets)
                  ActionChip(label: Text(p.label), onPressed: () => _apply(p)),
              ],
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<WatchAppType>(
              initialValue: _app,
              decoration: const InputDecoration(labelText: 'App type'),
              items: [
                for (final t in WatchAppType.values)
                  DropdownMenuItem(
                    value: t,
                    child: Text('${t.label} (0x${t.code.toRadixString(16)})'),
                  ),
              ],
              onChanged: (v) => setState(() => _app = v ?? _app),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name / title'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _number,
              decoration: const InputDecoration(labelText: 'Number / subtitle'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _content,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Message'),
            ),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Invert text bytes. Try this if the text shows as garbage; the SDK does it for some device capabilities.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: SilenceColors.muted,
                    ),
                  ),
                ),
                Switch(
                  value: _invert,
                  onChanged: (v) => setState(() => _invert = v),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FilledButton.icon(
              onPressed: c.canNotify ? _send : null,
              icon: const Icon(Icons.notifications_active_outlined, size: 18),
              label: const Text('Send test notification'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: c.canNotify ? c.runReplyTimingTest : null,
              icon: const Icon(Icons.timer_outlined, size: 18),
              label: const Text('Reply timing test'),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Sets replies A1–A5, sends a message, then swaps to B1–B5 after 6 s. Wait, open the message and tap Reply: if you see B, the watch reads replies at tap time.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: SilenceColors.muted,
                ),
              ),
            ),
            if (c.presetStatus != null) ...[
              const SizedBox(height: 8),
              Text(
                c.presetStatus!,
                style: const TextStyle(fontSize: 13, color: SilenceColors.ink),
              ),
            ],
            if (c.notifyStatus != null) ...[
              const SizedBox(height: 12),
              Text(
                c.notifyStatus!,
                style: TextStyle(
                  fontSize: 13,
                  color: c.notifySuccess == false
                      ? Colors.redAccent
                      : SilenceColors.ink,
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}
