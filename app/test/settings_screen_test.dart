import 'dart:async';
import 'dart:io';

import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/database_provider.dart';
import 'package:chorebuddy/core/strings/superhero_strings.dart';
import 'package:chorebuddy/features/settings/domain/backup_service.dart';
import 'package:chorebuddy/features/settings/domain/file_dialog_service.dart';
import 'package:chorebuddy/features/settings/presentation/settings_screen.dart';
import 'package:chorebuddy/features/settings/providers/settings_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'fakes/fake_file_dialog_service.dart';

// NOTE: All filesystem work in this file uses SYNC dart:io calls
// (createTempSync/writeAsBytesSync/deleteSync). testWidgets bodies run in a
// FakeAsync zone where dart:io *async* completion events never arrive, so an
// `await Directory.systemTemp.createTemp(...)` hangs the test forever.
// Flows that make the app itself do async file IO (a real import/export) are
// wrapped in tester.runAsync.

const _strings = SuperheroStrings();

class _FakePathProviderPlatform extends PathProviderPlatform {
  final String documentsPath;
  final String supportPath;
  final String tempPath;

  _FakePathProviderPlatform({
    required this.documentsPath,
    required this.supportPath,
    required this.tempPath,
  });

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;

  @override
  Future<String?> getApplicationSupportPath() async => supportPath;

  @override
  Future<String?> getTemporaryPath() async => tempPath;}

/// Routing-only fake: the real import/export IO is covered end-to-end in
/// backup_service_test.dart (plain test(), real event loop). Widget tests
/// here only verify which dialogs the screen routes to.
class _FakeBackupService implements BackupService {
  _FakeBackupService({
    this.importError,
    this.importPath,
  });

  final Object? importError;
  final String? importPath;
  int importCallCount = 0;

  /// Wired by tests to mimic the real service's lastBackupAt update.
  void Function()? onExportSuccess;

  @override
  Ref get ref => throw UnsupportedError('fake');

  @override
  Future<void> Function(File backupFile)? onBackupStaged;

  @override
  Future<void> Function()? onAfterSwap;

  @override
  Future<bool> exportDatabase() async {
    onExportSuccess?.call();
    return true;
  }

  @override
  Future<String?> pickImportFile() async => importPath;

  @override
  Future<void> importDatabase(String sourcePath) async {
    importCallCount++;
    final error = importError;
    if (error != null) throw error;
  }
}

void main() {
  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'ChoreBuddy',
      packageName: 'com.philipreese.chorebuddy',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  late Directory tempDir;
  late File dbFile;
  final openedDbs = <AppDatabase>[];

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('chorebuddy_settings_test');
    final documentsDir = Directory(p.join(tempDir.path, 'docs'))..createSync();
    final supportDir = Directory(p.join(tempDir.path, 'support'))..createSync();
    final cacheDir = Directory(p.join(tempDir.path, 'cache'))..createSync();

    PathProviderPlatform.instance = _FakePathProviderPlatform(
      documentsPath: documentsDir.path,
      supportPath: supportDir.path,
      tempPath: cacheDir.path,
    );

    dbFile = File(p.join(documentsDir.path, '$kDatabaseName.sqlite'));
  });

  tearDown(() async {
    // Close every db opened by this test BEFORE deleting the tree, or
    // Windows refuses the delete (open handles).
    for (final db in openedDbs) {
      await db.close();
    }
    openedDbs.clear();
    try {
      tempDir.deleteSync(recursive: true);
    } on FileSystemException {
      // A transiently-held handle (antivirus, indexer) shouldn't fail the
      // test; the OS temp cleaner collects strays.
    }
  });

  ProviderContainer buildContainer(FileDialogService dialogService,
      {BackupService? backupService}) {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          final database = AppDatabase(NativeDatabase(dbFile));
          openedDbs.add(database);
          return database;
        }),
        fileDialogServiceProvider.overrideWithValue(dialogService),
        if (backupService != null)
          backupServiceProvider.overrideWithValue(backupService),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 150,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
  }

  Future<void> pumpSettings(WidgetTester tester, ProviderContainer container) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
  }

  testWidgets(
    'a second tap on Import while the first is still pending is ignored',
    (tester) async {
      final dialog = FakeFileDialogService()
        ..pendingImportPick = Completer<String?>();
      final container = buildContainer(dialog);
      await pumpSettings(tester, container);
      await tester.pumpAndSettle();

      final importTile = find.byKey(const Key('settings_import_button'));

      await scrollTo(tester, importTile);
      // First tap: _handleImport sets _busy and parks on the pending picker.
      await tester.tap(importTile);
      await tester.pump();
      // Second tap while genuinely in flight: the busy guard must drop it.
      await tester.tap(importTile);
      await tester.pump();

      expect(dialog.pickImportFilePathCallCount, equals(1));

      // Release the picker (canceled) so the flow unwinds cleanly.
      dialog.pendingImportPick!.complete(null);
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'a destructive import requires confirmation before the file is touched',
    (tester) async {
      final garbageFile = File(p.join(tempDir.path, 'garbage.db3'))
        ..writeAsBytesSync([1, 2, 3]);
      final dialog = FakeFileDialogService()
        ..importFilePathToReturn = garbageFile.path;
      final container = buildContainer(dialog);
      await pumpSettings(tester, container);
      await tester.pumpAndSettle();

      await scrollTo(tester, find.byKey(const Key('settings_import_button')));

      await tester.tap(find.byKey(const Key('settings_import_button')));
      await tester.pumpAndSettle();

      expect(find.text(_strings.restoreArchivesTitle), findsOneWidget);

      await tester.tap(find.text(_strings.abortButton));
      await tester.pumpAndSettle();

      // Aborting must never reach the import attempt, so no result dialog
      // of either kind appears.
      expect(find.text(_strings.restoreFailedTitle), findsNothing);
      expect(find.text(_strings.restoreSuccessTitle), findsNothing);
    },
  );

  testWidgets(
    'confirming import routes to the failure dialog when the file is invalid',
    (tester) async {
      final service = _FakeBackupService(
        importPath: 'irrelevant.db3',
        importError: Exception('integrity check failed'),
      );
      final container = buildContainer(FakeFileDialogService(),
          backupService: service);
      await pumpSettings(tester, container);
      await tester.pumpAndSettle();

      await scrollTo(tester, find.byKey(const Key('settings_import_button')));
      await tester.tap(find.byKey(const Key('settings_import_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_strings.restoreConfirmAction));
      await tester.pumpAndSettle();

      expect(service.importCallCount, equals(1));
      expect(find.text(_strings.restoreFailedTitle), findsOneWidget);
    },
  );

  testWidgets(
    'confirming import routes to the success dialog when the file is valid',
    (tester) async {
      final service = _FakeBackupService(importPath: 'incoming.db3');
      final container = buildContainer(FakeFileDialogService(),
          backupService: service);
      await pumpSettings(tester, container);
      await tester.pumpAndSettle();

      await scrollTo(tester, find.byKey(const Key('settings_import_button')));
      await tester.tap(find.byKey(const Key('settings_import_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_strings.restoreConfirmAction));
      await tester.pumpAndSettle();

      expect(service.importCallCount, equals(1));
      expect(find.text(_strings.restoreSuccessTitle), findsOneWidget);
    },
  );

  testWidgets(
    'the last-backup label shows never by default and updates after a successful export',
    (tester) async {
      final service = _FakeBackupService();
      final container = buildContainer(FakeFileDialogService(),
          backupService: service);
      service.onExportSuccess = () => container
          .read(lastBackupAtProvider.notifier)
          .set(DateTime(2026, 8, 10, 12, 0));
      await pumpSettings(tester, container);
      await tester.pumpAndSettle();

      await scrollTo(tester, find.byKey(const Key('settings_export_button')));

      expect(find.text(_strings.lastBackupNeverLabel), findsOneWidget);

      await tester.tap(find.byKey(const Key('settings_export_button')));
      await tester.pumpAndSettle();

      expect(find.text(_strings.intelSecuredTitle), findsOneWidget);
      await tester.tap(find.text(_strings.ok));
      await tester.pumpAndSettle();

      expect(find.text(_strings.lastBackupNeverLabel), findsNothing);
    },
  );
}
