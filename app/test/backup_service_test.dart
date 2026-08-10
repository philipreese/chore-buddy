import 'dart:io';

import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/database_file_locator.dart';
import 'package:chorebuddy/core/database/database_provider.dart';
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
import 'fakes/fake_notification_service.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  final String documentsPath;
  final String supportPath;

  _FakePathProviderPlatform({
    required this.documentsPath,
    required this.supportPath,
  });

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;

  @override
  Future<String?> getApplicationSupportPath() async => supportPath;
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
    exportDir = Directory(p.join(tempDir.path, 'exports'))..createSync();

    PathProviderPlatform.instance = _FakePathProviderPlatform(
      documentsPath: documentsDir.path,
      supportPath: supportDir.path,
    );

    dbFile = File(p.join(documentsDir.path, '$kDatabaseName.sqlite'));
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  ProviderContainer buildContainer({
    required FakeFileDialogService dialogService,
    FakeNotificationService? notificationService,
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
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<File> writeValidDatabase(String path, {required String choreName}) async {
    final file = File(path);
    final db = AppDatabase(NativeDatabase(file));
    await db.insertChore(ChoresCompanion(name: Value(choreName)));
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

    test('a failure mid-swap restores the pre-import backup, leaving the db intact',
        () async {
      final container = buildContainer(dialogService: FakeFileDialogService());
      final originalDb = container.read(appDatabaseProvider);
      await originalDb.insertChore(const ChoresCompanion(name: Value('Keep Me')));

      final sourceFile = await writeValidDatabase(
        p.join(tempDir.path, 'incoming.db3'),
        choreName: 'Imported Chore',
      );

      // Occupy the staging path with a directory so the copy-to-staging
      // step fails after the pre-import backup has already been made.
      await Directory('${dbFile.path}.importing').create();

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

      final backupFile = await resolvePreImportBackupFile();
      expect(await backupFile.exists(), isFalse);

      final freshDb = container.read(appDatabaseProvider);
      final chores = await freshDb.select(freshDb.chores).get();
      expect(chores.map((c) => c.name), equals(['Keep Me']));
    });
  });
}
