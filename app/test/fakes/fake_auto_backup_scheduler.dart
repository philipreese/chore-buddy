import 'package:chorebuddy/features/settings/domain/auto_backup_scheduler.dart';

/// In-memory [AutoBackupScheduler] for tests: records calls instead of
/// touching the `workmanager` platform channel, mirroring
/// [FakeWidgetInteractivity].
class FakeAutoBackupScheduler implements AutoBackupScheduler {
  int scheduleCallCount = 0;
  int cancelCallCount = 0;

  @override
  Future<void> schedule() async {
    scheduleCallCount++;
  }

  @override
  Future<void> cancel() async {
    cancelCallCount++;
  }
}
