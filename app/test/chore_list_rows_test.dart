import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/chore_with_details.dart';
import 'package:chorebuddy/core/database/tables.dart';
import 'package:chorebuddy/features/chores/domain/chore_filter_sort.dart';
import 'package:chorebuddy/features/chores/domain/chore_list_rows.dart';
import 'package:chorebuddy/features/chores/domain/due_status.dart';
import 'package:flutter_test/flutter_test.dart';

ChoreWithDetails _chore(int id, String name, {DateTime? due}) {
  return ChoreWithDetails(
    chore: ChoreEntity(
      id: id,
      name: name,
      isActive: true,
      nextDueDate: due,
      recurrence: RecurrenceType.none,
      isNotificationEnabled: true,
      createdAt: DateTime(2026, 1, 1),
    ),
    tags: const [],
  );
}

void main() {
  final now = DateTime(2026, 8, 10, 12, 0);
  final yesterday = DateTime(2026, 8, 9, 9, 0);
  final today = DateTime(2026, 8, 10, 18, 0);
  final tomorrow = DateTime(2026, 8, 11, 9, 0);

  group('buildChoreListRows', () {
    test(
        'groups into Overdue/Today/Upcoming/Unscheduled under urgency-ascending',
        () {
      final chores = [
        _chore(1, 'Yesterday Chore', due: yesterday),
        _chore(2, 'Today Chore', due: today),
        _chore(3, 'Tomorrow Chore', due: tomorrow),
        _chore(4, 'No Date Chore'),
      ];

      final rows = buildChoreListRows(
        chores: chores,
        sortOrder: ChoreSortOrder.urgency,
        direction: SortDirection.ascending,
        now: now,
      );

      expect(rows, [
        isA<ChoreSectionHeaderRow>()
            .having((r) => r.section, 'section', DueSection.overdue)
            .having((r) => r.count, 'count', 1),
        isA<ChoreItemRow>().having((r) => r.chore.chore.id, 'id', 1),
        isA<ChoreSectionHeaderRow>()
            .having((r) => r.section, 'section', DueSection.today)
            .having((r) => r.count, 'count', 1),
        isA<ChoreItemRow>().having((r) => r.chore.chore.id, 'id', 2),
        isA<ChoreSectionHeaderRow>()
            .having((r) => r.section, 'section', DueSection.upcoming)
            .having((r) => r.count, 'count', 1),
        isA<ChoreItemRow>().having((r) => r.chore.chore.id, 'id', 3),
        isA<ChoreSectionHeaderRow>()
            .having((r) => r.section, 'section', DueSection.unscheduled)
            .having((r) => r.count, 'count', 1),
        isA<ChoreItemRow>().having((r) => r.chore.chore.id, 'id', 4),
      ]);
    });

    test('reverses section order under urgency-descending', () {
      final chores = [
        _chore(1, 'A', due: yesterday),
        _chore(2, 'B', due: tomorrow),
      ];
      final rows = buildChoreListRows(
        chores: chores,
        sortOrder: ChoreSortOrder.urgency,
        direction: SortDirection.descending,
        now: now,
      );

      final sections =
          rows.whereType<ChoreSectionHeaderRow>().map((r) => r.section).toList();
      expect(sections, [DueSection.upcoming, DueSection.overdue]);
    });

    test('omits sections with no chores in them', () {
      final chores = [_chore(1, 'Only overdue', due: yesterday)];
      final rows = buildChoreListRows(
        chores: chores,
        sortOrder: ChoreSortOrder.urgency,
        direction: SortDirection.ascending,
        now: now,
      );

      expect(rows, hasLength(2));
      expect(rows.whereType<ChoreSectionHeaderRow>().single.section,
          DueSection.overdue);
    });

    test('non-urgency sort orders render a flat list with no section headers',
        () {
      final chores = [
        _chore(1, 'A', due: yesterday),
        _chore(2, 'B', due: tomorrow),
      ];
      final rows = buildChoreListRows(
        chores: chores,
        sortOrder: ChoreSortOrder.name,
        direction: SortDirection.ascending,
        now: now,
      );

      expect(rows.whereType<ChoreSectionHeaderRow>(), isEmpty);
      expect(rows, hasLength(2));
      expect((rows[0] as ChoreItemRow).chore.chore.id, equals(1));
      expect((rows[1] as ChoreItemRow).chore.chore.id, equals(2));
    });

    test('preserves the incoming (already-sorted) order within a section',
        () {
      final chores = [
        _chore(3, 'C', due: tomorrow.add(const Duration(days: 2))),
        _chore(2, 'B', due: tomorrow),
        _chore(1, 'A', due: tomorrow.add(const Duration(days: 1))),
      ];
      final rows = buildChoreListRows(
        chores: chores,
        sortOrder: ChoreSortOrder.urgency,
        direction: SortDirection.ascending,
        now: now,
      );

      final ids = rows.whereType<ChoreItemRow>().map((r) => r.chore.chore.id).toList();
      // Encounter order from the (already comparator-sorted) input is kept
      // as-is, not re-sorted by this function.
      expect(ids, [3, 2, 1]);
    });

    test('due exactly at the start of today is Today, not Overdue or Upcoming',
        () {
      final startOfToday = DateTime(2026, 8, 10);
      final rows = buildChoreListRows(
        chores: [_chore(1, 'Midnight due', due: startOfToday)],
        sortOrder: ChoreSortOrder.urgency,
        direction: SortDirection.ascending,
        now: now,
      );

      expect(rows.whereType<ChoreSectionHeaderRow>().single.section,
          DueSection.today);
    });
  });
}
