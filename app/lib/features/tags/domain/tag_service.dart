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
    String? emoji,
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
        emoji: Value(_normalizeEmoji(emoji)),
      ),
    );
  }

  /// Sets or clears an existing tag's emoji. Store-what's-typed: no
  /// grapheme-cluster validation beyond trimming and treating an
  /// all-whitespace value as "cleared".
  Future<int> setTagEmoji(int id, String? emoji) async {
    return await _db.updateTagEmoji(id, _normalizeEmoji(emoji));
  }

  String? _normalizeEmoji(String? emoji) {
    final trimmed = emoji?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  Future<int> deleteTag(int id) async {
    return await _db.deleteTag(id);
  }

  Future<int> deleteAllTags() async {
    return await _db.deleteAllTags();
  }
}
