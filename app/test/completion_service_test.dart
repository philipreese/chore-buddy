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
  }) async {
    final id = await db.insertChore(
      ChoresCompanion(
        name: Value(name),
        nextDueDate: Value(nextDueDate),
        recurrence: Value(recurrence),
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
}
