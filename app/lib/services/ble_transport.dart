import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// BLE transport; [pair] is the only operation that writes to the watch.
abstract interface class BleTransport {
  Stream<Map<String, dynamic>> get events;
  Future<void> scan();
  Future<void> stopScan();
  Future<void> connect(String id);
  Future<void> disconnect();
  Future<void> discoverServices();

  /// Runs the TouchGUI bind handshake on the current connection.
  Future<void> pair();

  /// Sends a finished `.watch` file over the bound connection.
  Future<void> uploadWatchFile(Uint8List bytes);

  /// Writes already-built short-command bytes (for example weather) to the watch.
  Future<void> rawCommand(Uint8List bytes);

  /// Queries the watch (`battery`, `version`) or syncs its clock (`time`); replies arrive as events.
  Future<void> statusCommand(String kind);

  /// Fires the original notification's inline reply with [text]; false if it is gone.
  Future<bool> replyToNotification(String key, String text);

  /// Applies a watch music or volume key (`play`, `pause`, `next`, `previous`, `volumeUp`, `volumeDown`).
  Future<void> mediaControl(String action);

  /// Whether the user granted this app notification access.
  Future<bool> notificationAccess();

  /// Opens Android's notification access settings.
  Future<void> openNotificationAccessSettings();

  /// Sends a framed `0x33` long command (such as a notification) in packets.
  Future<void> sendLongCommand(Uint8List message);

  /// Sends the apply-dial command for the photo face.
  Future<void> applyDial();
  Future<void> releaseDevice();
  Future<void> openBluetoothSettings();
}

class AndroidBleTransport implements BleTransport {
  static const _methods = MethodChannel('dev.silence/ble');
  static const _events = EventChannel('dev.silence/ble_events');

  @override
  Stream<Map<String, dynamic>> get events => _events
      .receiveBroadcastStream()
      .map((event) => Map<String, dynamic>.from(event as Map));

  Future<T?> _invoke<T>(String method, [Map<String, dynamic>? args]) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw PlatformException(
        code: 'UNSUPPORTED_PLATFORM',
        message:
            'Watch discovery currently runs on Android. Use design preview to explore the app here.',
      );
    }
    return _methods.invokeMethod<T>(method, args);
  }

  @override
  Future<void> scan() => _invoke('scan');
  @override
  Future<void> stopScan() => _invoke('stopScan');
  @override
  Future<void> connect(String id) => _invoke('connect', {'id': id});
  @override
  Future<void> disconnect() => _invoke('disconnect');
  @override
  Future<void> discoverServices() => _invoke('discoverServices');
  @override
  Future<void> pair() => _invoke('pair');
  @override
  Future<void> uploadWatchFile(Uint8List bytes) =>
      _invoke('uploadWatchFile', {'bytes': bytes});
  @override
  Future<void> rawCommand(Uint8List bytes) =>
      _invoke('rawCommand', {'bytes': bytes});
  @override
  Future<void> statusCommand(String kind) =>
      _invoke('statusCommand', {'kind': kind});
  @override
  Future<bool> replyToNotification(String key, String text) async =>
      (await _invoke<bool>('replyToNotification', {
        'key': key,
        'text': text,
      })) ??
      false;
  @override
  Future<void> mediaControl(String action) =>
      _invoke('mediaControl', {'action': action});
  @override
  Future<bool> notificationAccess() async =>
      (await _invoke<bool>('notificationAccess')) ?? false;
  @override
  Future<void> openNotificationAccessSettings() =>
      _invoke('openNotificationAccessSettings');
  @override
  Future<void> sendLongCommand(Uint8List message) =>
      _invoke('sendLongCommand', {'bytes': message});
  @override
  Future<void> applyDial() => _invoke('applyDial');
  @override
  Future<void> releaseDevice() => _invoke('releaseDevice');
  @override
  Future<void> openBluetoothSettings() => _invoke('openBluetoothSettings');
}
