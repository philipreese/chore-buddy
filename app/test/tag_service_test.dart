import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/exceptions.dart';
import 'package:chorebuddy/features/tags/domain/tag_service.dart';

void main() {
  late AppDatabase db;
  late TagService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = TagService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('TagService Unit Tests', () {
    test('normalization trims and lowercases tag name before writing to DB', () async {
      final tagId = await service.createTag(name: '  KITCHEN  ', colorIndex: 1);
      expect(tagId, greaterThan(0));

      final tags = await db.watchTags().first;
      expect(tags.length, equals(1));
      expect(tags.first.name, equals('kitchen'));
      expect(tags.first.colorIndex, equals(1));
    });

    test('empty or whitespace name is rejected with TagValidationException', () async {
      await expectLater(
        service.createTag(name: '', colorIndex: 0),
        throwsA(isA<TagValidationException>()),
      );

      await expectLater(
        service.createTag(name: '   ', colorIndex: 0),
        throwsA(isA<TagValidationException>()),
      );
    });

    test('name longer than 22 chars is rejected with TagValidationException', () async {
      final longName = 'a' * 23;
      await expectLater(
        service.createTag(name: longName, colorIndex: 0),
        throwsA(isA<TagValidationException>()),
      );

      // Exactly 22 chars should succeed
      final valid22 = 'a' * 22;
      final tagId = await service.createTag(name: valid22, colorIndex: 2);
      expect(tagId, greaterThan(0));
    });

    test('duplicate name surfaces DuplicateNameException through service layer', () async {
      await service.createTag(name: 'urgent', colorIndex: 0);

      // Same name
      await expectLater(
        service.createTag(name: 'urgent', colorIndex: 1),
        throwsA(isA<DuplicateNameException>()),
      );

      // Uppercase variant that normalizes to existing name
      await expectLater(
        service.createTag(name: 'URGENT', colorIndex: 1),
        throwsA(isA<DuplicateNameException>()),
      );
    });

    test('deleteTag and deleteAllTags delete tags correctly', () async {
      final id1 = await service.createTag(name: 'tag1', colorIndex: 0);
      final id2 = await service.createTag(name: 'tag2', colorIndex: 1);

      var tags = await db.watchTags().first;
      expect(tags.length, equals(2));

      await service.deleteTag(id1);
      tags = await db.watchTags().first;
      expect(tags.length, equals(1));
      expect(tags.first.id, equals(id2));

      await service.deleteAllTags();
      tags = await db.watchTags().first;
      expect(tags, isEmpty);
    });
  });
}
