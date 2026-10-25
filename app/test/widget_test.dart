import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silence_app/controller/silence_controller.dart';
import 'package:silence_app/services/ble_transport.dart';
import 'package:silence_app/services/settings_store.dart';
import 'package:silence_app/studio/artwork.dart';
import 'package:silence_app/ui/silence_shell.dart';
import 'package:silence_app/ui/silence_theme.dart';

class _Transport implements BleTransport {
  final messages = StreamController<Map<String, dynamic>>.broadcast(sync: true);
  int scanCount = 0;
  @override
  Stream<Map<String, dynamic>> get events => messages.stream;
  @override
  Future<void> scan() async => scanCount++;
  @override
  Future<void> stopScan() async {}
  @override
  Future<void> connect(String id) async {}
  @override
  Future<void> disconnect() async {}
  @override
  Future<void> discoverServices() async {}
  int pairs = 0;
  @override
  Future<void> pair() async => pairs++;
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
  final longCommands = <Uint8List>[];
  @override
  Future<void> sendLongCommand(Uint8List message) async =>
      longCommands.add(message);
  final uploads = <Uint8List>[];
  @override
  Future<void> uploadWatchFile(Uint8List bytes) async => uploads.add(bytes);
  @override
  Future<void> applyDial() async {}
  int releases = 0;
  @override
  Future<void> releaseDevice() async => releases++;
  @override
  Future<void> openBluetoothSettings() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final writePreviews = Platform.environment['SILENCE_WRITE_PREVIEWS'] == '1';
  // Widget tests otherwise render with the wide Ahem font and overflow.
  setUpAll(() async {
    Future<ByteData> load(String name) async =>
        ByteData.sublistView(await File('assets/fonts/$name').readAsBytes());
    final loader = FontLoader('SilenceSans')
      ..addFont(load('Roboto-Regular.ttf'))
      ..addFont(load('Roboto-Medium.ttf'))
      ..addFont(load('Roboto-Bold.ttf'));
    await loader.load();
  });

  Future<({SilenceController controller, _Transport transport})> mount(
    WidgetTester tester, {
    double width = 390,
    double height = 844,
    double scale = 1,
    GlobalKey? captureKey,
    bool developerMode = true,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final transport = _Transport();
    final controller = SilenceController(
      transport: transport,
      developerMode: developerMode,
      autoRefreshStatus: false,
    );
    final artwork = ArtworkController();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      artwork.dispose();
      await transport.messages.close();
    });
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildSilenceTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: RepaintBoundary(
          key: captureKey,
          child: SilenceShell(controller: controller, artwork: artwork),
        ),
      ),
    );
    return (controller: controller, transport: transport);
  }

  for (final width in [320.0, 800.0]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('Device and Studio fit width $width with text scale $scale', (
        tester,
      ) async {
        final fixture = await mount(tester, width: width, scale: scale);
        expect(find.text('Find my watch'), findsOneWidget);
        expect(fixture.transport.scanCount, 0);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Studio'));
        await tester.pumpAndSettle();
        expect(find.text('Send to your watch'), findsOneWidget);
        expect(tester.takeException(), isNull);
        // Walk every card; content below the viewport also has to lay out cleanly.
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -1400),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Demo requires opt-in and never scans the native transport', (
    tester,
  ) async {
    final fixture = await mount(tester);
    FlutterError.onError = (d) => debugPrint(d.toString());
    expect(find.text('Design preview mode'), findsNothing);
    expect(fixture.controller.demoMode, isFalse);
    expect(fixture.transport.scanCount, 0);
    final explore = find.text('Just looking? Explore a demo');
    await tester.ensureVisible(explore);
    await tester.tap(explore);
    await tester.pumpAndSettle();
    expect(find.text('Design preview mode'), findsOneWidget);
    expect(fixture.controller.demoMode, isTrue);
    await tester.ensureVisible(find.text('Find my watch'));
    await tester.tap(find.text('Find my watch'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.text('ColorFit Pulse 2 · sample'), findsOneWidget);
    expect(fixture.transport.scanCount, 0);
    await tester.ensureVisible(
      find.byTooltip('Connect to ColorFit Pulse 2 · sample'),
    );
    await tester.tap(find.byTooltip('Connect to ColorFit Pulse 2 · sample'));
    await tester.pump(const Duration(milliseconds: 550));
    await tester.pumpAndSettle();
    expect(fixture.controller.connectedDevice?.id, 'demo-pulse-2');
    expect(find.text('0 Bluetooth services'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Exit preview'));
    await tester.tap(find.text('Exit preview'));
    await tester.pumpAndSettle();
    expect(fixture.controller.connectedDevice, isNull);
    expect(find.text('Design preview mode'), findsNothing);
  });

  testWidgets(
    'Release is available during connection and forgets local state',
    (tester) async {
      final fixture = await mount(tester);
      await fixture.controller.scan();
      fixture.transport.messages.add({
        'type': 'device',
        'id': 'pending',
        'name': 'Pending watch',
        'rssi': -40,
      });
      await fixture.controller.connect(fixture.controller.devices.single);
      expect(fixture.controller.busy, isTrue);
      await tester.tap(find.text('Unpair / release watch'));
      await tester.pumpAndSettle();
      expect(fixture.transport.releases, 1);
      expect(fixture.controller.busy, isFalse);
      expect(fixture.controller.connectedDevice, isNull);
      expect(fixture.controller.devices, isEmpty);
      fixture.transport.messages.add({
        'type': 'connection',
        'id': 'pending',
        'state': 'connected',
      });
      expect(fixture.controller.connectedDevice, isNull);
      expect(find.text('Watch released from Silence'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  test('Developer tools can be toggled while a watch is connected', () async {
    final transport = _Transport();
    final controller = SilenceController(transport: transport);
    addTearDown(() async {
      controller.dispose();
      await transport.messages.close();
    });
    const device = DiscoveredDevice(
      id: 'AA:BB:CC:DD:EE:FF',
      name: 'Pulse',
      rssi: -40,
    );
    await controller.connect(device);
    transport.messages.add({
      'type': 'connection',
      'id': device.id,
      'state': 'connected',
    });
    expect(controller.connectedDevice, isNotNull);
    controller.setDeveloperMode(true);
    expect(controller.developerMode, isTrue);
    expect(controller.selectedTab, 1, reason: 'stay on Studio while connected');
    controller.setDeveloperMode(false);
    expect(controller.developerMode, isFalse);
  });

  testWidgets('Studio is the default screen and hides developer tools', (
    tester,
  ) async {
    await mount(tester, developerMode: false);
    expect(find.text('Send to your watch'), findsOneWidget);
    expect(find.text('Unpair / release watch'), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Find my watch'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Cover rect fills the canvas and clamps panning', () {
    const image = Size(1000, 500);
    final rect = coverRect(image, 1, const Offset(9999, 9999));
    expect(rect.height, artworkCanvas.height);
    expect(rect.left <= 0 && rect.right >= artworkCanvas.width, isTrue);
    expect(rect.top, 0);
  });

  testWidgets('Pairing reports bind progress, result and the protocol log', (
    tester,
  ) async {
    final fixture = await mount(tester);
    await fixture.controller.scan();
    fixture.transport.messages.add({
      'type': 'device',
      'id': 'AA:BB:CC:DD:EE:FF',
      'name': 'Pulse',
      'rssi': -40,
    });
    fixture.transport.messages.add({'type': 'scanState', 'scanning': false});
    await fixture.controller.connect(fixture.controller.devices.single);
    fixture.transport.messages
      ..add({
        'type': 'connection',
        'id': 'AA:BB:CC:DD:EE:FF',
        'state': 'connected',
      })
      ..add({
        'type': 'services',
        'id': 'AA:BB:CC:DD:EE:FF',
        'services': [
          {
            'uuid': '000027f0-0000-1000-8000-00805f9b34fb',
            'characteristicCount': 2,
          },
        ],
      });
    await tester.pumpAndSettle();
    final pair = find.text('Pair watch');
    await tester.ensureVisible(pair);
    await tester.pumpAndSettle();
    await tester.tap(pair);
    await tester.pump();
    expect(fixture.transport.pairs, 1);
    expect(fixture.controller.pairing, isTrue);
    fixture.transport.messages
      ..add({
        'type': 'protocol',
        'dir': 'tx',
        'channel': '27f1',
        'hex': '04 01',
      })
      ..add({
        'type': 'pair',
        'stage': 'bindResult',
        'state': 0,
        'success': true,
      });
    await tester.pumpAndSettle();
    expect(fixture.controller.pairing, isFalse);
    expect(fixture.controller.pairSuccess, isTrue);
    expect(fixture.controller.protocolLog, ['tx 27f1 04 01']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Send to watch builds a face and reports upload progress', (
    tester,
  ) async {
    final fixture = await mount(tester);
    await fixture.controller.scan();
    fixture.transport.messages.add({
      'type': 'device',
      'id': 'AA:BB:CC:DD:EE:FF',
      'name': 'Pulse',
      'rssi': -40,
    });
    fixture.transport.messages.add({'type': 'scanState', 'scanning': false});
    await fixture.controller.connect(fixture.controller.devices.single);
    fixture.transport.messages
      ..add({
        'type': 'connection',
        'id': 'AA:BB:CC:DD:EE:FF',
        'state': 'connected',
      })
      ..add({
        'type': 'services',
        'id': 'AA:BB:CC:DD:EE:FF',
        'services': [
          {
            'uuid': '000027f0-0000-1000-8000-00805f9b34fb',
            'characteristicCount': 2,
          },
        ],
      })
      ..add({
        'type': 'pair',
        'stage': 'bindResult',
        'state': 0,
        'success': true,
      });
    fixture.controller.selectTab(1);
    await tester.pumpAndSettle();
    expect(fixture.controller.canUpload, isTrue);
    final send = find.text('Send to watch');
    await tester.ensureVisible(send);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(send);
      for (var i = 0; i < 50 && fixture.transport.uploads.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    });
    await tester.pump();
    expect(fixture.transport.uploads, hasLength(1));
    expect(fixture.transport.uploads.single.length, 578740);
    fixture.transport.messages.add({
      'type': 'upload',
      'stage': 'progress',
      'message': 'Sending',
      'percent': 40,
    });
    await tester.pump();
    expect(find.textContaining('Sending 40%'), findsOneWidget);
    fixture.transport.messages.add({'type': 'upload', 'stage': 'done'});
    await tester.pumpAndSettle();
    expect(fixture.controller.uploadSuccess, isTrue);
    expect(find.text('Set as current face'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'Connect-and-pair binds automatically and remembers the watch',
    () async {
      final transport = _Transport();
      final store = MemorySettingsStore();
      final controller = SilenceController(
        transport: transport,
        settings: store,
      );
      addTearDown(() async {
        controller.dispose();
        await transport.messages.close();
      });
      const device = DiscoveredDevice(
        id: 'AA:BB:CC:DD:EE:FF',
        name: 'Pulse 2',
        rssi: -40,
      );
      await controller.connectAndPair(device);
      transport.messages
        ..add({'type': 'connection', 'id': device.id, 'state': 'connected'})
        ..add({
          'type': 'services',
          'id': device.id,
          'services': [
            {
              'uuid': '000027f0-0000-1000-8000-00805f9b34fb',
              'characteristicCount': 2,
            },
          ],
        });
      await Future<void>.delayed(Duration.zero);
      expect(transport.pairs, 1);
      transport.messages.add({
        'type': 'pair',
        'stage': 'bindResult',
        'state': 0,
        'success': true,
      });
      await Future<void>.delayed(Duration.zero);
      expect(controller.lastDevice?.id, device.id);
      expect(store.values['lastDevice'], 'AA:BB:CC:DD:EE:FF|Pulse 2');

      final restored = SilenceController(
        transport: _Transport(),
        settings: store..values['developerMode'] = 'true',
      );
      addTearDown(restored.dispose);
      await restored.restore();
      expect(restored.lastDevice?.name, 'Pulse 2');
      expect(restored.developerMode, isTrue);
      expect(restored.autoConnect, isFalse);
    },
  );

  testWidgets('Connected service data and long names fit compact screens', (
    tester,
  ) async {
    final fixture = await mount(tester, width: 320, scale: 1.5);
    await fixture.controller.scan();
    fixture.transport.messages.add({
      'type': 'device',
      'id': 'AA:BB:CC:DD:EE:FF',
      'name': 'ColorFit Pulse 2 with a longer advertised device name',
      'rssi': -45,
    });
    fixture.transport.messages.add({'type': 'scanState', 'scanning': false});
    await fixture.controller.connect(fixture.controller.devices.single);
    fixture.transport.messages.add({
      'type': 'connection',
      'id': 'AA:BB:CC:DD:EE:FF',
      'state': 'connected',
    });
    fixture.transport.messages.add({
      'type': 'services',
      'id': 'AA:BB:CC:DD:EE:FF',
      'services': [
        {
          'uuid': '0000180a-0000-1000-8000-00805f9b34fb',
          'characteristicCount': 3,
        },
      ],
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Connection details'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('1 Bluetooth services'), findsOneWidget);
  });

  if (writePreviews) {
    testWidgets('Capture device and Studio design previews', (tester) async {
      final key = GlobalKey();
      await mount(tester, width: 800, height: 1150, captureKey: key);
      await tester.pumpAndSettle();
      Future<void> capture(String name) async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await tester.runAsync(() async {
          await Directory('build/previews').create(recursive: true);
          await File(
            'build/previews/$name.png',
          ).writeAsBytes(data!.buffer.asUint8List());
        });
        image.dispose();
      }

      await capture('device');
      await tester.tap(find.text('Studio'));
      await tester.pumpAndSettle();
      await capture('studio');
      expect(tester.takeException(), isNull);
    });
  }
}
