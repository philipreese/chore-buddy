import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/notifications/notifications_enabled_provider.dart';
import '../../../core/services/haptics_service.dart';
import '../../../core/strings/voice_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../chores/domain/date_formatter.dart';
import '../../chores/providers/chore_providers.dart';
import '../providers/settings_providers.dart';
import 'widgets/about_section.dart';
import 'widgets/settings_section_header.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmDeleteAllChores(BuildContext context, WidgetRef ref) async {
    final strings = ref.read(appStringsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.wipeAllChoresTitle),
        content: Text(strings.wipeAllChoresMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.wipeAllChoresConfirm),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = ref.read(appDatabaseProvider);
      final notificationService = ref.read(notificationServiceProvider);
      await db.deleteAllChores();
      await notificationService.cancelAll();
    }
  }

  Widget _buildVoicePicker(
    BuildContext context,
    WidgetRef ref,
    AppVoice activeVoice,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: AppVoice.values.map((voice) {
        final metadata = voice.metadata;
        final signature = voice.strings.voiceSignature;
        final selected = voice == activeVoice;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: selected
                ? colorScheme.secondaryContainer.withAlpha(90)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              key: Key('voice_row_${voice.name}'),
              borderRadius: BorderRadius.circular(16),
              onTap: () => ref.read(voiceProvider.notifier).setVoice(voice),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        metadata.glyph,
                        style: TextStyle(
                          fontSize: 18,
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            metadata.displayName,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            signature,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Row-level InkWell already handles selection --
                    // Radio's `groupValue`/`onChanged` are deprecated in
                    // favor of RadioGroup, which would need to wrap every
                    // row for a single tap target this simple indicator
                    // already covers.
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: selected
                          ? colorScheme.primary
                          : colorScheme.outline,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final voice = ref.watch(voiceProvider);
    final themeMode = ref.watch(themeProvider);
    final hapticsEnabled = ref.watch(hapticsEnabledProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final showDetails = ref.watch(showDetailsOnCardsProvider);
    final lastBackupAt = ref.watch(lastBackupAtProvider);
    final lastAutoBackupAt = ref.watch(lastAutoBackupAtProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // Most-recent backup of either kind, for the single summary row's
    // subtitle -- reuses the same never/at-label semantics the sub-page's
    // two separate labels use.
    DateTime? mostRecentBackup;
    if (lastBackupAt != null && lastAutoBackupAt != null) {
      mostRecentBackup =
          lastBackupAt.isAfter(lastAutoBackupAt) ? lastBackupAt : lastAutoBackupAt;
    } else {
      mostRecentBackup = lastBackupAt ?? lastAutoBackupAt;
    }

    return Scaffold(
      appBar: AppBar(title: Text(strings.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SettingsSectionHeader(label: strings.themeSectionTitle),
          Text(
            strings.themePickerHint,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            key: const Key('settings_theme_mode_selector'),
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(strings.themeModeSystem),
                icon: const Icon(Icons.brightness_auto),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(strings.themeModeLight),
                icon: const Icon(Icons.light_mode),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(strings.themeModeDark),
                icon: const Icon(Icons.dark_mode),
              ),
            ],
            selected: {themeMode},
            onSelectionChanged: (selection) => ref
                .read(themeProvider.notifier)
                .setThemeMode(selection.first),
          ),
          const Divider(height: 32),
          const SettingsSectionHeader(label: 'Voice'),
          _buildVoicePicker(context, ref, voice),
          const Divider(height: 32),
          SettingsSectionHeader(label: strings.behaviorSectionTitle),
          SwitchListTile(
            key: const Key('settings_haptics_toggle'),
            contentPadding: EdgeInsets.zero,
            title: Text(strings.hapticsToggleTitle),
            value: hapticsEnabled,
            onChanged: (value) =>
                ref.read(hapticsEnabledProvider.notifier).setEnabled(value),
          ),
          SwitchListTile(
            key: const Key('settings_notifications_toggle'),
            contentPadding: EdgeInsets.zero,
            title: Text(strings.notificationsToggleTitle),
            value: notificationsEnabled,
            onChanged: (value) => ref
                .read(notificationsEnabledProvider.notifier)
                .setEnabled(value),
          ),
          SwitchListTile(
            key: const Key('settings_show_details_toggle'),
            contentPadding: EdgeInsets.zero,
            title: Text(strings.showDetailsToggleTitle),
            value: showDetails,
            onChanged: (value) =>
                ref.read(showDetailsOnCardsProvider.notifier).setVisible(value),
          ),
          const Divider(height: 32),
          SettingsSectionHeader(label: strings.tagsSectionTitle),
          ListTile(
            key: const Key('settings_manage_tags_tile'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.style_outlined),
            title: Text(strings.manageTags),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/tags'),
          ),
          const Divider(height: 32),
          ListTile(
            key: const Key('settings_backup_restore_tile'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.cloud_sync_outlined),
            title: Text(strings.backupRestoreRowTitle),
            subtitle: Text(
              key: const Key('settings_backup_restore_subtitle'),
              mostRecentBackup == null
                  ? strings.lastBackupNeverLabel
                  : strings.lastBackupAtLabel(formatDateTime(mostRecentBackup)),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/backup'),
          ),
          const Divider(height: 32),
          SettingsSectionHeader(
            label: strings.dangerZoneSectionTitle,
            color: colorScheme.error,
          ),
          ListTile(
            key: const Key('settings_delete_all_chores_tile'),
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.delete_forever,
              color: colorScheme.error,
            ),
            title: Text(
              strings.wipeAllChoresButton,
              style: TextStyle(color: colorScheme.error),
            ),
            onTap: () => _confirmDeleteAllChores(context, ref),
          ),
          const Divider(height: 32),
          const AboutSection(),
        ],
      ),
    );
  }
}
