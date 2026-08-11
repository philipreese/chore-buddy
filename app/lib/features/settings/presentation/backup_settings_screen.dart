import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chores/domain/date_formatter.dart';
import '../../../core/strings/voice_provider.dart';
import '../domain/backup_service.dart';
import '../providers/settings_providers.dart';

/// Manual export/import and automatic (daily) backup controls, split out of
/// the main settings screen (spec 20) so that screen isn't a 14-row
/// catch-all. Behavior is byte-for-byte identical to what used to live
/// there -- same providers, same dialogs, same snackbars -- just grouped
/// under its own route.
class BackupSettingsScreen extends ConsumerStatefulWidget {
  const BackupSettingsScreen({super.key});

  @override
  ConsumerState<BackupSettingsScreen> createState() =>
      _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends ConsumerState<BackupSettingsScreen> {
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

  Future<void> _handleBackUpNow() async {
    if (_busy) return;
    setState(() => _busy = true);
    final strings = ref.read(appStringsProvider);

    try {
      final success = await ref.read(backupServiceProvider).backUpNow();
      if (!mounted) return;
      await _showResultDialog(
        success ? strings.autoBackupNowSuccessTitle : strings.autoBackupNowFailedTitle,
        success ? strings.autoBackupNowSuccessMessage : strings.autoBackupNowFailedMessage,
      );
    } catch (_) {
      if (!mounted) return;
      await _showResultDialog(
        strings.autoBackupNowFailedTitle,
        strings.autoBackupNowFailedMessage,
      );
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
    final lastBackupAt = ref.watch(lastBackupAtProvider);
    final autoBackupEnabled = ref.watch(autoBackupEnabledProvider);
    final lastAutoBackupAt = ref.watch(lastAutoBackupAtProvider);
    final autoBackupDestination = ref.watch(autoBackupDestinationProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(strings.backupRestoreRowTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
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
          Text(strings.autoBackupSectionTitle, style: textTheme.titleMedium),
          const SizedBox(height: 8),
          SwitchListTile(
            key: const Key('settings_auto_backup_toggle'),
            contentPadding: EdgeInsets.zero,
            title: Text(strings.autoBackupToggleTitle),
            subtitle: Text(strings.autoBackupToggleSubtitle),
            value: autoBackupEnabled,
            onChanged: (value) =>
                ref.read(autoBackupEnabledProvider.notifier).setEnabled(value),
          ),
          ListTile(
            key: const Key('settings_auto_backup_now_button'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.cloud_sync_outlined),
            title: Text(strings.autoBackupNowButton),
            enabled: !_busy,
            onTap: _handleBackUpNow,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text(
              key: const Key('settings_last_auto_backup_label'),
              lastAutoBackupAt == null
                  ? strings.autoBackupNeverLabel
                  : strings.autoBackupAtLabel(formatDateTime(lastAutoBackupAt)),
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text(
              key: const Key('settings_auto_backup_destination_label'),
              autoBackupDestination.when(
                data: (path) => strings.autoBackupDestinationLabel(path),
                loading: () => strings.autoBackupDestinationLabel('...'),
                error: (_, _) => strings.autoBackupDestinationLabel('...'),
              ),
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
