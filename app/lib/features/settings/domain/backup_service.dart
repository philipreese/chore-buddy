import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/database/app_database.dart';
import '../../../core/database/database_file_locator.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/home_widget/widget_sync_service.dart';
import '../../../core/notifications/notification_service.dart';
import '../providers/settings_providers.dart';
import 'auto_backup_core.dart';
import 'backup_validation.dart';
import 'file_dialog_service.dart';

enum ImportFailureReason {
  /// The user's picked file doesn't exist, is empty, or isn't a ChoreBuddy
  /// database (garbage bytes, a valid sqlite file missing the expected
  /// tables, or one that fails a structural integrity check). The live
  /// database was never touched.
  integrityCheckFailed,

  /// The picked file is a genuine ChoreBuddy database, but its
  /// `PRAGMA user_version` is newer than this build's schema -- it was
  /// exported by a newer version of the app. Importing it would either
  /// silently mis-migrate (stamping a physically-newer file back to this
  /// build's version) or arm a permanent open failure the next time the
  /// app is genuinely updated, so it's rejected before the live database
  /// is ever touched.
  newerSchemaVersion,

  /// The pre-import WAL checkpoint reported that another connection (e.g.
  /// the scheduled auto-backup job or the notification background isolate,
  /// each of which opens its own connection to the same file) holds a read
  /// lock, so recent commits may still be WAL-only. The live database was
  /// never touched; retrying once that other connection releases its lock
  /// should succeed.
  checkpointBusy,

  /// The integrity check passed but something failed while swapping the
  /// file in (disk I/O, permissions, or a failure reopening/repairing the
  /// imported data, rescheduling notifications, or syncing the widget). If
  /// the failure happened before the live database file was actually
  /// replaced, it is left untouched -- no restore is attempted or needed.
  /// If it happened after, the pre-swap backup (main file plus its -wal/
  /// -shm sidecars) is restored provided it still validates (same length
  /// as the pre-swap file, and passes the same read-only check import
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

  /// Runs the same rotating-snapshot core the scheduled background job uses
  /// (see `auto_backup_task.dart`) in-process, for the Settings screen's
  /// "Back Up Now" action. Returns false if the database file doesn't exist
  /// yet or the fresh copy fails validation; true on success, having also
  /// updated [lastAutoBackupAtProvider] and rotated old snapshots away.
  Future<bool> backUpNow() async {
    final dbFile = await resolveDatabaseFile();
    final db = ref.read(appDatabaseProvider);
    final backupsDir = await resolveAutoBackupDirectory();

    final written = await writeAutoBackupSnapshot(
      db: db,
      dbFile: dbFile,
      backupsDir: backupsDir,
    );
    if (written == null) return false;

    ref.read(lastAutoBackupAtProvider.notifier).set(DateTime.now());
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

    // Checked ahead of the general validity check so a backup from a newer
    // build gets a specific, actionable failure reason instead of the
    // generic "not a valid database" one.
    final sourceVersion = await readDatabaseUserVersion(sourceFile);
    if (sourceVersion != null && sourceVersion > kSchemaVersion) {
      throw const ImportException(ImportFailureReason.newerSchemaVersion);
    }
    if (!await isValidChoreBuddyDatabase(sourceFile)) {
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
    bool checkpointBusy;
    try {
      final checkpointRow = await db
          .customSelect('PRAGMA wal_checkpoint(FULL);')
          .getSingleOrNull();
      // `PRAGMA wal_checkpoint(FULL)` reports failure via this result row's
      // `busy` column rather than throwing -- a bare `customStatement` call
      // (which discards any result) would make a busy checkpoint
      // completely invisible.
      checkpointBusy = checkpointRow != null && checkpointRow.read<int>('busy') != 0;
    } catch (e, st) {
      debugPrint('BackupService.importDatabase: checkpoint failed: $e\n$st');
      // Can't tell whether the checkpoint actually completed -- treat it
      // the same as busy so the import aborts rather than risk taking a
      // rollback copy that's silently missing WAL-only commits.
      checkpointBusy = true;
    } finally {
      await db.close();
    }

    if (checkpointBusy) {
      ref.invalidate(appDatabaseProvider);
      throw const ImportException(ImportFailureReason.checkpointBusy);
    }

    // From here the current connection is gone regardless of outcome, so
    // every exit path below must invalidate the provider to reconnect.
    var swapAttempted = false;
    int? preSwapLength;
    // Set once repair/reschedule/sync opens a fresh connection to the
    // swapped-in file below, so the catch block can close it explicitly
    // (and await that close) before overwriting the file during a restore
    // -- the same reason the pre-swap connection above is closed and
    // awaited before the swap starts.
    AppDatabase? postSwapDb;
    try {
      if (await dbFile.exists()) {
        preSwapLength = await dbFile.length();
        await dbFile.copy(backupFile.path);
        // Byte-faithful regardless of the checkpoint outcome above: carries
        // along whatever -wal/-shm state exists at backup time, so a
        // restore can never end up missing a commit the checkpoint didn't
        // actually clear from the main file.
        await _copySidecarFiles(dbFile, backupFile);
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

      // Reconnect now, before reading the imported data below, so the
      // repair/reschedule/sync steps see the freshly-swapped-in file
      // rather than the connection closed for the checkpoint above.
      ref.invalidate(appDatabaseProvider);
      final reopenedDb = ref.read(appDatabaseProvider);
      postSwapDb = reopenedDb;

      // This is the first time the imported file is ever opened as a
      // database, so reconnecting above just ran the schema migration --
      // the column this reads/writes is guaranteed to exist even for a
      // legacy backup. Deliberately inside the try: any failure here (a
      // reopen failure on a structurally-corrupt-but-schema-intact file,
      // or a failure rescheduling/syncing) must roll back the swap instead
      // of leaving the user with neither the original database nor a
      // backup.
      await reopenedDb.repairInvalidCustomDaysRecurrence();
      await ref.read(notificationServiceProvider).rescheduleAll();
      await ref.read(widgetSyncServiceProvider).sync();

      // Only now -- after the imported database has been successfully
      // reopened and read -- is the rollback point no longer needed.
      if (await backupFile.exists()) {
        await backupFile.delete();
      }
      await _deleteSidecarFiles(backupFile);
    } catch (e) {
      await _cleanupStagingEntity(stagingFile.path);

      if (postSwapDb != null) {
        try {
          await postSwapDb.close();
        } catch (_) {
          // Best-effort; the restore attempt below (or the swapFailed
          // thrown either way) already surfaces any real problem.
        }
      }

      if (swapAttempted &&
          preSwapLength != null &&
          await _isRestorableBackup(backupFile, preSwapLength)) {
        try {
          await backupFile.copy(dbFile.path);
          await _restoreSidecarFiles(backupFile, dbFile);
          await backupFile.delete();
          await _deleteSidecarFiles(backupFile);
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
          await _deleteSidecarFiles(backupFile);
        } catch (_) {
          // Best-effort; the swapFailed thrown below already reports e.
        }
      }
      throw ImportException(ImportFailureReason.swapFailed, e);
    } finally {
      ref.invalidate(appDatabaseProvider);
    }
  }

  /// True if [backupFile] is safe to copy back onto the live database:
  /// present, the same size the live file was before the swap touched it,
  /// and passing the same read-only table/version/integrity check an
  /// import candidate does. Guards against restoring a backup that was
  /// itself only partially written (e.g. the disk filled up mid-copy).
  Future<bool> _isRestorableBackup(File backupFile, int expectedLength) async {
    if (!await backupFile.exists()) return false;
    if (await backupFile.length() != expectedLength) return false;
    return isValidChoreBuddyDatabase(backupFile);
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

  Future<void> _deleteSidecarFiles(File dbFile) async {
    for (final suffix in ['-wal', '-shm']) {
      final sidecar = File('${dbFile.path}$suffix');
      if (await sidecar.exists()) {
        await sidecar.delete();
      }
    }
  }

  /// Copies [source]'s `-wal`/`-shm` sidecars alongside [destination] (only
  /// the ones that actually exist), so a byte-copy of [source]'s main file
  /// can be restored exactly as it stood, WAL included.
  Future<void> _copySidecarFiles(File source, File destination) async {
    for (final suffix in ['-wal', '-shm']) {
      final sourceSidecar = File('${source.path}$suffix');
      if (await sourceSidecar.exists()) {
        await sourceSidecar.copy('${destination.path}$suffix');
      }
    }
  }

  /// Restores [destination]'s `-wal`/`-shm` sidecars from [source]'s,
  /// mirroring [_copySidecarFiles] in reverse for the rollback path.
  /// Clears a destination sidecar that has no counterpart in [source] so a
  /// stale WAL from the swapped-in (now rolled-back) file can never end up
  /// paired with the restored main file.
  Future<void> _restoreSidecarFiles(File source, File destination) async {
    for (final suffix in ['-wal', '-shm']) {
      final sourceSidecar = File('${source.path}$suffix');
      final destinationSidecar = File('${destination.path}$suffix');
      if (await sourceSidecar.exists()) {
        await sourceSidecar.copy(destinationSidecar.path);
      } else if (await destinationSidecar.exists()) {
        await destinationSidecar.delete();
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
