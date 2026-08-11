import 'dart:async';

import 'package:chorebuddy/features/settings/domain/file_dialog_service.dart';

/// Returns pre-programmed answers instead of touching a platform channel.
class FakeFileDialogService implements FileDialogService {
  String? exportDirectoryToReturn;
  String? importFilePathToReturn;

  /// When set, [pickImportFilePath] stays pending until this completer is
  /// completed — lets tests hold an import "in flight" (e.g. the double-tap
  /// reentrancy guard, which is unobservable with an instantly-resolving
  /// fake).
  Completer<String?>? pendingImportPick;

  int pickExportDirectoryCallCount = 0;
  int pickImportFilePathCallCount = 0;

  @override
  Future<String?> pickExportDirectory() async {
    pickExportDirectoryCallCount++;
    return exportDirectoryToReturn;
  }

  @override
  Future<String?> pickImportFilePath() {
    pickImportFilePathCallCount++;
    final pending = pendingImportPick;
    if (pending != null) return pending.future;
    return Future.value(importFilePathToReturn);
  }
}
