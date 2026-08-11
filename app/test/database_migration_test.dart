import 'dart:io';

import 'package:chorebuddy/core/database/app_database.dart';
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
}
