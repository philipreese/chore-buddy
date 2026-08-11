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

    test(
        'card fill is a visibly distinct tonal step from the scaffold '
        'background in light mode, and the card border carries the '
        'separation in dark mode (regression tripwire: elevation-0 + one '
        'adjacent tonal step measured as imperceptible on real dynamic-'
        'color devices; see ChoreCard/ArchivedChoreCard, which use '
        'surfaceContainerHigh -- two steps from surface -- plus an '
        'outlineVariant border)', () {
      // Measured against ColorScheme.fromSeed(seedColor: fallbackSeedColor):
      // in light mode the two-step tonal jump alone clears a real
      // separation floor (delta ~0.14). In dark mode M3's own tonal scale
      // tops out below that floor for this seed -- even the most extreme
      // surfaceContainerHighest role only reaches ~0.029 -- so a literal
      // >=0.03 fill-vs-surface assertion is unreachable via tone alone in
      // dark, which is exactly what item 1's spec text anticipates ("the
      // border + bigger tonal jump must carry it"). The fill assertion
      // below is calibrated to the real ceiling (three times the old
      // one-step surfaceContainerLow baseline, ~0.005 dark) so it still
      // catches a regression to a single tonal step; the border assertion
      // is the >=0.03 tripwire dark mode actually relies on.
      for (final brightness in [Brightness.light, Brightness.dark]) {
        final scheme = ColorScheme.fromSeed(
          seedColor: fallbackSeedColor,
          brightness: brightness,
        );
        final fillDelta =
            (scheme.surfaceContainerHigh.computeLuminance() -
                    scheme.surface.computeLuminance())
                .abs();
        final borderDelta =
            (scheme.outlineVariant.computeLuminance() -
                    scheme.surface.computeLuminance())
                .abs();

        final fillFloor = brightness == Brightness.light ? 0.03 : 0.015;
        expect(
          fillDelta,
          greaterThanOrEqualTo(fillFloor),
          reason:
              'surfaceContainerHigh vs surface luminance delta in '
              '$brightness was $fillDelta, below the visibility floor',
        );
        expect(
          borderDelta,
          greaterThanOrEqualTo(0.03),
          reason:
              'outlineVariant vs surface luminance delta in $brightness '
              'was $borderDelta, below the visibility floor',
        );
      }
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
