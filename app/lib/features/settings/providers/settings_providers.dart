import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../domain/auto_backup_core.dart';

/// Timestamp of the last successful backup export. Hydrated from and
/// persisted to disk by `settingsHydrationProvider`; [BackupService] only
/// ever updates this provider, never storage directly, so the persistence
/// pattern for this field matches the other settings.
class LastBackupAtNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void set(DateTime? value) {
    state = value;
  }
}

final lastBackupAtProvider =
    NotifierProvider<LastBackupAtNotifier, DateTime?>(
  LastBackupAtNotifier.new,
);

/// Whether the daily auto-backup job is enabled. Hydrated from and
/// persisted to disk by `settingsHydrationProvider`, which also
/// (re)schedules or cancels the WorkManager job whenever this changes.
class AutoBackupEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void setEnabled(bool value) {
    state = value;
  }
}

final autoBackupEnabledProvider =
    NotifierProvider<AutoBackupEnabledNotifier, bool>(
  AutoBackupEnabledNotifier.new,
);

/// Timestamp of the last successful auto-backup, written by the background
/// job (see `auto_backup_task.dart`) and by the in-process "Back Up Now"
/// action. Hydrated the same way [lastBackupAtProvider] is.
class LastAutoBackupAtNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void set(DateTime? value) {
    state = value;
  }
}

final lastAutoBackupAtProvider =
    NotifierProvider<LastAutoBackupAtNotifier, DateTime?>(
  LastAutoBackupAtNotifier.new,
);

/// The folder auto-backups are written to, for the read-only destination
/// display in Settings. Resolved the same way [writeAutoBackupSnapshot]
/// resolves it, so the displayed path always matches where files actually
/// land.
final autoBackupDestinationProvider = FutureProvider<String>((ref) async {
  final directory = await resolveAutoBackupDirectory();
  return directory.path;
});

/// App name/version/build/package id for the About section.
final packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});
