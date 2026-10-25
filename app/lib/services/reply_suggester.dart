/// Suggests short replies for an incoming message, entirely on the phone.
library;

import 'package:flutter/services.dart';

/// What the suggester knows about the message being answered.
class ReplyContext {
  const ReplyContext({
    required this.sender,
    required this.text,
    this.history = const [],
  });
  final String sender;
  final String text;

  /// Earlier messages from the same sender, oldest first.
  final List<String> history;
}

abstract interface class ReplySuggester {
  /// Up to [count] short replies fitting the tone of [context].
  Future<List<String>> suggest(ReplyContext context, {int count = 3});
}

/// Keyword-and-shape heuristics: instant, no model. Stands in until an
/// on-device language model is plugged in behind [ReplySuggester].
class RuleBasedSuggester implements ReplySuggester {
  const RuleBasedSuggester();

  @override
  Future<List<String>> suggest(ReplyContext context, {int count = 3}) async {
    final text = context.text.toLowerCase().trim();
    final picks = <String>[];
    bool has(Pattern p) => text.contains(p);
    bool word(String w) => RegExp('\\b$w\\b').hasMatch(text);

    if (word('thanks') || word('thank') || word('thx')) {
      picks.addAll(['You’re welcome!', 'Anytime', 'No problem']);
    } else if (word('sorry')) {
      picks.addAll(['No worries', 'All good', 'It’s okay']);
    } else if (word('happy birthday') || has('congrat')) {
      picks.addAll(['Thank you!', 'Thanks so much!', 'Appreciate it']);
    } else if (word('late') || word('delayed') || has('running behind')) {
      picks.addAll(['No worries', 'See you soon', 'Okay, take your time']);
    } else if (word('where') || has('where are you')) {
      picks.addAll(['On my way', 'Be there soon', 'Give me 5 minutes']);
    } else if (RegExp(r'\b(call|ring|phone)\b').hasMatch(text)) {
      picks.addAll([
        'Calling you now',
        'Can’t talk now',
        'I’ll call you later',
      ]);
    } else if (RegExp(
          r'\b(dinner|lunch|coffee|drinks|meet|tonight)\b',
        ).hasMatch(text) &&
        text.contains('?')) {
      picks.addAll(['Sounds good', 'Sure, what time?', 'Can’t make it']);
    } else if (RegExp(
      r"how are you|how r u|how('s| is) it going|how have you been|what's up|whats up|wassup",
    ).hasMatch(text)) {
      picks.addAll(['Good, you?', 'All good, you?', 'Busy, but good']);
    } else if (RegExp(r'^(hi|hey|hello|yo|hiya)\b').hasMatch(text)) {
      picks.addAll(['Hey!', 'Hi, what’s up?', 'Hello!']);
    } else if (RegExp(r'^(good )?(morning|night)\b').hasMatch(text)) {
      picks.addAll(['Good morning!', 'Same to you', 'Talk later']);
    } else if (RegExp(
          r'^(are|is|do|does|did|can|could|will|would|should|have|has)\b',
        ).hasMatch(text) ||
        (text.endsWith('?') && text.length < 60)) {
      picks.addAll(['Yes', 'No', 'Let me check']);
    } else if (text.endsWith('?')) {
      picks.addAll(['Let me check', 'I’ll get back to you', 'Not sure yet']);
    } else if (text.endsWith('!')) {
      picks.addAll(['Nice!', 'Great', 'Awesome']);
    }
    return picks.take(count).toList();
  }
}

/// ML Kit Smart Reply over a platform channel, falling back to [fallback]
/// when it has nothing to offer (unsupported language, failure, no result).
class MlKitSuggester implements ReplySuggester {
  const MlKitSuggester({this.fallback = const RuleBasedSuggester()});
  static const _channel = MethodChannel('dev.silence/smart_reply');
  final ReplySuggester fallback;

  @override
  Future<List<String>> suggest(ReplyContext context, {int count = 3}) async {
    var picks = <String>[];
    try {
      final result = await _channel.invokeListMethod<String>('suggest', {
        'sender': context.sender,
        'messages': [...context.history, context.text],
      });
      picks = (result ?? const []).where((r) => r.trim().isNotEmpty).toList();
    } on PlatformException {
      // Fall through to the fallback.
    } on MissingPluginException {
      // Not on Android.
    }
    if (picks.length < count) {
      for (final extra in await fallback.suggest(context, count: count)) {
        if (picks.length >= count) break;
        if (!picks.contains(extra)) picks.add(extra);
      }
    }
    return picks.take(count).toList();
  }
}
