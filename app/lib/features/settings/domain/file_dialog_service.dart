import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// File-picker surface the backup export/import flow needs. Kept behind an
/// interface because platform file dialogs cannot run under `flutter test`;
/// tests substitute a fake via [fileDialogServiceProvider].
abstract class FileDialogService {
  /// Lets the user choose a destination folder for an export. Returns null
  /// if the user cancels.
  Future<String?> pickExportDirectory();

  /// Lets the user choose a `.db3`/`.sqlite` file to import. Returns null if
  /// the user cancels.
  Future<String?> pickImportFilePath();
}

/// `file_selector`-backed implementation.
///
/// Export uses a *directory* picker rather than `getSaveLocation()`: the
/// Android platform implementation (`file_selector_android`) only
/// implements `openFile`/`openFiles`/`getDirectoryPath` -- `getSaveLocation`
/// falls through to the platform-interface default, which throws
/// `UnimplementedError`. Since this app is Android-only (ADR-0001), the save
/// dialog described in the proposal isn't available; picking a directory and
/// writing the backup file into it is the closest equivalent `file_selector`
/// actually supports on this platform.
class FileSelectorDialogService implements FileDialogService {
  const FileSelectorDialogService();

  @override
  Future<String?> pickExportDirectory() {
    return getDirectoryPath();
  }

  @override
  Future<String?> pickImportFilePath() async {
    const typeGroup = XTypeGroup(
      label: 'ChoreBuddy backup',
      extensions: ['db3', 'sqlite'],
    );
    final file = await openFile(acceptedTypeGroups: const [typeGroup]);
    return file?.path;
  }
}

final fileDialogServiceProvider = Provider<FileDialogService>((ref) {
  return const FileSelectorDialogService();
});
