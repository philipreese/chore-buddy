import 'dart:convert';

import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/tables.dart';
import 'package:chorebuddy/core/home_widget/widget_sync_service.dart';
import 'package:chorebuddy/core/strings/superhero_strings.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_widget_data_writer.dart';

/// Covers [selectWidgetChores] (pure) and [WidgetSyncService.sync] against
/// an in-memory database with [FakeWidgetDataWriter] standing in for
/// `home_widget`'s platform channel -- neither touches a real plugin, so
/// this suite runs fine under `flutter test`.
void main() {
  const strings = SuperheroStrings();
  final now = DateTime(2026, 8, 10, 12, 0);

  ChoreEntity chore({
    required int id,
    required String name,
    DateTime? nextDueDate,
  }) {
    return ChoreEntity(
      id: id,
      name: name,
      isActive: true,
      nextDueDate: nextDueDate,
      recurrence: RecurrenceType.daily,
      isNotificationEnabled: true,
      createdAt: now,
    );
  }

  group('selectWidgetChores', () {
    test('includes only overdue and due-within-24h chores', () {
      final overdue = chore(
        id: 1,
        name: 'Overdue Chore',
        nextDueDate: now.subtract(const Duration(hours: 2)),
      );
      final dueSoon = chore(
        id: 2,
        name: 'Due Soon Chore',
        nextDueDate: now.add(const Duration(hours: 10)),
      );
      final farOut = chore(
        id: 3,
        name: 'Far Out Chore',
        nextDueDate: now.add(const Duration(days: 5)),
      );
      final noDueDate = chore(id: 4, name: 'No Due Date Chore');

      final result = selectWidgetChores(
        [farOut, noDueDate, overdue, dueSoon],
        strings: strings,
        now: now,
      );

      expect(result.map((e) => e.id), equals([1, 2]));
    });

    test('orders by urgency (soonest/most overdue due date first)', () {
      final soonest = chore(
        id: 1,
        name: 'Soonest',
        nextDueDate: now.add(const Duration(hours: 1)),
      );
      final mostOverdue = chore(
        id: 2,
        name: 'Most Overdue',
        nextDueDate: now.subtract(const Duration(days: 2)),
      );
      final slightlyOverdue = chore(
        id: 3,
        name: 'Slightly Overdue',
        nextDueDate: now.subtract(const Duration(hours: 1)),
      );

      final result = selectWidgetChores(
        [soonest, mostOverdue, slightlyOverdue],
        strings: strings,
        now: now,
      );

      expect(
        result.map((e) => e.id),
        equals([2, 3, 1]),
      );
    });

    test('flags overdue chores and formats due labels via AppStrings', () {
      final overdue = chore(
        id: 1,
        name: 'Overdue Chore',
        nextDueDate: DateTime(2026, 8, 8, 9, 0),
      );
      final dueSoon = chore(
        id: 2,
        name: 'Due Soon Chore',
        nextDueDate: now.add(const Duration(hours: 5)),
      );

      final result = selectWidgetChores(
        [overdue, dueSoon],
        strings: strings,
        now: now,
      );

      final overdueEntry = result.firstWhere((e) => e.id == 1);
      expect(overdueEntry.overdue, isTrue);
      expect(overdueEntry.dueLabel, startsWith('Overdue: '));

      final dueSoonEntry = result.firstWhere((e) => e.id == 2);
      expect(dueSoonEntry.overdue, isFalse);
      expect(dueSoonEntry.dueLabel, startsWith('Due: '));
    });

    test('caps at kWidgetMaxEntries, keeping the most urgent', () {
      final chores = List.generate(
        kWidgetMaxEntries + 3,
        (i) => chore(
          id: i,
          name: 'Chore $i',
          // Chore 0 is the most overdue; each subsequent id is 1h less
          // urgent, so the expected surviving ids are exactly 0..N-1.
          nextDueDate: now.subtract(Duration(hours: 20 - i)),
        ),
      );

      final result = selectWidgetChores(chores, strings: strings, now: now);

      expect(result, hasLength(kWidgetMaxEntries));
      expect(
        result.map((e) => e.id),
        equals(List.generate(kWidgetMaxEntries, (i) => i)),
      );
    });

    test('excludes inactive-status chores implicitly via the caller', () {
      // selectWidgetChores itself doesn't filter on isActive -- callers are
      // expected to pass only active chores (as WidgetSyncService.sync does
      // via AppDatabase.getActiveChores()). Documented here so a future
      // change to that contract doesn't slip by unnoticed.
      final due = chore(
        id: 1,
        name: 'Due Chore',
        nextDueDate: now.subtract(const Duration(hours: 1)),
      );
      final result = selectWidgetChores([due], strings: strings, now: now);
      expect(result, hasLength(1));
    });
  });

  group('WidgetSyncService.sync', () {
    late AppDatabase db;
    late FakeWidgetDataWriter writer;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      writer = FakeWidgetDataWriter();
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> insertChore({
      required String name,
      DateTime? nextDueDate,
    }) {
      return db.insertChore(
        ChoresCompanion(
          name: Value(name),
          nextDueDate: Value(nextDueDate),
          recurrence: const Value(RecurrenceType.daily),
          isNotificationEnabled: const Value(true),
        ),
      );
    }

    test('serializes the selected chores and updates the widget once',
        () async {
      await insertChore(
        name: 'Overdue Chore',
        nextDueDate: now.subtract(const Duration(hours: 3)),
      );
      await insertChore(
        name: 'Future Chore',
        nextDueDate: now.add(const Duration(days: 3)),
      );

      final service = WidgetSyncService(db, strings: strings, writer: writer);
      await service.sync(now: now);

      expect(writer.savedJson, hasLength(1));
      expect(writer.updateWidgetCallCount, equals(1));

      final decoded = jsonDecode(writer.savedJson.single) as List<dynamic>;
      expect(decoded, hasLength(1));
      final entry = decoded.single as Map<String, dynamic>;
      expect(entry['name'], equals('Overdue Chore'));
      expect(entry['overdue'], isTrue);
    });

    test('archived (inactive) chores never reach the widget', () async {
      final id = await insertChore(
        name: 'Overdue Chore',
        nextDueDate: now.subtract(const Duration(hours: 3)),
      );
      await db.archiveChore(id);

      final service = WidgetSyncService(db, strings: strings, writer: writer);
      await service.sync(now: now);

      final decoded = jsonDecode(writer.savedJson.single) as List<dynamic>;
      expect(decoded, isEmpty);
    });
  });
}
