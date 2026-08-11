import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/notifications/notifications_enabled_provider.dart';
import '../../../core/services/haptics_service.dart';
import '../../../core/strings/flavor_provider.dart';
import '../../chores/domain/date_formatter.dart';
import '../../chores/providers/chore_providers.dart';
import '../domain/backup_service.dart';
import '../providers/settings_providers.dart';
import 'widgets/about_section.dart';
import 'widgets/theme_picker_row.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;

  Future<void> _handleExport() async {
    if (_busy) return;
    setState(() => _busy = true);
    final strings = ref.read(appStringsProvider);

    try {
      final success = await ref.read(backupServiceProvider).exportDatabase();
      if (!mounted) return;
      if (success) {
        await _showResultDialog(strings.intelSecuredTitle, strings.intelSecuredMessage);
      }
      // A `false` result means the user canceled the folder picker (or
      // there's nothing to export yet) -- neither warrants an error dialog.
    } catch (_) {
      if (!mounted) return;
      await _showResultDialog(strings.backupFailedTitle, strings.backupFailedMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleImport() async {
    if (_busy) return;
    setState(() => _busy = true);
    final strings = ref.read(appStringsProvider);
    final backupService = ref.read(backupServiceProvider);

    try {
      final path = await backupService.pickImportFile();
      if (path == null || !mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(strings.restoreArchivesTitle),
          content: Text(strings.restoreArchivesMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.abortButton),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(strings.restoreConfirmAction),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      await backupService.importDatabase(path);
      if (!mounted) return;
      await _showResultDialog(strings.restoreSuccessTitle, strings.restoreSuccessMessage);
    } catch (_) {
      if (!mounted) return;
      await _showResultDialog(strings.restoreFailedTitle, strings.restoreFailedMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDeleteAllChores() async {
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

    if (confirmed == true && mounted) {
      final db = ref.read(appDatabaseProvider);
      final notificationService = ref.read(notificationServiceProvider);
      await db.deleteAllChores();
      await notificationService.cancelAll();
    }
  }

  Future<void> _showResultDialog(String title, String message) {
    final strings = ref.read(appStringsProvider);
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final hapticsEnabled = ref.watch(hapticsEnabledProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final showDetails = ref.watch(showDetailsOnCardsProvider);
    final lastBackupAt = ref.watch(lastBackupAtProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(strings.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(strings.themeSectionTitle, style: textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            strings.themePickerHint,
            style: textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          const ThemePickerRow(),
          const Divider(height: 32),
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
          ListTile(
            key: const Key('settings_manage_tags_tile'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.style_outlined),
            title: Text(strings.manageTags),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/tags'),
          ),
          const Divider(height: 32),
          Text(strings.backupSectionTitle, style: textTheme.titleMedium),
          const SizedBox(height: 8),
          ListTile(
            key: const Key('settings_export_button'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.upload_outlined),
            title: Text(strings.exportBackupButton),
            enabled: !_busy,
            onTap: _handleExport,
          ),
          ListTile(
            key: const Key('settings_import_button'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.download_outlined),
            title: Text(strings.importBackupButton),
            enabled: !_busy,
            onTap: _handleImport,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text(
              key: const Key('settings_last_backup_label'),
              lastBackupAt == null
                  ? strings.lastBackupNeverLabel
                  : strings.lastBackupAtLabel(formatDateTime(lastBackupAt)),
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Divider(height: 32),
          Text(
            strings.dangerZoneSectionTitle,
            style: textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            key: const Key('settings_delete_all_chores_tile'),
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.delete_forever,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              strings.wipeAllChoresButton,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: _confirmDeleteAllChores,
          ),
          const Divider(height: 32),
          const AboutSection(),
        ],
      ),
    );
  }
}
