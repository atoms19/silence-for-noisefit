/// Maps Android notifications to what the watch can display.
library;

import 'touchgui_notification.dart';

/// A notification read from the phone (via the notification listener).
class PhoneNotification {
  const PhoneNotification({
    required this.package,
    required this.key,
    required this.title,
    required this.text,
    this.category = '',
  });

  factory PhoneNotification.fromEvent(Map<String, dynamic> event) =>
      PhoneNotification(
        package: event['package'] as String? ?? '',
        key: event['key'] as String? ?? '',
        title: (event['title'] as String? ?? '').trim(),
        text: (event['text'] as String? ?? '').trim(),
        category: event['category'] as String? ?? '',
      );

  final String package;
  final String key;
  final String title;
  final String text;
  final String category;
}

class AppRule {
  const AppRule(this.label, this.type);
  final String label;
  final WatchAppType type;
}

/// Verified watch categories are used for apps the Pulse 2 recognises. LinkedIn
/// and Calendar fall back to `other` because their codes show nothing on it.
const knownApps = <String, AppRule>{
  'com.whatsapp': AppRule('WhatsApp', WatchAppType.whatsApp),
  'com.whatsapp.w4b': AppRule('WhatsApp Business', WatchAppType.whatsApp),
  'org.telegram.messenger': AppRule('Telegram', WatchAppType.telegram),
  'org.thunderdog.challegram': AppRule('Telegram X', WatchAppType.telegram),
  'com.instagram.android': AppRule('Instagram', WatchAppType.instagram),
  'com.google.android.gm': AppRule('Gmail', WatchAppType.gmail),
  'com.microsoft.office.outlook': AppRule('Outlook', WatchAppType.outlook),
  'com.facebook.orca': AppRule('Messenger', WatchAppType.messenger),
  'com.facebook.katana': AppRule('Facebook', WatchAppType.messenger),
  'com.twitter.android': AppRule('X', WatchAppType.twitter),
  'com.skype.raider': AppRule('Skype', WatchAppType.skype),
  'com.viber.voip': AppRule('Viber', WatchAppType.viber),
  'com.snapchat.android': AppRule('Snapchat', WatchAppType.snapchat),
  'com.tencent.mm': AppRule('WeChat', WatchAppType.weChat),
  'com.google.android.apps.messaging': AppRule('Messages', WatchAppType.sms),
  'com.samsung.android.messaging': AppRule('Messages', WatchAppType.sms),
  'com.android.mms': AppRule('Messages', WatchAppType.sms),
  'com.linkedin.android': AppRule('LinkedIn', WatchAppType.other),
  'com.google.android.calendar': AppRule('Calendar', WatchAppType.other),
  'com.slack': AppRule('Slack', WatchAppType.other),
};

/// System and call packages: calls use a separate command, and system noise
/// should never reach the watch.
const ignoredPackages = <String>{
  'android',
  'com.android.systemui',
  'com.android.vending',
  'com.android.providers.downloads',
  'com.google.android.dialer',
  'com.android.dialer',
  'com.android.server.telecom',
  'com.samsung.android.incallui',
};

/// What to send for [n], or null when it should be skipped.
({AppRule app, String name, String number, String content})? mapNotification(
  PhoneNotification n, {
  required bool includeText,
}) {
  if (ignoredPackages.contains(n.package)) return null;
  final rule =
      knownApps[n.package] ?? AppRule(_labelFor(n.package), WatchAppType.other);
  if (!includeText) {
    return (
      app: rule,
      name: rule.label,
      number: '',
      content: 'New notification',
    );
  }
  final unknown = !knownApps.containsKey(n.package);
  return (
    app: rule,
    name: n.title.isNotEmpty ? n.title : rule.label,
    // Unknown apps all show as "other"; the label says where it came from.
    number: unknown ? rule.label : '',
    content: n.text,
  );
}

String _labelFor(String package) {
  final parts = package.split('.').where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return 'App';
  final last = parts.last;
  return last[0].toUpperCase() + last.substring(1);
}
