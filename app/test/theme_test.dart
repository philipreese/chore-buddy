import 'package:chorebuddy/core/theme/app_theme.dart';
import 'package:chorebuddy/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Theme Engine Tests', () {
    test('buildLightTheme falls back to the fixed seed when no dynamic '
        'scheme is available', () {
      final theme = AppTheme.buildLightTheme();

      expect(
        theme.colorScheme,
        equals(
          ColorScheme.fromSeed(
            seedColor: fallbackSeedColor,
            brightness: Brightness.light,
          ),
        ),
      );
      expect(theme.brightness, equals(Brightness.light));
    });

    test('buildDarkTheme falls back to the fixed seed when no dynamic '
        'scheme is available', () {
      final theme = AppTheme.buildDarkTheme();

      expect(
        theme.colorScheme,
        equals(
          ColorScheme.fromSeed(
            seedColor: fallbackSeedColor,
            brightness: Brightness.dark,
          ),
        ),
      );
      expect(theme.brightness, equals(Brightness.dark));
    });

    test('a provided dynamic scheme wins over the fallback seed', () {
      final dynamicScheme = ColorScheme.fromSeed(
        seedColor: Colors.red,
        brightness: Brightness.light,
      );

      final theme = AppTheme.buildLightTheme(dynamicScheme: dynamicScheme);

      expect(theme.colorScheme, equals(dynamicScheme));
    });

    test('themeProvider defaults to system and allows setting the mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeProvider), equals(ThemeMode.system));

      container.read(themeProvider.notifier).setThemeMode(ThemeMode.dark);
      expect(container.read(themeProvider), equals(ThemeMode.dark));

      container.read(themeProvider.notifier).setThemeMode(ThemeMode.light);
      expect(container.read(themeProvider), equals(ThemeMode.light));
    });
  });
}
