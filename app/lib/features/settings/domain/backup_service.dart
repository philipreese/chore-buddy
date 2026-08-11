import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import '../../../core/database/database_file_locator.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/home_widget/widget_sync_service.dart';
import '../../../core/notifications/notification_service.dart';
import '../providers/settings_providers.dart';
import 'file_dialog_service.dart';

enum ImportFailureReason {
  /// The user's picked file doesn't exist, is empty, or isn't a ChoreBuddy
  /// database (garbage bytes, or a valid sqlite file missing the expected
  /// tables). The live database was never touched.
  integrityCheckFailed,

  /// The integrity check passed but something failed while swapping the
  /// file in (disk I/O, permissions, etc). If the failure happened before
  /// the live database file was actually replaced, it is left untouched --
  /// no restore is attempted or needed. If it happened after, the pre-swap
  /// backup is restored provided it still validates (same length as the
  /// pre-swap file, and passes the same read-only table check import
  /// candidates go through); see [restoreFailed] for when that isn't
  /// possible.
  swapFailed,

  /// The live database file was replaced and then something failed
  /// downstream, but restoring the pre-swap backup either failed outright
  /// or the backup no longer validated as a safe rollback source.
  /// [ImportException.cause] carries a message naming the on-disk path of
  /// the retained backup, if one exists.
  restoreFailed,

  /// Another import was already running when this call started.
  importInProgress,
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

  bool _importInProgress = false;

  /// Test-only seam: invoked with the pre-import backup file right after it
  /// has been written to disk, before the swap continues. Lets tests
  /// observe the backup mid-flow (it's deleted again on every exit path)
  /// or throw to provoke a failure before the live file is touched.
  @visibleForTesting
  Future<void> Function(File backupFile)? onBackupStaged;

  /// Test-only seam: invoked right after the staging file has been renamed
  /// into place -- i.e. after the live database has genuinely been
  /// replaced -- but before post-swap cleanup. Lets tests provoke a
  /// failure that must go through the restore path.
  @visibleForTesting
  Future<void> Function()? onAfterSwap;

  /// WAL-checkpoints then copies the live database file into a
  /// user-chosen directory. Returns false if the database file doesn't
  /// exist yet or the user cancels the directory picker; true on success.
  Future<bool> exportDatabase() async {
    final dbFile = await resolveDatabaseFile();
    if (!await dbFile.exists()) return false;

    final destinationDir =
        await ref.read(fileDialogServiceProvider).pickExportDirectory();
    if (destinationDir == null) return false;

    // Checkpointed as late as possible -- right before the copy -- so the
    // directory picker sitting open doesn't widen the window in which a
    // write could land in the WAL and be silently absent from the export.
    final db = ref.read(appDatabaseProvider);
    await db.customStatement('PRAGMA wal_checkpoint(FULL);');

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
  /// Throws [ImportException] on any failure -- see [ImportFailureReason]
  /// for what each reason guarantees about the live database's state.
  /// Throws [ImportException] with [ImportFailureReason.importInProgress]
  /// immediately if another import is already running.
  Future<void> importDatabase(String sourcePath) async {
    if (_importInProgress) {
      throw const ImportException(ImportFailureReason.importInProgress);
    }
    _importInProgress = true;
    try {
      await _importDatabase(sourcePath);
    } finally {
      _importInProgress = false;
    }
  }

  Future<void> _importDatabase(String sourcePath) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists() || await sourceFile.length() == 0) {
      throw const ImportException(ImportFailureReason.integrityCheckFailed);
    }
    if (!await _isValidChoreBuddyDatabase(sourceFile)) {
      throw const ImportException(ImportFailureReason.integrityCheckFailed);
    }

    final dbFile = await resolveDatabaseFile();
    final backupFile = await resolvePreImportBackupFile();
    // Timestamped so a leftover, undeletable entity from a previous failed
    // import can never permanently occupy the staging path for every
    // import after it.
    final stagingFile = File(
      '${dbFile.path}.importing.${DateTime.now().microsecondsSinceEpoch}',
    );

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
    var swapAttempted = false;
    int? preSwapLength;
    try {
      if (await dbFile.exists()) {
        preSwapLength = await dbFile.length();
        await dbFile.copy(backupFile.path);
        await onBackupStaged?.call(backupFile);
      }
      await sourceFile.copy(stagingFile.path);

      // Sidecars are already checkpointed and the connection already
      // closed, so it's safe -- and safer -- to clear them before the
      // rename rather than after: a crash in between can't leave the new
      // database file paired with a WAL that belongs to a different one.
      await _deleteSidecarFiles(dbFile);

      swapAttempted = true;
      await stagingFile.rename(dbFile.path);
      await onAfterSwap?.call();

      if (await backupFile.exists()) {
        await backupFile.delete();
      }
    } catch (e) {
      await _cleanupStagingEntity(stagingFile.path);

      if (swapAttempted &&
          preSwapLength != null &&
          await _isRestorableBackup(backupFile, preSwapLength)) {
        try {
          await backupFile.copy(dbFile.path);
          await backupFile.delete();
        } catch (restoreError) {
          throw ImportException(
            ImportFailureReason.restoreFailed,
            'restore failed after swap error ($e); pre-import backup '
                'retained at ${backupFile.path}: $restoreError',
          );
        }
      } else if (await backupFile.exists()) {
        // Either the live file was never actually replaced (nothing to
        // roll back to) or the backup no longer validates as a safe
        // rollback source -- either way it's just unneeded scratch now.
        try {
          await backupFile.delete();
        } catch (_) {
          // Best-effort; the swapFailed thrown below already reports e.
        }
      }
      throw ImportException(ImportFailureReason.swapFailed, e);
    } finally {
      ref.invalidate(appDatabaseProvider);
    }

    await ref.read(notificationServiceProvider).rescheduleAll();
    await ref.read(widgetSyncServiceProvider).sync();
  }

  /// True if [backupFile] is safe to copy back onto the live database:
  /// present, the same size the live file was before the swap touched it,
  /// and passing the same read-only table check an import candidate does.
  /// Guards against restoring a backup that was itself only partially
  /// written (e.g. the disk filled up mid-copy).
  Future<bool> _isRestorableBackup(File backupFile, int expectedLength) async {
    if (!await backupFile.exists()) return false;
    if (await backupFile.length() != expectedLength) return false;
    return _isValidChoreBuddyDatabase(backupFile);
  }

  /// Deletes whatever is at [path], file or directory, so a stray directory
  /// left at a staging path (e.g. by an earlier interrupted run) can't
  /// silently defeat cleanup the way `File.exists()` would.
  Future<void> _cleanupStagingEntity(String path) async {
    try {
      switch (await FileSystemEntity.type(path)) {
        case FileSystemEntityType.file:
          await File(path).delete();
          break;
        case FileSystemEntityType.directory:
          await Directory(path).delete(recursive: true);
          break;
        default:
          break;
      }
    } catch (_) {
      // Best-effort cleanup; the caller already has a failure to report.
    }
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
