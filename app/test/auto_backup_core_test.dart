import 'dart:io';

import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/features/settings/domain/auto_backup_core.dart';
import 'package:chorebuddy/features/settings/domain/backup_validation.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;

  setUp(() {
    // Sync IO throughout this file's setup: real dart:io async calls can
    // hang under `testWidgets`, and while these are plain `test()`s (not
    // `testWidgets()`), sync setup keeps the fake-clock file fixtures below
    // simple to read top to bottom.
    tempDir = Directory.systemTemp.createTempSync('chorebuddy_auto_backup_test');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('rotateAutoBackups', () {
    test('keeps only the newest 5 snapshots, deleting the rest', () async {
      final backupsDir = Directory(p.join(tempDir.path, 'backups'))
        ..createSync();

      // Fake clock: seven strictly increasing timestamps, oldest first.
      final clock = List.generate(
        7,
        (i) => DateTime(2026, 1, 1 + i, 3, 0, 0),
      );
      for (final timestamp in clock) {
        File(
          p.join(backupsDir.path, autoBackupFileName(timestamp)),
        ).writeAsBytesSync([1, 2, 3]);
      }

      await rotateAutoBackups(backupsDir);

      final remaining = backupsDir
          .listSync()
          .whereType<File>()
          .map((f) => p.basename(f.path))
          .toSet();
      expect(remaining, hasLength(5));
      expect(remaining, isNot(contains(autoBackupFileName(clock[0]))));
      expect(remaining, isNot(contains(autoBackupFileName(clock[1]))));
      for (final timestamp in clock.sublist(2)) {
        expect(remaining, contains(autoBackupFileName(timestamp)));
      }
    });

    test('never touches files outside its own auto-backup naming prefix',
        () async {
      final backupsDir = Directory(p.join(tempDir.path, 'backups'))
        ..createSync();
      final manualExport = File(
        p.join(backupsDir.path, 'chorebuddy_backup_20260101_030000.db3'),
      )..writeAsBytesSync([9]);
      for (var i = 0; i < 6; i++) {
        File(
          p.join(backupsDir.path, autoBackupFileName(DateTime(2026, 1, 1 + i))),
        ).writeAsBytesSync([1]);
      }

      await rotateAutoBackups(backupsDir);

      expect(manualExport.existsSync(), isTrue);
    });

    test('is a no-op when fewer than the keep count exist', () async {
      final backupsDir = Directory(p.join(tempDir.path, 'backups'))
        ..createSync();
      for (var i = 0; i < 3; i++) {
        File(
          p.join(backupsDir.path, autoBackupFileName(DateTime(2026, 1, 1 + i))),
        ).writeAsBytesSync([1]);
      }

      await rotateAutoBackups(backupsDir);

      expect(backupsDir.listSync(), hasLength(3));
    });
  });

  group('writeAutoBackupSnapshot: failure path', () {
    test(
        'a snapshot that fails validation is deleted and every existing '
        'snapshot is left untouched (no rotation)', () async {
      final backupsDir = Directory(p.join(tempDir.path, 'backups'))
        ..createSync();
      final preExisting = List.generate(
        5,
        (i) => File(
          p.join(backupsDir.path, autoBackupFileName(DateTime(2026, 1, 1 + i))),
        )..writeAsBytesSync([1, 2, 3]),
      );

      // Not a real ChoreBuddy database -- the copy will exist on disk but
      // fail the read-only table check, which must abort before rotation.
      final garbageDbFile = File(p.join(tempDir.path, 'garbage.sqlite'))
        ..writeAsBytesSync([1, 2, 3, 4, 5]);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final result = await writeAutoBackupSnapshot(
        db: db,
        dbFile: garbageDbFile,
        backupsDir: backupsDir,
        now: DateTime(2026, 6, 1),
      );

      expect(result, isNull);
      for (final file in preExisting) {
        expect(file.existsSync(), isTrue);
      }
      // Only the 5 pre-existing files remain -- the invalid new copy was
      // deleted, not left behind as a 6th entry.
      expect(backupsDir.listSync(), hasLength(5));
    });

    test('returns null and writes nothing when the database file does not exist yet',
        () async {
      final dbFile = File(p.join(tempDir.path, 'missing.sqlite'));
      final backupsDir = Directory(p.join(tempDir.path, 'backups'));
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final result = await writeAutoBackupSnapshot(
        db: db,
        dbFile: dbFile,
        backupsDir: backupsDir,
      );

      expect(result, isNull);
      expect(backupsDir.existsSync(), isFalse);
    });
  });

  group('writeAutoBackupSnapshot: backup core against an in-memory -> file db', () {
    test('writes a validated snapshot containing the live data and rotates old ones away',
        () async {
      final dbFile = File(p.join(tempDir.path, 'chore_buddy.sqlite'));
      final db = AppDatabase(NativeDatabase(dbFile));
      addTearDown(db.close);
      await db.insertChore(
        const ChoresCompanion(name: Value('Water Plants')),
      );

      final backupsDir = Directory(p.join(tempDir.path, 'backups'))
        ..createSync();
      for (var i = 0; i < 5; i++) {
        File(
          p.join(backupsDir.path, autoBackupFileName(DateTime(2026, 1, 1 + i))),
        ).writeAsBytesSync([1, 2, 3]);
      }

      final result = await writeAutoBackupSnapshot(
        db: db,
        dbFile: dbFile,
        backupsDir: backupsDir,
        now: DateTime(2026, 6, 1),
      );

      expect(result, isNotNull);
      expect(await isValidChoreBuddyDatabase(result!), isTrue);
      expect(p.basename(result.path), equals(autoBackupFileName(DateTime(2026, 6, 1))));

      // 5 pre-existing + 1 new = 6, rotated back down to the newest 5.
      expect(backupsDir.listSync(), hasLength(5));

      final resultDb = AppDatabase(NativeDatabase(result));
      final chores = await resultDb.select(resultDb.chores).get();
      expect(chores.map((c) => c.name), contains('Water Plants'));
      await resultDb.close();
    });
  });
}
