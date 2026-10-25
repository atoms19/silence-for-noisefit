// Socket-free smoke/render runner for restricted CI. Not an app entry point.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:silence_app/controller/silence_controller.dart';
import 'package:silence_app/services/ble_transport.dart';
import 'package:silence_app/studio/artwork.dart';
import 'package:silence_app/ui/silence_shell.dart';
import 'package:silence_app/ui/silence_theme.dart';

class _PreviewBinding extends WidgetsFlutterBinding {
  Size size = const Size(390, 844);
  @override
  ViewConfiguration createViewConfigurationFor(RenderView renderView) =>
      ViewConfiguration(
        logicalConstraints: BoxConstraints.tight(size),
        physicalConstraints: BoxConstraints.tight(size),
        devicePixelRatio: 1,
      );
  void resize(Size value) {
    size = value;
    handleMetricsChanged();
  }
}

class _FakeBle implements BleTransport {
  final messages = StreamController<Map<String, dynamic>>.broadcast(sync: true);
  int scans = 0;
  int connects = 0;
  @override
  Stream<Map<String, dynamic>> get events => messages.stream;
  @override
  Future<void> scan() async => scans++;
  @override
  Future<void> stopScan() async {}
  @override
  Future<void> connect(String id) async => connects++;
  @override
  Future<void> disconnect() async {}
  @override
  Future<void> discoverServices() async {}
  @override
  Future<void> pair() async {}
  @override
  Future<void> rawCommand(Uint8List bytes) async {}
  @override
  Future<bool> replyToNotification(String key, String text) async => false;
  @override
  Future<void> mediaControl(String action) async {}
  @override
  Future<void> statusCommand(String kind) async {}
  @override
  Future<bool> notificationAccess() async => false;
  @override
  Future<void> openNotificationAccessSettings() async {}
  @override
  Future<void> sendLongCommand(Uint8List message) async {}
  @override
  Future<void> uploadWatchFile(Uint8List bytes) async {}
  @override
  Future<void> applyDial() async {}
  int releases = 0;
  @override
  Future<void> releaseDevice() async => releases++;
  @override
  Future<void> openBluetoothSettings() async {}
}

void require(bool condition, String message) {
  if (!condition) throw StateError(message);
}

Future<void> main() async {
  final binding = _PreviewBinding();
  final errors = <String>[];
  FlutterError.onError = (details) {
    errors.add(details.exceptionAsString());
    stderr.writeln(details);
  };
  try {
    final sdk = Platform.environment['FLUTTER_ROOT'];
    if (sdk != null) {
      final font = File(
        '$sdk/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
      );
      if (font.existsSync()) {
        await (FontLoader('Roboto')..addFont(
              Future.value(ByteData.sublistView(await font.readAsBytes())),
            ))
            .load();
      }
    }
    final transport = _FakeBle();
    final controller = SilenceController(
      transport: transport,
      developerMode: true,
    );
    final artwork = ArtworkController();
    require(
      transport.scans == 0 && transport.connects == 0,
      'Startup contacted a device',
    );
    await controller.scan();
    transport.messages.add({
      'type': 'device',
      'id': 'fixture-a',
      'name': 'Fixture watch',
      'rssi': -45,
    });
    transport.messages.add({
      'type': 'device',
      'id': 'fixture-a',
      'name': 'Fixture watch',
      'rssi': -42,
    });
    require(
      controller.devices.length == 1 && controller.devices.single.rssi == -42,
      'Scan result deduplication failed',
    );
    transport.messages.add({'type': 'scanState', 'scanning': false});
    await controller.connect(controller.devices.single);
    transport.messages.add({
      'type': 'connection',
      'id': 'stale-device',
      'state': 'connected',
    });
    require(controller.connectedDevice == null, 'Stale connection accepted');
    transport.messages.add({
      'type': 'connection',
      'id': 'fixture-a',
      'state': 'connected',
    });
    transport.messages.add({
      'type': 'services',
      'id': 'stale-device',
      'services': <Object>[],
    });
    require(controller.busy, 'Stale service event ended discovery');
    transport.messages.add({
      'type': 'services',
      'id': 'fixture-a',
      'services': [
        {'uuid': 'fixture-service', 'characteristicCount': 3},
      ],
    });
    require(
      !controller.busy && controller.services.single.characteristicCount == 3,
      'Discovery did not complete',
    );
    await controller.disconnect();
    require(
      controller.connectedDevice == null && controller.services.isEmpty,
      'Disconnect retained old data',
    );
    await controller.scan();
    transport.messages.add({
      'type': 'device',
      'id': 'pending-watch',
      'name': 'Pending watch',
      'rssi': -50,
    });
    await controller.connect(controller.devices.single);
    require(controller.busy, 'Fixture should be connecting');
    require(await controller.unpair(), 'Emergency release failed while busy');
    require(
      transport.releases == 1 && !controller.busy && controller.devices.isEmpty,
      'Emergency release did not clear ownership',
    );
    transport.messages.add({
      'type': 'connection',
      'id': 'pending-watch',
      'state': 'connected',
    });
    require(
      controller.connectedDevice == null,
      'Late callback restored a released connection',
    );
    final scansBeforeDemo = transport.scans;
    controller.setDemoMode(true);
    await controller.scan();
    await Future<void>.delayed(const Duration(milliseconds: 700));
    require(
      controller.devices.single.id == 'demo-pulse-2' &&
          transport.scans == scansBeforeDemo,
      'Demo used real scan transport',
    );
    controller.setDemoMode(false);
    require(
      controller.devices.isEmpty && controller.connectedDevice == null,
      'Preview mode leaked state',
    );

    final capture = GlobalKey();
    Future<void> render(
      double width,
      double scale,
      int tab,
      String name,
    ) async {
      binding.resize(Size(width, 1100));
      controller.selectTab(tab);
      runApp(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildSilenceTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              size: Size(width, 1100),
              textScaler: TextScaler.linear(scale),
            ),
            child: child!,
          ),
          home: RepaintBoundary(
            key: capture,
            child: SilenceShell(controller: controller, artwork: artwork),
          ),
        ),
      );
      binding.scheduleFrame();
      await binding.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 250));
      binding.scheduleFrame();
      await binding.endOfFrame;
      require(
        errors.isEmpty,
        'Layout errors at $width / $scale / $tab: $errors',
      );
      final boundary =
          capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/previews').create(recursive: true);
      await File(
        'build/previews/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    }

    await render(390, 1, 0, 'device');
    await render(390, 1, 1, 'studio');
    for (final width in [320.0, 800.0]) {
      for (final tab in [0, 1]) {
        await render(width, 1.5, tab, 'responsive-${width.toInt()}-$tab');
      }
    }
    VoidCallback findButton(String label) {
      VoidCallback? callback;
      void visit(Element element) {
        if (element.widget is ButtonStyleButton) {
          var matches = false;
          void text(Element child) {
            if (child.widget is Text && (child.widget as Text).data == label) {
              matches = true;
            }
            child.visitChildren(text);
          }

          element.visitChildren(text);
          if (matches)
            callback ??= (element.widget as ButtonStyleButton).onPressed;
        }
        element.visitChildren(visit);
      }

      binding.rootElement!.visitChildren(visit);
      if (callback == null) throw StateError('Missing enabled button: $label');
      return callback!;
    }

    findButton('Preview design')();
    binding.scheduleFrame();
    await binding.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    binding.scheduleFrame();
    await binding.endOfFrame;
    findButton('Back to collection')();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    binding.scheduleFrame();
    await binding.endOfFrame;
    await controller.scan();
    transport.messages.add({
      'type': 'device',
      'id': 'fixture-long',
      'name': 'ColorFit Pulse 2 with a longer advertised device name',
      'rssi': -49,
    });
    transport.messages.add({'type': 'scanState', 'scanning': false});
    await controller.connect(controller.devices.single);
    transport.messages.add({
      'type': 'connection',
      'id': 'fixture-long',
      'state': 'connected',
    });
    transport.messages.add({
      'type': 'services',
      'id': 'fixture-long',
      'services': [
        {
          'uuid': '0000180a-0000-1000-8000-00805f9b34fb',
          'characteristicCount': 3,
        },
      ],
    });
    await render(320, 1.5, 0, 'connected-compact');
    transport.messages.add({
      'type': 'error',
      'message': 'Permission was revoked. Reconnect to retry.',
    });
    require(
      controller.error != null && !controller.busy,
      'Error left operation busy',
    );
    await render(320, 1.5, 0, 'error-compact');
    findButton('Unpair / release watch')();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    binding.scheduleFrame();
    await binding.endOfFrame;
    require(
      controller.connectedDevice == null &&
          !controller.busy &&
          transport.releases == 2,
      'Release button did not release the connected device',
    );
    findButton('Done')();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    binding.scheduleFrame();
    await binding.endOfFrame;
    require(errors.isEmpty, 'Render errors: $errors');
    controller.dispose();
    await transport.messages.close();
    stdout.writeln(
      'PASS: controller discovery, deduplication, stale-event rejection, disconnect, demo isolation, emergency release while busy, late-callback rejection, visible release-button action; eight rendered layouts and watchface preview open/close without Flutter errors.',
    );
    exit(0);
  } catch (error, stack) {
    stderr.writeln('$error\n$stack');
    exit(1);
  }
}
