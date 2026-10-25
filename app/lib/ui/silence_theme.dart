import 'package:flutter/material.dart';

abstract final class SilenceColors {
  static const background = Color(0xFF10120F);
  static const surface = Color(0xFF1A1D18);
  static const elevated = Color(0xFF23271F);
  static const line = Color(0xFF343A2E);
  static const ink = Color(0xFFF3F1E9);
  static const muted = Color(0xFFA5AD9C);
  static const accent = Color(0xFFD0F58B);
}

ThemeData buildSilenceTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: SilenceColors.accent,
    brightness: Brightness.dark,
    surface: SilenceColors.surface,
    primary: SilenceColors.accent,
    onPrimary: SilenceColors.background,
    onSurface: SilenceColors.ink,
  );
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'SilenceSans',
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: SilenceColors.background,
    dividerColor: SilenceColors.line,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 38,
        height: 1.1,
        fontWeight: FontWeight.w500,
        letterSpacing: -1.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        height: 1.15,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.8,
      ),
      titleLarge: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.4,
      ),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5),
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.6,
      ),
    ).apply(bodyColor: SilenceColors.ink, displayColor: SilenceColors.ink),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: SilenceColors.surface,
      indicatorColor: SilenceColors.accent.withAlpha(27),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? SilenceColors.accent
              : SilenceColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: SilenceColors.ink,
        minimumSize: const Size(0, 46),
        side: const BorderSide(color: SilenceColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}
