import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/tables.dart';
import 'package:chorebuddy/features/chores/domain/completion_service.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late CompletionService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = CompletionService(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<ChoreEntity> insertChore({
    required String name,
    DateTime? nextDueDate,
    RecurrenceType recurrence = RecurrenceType.daily,
    int? recurrenceInterval,
  }) async {
    final id = await db.insertChore(
      ChoresCompanion(
        name: Value(name),
        nextDueDate: Value(nextDueDate),
        recurrence: Value(recurrence),
        recurrenceInterval: Value(recurrenceInterval),
      ),
    );
    final chores = await db.watchActiveChoresWithDetails().first;
    return chores.firstWhere((c) => c.chore.id == id).chore;
  }

  group('CompletionService.completeChore', () {
    test('inserts a completion record and advances the due date', () async {
      final chore = await insertChore(
        name: 'Water Plants',
        nextDueDate: DateTime(2026, 8, 9, 14, 0),
        recurrence: RecurrenceType.daily,
      );

      final completedAt = DateTime(2026, 8, 10, 9, 0);
      final token = await service.completeChore(
        chore: chore,
        completedAt: completedAt,
        note: 'Gave them a good soak',
      );

      final history = await db.watchHistoryForChore(chore.id).first;
      expect(history.length, equals(1));
      expect(history.single.id, equals(token.recordId));
      expect(history.single.completedAt, equals(completedAt));
      expect(history.single.note, equals('Gave them a good soak'));

      final updated = await db.watchActiveChoresWithDetails().first;
      final updatedChore = updated.firstWhere((c) => c.chore.id == chore.id).chore;
      expect(updatedChore.nextDueDate, equals(DateTime(2026, 8, 11, 14, 0)));

      expect(token.choreId, equals(chore.id));
      expect(token.previousNextDueDate, equals(DateTime(2026, 8, 9, 14, 0)));
    });

    test('customDays(10) advances the due date by 10 days (fake clock)',
        () async {
      final chore = await insertChore(
        name: 'Change Sheets',
        nextDueDate: DateTime(2026, 8, 9, 14, 0),
        recurrence: RecurrenceType.customDays,
        recurrenceInterval: 10,
      );

      final completedAt = DateTime(2026, 8, 10, 9, 0);
      await service.completeChore(chore: chore, completedAt: completedAt);

      final updated = await db.watchActiveChoresWithDetails().first;
      final updatedChore = updated.firstWhere((c) => c.chore.id == chore.id).chore;
      // Anchored to the completion date (Aug 10) + 10, matching the daily
      // case's contract -- not previous due + 10.
      expect(updatedChore.nextDueDate, equals(DateTime(2026, 8, 20, 14, 0)));
    });

    test('none recurrence clears the due date', () async {
      final chore = await insertChore(
        name: 'One-off task',
        nextDueDate: DateTime(2026, 8, 9, 14, 0),
        recurrence: RecurrenceType.none,
      );

      await service.completeChore(
        chore: chore,
        completedAt: DateTime(2026, 8, 10, 9, 0),
      );

      final updated = await db.watchActiveChoresWithDetails().first;
      final updatedChore = updated.firstWhere((c) => c.chore.id == chore.id).chore;
      expect(updatedChore.nextDueDate, isNull);
    });
  });

  group('CompletionService.undoCompletion', () {
    test('deletes the record and restores the prior due date', () async {
      final chore = await insertChore(
        name: 'Feed Cat',
        nextDueDate: DateTime(2026, 8, 9, 8, 0),
        recurrence: RecurrenceType.weekly,
      );

      final token = await service.completeChore(
        chore: chore,
        completedAt: DateTime(2026, 8, 10, 9, 0),
        note: 'Fed twice',
      );

      await service.undoCompletion(token);

      final history = await db.watchHistoryForChore(chore.id).first;
      expect(history, isEmpty);

      final restored = await db.watchActiveChoresWithDetails().first;
      final restoredChore = restored.firstWhere((c) => c.chore.id == chore.id).chore;
      expect(restoredChore.nextDueDate, equals(DateTime(2026, 8, 9, 8, 0)));
    });

    test('restores a null prior due date when undoing a none-recurrence completion', () async {
      final chore = await insertChore(
        name: 'One-off task',
        nextDueDate: null,
        recurrence: RecurrenceType.none,
      );

      final token = await service.completeChore(
        chore: chore,
        completedAt: DateTime(2026, 8, 10, 9, 0),
      );

      await service.undoCompletion(token);

      final restored = await db.watchActiveChoresWithDetails().first;
      final restoredChore = restored.firstWhere((c) => c.chore.id == chore.id).chore;
      expect(restoredChore.nextDueDate, isNull);
    });
  });

  Future<ChoreEntity> fetchChore(int id) {
    return (db.select(db.chores)..where((c) => c.id.equals(id))).getSingle();
  }

  group('CompletionService concurrency invariants', () {
    test('completeChore derives the advance from the current row, not the caller snapshot',
        () async {
      final stale = await insertChore(
        name: 'Mop Floors',
        nextDueDate: DateTime(2026, 8, 9, 14, 0),
        recurrence: RecurrenceType.daily,
      );

      // First completion moves the due date; `stale` still holds the
      // original snapshot, as a not-yet-rebuilt card would.
      await service.completeChore(
        chore: stale,
        completedAt: DateTime(2026, 8, 10, 9, 0),
      );

      final token2 = await service.completeChore(
        chore: stale,
        completedAt: DateTime(2026, 8, 12, 9, 0),
      );

      // The second advance must build on the FIRST completion's write
      // (due 2026-08-11 14:00), not the stale snapshot's 08-09.
      expect(token2.previousNextDueDate, equals(DateTime(2026, 8, 11, 14, 0)));
      final current = await fetchChore(stale.id);
      expect(current.nextDueDate, equals(DateTime(2026, 8, 13, 14, 0)));

      // Undoing the second restores the first completion's due date.
      await service.undoCompletion(token2);
      final afterUndo = await fetchChore(stale.id);
      expect(afterUndo.nextDueDate, equals(DateTime(2026, 8, 11, 14, 0)));
    });

    test('undo does not clobber a due date edited during the undo window',
        () async {
      final chore = await insertChore(
        name: 'Clean Gutters',
        nextDueDate: DateTime(2026, 8, 9, 14, 0),
        recurrence: RecurrenceType.weekly,
      );

      final token = await service.completeChore(
        chore: chore,
        completedAt: DateTime(2026, 8, 10, 9, 0),
      );

      // User edits the due date while the undo window is open.
      final edited = DateTime(2026, 12, 25, 8, 0);
      await (db.update(db.chores)..where((c) => c.id.equals(chore.id)))
          .write(ChoresCompanion(nextDueDate: Value(edited)));

      await service.undoCompletion(token);

      // The record is gone, but the user's edit survives.
      final history = await (db.select(db.completionRecords)
            ..where((r) => r.choreId.equals(chore.id)))
          .get();
      expect(history, isEmpty);
      final current = await fetchChore(chore.id);
      expect(current.nextDueDate, equals(edited));
    });
  });
}
