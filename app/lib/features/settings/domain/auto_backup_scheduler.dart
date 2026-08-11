import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import 'auto_backup_task.dart';

/// Seam over `workmanager`'s platform-channel statics -- register/cancel the
/// daily periodic job -- kept separate from the settings surface so tests
/// never touch a platform channel, mirroring how [WidgetDataWriter] and
/// [WidgetInteractivity] wrap the `home_widget` statics.
abstract class AutoBackupScheduler {
  Future<void> schedule();
  Future<void> cancel();
}

/// Real implementation backed by `workmanager`. Every call is wrapped so a
/// platform failure (missing platform channel under `flutter test`, a
/// plugin quirk on an unusual OEM build) degrades to "no scheduled job"
/// instead of crashing the settings flow that triggered it.
class WorkManagerAutoBackupScheduler implements AutoBackupScheduler {
  @override
  Future<void> schedule() async {
    try {
      await Workmanager().initialize(autoBackupCallbackDispatcher);
      await Workmanager().registerPeriodicTask(
        kAutoBackupTaskName,
        kAutoBackupTaskName,
        frequency: const Duration(hours: 24),
        constraints: Constraints(requiresBatteryNotLow: true),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
    } catch (e, st) {
      debugPrint('WorkManagerAutoBackupScheduler.schedule failed: $e\n$st');
    }
  }

  @override
  Future<void> cancel() async {
    try {
      await Workmanager().cancelByUniqueName(kAutoBackupTaskName);
    } catch (e, st) {
      debugPrint('WorkManagerAutoBackupScheduler.cancel failed: $e\n$st');
    }
  }
}

final autoBackupSchedulerProvider = Provider<AutoBackupScheduler>((ref) {
  return WorkManagerAutoBackupScheduler();
});
