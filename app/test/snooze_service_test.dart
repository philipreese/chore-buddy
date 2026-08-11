import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/tables.dart';
import 'package:chorebuddy/features/chores/domain/snooze_service.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SnoozeService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = SnoozeService(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insertChore({
    required String name,
    DateTime? nextDueDate,
    RecurrenceType recurrence = RecurrenceType.daily,
  }) {
    return db.insertChore(
      ChoresCompanion(
        name: Value(name),
        nextDueDate: Value(nextDueDate),
        recurrence: Value(recurrence),
      ),
    );
  }

  Future<ChoreEntity> fetchChore(int id) {
    return (db.select(db.chores)..where((c) => c.id.equals(id))).getSingle();
  }

  group('SnoozeService.snoozeChore', () {
    test('advances the due date to tomorrow, preserving time-of-day and recurrence',
        () async {
      final choreId = await insertChore(
        name: 'Water Plants',
        nextDueDate: DateTime(2026, 8, 9, 14, 0),
        recurrence: RecurrenceType.weekly,
      );

      final result = await service.snoozeChore(
        choreId: choreId,
        now: DateTime(2026, 8, 10, 9, 0),
      );

      expect(result, isTrue);
      final updated = await fetchChore(choreId);
      expect(updated.nextDueDate, equals(DateTime(2026, 8, 11, 14, 0)));
      // Recurrence is untouched by a snooze.
      expect(updated.recurrence, equals(RecurrenceType.weekly));
    });

    test('does nothing and returns false when the chore has no due date',
        () async {
      final choreId = await insertChore(name: 'Feed Cat', nextDueDate: null);

      final result = await service.snoozeChore(
        choreId: choreId,
        now: DateTime(2026, 8, 10, 9, 0),
      );

      expect(result, isFalse);
      final updated = await fetchChore(choreId);
      expect(updated.nextDueDate, isNull);
    });

    test('does nothing and returns false when the chore does not exist',
        () async {
      final result = await service.snoozeChore(
        choreId: 999,
        now: DateTime(2026, 8, 10, 9, 0),
      );

      expect(result, isFalse);
    });

    test('snoozes to a given targetDate, preserving time-of-day, overriding the tomorrow default',
        () async {
      final choreId = await insertChore(
        name: 'Water Plants',
        nextDueDate: DateTime(2026, 8, 9, 14, 0),
      );

      final result = await service.snoozeChore(
        choreId: choreId,
        now: DateTime(2026, 8, 10, 9, 0),
        targetDate: DateTime(2026, 8, 20),
      );

      expect(result, isTrue);
      final updated = await fetchChore(choreId);
      expect(updated.nextDueDate, equals(DateTime(2026, 8, 20, 14, 0)));
    });

    test('never writes a completion record', () async {
      final choreId = await insertChore(
        name: 'Mop Floors',
        nextDueDate: DateTime(2026, 8, 9, 8, 0),
      );

      await service.snoozeChore(
        choreId: choreId,
        now: DateTime(2026, 8, 10, 9, 0),
      );

      final history = await (db.select(db.completionRecords)
            ..where((r) => r.choreId.equals(choreId)))
          .get();
      expect(history, isEmpty);
    });
  });
}
