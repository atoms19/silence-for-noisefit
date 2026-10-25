import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:silence_app/controller/silence_controller.dart';
import 'package:silence_app/services/ble_transport.dart';
import 'package:silence_app/services/phone_notifications.dart';
import 'package:silence_app/services/reply_suggester.dart';
import 'package:silence_app/services/touchgui_weather.dart';
import 'package:silence_app/services/weather_service.dart';
import 'package:silence_app/services/touchgui_notification.dart';

class _Ble implements BleTransport {
  final messages = StreamController<Map<String, dynamic>>.broadcast(sync: true);
  @override
  Stream<Map<String, dynamic>> get events => messages.stream;
  @override
  Future<bool> notificationAccess() async => true;
  final sent = <Uint8List>[];
  final queries = <String>[];
  final raw = <Uint8List>[];
  @override
  Future<void> rawCommand(Uint8List bytes) async => raw.add(bytes);
  final replies = <(String, String)>[];
  final media = <String>[];
  @override
  Future<bool> replyToNotification(String key, String text) async {
    replies.add((key, text));
    return true;
  }

  @override
  Future<void> mediaControl(String action) async => media.add(action);
  @override
  Future<void> statusCommand(String kind) async => queries.add(kind);
  @override
  Future<void> sendLongCommand(Uint8List message) async {
    sent.add(message);
    if (message[7] == 0x15) {
      messages.add({'type': 'presetReply', 'sequence': 0, 'status': 0});
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

void main() {
  test('CRC matches the CCITT-FALSE check value', () {
    expect(touchGuiCrc16('123456789'.codeUnits), 0x29B1);
  });

  test('Message body layout: flags, type, then length-prefixed fields', () {
    final body = buildNotificationBody(type: 1, name: 'A', content: 'Hi');
    expect(body, [
      0, 0, 1, 0, 1, 1, 0, // two zeros, name/number/content flags, type, zero
      0, 1, 0, 0, 0, 0x41, // name
      0, 2, 0, 0, 0, 0x48, 0x69, // content
    ]);
  });

  test('Framing: magic, version, length, command, sequence, body, CRC', () {
    final body = buildNotificationBody(type: 1, name: 'A', content: 'Hi');
    final message = frameLongCommand(
      body,
      commandId: messageCommandId,
      sequence: 5,
    );
    expect(message.length, body.length + 13);
    expect(message.sublist(0, 11), [
      0xDA,
      0xAD,
      0xDA,
      0xAD,
      1,
      0x1F,
      0,
      0x0B,
      0,
      5,
      0,
    ]);
    expect(message.sublist(11, 11 + body.length), body);
    final crc =
        message[message.length - 2] | (message[message.length - 1] << 8);
    expect(crc, touchGuiCrc16(message, message.length - 2));
  });

  test('Inverted text flips string bytes only', () {
    final body = buildNotificationBody(type: 1, content: 'A', invert: true);
    expect(body.sublist(body.length - 1), [~0x41 & 0xFF]);
    expect(body.sublist(0, 7), [0, 0, 0, 0, 1, 1, 0]);
  });

  test('Long content is cut to fit the body limit on character boundaries', () {
    final body = buildNotificationBody(type: 1, name: 'N', content: 'é' * 1000);
    // The SDK budgets 0x2ed before the content's own 5-byte field header.
    expect(body.length, lessThanOrEqualTo(0x2ed + 5));
    expect(body.length, greaterThan(0x2ed + 5 - 3));
    final length = ByteData.sublistView(
      body,
    ).getUint32(7 + 5 + 1 + 1, Endian.little);
    expect(length.isEven, isTrue, reason: 'no half-character');
  });

  test('Sequence numbers wrap within 1..0xFFFE', () {
    expect(nextSequence(1), 2);
    expect(nextSequence(0xFFFD), 0xFFFE);
    expect(nextSequence(0xFFFE), 1);
  });

  test('App type codes follow the SDK mapping', () {
    expect(WatchAppType.sms.code, 1);
    expect(WatchAppType.whatsApp.code, 8);
    expect(WatchAppType.gmail.code, 0x14);
    expect(WatchAppType.other.code, 0x80);
  });

  test('Controller sends a framed notification only after a bind', () async {
    final ble = _Ble();
    final controller = SilenceController(transport: ble);
    addTearDown(controller.dispose);
    await controller.sendDemoNotification(
      app: WatchAppType.sms,
      name: 'A',
      content: 'Hi',
    );
    expect(ble.sent, isEmpty, reason: 'not paired yet');
  });

  Future<(SilenceController, _Ble)> boundController({
    ReplySuggester? suggester,
  }) async {
    final ble = _Ble();
    final controller = SilenceController(transport: ble, suggester: suggester);
    addTearDown(() {
      controller.dispose();
      ble.messages.close();
    });
    const device = DiscoveredDevice(
      id: 'AA:BB:CC:DD:EE:FF',
      name: 'Pulse',
      rssi: -40,
    );
    await controller.connect(device);
    ble.messages
      ..add({'type': 'connection', 'id': device.id, 'state': 'connected'})
      ..add({
        'type': 'pair',
        'stage': 'bindResult',
        'state': 0,
        'success': true,
      });
    await controller.refreshAccess();
    controller.setRelayEnabled(true);
    return (controller, ble);
  }

  Map<String, dynamic> phone(String package, String title, String text) => {
    'type': 'phoneNotification',
    'package': package,
    'key': '$package$title',
    'title': title,
    'text': text,
  };

  String bodyText(Uint8List message) => utf8.decode(
    message.sublist(11, message.length - 2),
    allowMalformed: true,
  );

  test(
    'Relay sends mapped notifications, skips system apps and duplicates',
    () async {
      final (controller, ble) = await boundController();
      ble.messages
        ..add(phone('com.whatsapp', 'Priya', 'Dinner at 8?'))
        ..add(phone('com.whatsapp', 'Priya', 'Dinner at 8?'))
        ..add(phone('com.android.systemui', 'USB', 'charging'));
      await Future<void>.delayed(Duration.zero);
      expect(ble.sent, hasLength(1));
      final message = ble.sent.single;
      expect(message[11 + 5], WatchAppType.whatsApp.code);
      expect(bodyText(message), contains('Priya'));
      expect(bodyText(message), contains('Dinner at 8?'));
      expect(controller.relayLog.first.outcome, 'sent');
    },
  );

  test('Smart replies reach the watch before the notification', () async {
    final (controller, ble) = await boundController(
      suggester: const RuleBasedSuggester(),
    );
    controller.setSmartReplies(true);
    ble.sent.clear();
    ble.messages.add({
      ...phone('com.whatsapp', 'Priya', 'Dinner tonight?'),
      'canReply': true,
    });
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final commands = ble.sent.map((m) => m[7]).toList();
    expect(commands.last, 0x0B);
    expect(commands.where((c) => c == 0x15), isNotEmpty);
    expect(commands.indexOf(0x0B), commands.length - 1);
    expect(
      (await const RuleBasedSuggester().suggest(
        const ReplyContext(sender: 'P', text: 'Dinner tonight?'),
      )).first,
      'Sounds good',
    );
  });

  test('Relay honours disabled apps, privacy and unknown-app labels', () async {
    final (controller, ble) = await boundController();
    controller.setAppEnabled('com.whatsapp', false);
    controller.setIncludeText(false);
    ble.messages
      ..add(phone('com.whatsapp', 'Priya', 'secret'))
      ..add(phone('com.example.coolapp', 'Hi', 'secret text'));
    await Future<void>.delayed(Duration.zero);
    expect(ble.sent, hasLength(1));
    expect(bodyText(ble.sent.single), isNot(contains('secret')));
    expect(bodyText(ble.sent.single), contains('Coolapp'));
    controller.setIncludeText(true);
    ble.messages.add(phone('com.example.coolapp', 'Hi', 'other text'));
    await Future<void>.delayed(const Duration(milliseconds: 1700));
    expect(ble.sent, hasLength(2));
    expect(
      bodyText(ble.sent.last),
      contains('Coolapp'),
      reason: 'unknown apps carry their name',
    );
  });

  test('Relay queues bursts one at a time', () async {
    final (controller, ble) = await boundController();
    ble.messages
      ..add(phone('com.whatsapp', 'A', 'one'))
      ..add(phone('com.whatsapp', 'B', 'two'));
    await Future<void>.delayed(Duration.zero);
    expect(ble.sent, hasLength(1));
    await Future<void>.delayed(const Duration(milliseconds: 1700));
    expect(ble.sent, hasLength(2));
    expect(controller.relayLog, hasLength(2));
  });

  test('Relay does nothing when disabled or the watch is not ready', () async {
    final ble = _Ble();
    final controller = SilenceController(transport: ble);
    addTearDown(() {
      controller.dispose();
      ble.messages.close();
    });
    ble.messages.add(phone('com.whatsapp', 'A', 'one'));
    await Future<void>.delayed(Duration.zero);
    expect(ble.sent, isEmpty);
    expect(controller.relayLog, isEmpty);
  });

  test('Mapping falls back to other for unsupported watch categories', () {
    final linkedin = mapNotification(
      const PhoneNotification(
        package: 'com.linkedin.android',
        key: 'k',
        title: 'Job',
        text: 'New role',
      ),
      includeText: true,
    )!;
    expect(linkedin.app.type, WatchAppType.other);
    expect(
      mapNotification(
        const PhoneNotification(
          package: 'com.google.android.dialer',
          key: 'k',
          title: 'x',
          text: 'y',
        ),
        includeText: true,
      ),
      isNull,
    );
  });

  test(
    'Binding triggers a time sync and status reads, and events fill the status',
    () async {
      final (controller, ble) = await boundController();
      await Future<void>.delayed(const Duration(milliseconds: 1600));
      expect(ble.queries, ['time', 'battery', 'version']);
      ble.messages
        ..add({
          'type': 'status',
          'kind': 'battery',
          'level': 87,
          'state': 1,
          'voltage': 4012,
        })
        ..add({'type': 'status', 'kind': 'version', 'detail': 'V5.4.328.26'})
        ..add({'type': 'status', 'kind': 'time', 'status': 0});
      expect(controller.batteryLevel, 87);
      expect(controller.batteryMillivolts, 4012);
      expect(controller.firmwareDetail, 'V5.4.328.26');
      expect(controller.lastTimeSync, isNotNull);
      ble.messages.add({
        'type': 'pair',
        'stage': 'deviceInfo',
        'fields': [2109, 1, 0, 0, 55, 0, 0, 1, 0, 0, 0, 0x30a, 1],
      });
      expect(controller.batteryLevel, 55);
      expect(controller.protocolVersion, 0x30a);
    },
  );

  test(
    'Quick reply preset messages use command 0x15 with count, index and text',
    () {
      final body = buildQuickReplyPresetBody(
        count: 5,
        index: 2,
        text: 'On my way',
      );
      expect(body, [5, 2, 9, ...'On my way'.codeUnits]);
      final message = buildQuickReplyPresetMessage(
        count: 5,
        index: 1,
        text: 'OK',
        sequence: 3,
      );
      expect(message.sublist(7, 9), [0x15, 0x00]);
      expect(message.sublist(11, 11 + 5), [5, 1, 2, 0x4F, 0x4B]);
      final long = buildQuickReplyPresetBody(
        count: 5,
        index: 1,
        text: 'é' * 100,
      );
      expect(long.length - 3, lessThanOrEqualTo(quickReplyMaxBytes));
    },
  );

  test('A quick reply is delivered to the last relayed notification', () async {
    final (controller, ble) = await boundController();
    ble.messages.add({
      ...phone('com.whatsapp', 'Priya', 'Dinner?'),
      'canReply': true,
    });
    await Future<void>.delayed(Duration.zero);
    ble.messages.add({
      'type': 'watchEvent',
      'kind': 'quickReply',
      'index': 2,
      'text': 'On my way',
      'number': '',
    });
    await Future<void>.delayed(Duration.zero);
    expect(ble.replies, [
      (
        'com.whatsapp'
            'Priya',
        'On my way',
      ),
    ]);
    expect(controller.relayLog.first.outcome, 'reply sent');
  });

  test('A quick reply with nothing to answer is reported, not sent', () async {
    final (controller, ble) = await boundController();
    ble.messages.add({
      'type': 'watchEvent',
      'kind': 'quickReply',
      'index': 1,
      'text': 'OK',
    });
    await Future<void>.delayed(Duration.zero);
    expect(ble.replies, isEmpty);
    expect(controller.watchEvents.first, contains('nothing to reply to'));
  });

  test(
    'Watch music and volume keys map to media actions unless turned off',
    () async {
      final (controller, ble) = await boundController();
      for (final code in [1, 2, 4, 5, 8, 9]) {
        ble.messages.add({
          'type': 'watchEvent',
          'kind': 'short',
          'category': 1,
          'code': code,
        });
      }
      await Future<void>.delayed(Duration.zero);
      expect(ble.media, [
        'play',
        'pause',
        'previous',
        'next',
        'volumeUp',
        'volumeDown',
      ]);
      controller.setWatchControls(false);
      ble.messages.add({
        'type': 'watchEvent',
        'kind': 'short',
        'category': 1,
        'code': 1,
      });
      await Future<void>.delayed(Duration.zero);
      expect(ble.media, hasLength(6));
      ble.messages.add({
        'type': 'watchEvent',
        'kind': 'short',
        'category': 2,
        'code': 0,
      });
      await Future<void>.delayed(Duration.zero);
      expect(controller.watchEvents.first, contains('not handled'));
    },
  );

  test(
    'Reply-capable apps are sent as SMS when quick replies are wanted',
    () async {
      final (controller, ble) = await boundController();
      ble.messages.add({
        ...phone('com.whatsapp', 'Priya', 'Dinner?'),
        'canReply': true,
      });
      await Future<void>.delayed(Duration.zero);
      expect(ble.sent.single[11 + 5], WatchAppType.sms.code);
      expect(bodyText(ble.sent.single), contains('WhatsApp'));
      controller.setReplyAsSms(false);
      await Future<void>.delayed(const Duration(milliseconds: 1700));
      ble.messages.add({
        ...phone('com.whatsapp', 'Priya', 'Another one'),
        'canReply': true,
      });
      await Future<void>.delayed(Duration.zero);
      expect(ble.sent.last[11 + 5], WatchAppType.whatsApp.code);
      ble.messages.add({
        ...phone('com.google.android.gm', 'Boss', 'Report'),
        'canReply': false,
      });
      await Future<void>.delayed(const Duration(milliseconds: 1700));
      expect(ble.sent.last[11 + 5], WatchAppType.gmail.code);
    },
  );

  test('Weather command layouts', () {
    const report = WeatherReport(
      type: WatchWeather.rain,
      temperature: -3,
      max: 2,
      min: -6,
      humidity: 80,
      days: [
        DayForecast(type: WatchWeather.clear, max: 5, min: -1),
        DayForecast(type: WatchWeather.snow, max: 0, min: -4),
        DayForecast(type: WatchWeather.clouds, max: 3, min: 1),
        DayForecast(type: WatchWeather.drizzle, max: 4, min: 2),
        DayForecast(type: WatchWeather.other, max: 9, min: 9),
      ],
    );
    expect(buildWeatherCommand(report), [
      0x0A,
      0x04,
      4,
      0xFD,
      2,
      0xFA,
      80,
      0,
      0,
      0,
      0,
      0,
      0,
      1,
      5,
      0xFF,
      7,
      0,
      0xFC,
      2,
      3,
      1,
      0x12,
      4,
      2,
    ]);
    final legacy = buildLegacyWeatherCommand(report);
    expect(legacy.length, 20);
    expect(legacy.sublist(0, 9), [0x0A, 0x01, 4, 0xFD, 2, 0xFA, 80, 0, 0]);
    expect(legacy.sublist(9, 12), [1, 5, 0xFF]);
    expect(usesNewWeatherFormat(protocolVersion: 0x0301, deviceId: 5), isTrue);
    expect(
      usesNewWeatherFormat(protocolVersion: 0x0201, deviceId: 0x1fa),
      isTrue,
    );
    expect(usesNewWeatherFormat(protocolVersion: 0x0201, deviceId: 5), isFalse);
  });

  test('WMO codes map to the watch weather types', () {
    expect(weatherFromWmo(0), WatchWeather.clear);
    expect(weatherFromWmo(2), WatchWeather.clouds);
    expect(weatherFromWmo(45), WatchWeather.other);
    expect(weatherFromWmo(53), WatchWeather.drizzle);
    expect(weatherFromWmo(63), WatchWeather.rain);
    expect(weatherFromWmo(81), WatchWeather.rain);
    expect(weatherFromWmo(73), WatchWeather.snow);
    expect(weatherFromWmo(95), WatchWeather.thunderstorm);
  });

  test('Open-Meteo responses become a report with four future days', () {
    final report = parseOpenMeteo({
      'current': {
        'temperature_2m': 21.6,
        'relative_humidity_2m': 55,
        'weather_code': 1,
      },
      'daily': {
        'weather_code': [1, 61, 0, 3, 95],
        'temperature_2m_max': [24.2, 20.0, 22.0, 19.5, 18.0],
        'temperature_2m_min': [14.0, 12.0, 13.0, 11.5, 10.0],
      },
    });
    expect(report.temperature, 22);
    expect(report.max, 24);
    expect(report.days, hasLength(4));
    expect(report.days.first.type, WatchWeather.rain);
    expect(report.days.last.type, WatchWeather.thunderstorm);
  });

  test(
    'Sending weather uses the format for the device and reports status',
    () async {
      final ble = _Ble();
      final controller = SilenceController(
        transport: ble,
        weather: _FakeWeather(),
        autoRefreshStatus: false,
      );
      addTearDown(() {
        controller.dispose();
        ble.messages.close();
      });
      await controller.sendWeather();
      expect(controller.weatherStatus, contains('Choose a place'));
      await controller.chooseWeatherPlace(
        const WeatherPlace(name: 'Testville', latitude: 1, longitude: 2),
      );
      const device = DiscoveredDevice(
        id: 'AA:BB:CC:DD:EE:FF',
        name: 'Pulse',
        rssi: -40,
      );
      await controller.connect(device);
      ble.messages
        ..add({'type': 'connection', 'id': device.id, 'state': 'connected'})
        ..add({
          'type': 'pair',
          'stage': 'bindResult',
          'state': 0,
          'success': true,
        })
        ..add({
          'type': 'pair',
          'stage': 'deviceInfo',
          'fields': [2109, 1, 0, 0, 55, 0, 0, 1, 0, 0, 0, 0x30a, 1],
        });
      await controller.sendWeather();
      expect(ble.raw.single.sublist(0, 2), [0x0A, 0x04]);
      expect(controller.weatherStatus, contains('Testville'));
      expect(controller.lastWeather?.temperature, 20);
    },
  );

  test('Reply list sync sends only the slots that changed', () async {
    final ble = _Ble();
    final controller = SilenceController(
      transport: ble,
      autoRefreshStatus: false,
    );
    addTearDown(() {
      controller.dispose();
      ble.messages.close();
    });
    const device = DiscoveredDevice(
      id: 'AA:BB:CC:DD:EE:FF',
      name: 'Pulse',
      rssi: -40,
    );
    await controller.connect(device);
    ble.messages
      ..add({'type': 'connection', 'id': device.id, 'state': 'connected'})
      ..add({
        'type': 'pair',
        'stage': 'bindResult',
        'state': 0,
        'success': true,
      });
    await controller.setWatchReplies(['a', 'b', 'c', 'd', 'e']);
    expect(ble.sent, hasLength(5));
    await controller.setWatchReplies(['a', 'b', 'X', 'd', 'e']);
    expect(ble.sent, hasLength(6));
    await controller.setWatchReplies(['a', 'b', 'X', 'd', 'e']);
    expect(ble.sent, hasLength(6));
    expect(controller.presetStatus, contains('up to date'));
    await controller.setWatchReplies(['a', 'b', 'X', 'd', 'e'], force: true);
    expect(ble.sent, hasLength(11));
  });
}

class _FakeWeather implements WeatherService {
  @override
  Future<List<WeatherPlace>> search(String query) async => const [];
  @override
  Future<WeatherReport> fetch(WeatherPlace place) async => const WeatherReport(
    type: WatchWeather.clear,
    temperature: 20,
    max: 24,
    min: 15,
    humidity: 40,
    days: [DayForecast(type: WatchWeather.rain, max: 18, min: 12)],
  );
}
