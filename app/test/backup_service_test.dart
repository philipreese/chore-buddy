import 'dart:io';

import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/database_file_locator.dart';
import 'package:chorebuddy/core/database/database_provider.dart';
import 'package:chorebuddy/core/database/tables.dart';
import 'package:chorebuddy/features/settings/domain/auto_backup_core.dart';
import 'package:chorebuddy/features/settings/domain/backup_service.dart';
import 'package:chorebuddy/features/settings/domain/file_dialog_service.dart';
import 'package:chorebuddy/features/settings/providers/settings_providers.dart';
import 'package:chorebuddy/core/notifications/notification_service.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import 'fakes/fake_file_dialog_service.dart';
import 'fakes/fake_notification_scheduler.dart';
import 'fakes/fake_notification_service.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  final String documentsPath;
  final String supportPath;
  final String? externalStoragePath;

  _FakePathProviderPlatform({
    required this.documentsPath,
    required this.supportPath,
    this.externalStoragePath,
  });

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;

  @override
  Future<String?> getApplicationSupportPath() async => supportPath;

  @override
  Future<String?> getExternalStoragePath() async => externalStoragePath;
}

void main() {
  late Directory tempDir;
  late Directory exportDir;
  late File dbFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('chorebuddy_backup_test');
    final documentsDir = Directory(p.join(tempDir.path, 'docs'))
      ..createSync();
    final supportDir = Directory(p.join(tempDir.path, 'support'))
      ..createSync();
    final externalDir = Directory(p.join(tempDir.path, 'external'))
      ..createSync();
    exportDir = Directory(p.join(tempDir.path, 'exports'))..createSync();

    PathProviderPlatform.instance = _FakePathProviderPlatform(
      documentsPath: documentsDir.path,
      supportPath: supportDir.path,
      externalStoragePath: externalDir.path,
    );

    dbFile = File(p.join(documentsDir.path, '$kDatabaseName.sqlite'));
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  ProviderContainer buildContainer({
    required FakeFileDialogService dialogService,
    FakeNotificationService? notificationService,
    FakeNotificationScheduler? notificationScheduler,
  }) {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          final database = AppDatabase(NativeDatabase(dbFile));
          ref.onDispose(() => database.close());
          return database;
        }),
        fileDialogServiceProvider.overrideWithValue(dialogService),
        if (notificationService != null)
          notificationServiceProvider.overrideWithValue(notificationService),
        if (notificationScheduler != null)
          notificationSchedulerProvider.overrideWithValue(notificationScheduler),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<File> writeValidDatabase(
    String path, {
    required String choreName,
    DateTime? nextDueDate,
  }) async {
    final file = File(path);
    final db = AppDatabase(NativeDatabase(file));
    await db.insertChore(
      ChoresCompanion(
        name: Value(choreName),
        nextDueDate: Value(nextDueDate),
      ),
    );
    await db.close();
    return file;
  }

  group('BackupService.exportDatabase', () {
    test('checkpoints, copies the db into the chosen directory, and records the timestamp',
        () async {
      final dialog = FakeFileDialogService()
        ..exportDirectoryToReturn = exportDir.path;
      final container = buildContainer(dialogService: dialog);
      final db = container.read(appDatabaseProvider);
      await db.insertChore(const ChoresCompanion(name: Value('Water Plants')));

      final result = await container.read(backupServiceProvider).exportDatabase();

      expect(result, isTrue);
      final exported = exportDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.db3'))
          .toList();
      expect(exported, hasLength(1));
      expect(container.read(lastBackupAtProvider), isNotNull);

      final exportedDb = AppDatabase(NativeDatabase(exported.single));
      final chores = await exportedDb.select(exportedDb.chores).get();
      expect(chores.map((c) => c.name), contains('Water Plants'));
      await exportedDb.close();
    });

    test('returns false and writes nothing when the user cancels the directory picker',
        () async {
      final dialog = FakeFileDialogService(); // exportDirectoryToReturn left null
      final container = buildContainer(dialogService: dialog);
      await container.read(appDatabaseProvider).insertChore(
            const ChoresCompanion(name: Value('Water Plants')),
          );

      final result = await container.read(backupServiceProvider).exportDatabase();

      expect(result, isFalse);
      expect(container.read(lastBackupAtProvider), isNull);
    });
  });

  group('BackupService.backUpNow', () {
    test('writes a rotating snapshot into the resolved auto-backup directory and records the timestamp',
        () async {
      final container = buildContainer(dialogService: FakeFileDialogService());
      await container.read(appDatabaseProvider).insertChore(
            const ChoresCompanion(name: Value('Water Plants')),
          );

      final result = await container.read(backupServiceProvider).backUpNow();

      expect(result, isTrue);
      expect(container.read(lastAutoBackupAtProvider), isNotNull);

      final backupsDir = await resolveAutoBackupDirectory();
      final written = backupsDir
          .listSync()
          .whereType<File>()
          .where((f) => p.basename(f.path).startsWith(kAutoBackupFilePrefix))
          .toList();
      expect(written, hasLength(1));

      final writtenDb = AppDatabase(NativeDatabase(written.single));
      final chores = await writtenDb.select(writtenDb.chores).get();
      expect(chores.map((c) => c.name), contains('Water Plants'));
      await writtenDb.close();
    });

    test('returns false and records nothing when the database file does not exist yet',
        () async {
      final container = buildContainer(dialogService: FakeFileDialogService());
      // No insert, no provider read that would open the connection --
      // resolveDatabaseFile() points at a file that was never created.

      final result = await container.read(backupServiceProvider).backUpNow();

      expect(result, isFalse);
      expect(container.read(lastAutoBackupAtProvider), isNull);
    });
  });

  group('BackupService.importDatabase', () {
    test('a valid file swaps in and a fresh provider read shows the imported data',
        () async {
      final notificationService = FakeNotificationService();
      final container = buildContainer(
        dialogService: FakeFileDialogService(),
        notificationService: notificationService,
      );
      await container.read(appDatabaseProvider).insertChore(
            const ChoresCompanion(name: Value('Original Chore')),
          );

      final sourceFile = await writeValidDatabase(
        p.join(tempDir.path, 'incoming.db3'),
        choreName: 'Imported Chore',
      );

      await container.read(backupServiceProvider).importDatabase(sourceFile.path);

      final freshDb = container.read(appDatabaseProvider);
      final chores = await freshDb.select(freshDb.chores).get();
      expect(chores.map((c) => c.name), equals(['Imported Chore']));
      expect(notificationService.rescheduleAllCallCount, equals(1));

      final backupFile = await resolvePreImportBackupFile();
      expect(await backupFile.exists(), isFalse);
    });

    test(
        'rescheduleAll after import reads the freshly imported data, not the closed connection',
        () async {
      final scheduler = FakeNotificationScheduler();
      final container = buildContainer(
        dialogService: FakeFileDialogService(),
        notificationScheduler: scheduler,
      );
      await container.read(appDatabaseProvider).insertChore(
            ChoresCompanion(
              name: const Value('Original Chore'),
              nextDueDate: Value(DateTime.now().add(const Duration(days: 1))),
            ),
          );

      // Whole-second value: drift's DateTime column round-trips at second
      // precision, so sub-second components would fail the equality below.
      final now = DateTime.now();
      final due = DateTime(now.year, now.month, now.day, now.hour)
          .add(const Duration(days: 3));
      final sourceFile = await writeValidDatabase(
        p.join(tempDir.path, 'incoming.db3'),
        choreName: 'Imported Chore',
        nextDueDate: due,
      );

      await container.read(backupServiceProvider).importDatabase(sourceFile.path);

      // This only passes if `ref.read(notificationServiceProvider)` after
      // the invalidate at the end of the swap actually rebuilds against the
      // newly-imported database rather than reusing a closed connection
      // captured before the swap.
      expect(scheduler.scheduled, hasLength(1));
      expect(scheduler.scheduled.single.title, contains('Imported Chore'));
      expect(scheduler.scheduled.single.scheduledDate, equals(due));
    });

    test('garbage bytes are rejected and the current db is left untouched',
        () async {
      final container = buildContainer(dialogService: FakeFileDialogService());
      final originalDb = container.read(appDatabaseProvider);
      await originalDb.insertChore(const ChoresCompanion(name: Value('Keep Me')));

      final garbageFile = File(p.join(tempDir.path, 'garbage.db3'));
      await garbageFile.writeAsBytes([1, 2, 3, 4, 5]);

      await expectLater(
        () => container.read(backupServiceProvider).importDatabase(garbageFile.path),
        throwsA(
          isA<ImportException>().having(
            (e) => e.reason,
            'reason',
            ImportFailureReason.integrityCheckFailed,
          ),
        ),
      );

      final chores = await originalDb.select(originalDb.chores).get();
      expect(chores.map((c) => c.name), equals(['Keep Me']));
      final backupFile = await resolvePreImportBackupFile();
      expect(
        await backupFile.exists(),
        isFalse,
        reason: 'integrity check must fail before any backup is staged',
      );
    });

    test('a sqlite file missing the expected tables is rejected', () async {
      final container = buildContainer(dialogService: FakeFileDialogService());
      final unrelatedPath = p.join(tempDir.path, 'unrelated.sqlite');
      final rawDb = sqlite3.sqlite3.open(unrelatedPath);
      rawDb.execute('CREATE TABLE some_other_table (id INTEGER PRIMARY KEY);');
      rawDb.dispose();

      await expectLater(
        () => container.read(backupServiceProvider).importDatabase(unrelatedPath),
        throwsA(
          isA<ImportException>().having(
            (e) => e.reason,
            'reason',
            ImportFailureReason.integrityCheckFailed,
          ),
        ),
      );
    });

    test(
        'a failure before the swap (backup copy fails) leaves the live db untouched and does not restore',
        () async {
      final container = buildContainer(dialogService: FakeFileDialogService());
      final originalDb = container.read(appDatabaseProvider);
      await originalDb.insertChore(const ChoresCompanion(name: Value('Keep Me')));

      final sourceFile = await writeValidDatabase(
        p.join(tempDir.path, 'incoming.db3'),
        choreName: 'Imported Chore',
      );

      // Occupy the pre-import backup path with a directory so the very
      // first mutating step -- copying the live db there -- throws before
      // the live database has been touched at all. `File.copy` cannot
      // overwrite a directory.
      final backupFile = await resolvePreImportBackupFile();
      await Directory(backupFile.path).create(recursive: true);

      await expectLater(
        () => container.read(backupServiceProvider).importDatabase(sourceFile.path),
        throwsA(
          isA<ImportException>().having(
            (e) => e.reason,
            'reason',
            ImportFailureReason.swapFailed,
          ),
        ),
      );

      final freshDb = container.read(appDatabaseProvider);
      final chores = await freshDb.select(freshDb.chores).get();
      expect(chores.map((c) => c.name), equals(['Keep Me']));
    });

    test(
        'a failure after the swap restores the pre-import backup, leaving the db intact',
        () async {
      final container = buildContainer(dialogService: FakeFileDialogService());
      final originalDb = container.read(appDatabaseProvider);
      await originalDb.insertChore(const ChoresCompanion(name: Value('Keep Me')));

      final sourceFile = await writeValidDatabase(
        p.join(tempDir.path, 'incoming.db3'),
        choreName: 'Imported Chore',
      );

      final service = container.read(backupServiceProvider);
      // Fires only after the staging file has genuinely been renamed into
      // place, i.e. after the live database really has been replaced --
      // this is the branch finding 1 requires be conditional on.
      service.onAfterSwap = () async {
        throw StateError('simulated post-swap failure');
      };

      await expectLater(
        () => service.importDatabase(sourceFile.path),
        throwsA(
          isA<ImportException>().having(
            (e) => e.reason,
            'reason',
            ImportFailureReason.swapFailed,
          ),
        ),
      );

      final backupFile = await resolvePreImportBackupFile();
      expect(await backupFile.exists(), isFalse);

      final freshDb = container.read(appDatabaseProvider);
      final chores = await freshDb.select(freshDb.chores).get();
      expect(chores.map((c) => c.name), equals(['Keep Me']));
    });

    test(
        'the pre-import backup file is actually written to disk during a successful swap, before cleanup',
        () async {
      final container = buildContainer(dialogService: FakeFileDialogService());
      await container.read(appDatabaseProvider).insertChore(
            const ChoresCompanion(name: Value('Keep Me')),
          );

      final sourceFile = await writeValidDatabase(
        p.join(tempDir.path, 'incoming.db3'),
        choreName: 'Imported Chore',
      );

      final service = container.read(backupServiceProvider);
      File? stagedBackup;
      bool? existedWhenStaged;
      service.onBackupStaged = (backupFile) async {
        stagedBackup = backupFile;
        existedWhenStaged = await backupFile.exists();
      };

      await service.importDatabase(sourceFile.path);

      expect(stagedBackup, isNotNull);
      expect(existedWhenStaged, isTrue);
      // ... and cleaned up again once the swap succeeds.
      expect(await stagedBackup!.exists(), isFalse);
    });

    test('a second import while one is already running is rejected immediately',
        () async {
      final container = buildContainer(dialogService: FakeFileDialogService());
      await container.read(appDatabaseProvider).insertChore(
            const ChoresCompanion(name: Value('Keep Me')),
          );

      final sourceFile = await writeValidDatabase(
        p.join(tempDir.path, 'incoming.db3'),
        choreName: 'Imported Chore',
      );

      final service = container.read(backupServiceProvider);
      final reentrantErrors = <Object>[];
      service.onBackupStaged = (_) async {
        try {
          await service.importDatabase(sourceFile.path);
        } catch (e) {
          reentrantErrors.add(e);
        }
      };

      await service.importDatabase(sourceFile.path);

      expect(reentrantErrors, hasLength(1));
      expect(
        (reentrantErrors.single as ImportException).reason,
        equals(ImportFailureReason.importInProgress),
      );
    });

    test('an auto-backup export is importable through the same restore path',
        () async {
      final container = buildContainer(dialogService: FakeFileDialogService());
      await container.read(appDatabaseProvider).insertChore(
            const ChoresCompanion(name: Value('Original Chore')),
          );

      // Produce a file the same way the scheduled background job and the
      // "Back Up Now" action do, then feed it straight into the manual
      // import flow -- the restore path a user reaches for the auto-backup
      // files this spec adds.
      final autoBackupDb = AppDatabase(
        NativeDatabase(File(p.join(tempDir.path, 'auto_source.sqlite'))),
      );
      await autoBackupDb.insertChore(
        const ChoresCompanion(name: Value('Auto-Backed-Up Chore')),
      );
      final backupsDir = Directory(p.join(tempDir.path, 'auto_backups'));
      final autoBackupFile = await writeAutoBackupSnapshot(
        db: autoBackupDb,
        dbFile: File(p.join(tempDir.path, 'auto_source.sqlite')),
        backupsDir: backupsDir,
      );
      await autoBackupDb.close();
      expect(autoBackupFile, isNotNull);

      await container
          .read(backupServiceProvider)
          .importDatabase(autoBackupFile!.path);

      final freshDb = container.read(appDatabaseProvider);
      final chores = await freshDb.select(freshDb.chores).get();
      expect(chores.map((c) => c.name), equals(['Auto-Backed-Up Chore']));
    });

    test('a tag emoji round-trips through export then import (spec 19)',
        () async {
      final dialog = FakeFileDialogService()
        ..exportDirectoryToReturn = exportDir.path;
      final container = buildContainer(dialogService: dialog);
      final db = container.read(appDatabaseProvider);
      await db.insertTag(
        const TagsCompanion(
          name: Value('kitchen'),
          colorIndex: Value(0),
          emoji: Value('🧹'),
        ),
      );

      expect(await container.read(backupServiceProvider).exportDatabase(),
          isTrue);
      final exported = exportDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.db3'))
          .single;

      await container
          .read(backupServiceProvider)
          .importDatabase(exported.path);

      final freshDb = container.read(appDatabaseProvider);
      final tags = await freshDb.select(freshDb.tags).get();
      expect(tags.single.name, equals('kitchen'));
      expect(tags.single.emoji, equals('🧹'));
    });

    test('a customDays interval round-trips through export then import (spec 21)',
        () async {
      final dialog = FakeFileDialogService()
        ..exportDirectoryToReturn = exportDir.path;
      final container = buildContainer(dialogService: dialog);
      final db = container.read(appDatabaseProvider);
      await db.insertChore(
        const ChoresCompanion(
          name: Value('Change Sheets'),
          recurrence: Value(RecurrenceType.customDays),
          recurrenceInterval: Value(10),
        ),
      );

      expect(await container.read(backupServiceProvider).exportDatabase(),
          isTrue);
      final exported = exportDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.db3'))
          .single;

      await container
          .read(backupServiceProvider)
          .importDatabase(exported.path);

      final freshDb = container.read(appDatabaseProvider);
      final chores = await freshDb.select(freshDb.chores).get();
      expect(chores.single.name, equals('Change Sheets'));
      expect(chores.single.recurrence, equals(RecurrenceType.customDays));
      expect(chores.single.recurrenceInterval, equals(10));
    });

    test(
        'a legacy backup written before recurrence_interval existed imports '
        'cleanly, with the interval absent/null (spec 21)', () async {
      final container = buildContainer(dialogService: FakeFileDialogService());
      await container.read(appDatabaseProvider).insertChore(
            const ChoresCompanion(name: Value('Original Chore')),
          );

      // A pre-spec-21 backup file: same tables, but the chores table has no
      // recurrence_interval column and the file's own schema version
      // predates it -- built the same way the emoji legacy test above does.
      final legacyPath = p.join(tempDir.path, 'legacy_no_interval.sqlite');
      final legacyDb = AppDatabase(NativeDatabase(File(legacyPath)));
      await legacyDb.insertChore(
        const ChoresCompanion(
          name: Value('Water Plants'),
          recurrence: Value(RecurrenceType.daily),
        ),
      );
      await legacyDb.close();
      final raw = sqlite3.sqlite3.open(legacyPath);
      raw.execute('ALTER TABLE chores DROP COLUMN recurrence_interval;');
      // A real v2 backup predates chores.emoji (v4) too -- without dropping
      // it the replayed migration hits "duplicate column name".
      raw.execute('ALTER TABLE chores DROP COLUMN emoji;');
      raw.execute('PRAGMA user_version = 2;');
      raw.dispose();

      await container
          .read(backupServiceProvider)
          .importDatabase(legacyPath);

      final freshDb = container.read(appDatabaseProvider);
      final chores = await freshDb.select(freshDb.chores).get();
      expect(chores.single.name, equals('Water Plants'));
      expect(chores.single.recurrenceInterval, isNull);
      expect(chores.single.emoji, isNull);
    });

    test(
        'a corrupt customDays chore with a null interval falls back to none '
        'on import instead of crashing (spec 21)', () async {
      final container = buildContainer(dialogService: FakeFileDialogService());
      await container.read(appDatabaseProvider).insertChore(
            const ChoresCompanion(name: Value('Original Chore')),
          );

      // Simulates a hand-tampered/corrupt backup: a customDays chore whose
      // interval never got written (or was cleared) -- current schema, so
      // no migration is involved, just the post-swap repair pass.
      final corruptPath = p.join(tempDir.path, 'corrupt_custom_days.sqlite');
      final corruptDb = AppDatabase(NativeDatabase(File(corruptPath)));
      await corruptDb.insertChore(
        const ChoresCompanion(
          name: Value('Broken Recurrence'),
          recurrence: Value(RecurrenceType.customDays),
        ),
      );
      await corruptDb.close();

      await container
          .read(backupServiceProvider)
          .importDatabase(corruptPath);

      final freshDb = container.read(appDatabaseProvider);
      final chores = await freshDb.select(freshDb.chores).get();
      expect(chores.single.name, equals('Broken Recurrence'));
      expect(chores.single.recurrence, equals(RecurrenceType.none));
      expect(chores.single.recurrenceInterval, isNull);
    });

    test(
        'a legacy backup written before the emoji column existed imports '
        'cleanly, with emoji absent/null (spec 19)', () async {
      final container = buildContainer(dialogService: FakeFileDialogService());
      await container.read(appDatabaseProvider).insertChore(
            const ChoresCompanion(name: Value('Original Chore')),
          );

      // A pre-spec-19 backup file: same tables, but the tags table has no
      // emoji column and the file's own schema version predates it -- built
      // the same way database_migration_test.dart does, by writing a
      // current-schema db and then stripping the column back off, so this
      // stays byte-for-byte what drift itself would have produced at v1.
      final legacyPath = p.join(tempDir.path, 'legacy_no_emoji.sqlite');
      final legacyDb = AppDatabase(NativeDatabase(File(legacyPath)));
      await legacyDb.insertTag(
        const TagsCompanion(name: Value('garage'), colorIndex: Value(1)),
      );
      await legacyDb.close();
      final raw = sqlite3.sqlite3.open(legacyPath);
      raw.execute('ALTER TABLE tags DROP COLUMN emoji;');
      // A real v1 backup predates recurrence_interval (v3) and chores.emoji
      // (v4) too -- without dropping every column newer than v1, the
      // replayed migration hits "duplicate column name".
      raw.execute('ALTER TABLE chores DROP COLUMN recurrence_interval;');
      raw.execute('ALTER TABLE chores DROP COLUMN emoji;');
      raw.execute('PRAGMA user_version = 1;');
      raw.dispose();

      await container
          .read(backupServiceProvider)
          .importDatabase(legacyPath);

      final freshDb = container.read(appDatabaseProvider);
      final tags = await freshDb.select(freshDb.tags).get();
      expect(tags.single.name, equals('garage'));
      expect(tags.single.emoji, isNull);
    });

    test(
        'a legacy backup written before chores.emoji existed imports '
        'cleanly, with emoji absent/null (spec 23)', () async {
      final container = buildContainer(dialogService: FakeFileDialogService());
      await container.read(appDatabaseProvider).insertChore(
            const ChoresCompanion(name: Value('Original Chore')),
          );

      // A pre-spec-23 backup file: same tables, but the chores table has no
      // emoji column and the file's own schema version predates it -- built
      // the same way as the other legacy-import tests above.
      final legacyPath = p.join(tempDir.path, 'legacy_no_chore_emoji.sqlite');
      final legacyDb = AppDatabase(NativeDatabase(File(legacyPath)));
      await legacyDb.insertChore(
        const ChoresCompanion(name: Value('Water Plants')),
      );
      await legacyDb.close();
      final raw = sqlite3.sqlite3.open(legacyPath);
      raw.execute('ALTER TABLE chores DROP COLUMN emoji;');
      raw.execute('PRAGMA user_version = 3;');
      raw.dispose();

      await container
          .read(backupServiceProvider)
          .importDatabase(legacyPath);

      final freshDb = container.read(appDatabaseProvider);
      final chores = await freshDb.select(freshDb.chores).get();
      expect(chores.single.name, equals('Water Plants'));
      expect(chores.single.emoji, isNull);
    });

    test('a chore emoji round-trips through export then import (spec 23)',
        () async {
      final dialog = FakeFileDialogService()
        ..exportDirectoryToReturn = exportDir.path;
      final container = buildContainer(dialogService: dialog);
      final db = container.read(appDatabaseProvider);
      await db.insertChore(
        const ChoresCompanion(
          name: Value('Take Out Trash'),
          emoji: Value('🗑️'),
        ),
      );

      expect(await container.read(backupServiceProvider).exportDatabase(),
          isTrue);
      final exported = exportDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.db3'))
          .single;

      await container
          .read(backupServiceProvider)
          .importDatabase(exported.path);

      final freshDb = container.read(appDatabaseProvider);
      final chores = await freshDb.select(freshDb.chores).get();
      expect(chores.single.name, equals('Take Out Trash'));
      expect(chores.single.emoji, equals('🗑️'));
    });
  });
}
