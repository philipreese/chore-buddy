import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/seed_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import 'theme_swatch.dart';

/// Horizontal selector of the 6 seed themes + Dynamic. Wrapped in its own
/// [DynamicColorBuilder] so the Dynamic swatch can preview the actual
/// wallpaper-derived scheme even when it isn't the currently-active theme;
/// on platforms/API levels without dynamic color it falls back to the seed
/// scheme like every other swatch.
class ThemePickerRow extends ConsumerWidget {
  const ThemePickerRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final brightness = Theme.of(context).brightness;

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final dynamicScheme = brightness == Brightness.dark
            ? darkDynamic
            : lightDynamic;

        return SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: AppThemeId.values.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final themeId = AppThemeId.values[index];
              final isSelected = themeState.themeId == themeId;
              final scheme = themeId == AppThemeId.dynamicTheme
                  ? (dynamicScheme ??
                        ColorScheme.fromSeed(
                          seedColor: themeId.seedColor,
                          brightness: brightness,
                        ))
                  : ColorScheme.fromSeed(
                      seedColor: themeId.seedColor,
                      brightness: brightness,
                    );

              return _ThemeOptionTile(
                key: Key('theme_swatch_${themeId.name}'),
                themeId: themeId,
                scheme: scheme,
                selected: isSelected,
                onTap: () =>
                    ref.read(themeProvider.notifier).setThemeId(themeId),
              );
            },
          ),
        );
      },
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  final AppThemeId themeId;
  final ColorScheme scheme;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOptionTile({
    super.key,
    required this.themeId,
    required this.scheme,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ThemeSwatch(scheme: scheme, selected: selected),
            const SizedBox(height: 6),
            Text(
              themeId.displayName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? Theme.of(context).colorScheme.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
