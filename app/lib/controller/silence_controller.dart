import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../services/ble_transport.dart';
import '../services/phone_notifications.dart';
import '../services/reply_suggester.dart';
import '../services/settings_store.dart';
import '../services/touchgui_notification.dart';
import '../services/touchgui_weather.dart';
import '../services/weather_service.dart';

@immutable
class DiscoveredDevice {
  const DiscoveredDevice({
    required this.id,
    required this.name,
    required this.rssi,
  });
  final String id;
  final String name;
  final int rssi;
}

/// One notification the relay handled, for the on-screen log.
@immutable
class RelayEntry {
  const RelayEntry(this.time, this.app, this.title, this.outcome);
  final DateTime time;
  final String app;
  final String title;
  final String outcome;
}

@immutable
class GattServiceInfo {
  const GattServiceInfo({
    required this.uuid,
    required this.characteristicCount,
  });
  final String uuid;
  final int characteristicCount;
}

/// Owns screen state. Only [pairWatch] triggers watch writes, on explicit user action.
class SilenceController extends ChangeNotifier {
  SilenceController({
    BleTransport? transport,
    SettingsStore? settings,
    WeatherService? weather,
    this.developerMode = false,
    this.autoRefreshStatus = true,
    ReplySuggester? suggester,
  }) : selectedTab = developerMode ? 0 : 1,
       _settings = settings ?? MemorySettingsStore(),
       _suggester = suggester ?? const MlKitSuggester(),
       _weatherService = weather ?? OpenMeteoWeatherService(),
       _transport = transport ?? AndroidBleTransport() {
    if (transport != null ||
        (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)) {
      _subscription = _transport.events.listen(
        _handleEvent,
        onError: _handleStreamError,
      );
    }
  }

  final BleTransport _transport;
  final SettingsStore _settings;
  final WeatherService _weatherService;
  bool _autoPair = false;

  /// The watch bound in an earlier session; saved after a successful bind.
  DiscoveredDevice? lastDevice;

  /// Connect to [lastDevice] when the app starts. Off by default because
  /// holding the connection keeps NoiseFit from reaching the watch.
  bool autoConnect = false;

  /// Sync the clock and read status after each bind. Tests turn this off to
  /// avoid long-lived timers.
  final bool autoRefreshStatus;
  StreamSubscription<Map<String, dynamic>>? _subscription;
  Timer? _demoTimer;
  Timer? _operationTimeout;
  bool _disposed = false;
  int _generation = 0;
  bool scanning = false;
  bool busy = false;
  bool releasing = false;
  bool demoMode = false;

  /// 0 = Device (developer tools), 1 = Studio.
  int selectedTab;
  bool developerMode;
  String status = 'Ready when you are';
  String? error;
  DiscoveredDevice? connectedDevice;
  String? _connectingId;
  DiscoveredDevice? _connectingDevice;
  final Map<String, DiscoveredDevice> _devices = {};
  List<GattServiceInfo> services = const [];

  /// TouchGUI bind progress; [pairSuccess] is null until the watch answers.
  bool pairing = false;
  String? pairStatus;
  bool? pairSuccess;
  final List<String> protocolLog = [];

  /// Watch-face upload state; [uploadSuccess] is null until the watch answers.
  bool uploading = false;
  int uploadPercent = 0;
  String? uploadStatus;
  bool? uploadSuccess;

  /// Notification demo state; [notifySuccess] is null until the watch replies.
  String? notifyStatus;
  bool? notifySuccess;
  int _sequence = 1;

  /// Phone notification relay. Needs Android notification access and a bound watch.
  bool accessGranted = false;
  bool relayEnabled = false;
  bool includeText = true;
  final Set<String> disabledApps = {};
  final Set<String> seenApps = {};
  final List<RelayEntry> relayLog = [];
  final List<
    ({
      WatchAppType app,
      String name,
      String number,
      String content,
      String label,
      String title,
      String key,
      bool canReply,
    })
  >
  _relayQueue = [];
  final Map<String, DateTime> _recent = {};

  /// The most recent notification sent to the watch; a quick reply answers it.
  ({String key, String label, bool canReply})? _lastRelayed;

  /// Preset replies offered on the watch (up to five), and whether the watch
  /// may drive music and volume.
  static const defaultQuickReplies = [
    'OK',
    'Can\u2019t talk now',
    'On my way',
    'I\u2019ll call you later',
    'Thanks',
  ];
  List<String> quickReplies = List.of(defaultQuickReplies);
  bool watchControls = true;

  /// The watch only offers quick replies on SMS-type notifications, so apps
  /// with an inline reply are sent as SMS (app name in the subtitle).
  bool replyAsSms = true;

  /// Whether replies are tailored to each incoming message before it is sent,
  /// and the longest the relay may wait for that.
  bool smartReplies = false;
  static const smartReplyBudget = Duration(milliseconds: 1500);
  final ReplySuggester _suggester;
  bool _relayBusy = false;
  final Map<String, List<String>> _history = {};
  String? presetStatus;
  final List<String> watchEvents = [];
  Timer? _relayTimer;

  /// Watch status from the battery, version and time-sync queries.
  int? batteryLevel;
  int? batteryState;
  int? batteryMillivolts;
  String? firmwareDetail;
  int? protocolVersion;
  DateTime? lastTimeSync;
  String? statusMessage;
  Timer? _statusTimer;

  /// Weather sent to the watch: chosen place, last report and status.
  WeatherPlace? weatherPlace;
  bool weatherEnabled = false;
  WeatherReport? lastWeather;
  String? weatherStatus;
  List<WeatherPlace> weatherResults = const [];
  int? deviceId;
  Timer? _weatherTimer;

  bool get canQuery =>
      !demoMode && connectedDevice != null && pairSuccess == true && !uploading;

  bool get canNotify =>
      !demoMode && connectedDevice != null && pairSuccess == true && !uploading;

  bool get canUpload =>
      !demoMode && connectedDevice != null && pairSuccess == true && !uploading;

  List<DiscoveredDevice> get devices {
    final values = _devices.values.toList();
    values.sort((a, b) => b.rssi.compareTo(a.rssi));
    return List.unmodifiable(values);
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  void selectTab(int value) {
    if (value < 0 || value > 1 || value == selectedTab) return;
    selectedTab = value;
    _changed();
  }

  /// Loads saved preferences and, if enabled, reconnects to the last watch.
  Future<void> restore() async {
    developerMode = await _settings.getString('developerMode') == 'true';
    autoConnect = await _settings.getString('autoConnect') == 'true';
    final saved = await _settings.getString('lastDevice');
    if (saved != null && saved.contains('|')) {
      final split = saved.indexOf('|');
      lastDevice = DiscoveredDevice(
        id: saved.substring(0, split),
        name: saved.substring(split + 1),
        rssi: -100,
      );
    }
    relayEnabled = await _settings.getString('relayEnabled') == 'true';
    includeText = await _settings.getString('includeText') != 'false';
    final disabled = await _settings.getString('disabledApps');
    if (disabled != null) {
      try {
        disabledApps
          ..clear()
          ..addAll((jsonDecode(disabled) as List).cast<String>());
      } catch (_) {}
    }
    weatherPlace = WeatherPlace.decode(
      await _settings.getString('weatherPlace'),
    );
    weatherEnabled = await _settings.getString('weatherEnabled') == 'true';
    watchControls = await _settings.getString('watchControls') != 'false';
    replyAsSms = await _settings.getString('replyAsSms') != 'false';
    smartReplies = await _settings.getString('smartReplies') == 'true';
    final replies = await _settings.getString('quickReplies');
    if (replies != null) {
      try {
        final list = (jsonDecode(replies) as List).cast<String>();
        if (list.length == 5) quickReplies = list;
      } catch (_) {}
    }
    await refreshAccess();
    if (_disposed) return;
    if (connectedDevice == null && !busy) selectedTab = developerMode ? 0 : 1;
    _changed();
    if (autoConnect && lastDevice != null && !developerMode) {
      await connectAndPair(lastDevice!);
    }
  }

  void setAutoConnect(bool value) {
    autoConnect = value;
    unawaited(_settings.setString('autoConnect', '$value'));
    _changed();
  }

  /// Re-reads whether Android notification access is granted.
  Future<void> refreshAccess() async {
    try {
      accessGranted = await _transport.notificationAccess();
    } catch (_) {
      accessGranted = false;
    }
    if (!accessGranted) relayEnabled = false;
    _changed();
  }

  Future<void> openNotificationAccessSettings() async {
    try {
      await _transport.openNotificationAccessSettings();
    } catch (e) {
      error = _message(e);
      _changed();
    }
  }

  void setRelayEnabled(bool value) {
    if (value && !accessGranted) return;
    relayEnabled = value;
    if (!value) {
      _relayQueue.clear();
      _relayTimer?.cancel();
    }
    unawaited(_settings.setString('relayEnabled', '$value'));
    _changed();
  }

  void setIncludeText(bool value) {
    includeText = value;
    unawaited(_settings.setString('includeText', '$value'));
    _changed();
  }

  void setAppEnabled(String package, bool enabled) {
    if (enabled) {
      disabledApps.remove(package);
    } else {
      disabledApps.add(package);
    }
    unawaited(
      _settings.setString('disabledApps', jsonEncode(disabledApps.toList())),
    );
    _changed();
  }

  Future<void> searchWeatherPlace(String query) async {
    if (query.trim().isEmpty) return;
    weatherStatus = 'Searching…';
    _changed();
    try {
      weatherResults = await _weatherService.search(query.trim());
      weatherStatus = weatherResults.isEmpty ? 'No places found.' : null;
    } catch (e) {
      weatherResults = const [];
      weatherStatus = 'Search failed: ${_message(e)}';
    }
    _changed();
  }

  Future<void> chooseWeatherPlace(WeatherPlace place) async {
    weatherPlace = place;
    weatherResults = const [];
    unawaited(_settings.setString('weatherPlace', place.encode()));
    _changed();
    if (weatherEnabled) await sendWeather();
  }

  void setWeatherEnabled(bool value) {
    weatherEnabled = value;
    unawaited(_settings.setString('weatherEnabled', '$value'));
    if (value) {
      unawaited(sendWeather());
      _startWeatherTimer();
    } else {
      _weatherTimer?.cancel();
    }
    _changed();
  }

  void _startWeatherTimer() {
    _weatherTimer?.cancel();
    _weatherTimer = Timer.periodic(const Duration(hours: 1), (_) {
      if (weatherEnabled && canQuery) unawaited(sendWeather());
    });
  }

  /// Fetches the forecast for the chosen place and sends it to the watch.
  Future<void> sendWeather() async {
    final place = weatherPlace;
    if (_disposed || place == null) {
      weatherStatus = 'Choose a place first.';
      _changed();
      return;
    }
    if (!canQuery) {
      weatherStatus = 'Connect and pair your watch first.';
      _changed();
      return;
    }
    weatherStatus = 'Fetching weather…';
    _changed();
    try {
      final report = await _weatherService.fetch(place);
      final newFormat = usesNewWeatherFormat(
        protocolVersion: protocolVersion ?? 0,
        deviceId: deviceId ?? 0,
      );
      await _transport.rawCommand(
        newFormat
            ? buildWeatherCommand(report)
            : buildLegacyWeatherCommand(report),
      );
      lastWeather = report;
      weatherStatus =
          'Sent ${report.temperature}\u00b0C ${report.type.name} for ${place.name} (${newFormat ? 'new' : 'legacy'} format).';
    } catch (e) {
      weatherStatus = 'Weather failed: ${_message(e)}';
    }
    _changed();
  }

  void setWatchControls(bool value) {
    watchControls = value;
    unawaited(_settings.setString('watchControls', '$value'));
    _changed();
  }

  void setSmartReplies(bool value) {
    smartReplies = value;
    unawaited(_settings.setString('smartReplies', '$value'));
    if (!value) unawaited(setWatchReplies(quickReplies));
    _changed();
  }

  void setReplyAsSms(bool value) {
    replyAsSms = value;
    unawaited(_settings.setString('replyAsSms', '$value'));
    _changed();
  }

  void setQuickReply(int index, String text) {
    if (index < 0 || index >= quickReplies.length) return;
    quickReplies[index] = text;
    unawaited(_settings.setString('quickReplies', jsonEncode(quickReplies)));
  }

  /// Sends the saved preset replies to the watch (all five, even if unchanged).
  void sendQuickReplyPresets() =>
      unawaited(setWatchReplies(quickReplies, force: true));

  /// Reply list last confirmed on the watch; null where unknown.
  final List<String?> _watchReplies = List.filled(5, null);
  List<String>? _replyTarget;
  bool _replySyncing = false;
  Completer<void>? _presetAck;

  /// Last reply sync duration in milliseconds, for latency tuning.
  int? replySyncMillis;

  /// Brings the watch's reply list to [replies], sending only slots that
  /// differ from what it already holds and waiting for each confirmation.
  /// A call made while a sync is running replaces the pending target.
  Future<void> setWatchReplies(
    List<String> replies, {
    bool force = false,
  }) async {
    if (_disposed || !canQuery || replies.length != 5) return;
    _replyTarget = List.of(replies);
    if (force) _watchReplies.fillRange(0, 5, null);
    if (_replySyncing) return;
    _replySyncing = true;
    final clock = Stopwatch()..start();
    var sent = 0;
    presetStatus = 'Sending replies…';
    _changed();
    try {
      while (_replyTarget != null && !_disposed && canQuery) {
        final target = _replyTarget!;
        _replyTarget = null;
        for (var i = 0; i < target.length; i++) {
          if (_watchReplies[i] == target[i]) continue;
          _sequence = nextSequence(_sequence);
          final ack = _presetAck = Completer<void>();
          await _transport.sendLongCommand(
            buildQuickReplyPresetMessage(
              count: target.length,
              index: i + 1,
              text: target[i],
              sequence: _sequence,
            ),
          );
          await ack.future.timeout(
            const Duration(milliseconds: 1500),
            onTimeout: () {},
          );
          _watchReplies[i] = target[i];
          sent++;
        }
      }
      replySyncMillis = clock.elapsedMilliseconds;
      presetStatus = sent == 0
          ? 'Watch replies already up to date.'
          : 'Updated $sent ${sent == 1 ? 'reply' : 'replies'} in $replySyncMillis ms.';
    } catch (e) {
      _watchReplies.fillRange(0, 5, null);
      presetStatus = _message(e);
    } finally {
      _replySyncing = false;
      _presetAck = null;
      _changed();
    }
  }

  /// Latency experiment: sends a message with reply list A, then swaps to
  /// list B [delay] later. If the watch shows B when Reply is tapped after the
  /// swap, it reads replies at tap time and updates can run after the notice.
  Future<void> runReplyTimingTest({
    Duration delay = const Duration(seconds: 6),
  }) async {
    if (_disposed || !canNotify) return;
    await setWatchReplies(const ['A1', 'A2', 'A3', 'A4', 'A5']);
    await sendDemoNotification(
      app: WatchAppType.sms,
      name: 'Reply test',
      content: 'Wait ${delay.inSeconds} s, open this, tap Reply: A or B?',
    );
    _after(
      delay,
      () => unawaited(setWatchReplies(const ['B1', 'B2', 'B3', 'B4', 'B5'])),
    );
  }

  void _logWatchEvent(String text) {
    watchEvents.insert(0, text);
    if (watchEvents.length > 10) watchEvents.removeLast();
  }

  Future<void> _handleWatchEvent(Map<String, dynamic> event) async {
    if (event['kind'] == 'quickReply') {
      final text = event['text'] as String? ?? '';
      final target = _lastRelayed;
      if (target == null || !target.canReply) {
        _logWatchEvent('Reply "$text": nothing to reply to');
      } else {
        var sent = false;
        try {
          sent = await _transport.replyToNotification(target.key, text);
        } catch (_) {}
        _logWatchEvent(
          'Reply "$text" to ${target.label}: ${sent ? 'sent' : 'failed'}',
        );
        _log(
          target.label,
          'Reply: $text',
          sent ? 'reply sent' : 'reply failed',
        );
      }
      _changed();
      return;
    }
    final category = event['category'] as int? ?? -1;
    final code = (event['code'] as num?)?.toInt() ?? -1;
    String? action;
    if (category == 1) {
      action = const {
        1: 'play',
        2: 'pause',
        4: 'previous',
        5: 'next',
        8: 'volumeUp',
        9: 'volumeDown',
      }[code];
    }
    if (action != null && watchControls) {
      _logWatchEvent('Watch: $action');
      try {
        await _transport.mediaControl(action);
      } catch (_) {}
    } else {
      _logWatchEvent(
        'Watch event $category/$code${action == null ? ' (not handled)' : ' (controls off)'}',
      );
    }
    _changed();
  }

  void _log(String app, String title, String outcome) {
    relayLog.insert(0, RelayEntry(DateTime.now(), app, title, outcome));
    if (relayLog.length > 20) relayLog.removeLast();
  }

  void _handlePhoneNotification(Map<String, dynamic> event) {
    if (!relayEnabled) return;
    final n = PhoneNotification.fromEvent(event);
    final mapped = mapNotification(n, includeText: includeText);
    if (mapped == null) return;
    seenApps.add(n.package);
    if (disabledApps.contains(n.package)) return;
    final fingerprint = '${n.package}|${n.title}|${n.text}';
    final now = DateTime.now();
    _recent.removeWhere(
      (_, t) => now.difference(t) > const Duration(seconds: 30),
    );
    final last = _recent[fingerprint];
    if (last != null && now.difference(last) < const Duration(seconds: 5)) {
      return;
    }
    _recent[fingerprint] = now;
    if (!canNotify) {
      _log(mapped.app.label, n.title, 'skipped: watch not ready');
      return;
    }
    if (_relayQueue.length >= 10) _relayQueue.removeAt(0);
    final canReply = event['canReply'] == true;
    final asSms = replyAsSms && canReply && mapped.app.type != WatchAppType.sms;
    _relayQueue.add((
      app: asSms ? WatchAppType.sms : mapped.app.type,
      name: mapped.name,
      number: asSms && mapped.number.isEmpty ? mapped.app.label : mapped.number,
      content: mapped.content,
      label: mapped.app.label,
      title: n.title,
      key: n.key,
      canReply: canReply,
    ));
    _pumpRelay();
  }

  /// Reply list for [message]: the first two saved presets stay fixed and the
  /// rest follow the message, padded from the saved presets.
  Future<List<String>> _smartReplies(String sender, String message) async {
    final past = _history.putIfAbsent(sender, () => []);
    final suggested = await _suggester.suggest(
      ReplyContext(sender: sender, text: message, history: List.of(past)),
    );
    past.add(message);
    if (past.length > 5) past.removeAt(0);
    return [
      quickReplies[0],
      quickReplies[1],
      for (var i = 0; i < 3; i++)
        i < suggested.length ? suggested[i] : quickReplies[2 + i],
    ];
  }

  void _pumpRelay() {
    if (_relayTimer != null || _relayBusy || _relayQueue.isEmpty) return;
    final next = _relayQueue.removeAt(0);
    _relayBusy = true;
    unawaited(() async {
      if (smartReplies &&
          next.canReply &&
          next.content.isNotEmpty &&
          canQuery) {
        try {
          final replies = await _smartReplies(next.title, next.content);
          await setWatchReplies(replies).timeout(smartReplyBudget);
        } catch (_) {
          // Late or failed: send with whatever list the watch already has.
        }
      }
      if (_disposed) return;
      _lastRelayed = (
        key: next.key,
        label: next.label,
        canReply: next.canReply,
      );
      await sendDemoNotification(
        app: next.app,
        name: next.name,
        number: next.number,
        content: next.content,
      );
      _log(
        next.label,
        next.title,
        notifySuccess == false ? 'failed: $notifyStatus' : 'sent',
      );
      _relayBusy = false;
      _changed();
      _relayTimer = Timer(const Duration(milliseconds: 1500), () {
        _relayTimer = null;
        if (!_disposed) _pumpRelay();
      });
    }());
  }

  /// Connects, then runs the bind handshake as soon as services are known.
  Future<void> connectAndPair(DiscoveredDevice device) async {
    if (_disposed || busy || connectedDevice != null) return;
    _autoPair = true;
    await connect(device);
    if (!busy) _autoPair = false;
  }

  Future<void> forgetWatch() async {
    if (connectedDevice != null) return;
    lastDevice = null;
    await _settings.remove('lastDevice');
    _changed();
  }

  /// Shows the developer tools. Safe at any time; it only changes visibility.
  void setDeveloperMode(bool value) {
    if (value == developerMode) return;
    developerMode = value;
    if (!value || connectedDevice == null) selectedTab = value ? 0 : 1;
    unawaited(_settings.setString('developerMode', '$value'));
    _changed();
  }

  void clearError() {
    error = null;
    _changed();
  }

  Future<void> scan() async {
    if (_disposed || busy || scanning || connectedDevice != null) return;
    error = null;
    _devices.clear();
    status = demoMode ? 'Finding a sample watch…' : 'Starting discovery…';
    scanning = true;
    _changed();
    if (demoMode) {
      _demoTimer?.cancel();
      _demoTimer = Timer(const Duration(milliseconds: 650), () {
        if (_disposed || !demoMode) return;
        _devices['demo-pulse-2'] = const DiscoveredDevice(
          id: 'demo-pulse-2',
          name: 'ColorFit Pulse 2 · sample',
          rssi: -52,
        );
        scanning = false;
        status = 'Sample watch found';
        _changed();
      });
      return;
    }
    final generation = _generation;
    try {
      await _transport.scan();
      if (_disposed || generation != _generation) return;
      // Native scanState ends the scan; allow permission dialogs time to resolve.
      _operationTimeout?.cancel();
      if (scanning) {
        _operationTimeout = Timer(const Duration(seconds: 60), () {
          if (!_disposed && scanning && !demoMode) {
            unawaited(_transport.stopScan().catchError((Object _) {}));
            _fail(
              'Discovery did not start or finish. Check Bluetooth permissions and try again.',
            );
          }
        });
      }
    } catch (e) {
      if (generation == _generation) _fail(_message(e));
    }
  }

  Future<void> connect(DiscoveredDevice device) async {
    if (_disposed || busy || connectedDevice != null) return;
    error = null;
    busy = true;
    scanning = false;
    services = const [];
    _connectingId = device.id;
    _connectingDevice = device;
    status = 'Connecting to ${device.name}…';
    _operationTimeout?.cancel();
    _demoTimer?.cancel();
    _changed();
    if (demoMode) {
      _demoTimer = Timer(const Duration(milliseconds: 500), () {
        if (_disposed || !demoMode) return;
        connectedDevice = device;
        _connectingId = null;
        busy = false;
        // Deliberately no fabricated services, version or battery data.
        status = 'Sample connection · no watch contacted';
        _changed();
      });
      return;
    }
    final generation = _generation;
    try {
      await _transport.stopScan();
      if (_disposed || generation != _generation) return;
      await _transport.connect(device.id);
      if (!_disposed && generation == _generation && busy) {
        _watchForCompletion(generation);
      }
    } catch (e) {
      if (generation == _generation) _fail(_message(e));
    }
  }

  Future<void> disconnect() async {
    if (_disposed || busy) return;
    _demoTimer?.cancel();
    _operationTimeout?.cancel();
    error = null;
    busy = true;
    _changed();
    final generation = _generation;
    try {
      if (!demoMode) await _transport.disconnect();
      if (_disposed || generation != _generation) return;
      connectedDevice = null;
      _connectingId = null;
      services = const [];
      busy = false;
      status = demoMode ? 'Design preview ready' : 'Disconnected';
      _changed();
    } catch (e) {
      if (generation == _generation) _fail(_message(e));
    }
  }

  /// Emergency local release, available even during a pending connection.
  /// Does not send a vendor unbind/reset or remove an Android system bond.
  /// Runs the bind handshake. The watch should leave the QR screen when it succeeds.
  Future<void> pairWatch() async {
    if (_disposed || demoMode || pairing || connectedDevice == null || busy) {
      return;
    }
    pairing = true;
    pairSuccess = null;
    pairStatus = 'Starting…';
    protocolLog.clear();
    _changed();
    try {
      await _transport.pair();
    } catch (e) {
      pairing = false;
      pairStatus = _message(e);
      _changed();
    }
  }

  void _resetPairing() {
    _autoPair = false;
    _watchReplies.fillRange(0, 5, null);
    _replyTarget = null;
    _cancelPendingTimers();
    batteryLevel = null;
    batteryState = null;
    batteryMillivolts = null;
    firmwareDetail = null;
    lastTimeSync = null;
    statusMessage = null;
    notifyStatus = null;
    notifySuccess = null;
    uploading = false;
    uploadStatus = null;
    uploadSuccess = null;
    uploadPercent = 0;
    pairing = false;
    pairStatus = null;
    pairSuccess = null;
  }

  /// Sends a finished `.watch` file. Requires a successful [pairWatch].
  Future<void> sendWatchFace(Uint8List bytes) async {
    if (_disposed || !canUpload) return;
    uploading = true;
    uploadSuccess = null;
    uploadPercent = 0;
    uploadStatus = 'Starting…';
    _changed();
    try {
      await _transport.uploadWatchFile(bytes);
    } catch (e) {
      uploading = false;
      uploadSuccess = false;
      uploadStatus = _message(e);
      _changed();
    }
  }

  /// Sends one notification to the watch (a protocol test, not a relay).
  Future<void> sendDemoNotification({
    required WatchAppType app,
    String name = '',
    String number = '',
    String content = '',
    bool invert = false,
  }) async {
    if (_disposed || !canNotify) return;
    _sequence = nextSequence(_sequence);
    notifySuccess = null;
    notifyStatus = 'Sending…';
    _changed();
    try {
      await _transport.sendLongCommand(
        buildNotificationMessage(
          app: app,
          name: name,
          number: number,
          content: content,
          sequence: _sequence,
          invert: invert,
        ),
      );
    } catch (e) {
      notifySuccess = false;
      notifyStatus = _message(e);
      _changed();
    }
  }

  final Set<Timer> _pendingTimers = {};

  /// Runs [action] after [delay] unless the controller is disposed or reset first.
  void _after(Duration delay, void Function() action) {
    late Timer timer;
    timer = Timer(delay, () {
      _pendingTimers.remove(timer);
      if (!_disposed) action();
    });
    _pendingTimers.add(timer);
  }

  void _cancelPendingTimers() {
    for (final timer in _pendingTimers) {
      timer.cancel();
    }
    _pendingTimers.clear();
    _statusTimer?.cancel();
    _weatherTimer?.cancel();
  }

  /// Asks the watch for battery and version, spaced so replies do not collide.
  Future<void> refreshWatchStatus() async {
    if (_disposed || !canQuery) return;
    statusMessage = 'Reading watch status…';
    _changed();
    await _statusCommand('battery');
    _after(const Duration(milliseconds: 400), () {
      if (canQuery) unawaited(_statusCommand('version'));
    });
  }

  Future<void> syncWatchTime() async {
    if (_disposed || !canQuery) return;
    statusMessage = 'Syncing time…';
    _changed();
    await _statusCommand('time');
  }

  Future<void> _statusCommand(String kind) async {
    try {
      await _transport.statusCommand(kind);
    } catch (e) {
      statusMessage = _message(e);
      _changed();
    }
  }

  /// Runs once per bind: sets the clock, then reads status, then keeps it fresh.
  Future<void> _afterBind() async {
    if (!autoRefreshStatus) return;
    await syncWatchTime();
    _after(
      const Duration(milliseconds: 500),
      () => unawaited(refreshWatchStatus()),
    );
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (canQuery) unawaited(_statusCommand('battery'));
    });
    if (weatherEnabled && weatherPlace != null) {
      _after(const Duration(seconds: 2), () => unawaited(sendWeather()));
      _startWeatherTimer();
    }
  }

  Future<void> applyWatchFace() async {
    if (_disposed || demoMode || connectedDevice == null || uploading) return;
    try {
      await _transport.applyDial();
      uploadStatus = 'Apply command sent. Check the watch.';
    } catch (e) {
      uploadStatus = _message(e);
    }
    _changed();
  }

  Future<bool> unpair() async {
    if (_disposed || releasing) return false;
    final generation = ++_generation;
    releasing = true;
    busy = true;
    _demoTimer?.cancel();
    _operationTimeout?.cancel();
    scanning = false;
    connectedDevice = null;
    _connectingId = null;
    services = const [];
    _resetPairing();
    _devices.clear();
    error = null;
    status = 'Releasing the watch from Silence…';
    _changed();
    try {
      if (!demoMode) {
        await _transport.releaseDevice().timeout(const Duration(seconds: 5));
      }
      if (_disposed || generation != _generation) return false;
      status = demoMode
          ? 'Sample connection cleared'
          : 'Released from Silence. Open NoiseFit and add your device.';
      return true;
    } catch (e) {
      if (!_disposed && generation == _generation) {
        error =
            '${_message(e)} Force-stop Silence in Android Settings, then retry NoiseFit.';
        status = 'Release could not be confirmed';
      }
      return false;
    } finally {
      if (!_disposed && generation == _generation) {
        releasing = false;
        busy = false;
        _changed();
      }
    }
  }

  Future<void> openBluetoothSettings() async {
    if (_disposed || demoMode) return;
    try {
      await _transport.openBluetoothSettings();
    } catch (e) {
      _fail(_message(e));
    }
  }

  Future<void> refreshServices() async {
    if (_disposed || busy || connectedDevice == null) return;
    if (demoMode) {
      status = 'Sample connection has no real Bluetooth services';
      _changed();
      return;
    }
    error = null;
    busy = true;
    status = 'Inspecting Bluetooth services…';
    _changed();
    final generation = _generation;
    try {
      await _transport.discoverServices();
      if (!_disposed && generation == _generation && busy) {
        _watchForCompletion(generation);
      }
    } catch (e) {
      if (generation == _generation) _fail(_message(e));
    }
  }

  void setDemoMode(bool value) {
    if (_disposed || demoMode == value || busy) return;
    _generation++;
    _demoTimer?.cancel();
    _operationTimeout?.cancel();
    final wasReal = !demoMode;
    demoMode = value;
    scanning = false;
    connectedDevice = null;
    _connectingId = null;
    services = const [];
    _devices.clear();
    error = null;
    status = value ? 'Design preview ready' : 'Ready when you are';
    // Native channel calls are serialized. Switching modes terminates real use.
    if (wasReal && !kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      unawaited(_transport.stopScan().catchError((Object _) {}));
      unawaited(_transport.disconnect().catchError((Object _) {}));
    }
    _changed();
  }

  void _handleEvent(Map<String, dynamic> event) {
    if (_disposed || demoMode || releasing) return;
    switch (event['type']) {
      case 'scanState':
        scanning = event['scanning'] == true;
        if (scanning) {
          status = 'Looking for nearby Bluetooth devices…';
        } else {
          _operationTimeout?.cancel();
          if (!busy && connectedDevice == null && error == null) {
            status = _devices.isEmpty
                ? 'No devices found. Move closer and try again.'
                : 'Choose your watch';
          }
        }
      case 'device':
        final id = event['id'];
        if (!scanning || id is! String || id.isEmpty) return;
        _devices[id] = DiscoveredDevice(
          id: id,
          name: event['name'] is String
              ? event['name'] as String
              : 'Unnamed device',
          rssi: (event['rssi'] as num?)?.toInt() ?? -100,
        );
      case 'connection':
        final id = event['id'] as String?;
        // Ignore events for a previous connection attempt or an old session.
        final expected = _connectingId ?? connectedDevice?.id;
        if (expected == null || id != expected) return;
        switch (event['state']) {
          case 'connecting':
            busy = true;
            status = 'Connecting…';
          case 'connected':
            connectedDevice =
                _devices[id] ??
                _connectingDevice ??
                DiscoveredDevice(
                  id: id!,
                  name: event['name'] as String? ?? 'Connected device',
                  rssi: -100,
                );
            _connectingId = null;
            busy = true;
            status = 'Connected · inspecting services…';
          case 'disconnected':
            _operationTimeout?.cancel();
            connectedDevice = null;
            _connectingId = null;
            services = const [];
            _resetPairing();
            busy = false;
            status = 'Disconnected';
        }
      case 'services':
        if (connectedDevice == null || event['id'] != connectedDevice!.id) {
          return;
        }
        _operationTimeout?.cancel();
        services = List.unmodifiable(
          ((event['services'] as List?) ?? []).map((raw) {
            final service = Map<String, dynamic>.from(raw as Map);
            return GattServiceInfo(
              uuid: service['uuid'] as String,
              characteristicCount: (service['characteristicCount'] as num)
                  .toInt(),
            );
          }),
        );
        busy = false;
        status = 'Connected · ${services.length} services discovered';
        if (_autoPair) {
          _autoPair = false;
          scheduleMicrotask(pairWatch);
        }
      case 'status':
        if (connectedDevice == null) return;
        switch (event['kind']) {
          case 'battery':
            batteryLevel = (event['level'] as num?)?.toInt() ?? batteryLevel;
            batteryState = (event['state'] as num?)?.toInt();
            batteryMillivolts = (event['voltage'] as num?)?.toInt();
            statusMessage = null;
          case 'version':
            final detail = event['detail'] as String?;
            firmwareDetail = (detail == null || detail.isEmpty)
                ? 'sdk ${event['sdk']}'
                : detail;
            statusMessage = null;
          case 'time':
            lastTimeSync = DateTime.now();
            statusMessage = 'Time synced (status ${event['status']}).';
        }
      case 'phoneNotification':
        _handlePhoneNotification(event);
        return;
      case 'watchEvent':
        unawaited(_handleWatchEvent(event));
        return;
      case 'presetReply':
        final ack = _presetAck;
        if (ack != null && !ack.isCompleted) ack.complete();

      case 'notify':
        if (connectedDevice == null) return;
        switch (event['stage']) {
          case 'sent':
            notifyStatus =
                'Sent ${event['bytes']} bytes. Waiting for the watch…';
          case 'reply':
            notifySuccess = true;
            notifyStatus =
                'Watch replied: status ${event['status']} (command ${event['command']}, sequence ${event['sequence']}). Check the watch.';
          case 'failed':
            notifySuccess = false;
            notifyStatus =
                event['message'] as String? ?? 'Notification failed.';
        }
      case 'upload':
        if (connectedDevice == null) return;
        switch (event['stage']) {
          case 'progress':
            uploadPercent =
                (event['percent'] as num?)?.toInt() ?? uploadPercent;
            uploadStatus = event['message'] as String?;
          case 'done':
            uploading = false;
            uploadSuccess = true;
            uploadPercent = 100;
            uploadStatus = 'Uploaded. Check the watch.';
          case 'failed':
            uploading = false;
            uploadSuccess = false;
            uploadStatus = event['message'] as String? ?? 'Upload failed.';
        }
      case 'protocol':
        if (connectedDevice == null) return;
        protocolLog.add('${event['dir']} ${event['channel']} ${event['hex']}');
        if (protocolLog.length > 200) protocolLog.removeAt(0);
      case 'pair':
        if (connectedDevice == null) return;
        switch (event['stage']) {
          case 'progress':
            pairStatus = event['message'] as String?;
          case 'deviceInfo':
            pairStatus = 'Device info: ${event['fields']}';
            final fields = (event['fields'] as List?)?.cast<num>();
            if (fields != null && fields.length >= 13) {
              batteryLevel = fields[4].toInt();
              protocolVersion = fields[11].toInt();
              deviceId = fields[0].toInt();
            }
          case 'bindResult':
            pairing = false;
            pairSuccess = event['success'] == true;
            if (pairSuccess! && connectedDevice != null) {
              scheduleMicrotask(_afterBind);
              lastDevice = connectedDevice;
              unawaited(
                _settings.setString(
                  'lastDevice',
                  '${connectedDevice!.id}|${connectedDevice!.name}',
                ),
              );
            }
            pairStatus = pairSuccess!
                ? 'Bound. The watch should leave the QR screen.'
                : 'The watch refused the bind (state ${event['state']}).';
          case 'failed':
            pairing = false;
            pairSuccess = false;
            pairStatus = event['message'] as String? ?? 'Pairing failed.';
        }
      case 'error':
        _fail(event['message'] as String? ?? 'Bluetooth operation failed.');
        return;
      default:
        return;
    }
    _changed();
  }

  void _watchForCompletion(int generation) {
    _operationTimeout?.cancel();
    _operationTimeout = Timer(const Duration(seconds: 60), () {
      if (_disposed || generation != _generation || !busy) return;
      connectedDevice = null;
      services = const [];
      _fail(
        'The Bluetooth operation timed out. Check permissions, release the watch from NoiseFit, and reconnect.',
      );
      unawaited(_transport.disconnect().catchError((Object _) {}));
    });
  }

  void _handleStreamError(Object error) => _fail(_message(error));

  void _fail(String message) {
    if (_disposed) return;
    _autoPair = false;
    _operationTimeout?.cancel();
    busy = false;
    scanning = false;
    _connectingId = null;
    error = message;
    status = 'Action needed';
    _changed();
  }

  String _message(Object error) => error is PlatformException
      ? error.message ?? 'Bluetooth operation failed (${error.code}).'
      : 'Unable to complete this Bluetooth operation. $error';

  @override
  void dispose() {
    _relayTimer?.cancel();
    _cancelPendingTimers();
    _disposed = true;
    _demoTimer?.cancel();
    _operationTimeout?.cancel();
    unawaited(_subscription?.cancel());
    // Cancelling the native event subscription releases scan and GATT resources.
    super.dispose();
  }
}
