import 'package:chorebuddy/core/theme/app_theme.dart';
import 'package:chorebuddy/core/theme/seed_colors.dart';
import 'package:chorebuddy/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Theme Engine Tests', () {
    test('Named seed themes generate distinct light ColorSchemes', () {
      final namedThemes = [
        AppThemeId.chambray,
        AppThemeId.blueStone,
        AppThemeId.russet,
        AppThemeId.affair,
        AppThemeId.spicyMustard,
        AppThemeId.woodland,
      ];

      final primaryColors = <Color>{};

      for (final themeId in namedThemes) {
        final lightTheme = AppTheme.buildLightTheme(themeId: themeId);
        final primary = lightTheme.colorScheme.primary;

        expect(primaryColors.contains(primary), isFalse,
            reason: 'Theme ${themeId.displayName} primary color should be unique.');
        primaryColors.add(primary);
      }

      expect(primaryColors.length, equals(6));
    });

    test('Named seed themes generate distinct dark ColorSchemes', () {
      final namedThemes = [
        AppThemeId.chambray,
        AppThemeId.blueStone,
        AppThemeId.russet,
        AppThemeId.affair,
        AppThemeId.spicyMustard,
        AppThemeId.woodland,
      ];

      final darkPrimaryColors = <Color>{};

      for (final themeId in namedThemes) {
        final darkTheme = AppTheme.buildDarkTheme(themeId: themeId);
        final primary = darkTheme.colorScheme.primary;

        expect(darkPrimaryColors.contains(primary), isFalse,
            reason: 'Theme ${themeId.displayName} dark primary color should be unique.');
        darkPrimaryColors.add(primary);
      }

      expect(darkPrimaryColors.length, equals(6));
    });

    test('themeProvider default is Chambray and allows setting themeId', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeProvider).themeId, equals(AppThemeId.chambray));

      container.read(themeProvider.notifier).setThemeId(AppThemeId.woodland);
      expect(container.read(themeProvider).themeId, equals(AppThemeId.woodland));

      container.read(themeProvider.notifier).setThemeId(AppThemeId.dynamicTheme);
      expect(container.read(themeProvider).themeId, equals(AppThemeId.dynamicTheme));
    });
  });
}
