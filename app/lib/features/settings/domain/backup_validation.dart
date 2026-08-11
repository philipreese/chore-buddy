import 'dart:io';

import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// Every table a genuine ChoreBuddy database must have. Shared by every path
/// that needs to tell a real database file apart from garbage bytes or an
/// unrelated sqlite file: manual import, and the rotating auto-backup job.
const requiredChoreBuddyTables = {
  'chores',
  'tags',
  'completion_records',
  'chore_tags',
};

/// Opens [file] strictly read-only and checks every table in
/// [requiredChoreBuddyTables] is present. Read-only is deliberate: opening
/// through [AppDatabase] would run its migration strategy, which would
/// silently *create* the expected tables in an unrelated empty sqlite file
/// and report it as valid. Garbage bytes fail to open at all; an unrelated
/// sqlite file opens but is missing the expected tables. Neither mutates the
/// file under inspection.
Future<bool> isValidChoreBuddyDatabase(File file) async {
  sqlite3.Database? raw;
  try {
    raw = sqlite3.sqlite3.open(file.path, mode: sqlite3.OpenMode.readOnly);
    final rows = raw.select(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    final tableNames = rows.map((row) => row['name'] as String).toSet();
    return requiredChoreBuddyTables.every(tableNames.contains);
  } catch (_) {
    return false;
  } finally {
    raw?.dispose();
  }
}
