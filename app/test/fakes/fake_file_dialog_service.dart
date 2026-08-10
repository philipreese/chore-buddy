import 'package:chorebuddy/features/settings/domain/file_dialog_service.dart';

/// Returns pre-programmed answers instead of touching a platform channel.
class FakeFileDialogService implements FileDialogService {
  String? exportDirectoryToReturn;
  String? importFilePathToReturn;

  int pickExportDirectoryCallCount = 0;
  int pickImportFilePathCallCount = 0;

  @override
  Future<String?> pickExportDirectory() async {
    pickExportDirectoryCallCount++;
    return exportDirectoryToReturn;
  }

  @override
  Future<String?> pickImportFilePath() async {
    pickImportFilePathCallCount++;
    return importFilePathToReturn;
  }
}
