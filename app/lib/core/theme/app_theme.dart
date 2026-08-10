import 'package:flutter/material.dart';
import 'seed_colors.dart';

class AppTheme {
  static ThemeData buildLightTheme({
    required AppThemeId themeId,
    ColorScheme? lightDynamicScheme,
  }) {
    ColorScheme colorScheme;
    if (themeId == AppThemeId.dynamicTheme && lightDynamicScheme != null) {
      colorScheme = lightDynamicScheme;
    } else {
      colorScheme = ColorScheme.fromSeed(
        seedColor: themeId.seedColor,
        brightness: Brightness.light,
      );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
    );
  }

  static ThemeData buildDarkTheme({
    required AppThemeId themeId,
    ColorScheme? darkDynamicScheme,
  }) {
    ColorScheme colorScheme;
    if (themeId == AppThemeId.dynamicTheme && darkDynamicScheme != null) {
      colorScheme = darkDynamicScheme;
    } else {
      colorScheme = ColorScheme.fromSeed(
        seedColor: themeId.seedColor,
        brightness: Brightness.dark,
      );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
    );
  }
}
