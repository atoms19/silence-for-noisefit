import 'package:flutter/material.dart';

import 'controller/silence_controller.dart';
import 'services/settings_store.dart';
import 'studio/artwork.dart';
import 'ui/silence_shell.dart';
import 'ui/silence_theme.dart';

/// The controller lives outside the widget tree: the Flutter engine keeps
/// running (headless) while the watch is connected, so the notification relay
/// must not depend on any screen being built.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = SilenceController(settings: PrefsSettingsStore());
  final artwork = ArtworkController();
  controller.restore();
  runApp(SilenceApp(controller: controller, artwork: artwork));
}

class SilenceApp extends StatefulWidget {
  const SilenceApp({
    super.key,
    required this.controller,
    required this.artwork,
  });
  final SilenceController controller;
  final ArtworkController artwork;

  @override
  State<SilenceApp> createState() => _SilenceAppState();
}

class _SilenceAppState extends State<SilenceApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.refreshAccess();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.controller.refreshAccess();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Silence',
    debugShowCheckedModeBanner: false,
    theme: buildSilenceTheme(),
    home: SilenceShell(controller: widget.controller, artwork: widget.artwork),
  );
}
