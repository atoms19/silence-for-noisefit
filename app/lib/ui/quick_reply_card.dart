/// Editor for the quick replies offered on the watch, plus watch-control switches.
library;

import 'package:flutter/material.dart';

import '../controller/silence_controller.dart';
import 'silence_theme.dart';
import 'widgets.dart';

class QuickReplyCard extends StatefulWidget {
  const QuickReplyCard({super.key, required this.controller});
  final SilenceController controller;

  @override
  State<QuickReplyCard> createState() => _QuickReplyCardState();
}

class _QuickReplyCardState extends State<QuickReplyCard> {
  late final List<TextEditingController> _fields = [
    for (final text in widget.controller.quickReplies)
      TextEditingController(text: text),
  ];

  @override
  void dispose() {
    for (final field in _fields) {
      field.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final c = widget.controller;
      // Controller values may load after this card is built (restore on launch).
      for (var i = 0; i < _fields.length; i++) {
        if (_fields[i].text.isEmpty && c.quickReplies[i].isNotEmpty) {
          _fields[i].text = c.quickReplies[i];
        }
      }
      return SilencePanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Replies offered on the watch for messages. Choosing one sends it through the original app (WhatsApp, Messages, Telegram and others that allow inline replies) for the latest notification Silence relayed.',
              style: TextStyle(
                fontSize: 12,
                height: 1.6,
                color: SilenceColors.muted,
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < _fields.length; i++) ...[
              TextField(
                controller: _fields[i],
                maxLength: 60,
                decoration: InputDecoration(
                  labelText: 'Reply ${i + 1}',
                  counterText: '',
                ),
                onChanged: (v) => c.setQuickReply(i, v),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 4),
            FilledButton.icon(
              onPressed: c.canQuery ? c.sendQuickReplyPresets : null,
              icon: const Icon(Icons.reply, size: 18),
              label: const Text('Send replies to watch'),
            ),
            if (c.presetStatus != null) ...[
              const SizedBox(height: 10),
              Text(
                c.presetStatus!,
                style: const TextStyle(
                  fontSize: 12,
                  color: SilenceColors.muted,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Show quick replies on messaging apps. The watch only offers replies on SMS-type notifications, so WhatsApp, Telegram and other apps with a reply button appear as SMS, with the app name underneath.',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                ),
                Switch(value: c.replyAsSms, onChanged: c.setReplyAsSms),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Smart replies: tailor three of the five replies to each message before it reaches the watch. Runs on this phone only.',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                ),
                Switch(value: c.smartReplies, onChanged: c.setSmartReplies),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Let the watch control music and volume',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                Switch(value: c.watchControls, onChanged: c.setWatchControls),
              ],
            ),
            if (c.watchEvents.isNotEmpty) ...[
              const SizedBox(height: 12),
              const SilenceEyebrow('WATCH EVENTS'),
              const SizedBox(height: 8),
              for (final e in c.watchEvents.take(5))
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    e,
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
        ),
      );
    },
  );
}
