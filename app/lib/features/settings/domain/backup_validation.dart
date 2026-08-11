import 'dart:io';

import 'package:sqlite3/sqlite3.dart' as sqlite3;

import '../../../core/database/app_database.dart' show kSchemaVersion;

/// Every table a genuine ChoreBuddy database must have. Shared by every path
/// that needs to tell a real database file apart from garbage bytes or an
/// unrelated sqlite file: manual import, and the rotating auto-backup job.
const requiredChoreBuddyTables = {
  'chores',
  'tags',
  'completion_records',
  'chore_tags',
};

/// Opens [file] strictly read-only and checks: every table in
/// [requiredChoreBuddyTables] is present, `PRAGMA user_version` is not from
/// a newer schema than this build understands, and `PRAGMA quick_check`
/// reports the file's pages are structurally sound. Read-only is deliberate:
/// opening through [AppDatabase] would run its migration strategy, which
/// would silently *create* the expected tables in an unrelated empty sqlite
/// file and report it as valid. Garbage bytes fail to open at all; an
/// unrelated sqlite file opens but is missing the expected tables. Neither
/// mutates the file under inspection.
///
/// The version and quick-check gates exist because table *names* alone
/// aren't enough to call a file safe to swap in: a `.db3` whose schema row
/// is intact but whose data pages are truncated/corrupt (e.g. copied onto a
/// full disk) would otherwise pass here and only fail once the live
/// database has already been replaced and the rollback copy discarded --
/// and a file from a newer build's schema would otherwise be silently
/// mis-migrated or crash past the point of no return. Both must be caught
/// here, before the caller ever touches the live file.
Future<bool> isValidChoreBuddyDatabase(File file) async {
  sqlite3.Database? raw;
  try {
    raw = sqlite3.sqlite3.open(file.path, mode: sqlite3.OpenMode.readOnly);

    final rows = raw.select(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    final tableNames = rows.map((row) => row['name'] as String).toSet();
    if (!requiredChoreBuddyTables.every(tableNames.contains)) return false;

    final versionRows = raw.select('PRAGMA user_version;');
    final userVersion = versionRows.first['user_version'] as int;
    if (userVersion > kSchemaVersion) return false;

    final quickCheckRows = raw.select('PRAGMA quick_check;');
    if (quickCheckRows.length != 1 ||
        quickCheckRows.first['quick_check'] != 'ok') {
      return false;
    }

    return true;
  } catch (_) {
    return false;
  } finally {
    raw?.dispose();
  }
}

/// Reads `PRAGMA user_version` from [file] opened strictly read-only, or
/// null if the file can't be opened as sqlite at all (garbage bytes, an
/// entity that doesn't exist, etc). Split out from
/// [isValidChoreBuddyDatabase] so [BackupService] can distinguish "not a
/// database" from "a database from a newer schema" and surface a more
/// specific [ImportFailureReason] for the latter than the generic
/// [ImportFailureReason.integrityCheckFailed].
Future<int?> readDatabaseUserVersion(File file) async {
  sqlite3.Database? raw;
  try {
    raw = sqlite3.sqlite3.open(file.path, mode: sqlite3.OpenMode.readOnly);
    final rows = raw.select('PRAGMA user_version;');
    return rows.first['user_version'] as int;
  } catch (_) {
    return null;
  } finally {
    raw?.dispose();
  }
}
