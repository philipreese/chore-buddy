import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/exceptions.dart';

class TagValidationException implements Exception {
  final String message;
  const TagValidationException(this.message);

  @override
  String toString() => 'TagValidationException: $message';
}

class TagService {
  final AppDatabase _db;

  TagService(this._db);

  /// Creates a tag after validating and normalizing its name.
  ///
  /// Domain rules:
  /// - Names trimmed and converted to lower-case before write.
  /// - Empty names rejected (throws [TagValidationException]).
  /// - Max 22 chars (throws [TagValidationException]).
  /// - Duplicate names throw [DuplicateNameException] from DB unique constraint.
  Future<int> createTag({
    required String name,
    required int colorIndex,
  }) async {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) {
      throw const TagValidationException('Tag name cannot be empty');
    }
    if (normalized.length > 22) {
      throw const TagValidationException('Tag name cannot exceed 22 characters');
    }

    return await _db.insertTag(
      TagsCompanion(
        name: Value(normalized),
        colorIndex: Value(colorIndex),
      ),
    );
  }

  Future<int> deleteTag(int id) async {
    return await _db.deleteTag(id);
  }

  Future<int> deleteAllTags() async {
    return await _db.deleteAllTags();
  }
}
