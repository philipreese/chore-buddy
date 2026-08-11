import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_database.dart';

/// The on-disk sqlite file drift opens for [AppDatabase], following the same
/// convention `drift_flutter`'s `driftDatabase()` helper uses internally
/// (`<application documents directory>/$kDatabaseName.sqlite`) so the backup
/// export/import flow operates on the exact file the app has open.
Future<File> resolveDatabaseFile() async {
  final directory = await getApplicationDocumentsDirectory();
  return File(p.join(directory.path, '$kDatabaseName.sqlite'));
}

/// Where the import flow stages a copy of the current database before
/// swapping it out, so a failed swap can be rolled back.
Future<File> resolvePreImportBackupFile() async {
  final directory = await getApplicationSupportDirectory();
  return File(p.join(directory.path, '.pre-import.bak'));
}
