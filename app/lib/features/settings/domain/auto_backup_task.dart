import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_file_locator.dart';
import '../../../core/settings/settings_prefs_service.dart';
import 'auto_backup_core.dart';

/// Registered with WorkManager as both the unique work name and the task
/// name -- there is only ever one auto-backup job, so a single constant
/// serves both roles (see [AutoBackupScheduler]).
const kAutoBackupTaskName = 'chorebuddy.autoBackup';

/// Entry point WorkManager invokes -- on a background isolate, with no
/// running app guaranteed -- once a day to take a rotating snapshot of the
/// database. `@pragma('vm:entry-point')` is required so the Dart compiler
/// doesn't tree-shake a function that is only ever reached via a native
/// callback lookup, never a direct Dart call, mirroring
/// `notificationBackgroundResponseHandler` and `widgetInteractivityHandler`
/// in `background_completion.dart`.
///
/// Owns its own [AppDatabase] connection -- opened and closed entirely
/// within this call -- rather than reading `appDatabaseProvider`, since no
/// `Ref` exists on this isolate.
@pragma('vm:entry-point')
void autoBackupCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != kAutoBackupTaskName) return true;

    WidgetsFlutterBinding.ensureInitialized();
    final prefsService = SharedPreferencesSettingsService();

    try {
      final snapshot = await prefsService.load();
      if (!snapshot.autoBackupEnabled) return true;

      final dbFile = await resolveDatabaseFile();
      final db = AppDatabase();
      try {
        final backupsDir = await resolveAutoBackupDirectory();
        final written = await writeAutoBackupSnapshot(
          db: db,
          dbFile: dbFile,
          backupsDir: backupsDir,
        );
        if (written != null) {
          await prefsService.setLastAutoBackupAt(DateTime.now());
        }
      } finally {
        await db.close();
      }
    } catch (e, st) {
      debugPrint('autoBackupCallbackDispatcher failed: $e\n$st');
    }
    return true;
  });
}
