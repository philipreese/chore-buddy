import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/database/app_database.dart';
import 'backup_validation.dart';

/// Auto-backup files are kept as `chorebuddy-auto-<stamp>.db`, distinct from
/// the `.db3` extension manual exports use, so rotation's directory listing
/// can never sweep up a manual export or an unrelated file that happens to
/// share the backups folder.
const kAutoBackupFilePrefix = 'chorebuddy-auto-';
const kAutoBackupFileExtension = '.db';

/// How many rotating snapshots [writeAutoBackupSnapshot] keeps. The newest
/// [kAutoBackupKeepCount] survive; anything older is deleted once a new,
/// validated snapshot lands.
const kAutoBackupKeepCount = 5;

/// `backups/` inside the app's external files directory, falling back to the
/// app documents directory when external storage isn't available (some
/// devices/emulators have none mounted). Shared by the in-process "Back Up
/// Now" action, the scheduled background job, and the settings screen's
/// read-only destination display, so all three always agree on where
/// auto-backups live.
Future<Directory> resolveAutoBackupDirectory() async {
  final externalDir = await getExternalStorageDirectory();
  final base = externalDir ?? await getApplicationDocumentsDirectory();
  return Directory(p.join(base.path, 'backups'));
}

/// `chorebuddy-auto-YYYYMMDD-HHmmss.db`, sortable lexicographically in
/// chronological order so [rotateAutoBackups] can pick the oldest files
/// without parsing the timestamp back out.
String autoBackupFileName(DateTime timestamp) {
  String pad(int value) => value.toString().padLeft(2, '0');
  final stamp =
      '${timestamp.year}${pad(timestamp.month)}${pad(timestamp.day)}'
      '-${pad(timestamp.hour)}${pad(timestamp.minute)}${pad(timestamp.second)}';
  return '$kAutoBackupFilePrefix$stamp$kAutoBackupFileExtension';
}

/// WAL-checkpoints [db], then copies [dbFile] into [backupsDir] under a
/// timestamped name and validates the copy through the same
/// [isValidChoreBuddyDatabase] check import candidates go through -- the
/// "same snapshot/validation code path as manual export" this exists to
/// share, rather than duplicate, between the in-process "Back Up Now" action
/// and the scheduled background job.
///
/// Returns null (and deletes the bad copy, but never touches an existing
/// snapshot) if [dbFile] doesn't exist yet or the freshly-written copy fails
/// validation -- e.g. the disk filled up mid-copy. Only rotates old snapshots
/// away once the new one is confirmed good, so a failed write can never
/// shrink the set of recoverable backups.
Future<File?> writeAutoBackupSnapshot({
  required AppDatabase db,
  required File dbFile,
  required Directory backupsDir,
  DateTime? now,
}) async {
  if (!await dbFile.exists()) return null;

  await db.customStatement('PRAGMA wal_checkpoint(FULL);');
  await backupsDir.create(recursive: true);

  final destination = File(
    p.join(backupsDir.path, autoBackupFileName(now ?? DateTime.now())),
  );
  await dbFile.copy(destination.path);

  if (!await isValidChoreBuddyDatabase(destination)) {
    try {
      await destination.delete();
    } catch (_) {
      // Best-effort; the null return already signals failure to the caller.
    }
    return null;
  }

  await rotateAutoBackups(backupsDir);
  return destination;
}

/// Keeps only the newest [keep] `chorebuddy-auto-*.db` files in
/// [backupsDir], deleting the rest. Filenames sort chronologically (see
/// [autoBackupFileName]), so no timestamp parsing is needed to find the
/// oldest ones.
Future<void> rotateAutoBackups(
  Directory backupsDir, {
  int keep = kAutoBackupKeepCount,
}) async {
  if (!await backupsDir.exists()) return;

  final entries = await backupsDir.list().toList();
  final autoBackups =
      entries
          .whereType<File>()
          .where(
            (file) => p.basename(file.path).startsWith(kAutoBackupFilePrefix),
          )
          .toList()
        ..sort((a, b) => p.basename(b.path).compareTo(p.basename(a.path)));

  for (final stale in autoBackups.skip(keep)) {
    try {
      await stale.delete();
    } catch (_) {
      // Best-effort: a file that can't be deleted this round is retried the
      // next time a new snapshot triggers rotation.
    }
  }
}
