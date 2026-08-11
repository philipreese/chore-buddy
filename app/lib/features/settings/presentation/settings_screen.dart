import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/home_widget/widget_sync_service.dart';
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
      final widgetSyncService = ref.read(widgetSyncServiceProvider);
      await db.deleteAllChores();
      await notificationService.cancelAll();
      await widgetSyncService.sync();
    }
  }

  Widget _voiceGlyphChip(
    String glyph,
    ColorScheme colorScheme, {
    double size = 40,
    double fontSize = 18,
  }) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        shape: BoxShape.circle,
      ),
      child: Text(
        glyph,
        style: TextStyle(
          fontSize: fontSize,
          color: colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }

  // A single dropdown-style field (device feedback, spec 28) replaces the
  // former column of nine always-visible radio rows: the collapsed field
  // previews the active voice (glyph + name + signature), and the popup
  // menu it opens lists every voice by glyph + name for one-tap selection.
  Widget _buildVoicePicker(
    BuildContext context,
    WidgetRef ref,
    AppVoice activeVoice,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final metadata = activeVoice.metadata;
    final signature = activeVoice.strings.voiceSignature;

    return PopupMenuButton<AppVoice>(
      key: const Key('voice_picker_dropdown'),
      position: PopupMenuPosition.under,
      onSelected: (voice) => ref.read(voiceProvider.notifier).setVoice(voice),
      itemBuilder: (context) => AppVoice.values.map((voice) {
        final entryMetadata = voice.metadata;
        final selected = voice == activeVoice;
        return PopupMenuItem<AppVoice>(
          key: Key('voice_row_${voice.name}'),
          value: voice,
          child: Row(
            children: [
              _voiceGlyphChip(entryMetadata.glyph, colorScheme, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entryMetadata.displayName,
                  style: textTheme.bodyLarge,
                ),
              ),
              if (selected)
                Icon(Icons.check, color: colorScheme.primary, size: 20),
            ],
          ),
        );
      }).toList(),
      child: Container(
        key: const Key('voice_picker_field'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _voiceGlyphChip(metadata.glyph, colorScheme),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
            Icon(Icons.arrow_drop_down, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
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
          SettingsSectionHeader(label: strings.voiceSectionTitle),
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
