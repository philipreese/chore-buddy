import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/strings/flavor_provider.dart';
import '../../../core/theme/seed_colors.dart';
import '../../../core/theme/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final themeState = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            key: const Key('settings_manage_tags_tile'),
            leading: const Icon(Icons.style_outlined),
            title: Text(strings.manageTags),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/tags'),
          ),
          const Divider(),
          ListTile(
            title: Text(strings.settingsTitle),
            subtitle: Text(themeState.themeId.displayName),
          ),
          const Divider(),
          ...AppThemeId.values.map((themeId) {
            final isSelected = themeState.themeId == themeId;
            return ListTile(
              title: Text(themeId.displayName),
              leading: CircleAvatar(
                backgroundColor: themeId.seedColor,
                radius: 12,
              ),
              trailing: isSelected
                  ? Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () {
                ref.read(themeProvider.notifier).setThemeId(themeId);
              },
              selected: isSelected,
            );
          }),

        ],
      ),
    );
  }
}
