import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import '../../../core/database/database_file_locator.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/notifications/notification_service.dart';
import '../providers/settings_providers.dart';
import 'file_dialog_service.dart';

enum ImportFailureReason {
  /// The user's picked file doesn't exist, is empty, or isn't a ChoreBuddy
  /// database (garbage bytes, or a valid sqlite file missing the expected
  /// tables).
  integrityCheckFailed,

  /// The integrity check passed but something failed while swapping the
  /// file in (disk I/O, permissions, etc). The pre-swap backup is restored
  /// before this is thrown, so the current database is left intact.
  swapFailed,
}

class ImportException implements Exception {
  final ImportFailureReason reason;
  final Object? cause;

  const ImportException(this.reason, [this.cause]);

  @override
  String toString() => 'ImportException: $reason${cause == null ? '' : ' ($cause)'}';
}

/// Database export/import, including the hot-swap import flow from
/// `docs/proposals/00-new-stack-ideas.md` §2.4: no app restart required, the
/// UI reconnects to the freshly-imported data via Riverpod invalidation.
class BackupService {
  BackupService({required this.ref});

  final Ref ref;

  /// WAL-checkpoints then copies the live database file into a
  /// user-chosen directory. Returns false if the user cancels the directory
  /// picker or the database file doesn't exist yet; true on success.
  Future<bool> exportDatabase() async {
    final db = ref.read(appDatabaseProvider);
    await db.customStatement('PRAGMA wal_checkpoint(FULL);');

    final dbFile = await resolveDatabaseFile();
    if (!await dbFile.exists()) return false;

    final destinationDir =
        await ref.read(fileDialogServiceProvider).pickExportDirectory();
    if (destinationDir == null) return false;

    final destinationFile = File(
      p.join(destinationDir, _backupFileName(DateTime.now())),
    );
    await dbFile.copy(destinationFile.path);

    ref.read(lastBackupAtProvider.notifier).set(DateTime.now());
    return true;
  }

  /// Lets the user pick a `.db3`/`.sqlite` file. Returns null if canceled.
  Future<String?> pickImportFile() {
    return ref.read(fileDialogServiceProvider).pickImportFilePath();
  }

  /// Validates [sourcePath], then hot-swaps it in for the live database:
  /// checkpoints and closes the current connection, stages the current file
  /// aside as a rollback point, atomically replaces the database file, then
  /// invalidates [appDatabaseProvider] so every stream reconnects and
  /// reschedules notifications from the imported data.
  ///
  /// Throws [ImportException] on any failure. A failed integrity check never
  /// touches the current database; a failed swap restores the pre-import
  /// backup before rethrowing, so the current database is left untouched
  /// either way.
  Future<void> importDatabase(String sourcePath) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists() || await sourceFile.length() == 0) {
      throw const ImportException(ImportFailureReason.integrityCheckFailed);
    }
    if (!await _isValidChoreBuddyDatabase(sourceFile)) {
      throw const ImportException(ImportFailureReason.integrityCheckFailed);
    }

    final dbFile = await resolveDatabaseFile();
    final backupFile = await resolvePreImportBackupFile();
    final stagingFile = File('${dbFile.path}.importing');

    final db = ref.read(appDatabaseProvider);
    try {
      await db.customStatement('PRAGMA wal_checkpoint(FULL);');
    } catch (e, st) {
      debugPrint('BackupService.importDatabase: checkpoint failed: $e\n$st');
    } finally {
      await db.close();
    }

    // From here the current connection is gone regardless of outcome, so
    // every exit path below must invalidate the provider to reconnect.
    try {
      if (await dbFile.exists()) {
        await dbFile.copy(backupFile.path);
      }
      await sourceFile.copy(stagingFile.path);
      await stagingFile.rename(dbFile.path);
      await _deleteSidecarFiles(dbFile);

      if (await backupFile.exists()) {
        await backupFile.delete();
      }
    } catch (e) {
      if (await stagingFile.exists()) {
        await stagingFile.delete();
      }
      if (await backupFile.exists()) {
        await backupFile.copy(dbFile.path);
        await backupFile.delete();
      }
      throw ImportException(ImportFailureReason.swapFailed, e);
    } finally {
      ref.invalidate(appDatabaseProvider);
    }

    await ref.read(notificationServiceProvider).rescheduleAll();
  }

  /// Opens [file] strictly read-only and checks every table the schema
  /// expects is present. Read-only is deliberate: opening through
  /// [AppDatabase] would run its migration strategy, which would silently
  /// *create* the expected tables in an unrelated empty sqlite file and
  /// report it as valid. Garbage bytes fail to open at all; an unrelated
  /// sqlite file opens but is missing the expected tables. Neither mutates
  /// the file under inspection.
  Future<bool> _isValidChoreBuddyDatabase(File file) async {
    sqlite3.Database? raw;
    try {
      raw = sqlite3.sqlite3.open(
        file.path,
        mode: sqlite3.OpenMode.readOnly,
      );
      final rows = raw.select(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      final tableNames = rows.map((row) => row['name'] as String).toSet();
      return _requiredTables.every(tableNames.contains);
    } catch (_) {
      return false;
    } finally {
      raw?.dispose();
    }
  }

  static const _requiredTables = {
    'chores',
    'tags',
    'completion_records',
    'chore_tags',
  };

  Future<void> _deleteSidecarFiles(File dbFile) async {
    for (final suffix in ['-wal', '-shm']) {
      final sidecar = File('${dbFile.path}$suffix');
      if (await sidecar.exists()) {
        await sidecar.delete();
      }
    }
  }

  String _backupFileName(DateTime timestamp) {
    String pad(int value) => value.toString().padLeft(2, '0');
    final stamp =
        '${timestamp.year}${pad(timestamp.month)}${pad(timestamp.day)}'
        '_${pad(timestamp.hour)}${pad(timestamp.minute)}${pad(timestamp.second)}';
    return 'chorebuddy_backup_$stamp.db3';
  }
}

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref: ref);
});
