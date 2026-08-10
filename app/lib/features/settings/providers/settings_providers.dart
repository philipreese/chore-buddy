import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

/// App name/version/build/package id for the About section.
final packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});
