import 'dart:io';

import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/tables.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

void main() {
  test(
      'schemaVersion 1 -> 2 migration adds a nullable emoji column without '
      'disturbing existing rows', () async {
    final dir =
        await Directory.systemTemp.createTemp('chorebuddy_migration_test');
    addTearDown(() => dir.delete(recursive: true));
    final path = p.join(dir.path, 'legacy.sqlite');

    // Build a real (current-schema) database via AppDatabase, then strip
    // the emoji column and roll PRAGMA user_version back to 1. This
    // guarantees the "legacy" schema this test upgrades from is exactly
    // what drift itself generates minus that one column, rather than a
    // hand-maintained duplicate of tables.dart that could drift out of
    // sync with the real schema.
    var db = AppDatabase(NativeDatabase(File(path)));
    await db.insertTag(
      const TagsCompanion(name: Value('kitchen'), colorIndex: Value(2)),
    );
    await db.close();

    final raw = sqlite3.sqlite3.open(path);
    raw.execute('ALTER TABLE tags DROP COLUMN emoji;');
    // A real v1 database predates recurrence_interval (v3) and chores.emoji
    // (v4) too -- without dropping every column newer than v1, the replayed
    // migration hits "duplicate column name".
    raw.execute('ALTER TABLE chores DROP COLUMN recurrence_interval;');
    raw.execute('ALTER TABLE chores DROP COLUMN emoji;');
    // A real v1 database predates the @TableIndex indexes (v5) too --
    // `AppDatabase(NativeDatabase(File(path)))` above already created them
    // via onCreate, so without dropping them the replayed v5 migration
    // hits "index already exists".
    raw.execute('DROP INDEX idx_completion_records_chore_id;');
    raw.execute('DROP INDEX idx_chore_tags_tag_id;');
    raw.execute('PRAGMA user_version = 1;');
    raw.dispose();

    // Reopening at the app's real schemaVersion (2) must run the
    // addColumn migration automatically.
    db = AppDatabase(NativeDatabase(File(path)));
    final tags = await db.select(db.tags).get();
    expect(tags, hasLength(1));
    expect(tags.single.name, equals('kitchen'));
    expect(tags.single.emoji, isNull);

    // The migrated column is genuinely usable afterwards, not just present.
    final newId = await db.insertTag(
      const TagsCompanion(
        name: Value('garage'),
        colorIndex: Value(1),
        emoji: Value('🚗'),
      ),
    );
    final fetched =
        await (db.select(db.tags)..where((t) => t.id.equals(newId)))
            .getSingle();
    expect(fetched.emoji, equals('🚗'));

    await db.close();
  });

  test(
      'schemaVersion 2 -> 3 migration adds a nullable recurrence_interval '
      'column without disturbing existing rows', () async {
    final dir =
        await Directory.systemTemp.createTemp('chorebuddy_migration_test');
    addTearDown(() => dir.delete(recursive: true));
    final path = p.join(dir.path, 'legacy.sqlite');

    // Same technique as the v1 -> v2 test above: build a real (current-
    // schema) database, then strip the new column back off and roll PRAGMA
    // user_version to 2, so the "legacy" schema upgraded from here is
    // exactly what drift itself generates minus recurrence_interval.
    var db = AppDatabase(NativeDatabase(File(path)));
    await db.insertChore(
      const ChoresCompanion(
        name: Value('Water Plants'),
        recurrence: Value(RecurrenceType.daily),
      ),
    );
    await db.close();

    final raw = sqlite3.sqlite3.open(path);
    raw.execute('ALTER TABLE chores DROP COLUMN recurrence_interval;');
    // A real v2 database predates chores.emoji (v4) too -- without dropping
    // it the replayed migration hits "duplicate column name".
    raw.execute('ALTER TABLE chores DROP COLUMN emoji;');
    // Predates the @TableIndex indexes (v5) too -- see the v1->v2 test's
    // comment above.
    raw.execute('DROP INDEX idx_completion_records_chore_id;');
    raw.execute('DROP INDEX idx_chore_tags_tag_id;');
    raw.execute('PRAGMA user_version = 2;');
    raw.dispose();

    // Reopening at the app's real schemaVersion (5) must run both addColumn
    // migrations (recurrence_interval, then emoji) automatically.
    db = AppDatabase(NativeDatabase(File(path)));
    final chores = await db.select(db.chores).get();
    expect(chores, hasLength(1));
    expect(chores.single.name, equals('Water Plants'));
    expect(chores.single.recurrenceInterval, isNull);
    expect(chores.single.emoji, isNull);

    // The migrated column is genuinely usable afterwards, not just present.
    final newId = await db.insertChore(
      const ChoresCompanion(
        name: Value('Change Sheets'),
        recurrence: Value(RecurrenceType.customDays),
        recurrenceInterval: Value(10),
      ),
    );
    final fetched =
        await (db.select(db.chores)..where((c) => c.id.equals(newId)))
            .getSingle();
    expect(fetched.recurrence, equals(RecurrenceType.customDays));
    expect(fetched.recurrenceInterval, equals(10));

    await db.close();
  });

  test(
      'schemaVersion 3 -> 4 migration adds a nullable chores.emoji column '
      'without disturbing existing rows', () async {
    final dir =
        await Directory.systemTemp.createTemp('chorebuddy_migration_test');
    addTearDown(() => dir.delete(recursive: true));
    final path = p.join(dir.path, 'legacy.sqlite');

    // Same technique as the migrations above: build a real (current-schema)
    // database, then strip chores.emoji back off and roll PRAGMA
    // user_version to 3, so the "legacy" schema upgraded from here is
    // exactly what drift itself generates minus that one column.
    var db = AppDatabase(NativeDatabase(File(path)));
    await db.insertChore(
      const ChoresCompanion(
        name: Value('Water Plants'),
        recurrence: Value(RecurrenceType.daily),
      ),
    );
    await db.close();

    final raw = sqlite3.sqlite3.open(path);
    raw.execute('ALTER TABLE chores DROP COLUMN emoji;');
    // Predates the @TableIndex indexes (v5) too -- see the v1->v2 test's
    // comment above.
    raw.execute('DROP INDEX idx_completion_records_chore_id;');
    raw.execute('DROP INDEX idx_chore_tags_tag_id;');
    raw.execute('PRAGMA user_version = 3;');
    raw.dispose();

    // Reopening at the app's real schemaVersion (5) must run the addColumn
    // migration automatically.
    db = AppDatabase(NativeDatabase(File(path)));
    final chores = await db.select(db.chores).get();
    expect(chores, hasLength(1));
    expect(chores.single.name, equals('Water Plants'));
    expect(chores.single.emoji, isNull);

    // The migrated column is genuinely usable afterwards, not just present.
    final newId = await db.insertChore(
      const ChoresCompanion(
        name: Value('Take Out Trash'),
        emoji: Value('🗑️'),
      ),
    );
    final fetched =
        await (db.select(db.chores)..where((c) => c.id.equals(newId)))
            .getSingle();
    expect(fetched.emoji, equals('🗑️'));

    await db.close();
  });

  test(
      'schemaVersion 4 -> 5 migration creates the completion_records and '
      'chore_tags indexes', () async {
    final dir =
        await Directory.systemTemp.createTemp('chorebuddy_migration_test');
    addTearDown(() => dir.delete(recursive: true));
    final path = p.join(dir.path, 'legacy.sqlite');

    // Build a real (current-schema) database, then drop the two @TableIndex
    // indexes createAll gave it and roll PRAGMA user_version back to 4, so
    // the "legacy" schema upgraded from here is exactly what a pre-spec-26
    // install would have on disk.
    var db = AppDatabase(NativeDatabase(File(path)));
    await db.insertChore(
      const ChoresCompanion(
        name: Value('Water Plants'),
        recurrence: Value(RecurrenceType.daily),
      ),
    );
    await db.close();

    final raw = sqlite3.sqlite3.open(path);
    raw.execute('DROP INDEX idx_completion_records_chore_id;');
    raw.execute('DROP INDEX idx_chore_tags_tag_id;');
    raw.execute('PRAGMA user_version = 4;');
    raw.dispose();

    // Reopening at the app's real schemaVersion (5) must (re)create both
    // indexes -- this is the case database_migration_test.dart couldn't
    // catch before: every prior fixture here was built via createAll, which
    // always includes the indexes, so only dropping columns never exposed
    // an onUpgrade path that skips them.
    db = AppDatabase(NativeDatabase(File(path)));
    await db.select(db.chores).get();

    final indexNames = (await db
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'index'",
            )
            .get())
        .map((row) => row.read<String>('name'))
        .toSet();
    expect(
      indexNames,
      containsAll(['idx_completion_records_chore_id', 'idx_chore_tags_tag_id']),
    );

    await db.close();
  });

  test(
      'opening a database whose user_version is newer than schemaVersion '
      'throws instead of silently downgrading it', () async {
    final dir =
        await Directory.systemTemp.createTemp('chorebuddy_migration_test');
    addTearDown(() => dir.delete(recursive: true));
    final path = p.join(dir.path, 'future.sqlite');

    var db = AppDatabase(NativeDatabase(File(path)));
    await db.insertChore(const ChoresCompanion(name: Value('Water Plants')));
    await db.close();

    final raw = sqlite3.sqlite3.open(path);
    raw.execute('PRAGMA user_version = 99;');
    raw.dispose();

    // onUpgrade's `if (from > to) throw` belt-and-braces guard must fire
    // rather than let a 99 -> 5 "upgrade" silently no-op through the
    // `from < N` chain and get stamped back down to 5.
    db = AppDatabase(NativeDatabase(File(path)));
    await expectLater(() => db.select(db.chores).get(), throwsA(anything));
    await db.close();
  });
}
