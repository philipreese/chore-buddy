import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/chore_with_details.dart';
import 'package:chorebuddy/core/database/exceptions.dart';
import 'package:chorebuddy/core/database/tables.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Drift Database & DAO Tests', () {
    test('CRUD round-trips for Chores, Tags, CompletionRecords, and ChoreTags', () async {
      // 1. Tags CRUD
      final tag1Id = await db.insertTag(
        const TagsCompanion(
          name: Value('kitchen'),
          colorIndex: Value(1),
        ),
      );
      final tag2Id = await db.insertTag(
        const TagsCompanion(
          name: Value('urgent'),
          colorIndex: Value(2),
        ),
      );

      final tagsList = await db.watchTags().first;
      expect(tagsList.length, equals(2));
      expect(tagsList.map((t) => t.name), containsAll(['kitchen', 'urgent']));

      // 2. Chores CRUD
      final choreId = await db.insertChore(
        ChoresCompanion(
          name: const Value('Wash Dishes'),
          nextDueDate: Value(DateTime.utc(2026, 8, 10, 12, 0)),
          recurrence: const Value(RecurrenceType.daily),
        ),
      );

      expect(choreId, greaterThan(0));

      final activeChoresBeforeTags = await db.watchActiveChoresWithDetails().first;
      expect(activeChoresBeforeTags.length, equals(1));
      expect(activeChoresBeforeTags.first.chore.name, equals('Wash Dishes'));
      expect(activeChoresBeforeTags.first.chore.recurrence, equals(RecurrenceType.daily));
      expect(activeChoresBeforeTags.first.tags, isEmpty);

      // 3. Set Chore Tags
      await db.setChoreTags(choreId, [tag1Id, tag2Id]);
      final activeChoresWithTags = await db.watchActiveChoresWithDetails().first;
      expect(activeChoresWithTags.first.tags.length, equals(2));
      expect(activeChoresWithTags.first.tags.map((t) => t.name), containsAll(['kitchen', 'urgent']));

      // 4. Update Chore
      final currentChore = activeChoresWithTags.first.chore;
      final updatedChore = currentChore.copyWith(name: 'Wash Big Dishes');
      final updated = await db.updateChore(updatedChore);
      expect(updated, isTrue);

      final activeChoresAfterUpdate = await db.watchActiveChoresWithDetails().first;
      expect(activeChoresAfterUpdate.first.chore.name, equals('Wash Big Dishes'));

      // 5. CompletionRecords CRUD
      final t1 = DateTime.utc(2026, 8, 9, 10, 0);
      final recordId = await db.insertCompletionRecord(
        CompletionRecordsCompanion(
          choreId: Value(choreId),
          completedAt: Value(t1),
          note: const Value('Cleaned all plates'),
        ),
      );
      expect(recordId, greaterThan(0));

      final history = await db.watchHistoryForChore(choreId).first;
      expect(history.length, equals(1));
      expect(history.first.note, equals('Cleaned all plates'));

      final updatedRecord = history.first.copyWith(note: 'Cleaned all plates and pots');
      final recordUpdated = await db.updateCompletionRecord(updatedRecord);
      expect(recordUpdated, isTrue);

      final historyAfterUpdate = await db.watchHistoryForChore(choreId).first;
      expect(historyAfterUpdate.first.note, equals('Cleaned all plates and pots'));

      // Delete completion record
      await db.deleteCompletionRecord(recordId);
      final historyAfterDelete = await db.watchHistoryForChore(choreId).first;
      expect(historyAfterDelete, isEmpty);
    });

    test('Cascade delete removes completion records and chore-tag links', () async {
      final tagId = await db.insertTag(
        const TagsCompanion(
          name: Value('laundry'),
          colorIndex: Value(3),
        ),
      );

      final choreId = await db.insertChore(
        const ChoresCompanion(
          name: Value('Do Laundry'),
        ),
      );

      await db.setChoreTags(choreId, [tagId]);
      await db.insertCompletionRecord(
        CompletionRecordsCompanion(
          choreId: Value(choreId),
          completedAt: Value(DateTime.utc(2026, 8, 8, 9, 0)),
          note: const Value('Done'),
        ),
      );

      // Verify created
      final historyBefore = await db.watchHistoryForChore(choreId).first;
      expect(historyBefore.length, equals(1));

      final detailsBefore = await db.watchActiveChoresWithDetails().first;
      expect(detailsBefore.first.tags.length, equals(1));

      // Delete Chore -> cascade deletes completion records & chore_tags
      await db.deleteChore(choreId);

      final activeChores = await db.watchActiveChoresWithDetails().first;
      expect(activeChores, isEmpty);

      final historyAfter = await db.watchHistoryForChore(choreId).first;
      expect(historyAfter, isEmpty);

      expect(await db.select(db.choreTags).get(), isEmpty);

      // Check tag still exists
      final tags = await db.watchTags().first;
      expect(tags.length, equals(1));

      // Test tag delete cascade
      final choreId2 = await db.insertChore(
        const ChoresCompanion(
          name: Value('Fold Clothes'),
        ),
      );
      await db.setChoreTags(choreId2, [tagId]);

      final detailsBeforeTagDelete = await db.watchActiveChoresWithDetails().first;
      expect(detailsBeforeTagDelete.first.tags.length, equals(1));

      await db.deleteTag(tagId);

      final detailsAfterTagDelete = await db.watchActiveChoresWithDetails().first;
      expect(detailsAfterTagDelete.first.tags, isEmpty);

      expect(await db.select(db.choreTags).get(), isEmpty);
    });

    test('Unique name conflict (case-insensitive) reported as DuplicateNameException', () async {
      await db.insertChore(
        const ChoresCompanion(
          name: Value('Vacuum Living Room'),
        ),
      );

      // Inserting exact same name with different casing should throw DuplicateNameException
      await expectLater(
        db.insertChore(
          const ChoresCompanion(
            name: Value('VACUUM LIVING ROOM'),
          ),
        ),
        throwsA(isA<DuplicateNameException>()),
      );

      await expectLater(
        db.insertChore(
          const ChoresCompanion(
            name: Value('vacuum living room'),
          ),
        ),
        throwsA(isA<DuplicateNameException>()),
      );

      // Updating another chore to existing name should also throw
      final chore2Id = await db.insertChore(
        const ChoresCompanion(
          name: Value('Mop Kitchen'),
        ),
      );

      final chore2List = await db.watchActiveChoresWithDetails().first;
      final chore2Entity = chore2List.firstWhere((c) => c.chore.id == chore2Id).chore;

      await expectLater(
        db.updateChore(chore2Entity.copyWith(name: 'vacuum living room')),
        throwsA(isA<DuplicateNameException>()),
      );

      // Tag unique name test
      await db.insertTag(
        const TagsCompanion(
          name: Value('outdoor'),
        ),
      );

      await expectLater(
        db.insertTag(
          const TagsCompanion(
            name: Value('outdoor'),
          ),
        ),
        throwsA(isA<DuplicateNameException>()),
      );
    });

    test('Derived lastCompleted/lastNote reflect latest record and update reactively', () async {
      final tagId = await db.insertTag(
        const TagsCompanion(
          name: Value('kitchen'),
        ),
      );

      final choreId = await db.insertChore(
        const ChoresCompanion(
          name: Value('Take Out Trash'),
        ),
      );

      final t0 = DateTime.utc(2026, 7, 20, 8, 0);
      final t1 = DateTime.utc(2026, 8, 1, 10, 0);
      final t2 = DateTime.utc(2026, 8, 5, 14, 30);

      late int rec1Id;
      late int rec2Id;

      final expectFuture = expectLater(
        db.watchActiveChoresWithDetails(),
        emitsInOrder([
          // 0. Initial emission: no tags, no completion records
          predicate<List<ChoreWithDetails>>(
            (list) => list.single.tags.isEmpty && list.single.lastCompleted == null,
          ),
          // 1. After setChoreTags: 1 tag, no completion records
          predicate<List<ChoreWithDetails>>(
            (list) =>
                list.single.tags.length == 1 &&
                list.single.tags.single.name == 'kitchen' &&
                list.single.lastCompleted == null,
          ),
          // 2. After rec1 (t1) inserted
          predicate<List<ChoreWithDetails>>(
            (list) =>
                list.single.lastCompleted?.toUtc() == t1 &&
                list.single.lastNote == 'Rec 1 Note',
          ),
          // 3. After rec2 (t2) inserted
          predicate<List<ChoreWithDetails>>(
            (list) =>
                list.single.lastCompleted?.toUtc() == t2 &&
                list.single.lastNote == 'Rec 2 Note',
          ),
          // 4. After rec0 (t0, earlier than t2) inserted
          predicate<List<ChoreWithDetails>>(
            (list) =>
                list.single.lastCompleted?.toUtc() == t2 &&
                list.single.lastNote == 'Rec 2 Note',
          ),
          // 5. After rec2 deleted -> falls back to rec1 (t1)
          predicate<List<ChoreWithDetails>>(
            (list) =>
                list.single.lastCompleted?.toUtc() == t1 &&
                list.single.lastNote == 'Rec 1 Note',
          ),
          // 6. After rec1 deleted -> falls back to rec0 (t0)
          predicate<List<ChoreWithDetails>>(
            (list) =>
                list.single.lastCompleted?.toUtc() == t0 &&
                list.single.lastNote == 'Older History Note',
          ),
        ]),
      );

      // Perform mutations driven sequentially
      await db.setChoreTags(choreId, [tagId]);

      rec1Id = await db.insertCompletionRecord(
        CompletionRecordsCompanion(
          choreId: Value(choreId),
          completedAt: Value(t1),
          note: const Value('Rec 1 Note'),
        ),
      );

      rec2Id = await db.insertCompletionRecord(
        CompletionRecordsCompanion(
          choreId: Value(choreId),
          completedAt: Value(t2),
          note: const Value('Rec 2 Note'),
        ),
      );

      await db.insertCompletionRecord(
        CompletionRecordsCompanion(
          choreId: Value(choreId),
          completedAt: Value(t0),
          note: const Value('Older History Note'),
        ),
      );

      await db.deleteCompletionRecord(rec2Id);
      await db.deleteCompletionRecord(rec1Id);

      await expectFuture;
    });

    test('Archive/restore flips visibility between watchActiveChoresWithDetails and watchArchivedChores', () async {
      final choreId = await db.insertChore(
        const ChoresCompanion(
          name: Value('Clean Garage'),
        ),
      );

      // Verify active
      var active = await db.watchActiveChoresWithDetails().first;
      var archived = await db.watchArchivedChores().first;
      expect(active.map((c) => c.chore.name), contains('Clean Garage'));
      expect(archived, isEmpty);

      // Archive chore
      await db.archiveChore(choreId);

      active = await db.watchActiveChoresWithDetails().first;
      archived = await db.watchArchivedChores().first;
      expect(active, isEmpty);
      expect(archived.map((c) => c.name), contains('Clean Garage'));

      // Restore chore
      await db.restoreChore(choreId);

      active = await db.watchActiveChoresWithDetails().first;
      archived = await db.watchArchivedChores().first;
      expect(active.map((c) => c.chore.name), contains('Clean Garage'));
      expect(archived, isEmpty);
    });

    test('Out-of-range recurrence value falls back to RecurrenceType.none', () async {
      await db.customInsert(
        "INSERT INTO chores (name, recurrence, is_active, is_notification_enabled, created_at) "
        "VALUES ('Invalid Recurrence Chore', 999, 1, 1, 1770638400);",
      );

      final active = await db.watchActiveChoresWithDetails().first;
      expect(active.length, equals(1));
      expect(active.first.chore.name, equals('Invalid Recurrence Chore'));
      expect(active.first.chore.recurrence, equals(RecurrenceType.none));
    });
  });
}
