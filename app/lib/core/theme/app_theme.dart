import 'package:flutter/material.dart';

/// Fallback seed color for devices without dynamic color support (Android
/// 11 and below, or platforms lacking Material You). Matches the app's
/// original default "Chambray" seed from the retired theme picker.
const fallbackSeedColor = Color(0xFF415F91);

class AppTheme {
  static ThemeData buildLightTheme({ColorScheme? dynamicScheme}) {
    final colorScheme =
        dynamicScheme ??
        ColorScheme.fromSeed(
          seedColor: fallbackSeedColor,
          brightness: Brightness.light,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
    );
  }

  static ThemeData buildDarkTheme({ColorScheme? dynamicScheme}) {
    final colorScheme =
        dynamicScheme ??
        ColorScheme.fromSeed(
          seedColor: fallbackSeedColor,
          brightness: Brightness.dark,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
    );
  }
}
