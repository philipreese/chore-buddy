import 'dart:io';

import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/database_file_locator.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

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

  // drift_flutter resolves a temp dir during database setup.
  @override
  Future<String?> getTemporaryPath() async => supportPath;
}

void main() {
  test(
    'resolveDatabaseFile() points at the exact file a default AppDatabase() opens',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'chorebuddy_locator_test',
      );
      addTearDown(() => tempDir.delete(recursive: true));

      final documentsDir = Directory(p.join(tempDir.path, 'docs'))
        ..createSync();
      final supportDir = Directory(p.join(tempDir.path, 'support'))
        ..createSync();

      PathProviderPlatform.instance = _FakePathProviderPlatform(
        documentsPath: documentsDir.path,
        supportPath: supportDir.path,
      );

      // No QueryExecutor override: this goes through the same
      // `driftDatabase(name: kDatabaseName)` wiring `database_provider.dart`
      // uses in production, so this pins the locator to drift's real
      // default path rather than to an assumption repeated in every test.
      final db = AppDatabase();
      addTearDown(db.close);
      await db.insertChore(const ChoresCompanion(name: Value('Water Plants')));

      final resolved = await resolveDatabaseFile();

      expect(await resolved.exists(), isTrue);
      expect(resolved.path, equals(p.join(documentsDir.path, '$kDatabaseName.sqlite')));
    },
  );
}
