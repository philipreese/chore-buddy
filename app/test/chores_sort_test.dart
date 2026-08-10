import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/chore_with_details.dart';
import 'package:chorebuddy/core/database/tables.dart';
import 'package:chorebuddy/features/chores/domain/chore_filter_sort.dart';
import 'package:chorebuddy/features/chores/providers/chore_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 8, 10, 12, 0);

  final itemA = ChoreWithDetails(
    chore: ChoreEntity(
      id: 1,
      name: 'Alpha Chore',
      isActive: true,
      nextDueDate: now.add(const Duration(hours: 2)),
      recurrence: RecurrenceType.daily,
      isNotificationEnabled: false,
      createdAt: now,
    ),
    tags: [],
    lastCompleted: now.subtract(const Duration(days: 2)),
    lastNote: null,
  );

  final itemB = ChoreWithDetails(
    chore: ChoreEntity(
      id: 2,
      name: 'Beta Chore',
      isActive: true,
      nextDueDate: now.add(const Duration(hours: 10)),
      recurrence: RecurrenceType.daily,
      isNotificationEnabled: false,
      createdAt: now,
    ),
    tags: [],
    lastCompleted: now.subtract(const Duration(days: 1)),
    lastNote: null,
  );

  final itemNullDue = ChoreWithDetails(
    chore: ChoreEntity(
      id: 3,
      name: 'Gamma Chore (No Due)',
      isActive: true,
      nextDueDate: null,
      recurrence: RecurrenceType.none,
      isNotificationEnabled: false,
      createdAt: now,
    ),
    tags: [],
    lastCompleted: now.subtract(const Duration(hours: 5)),
    lastNote: null,
  );

  final itemNeverDone = ChoreWithDetails(
    chore: ChoreEntity(
      id: 4,
      name: 'Delta Chore (Never Done)',
      isActive: true,
      nextDueDate: now.add(const Duration(hours: 5)),
      recurrence: RecurrenceType.none,
      isNotificationEnabled: false,
      createdAt: now,
    ),
    tags: [],
    lastCompleted: null,
    lastNote: null,
  );

  group('Chore Sorting Logic', () {
    test('Sort by Urgency (due date) descending - nulls last', () {
      final input = [itemNullDue, itemB, itemA];
      final result = sortChores(
        chores: input,
        sortOrder: ChoreSortOrder.urgency,
        direction: SortDirection.descending,
      );

      expect(result, [itemB, itemA, itemNullDue]);
    });

    test('Sort by Urgency (due date) ascending - nulls last', () {
      final input = [itemNullDue, itemB, itemA];
      final result = sortChores(
        chores: input,
        sortOrder: ChoreSortOrder.urgency,
        direction: SortDirection.ascending,
      );

      expect(result, [itemA, itemB, itemNullDue]);
    });

    test('Sort by Name ascending & descending', () {
      final input = [itemB, itemA, itemNullDue];

      final asc = sortChores(
        chores: input,
        sortOrder: ChoreSortOrder.name,
        direction: SortDirection.ascending,
      );
      expect(asc, [itemA, itemB, itemNullDue]);

      final desc = sortChores(
        chores: input,
        sortOrder: ChoreSortOrder.name,
        direction: SortDirection.descending,
      );
      expect(desc, [itemNullDue, itemB, itemA]);
    });

    test('Sort by Last Completed descending - nulls last', () {
      final input = [itemNeverDone, itemA, itemB];
      final result = sortChores(
        chores: input,
        sortOrder: ChoreSortOrder.lastCompleted,
        direction: SortDirection.descending,
      );

      expect(result, [itemB, itemA, itemNeverDone]);
    });

    test('Sort by Last Completed ascending - nulls last', () {
      final input = [itemNeverDone, itemA, itemB];
      final result = sortChores(
        chores: input,
        sortOrder: ChoreSortOrder.lastCompleted,
        direction: SortDirection.ascending,
      );

      expect(result, [itemA, itemB, itemNeverDone]);
    });
  });

  group('SortStateNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('default state is Urgency descending', () {
      final state = container.read(sortStateProvider);
      expect(state.order, ChoreSortOrder.urgency);
      expect(state.direction, SortDirection.descending);
    });

    test('flips direction when tapping active chip', () {
      final notifier = container.read(sortStateProvider.notifier);
      expect(container.read(sortStateProvider).direction, SortDirection.descending);

      notifier.selectOrder(ChoreSortOrder.urgency);
      expect(container.read(sortStateProvider).direction, SortDirection.ascending);

      notifier.selectOrder(ChoreSortOrder.urgency);
      expect(container.read(sortStateProvider).direction, SortDirection.descending);
    });

    test('resets direction to descending when switching sort order', () {
      final notifier = container.read(sortStateProvider.notifier);
      notifier.selectOrder(ChoreSortOrder.urgency);
      expect(container.read(sortStateProvider).direction, SortDirection.ascending);

      notifier.selectOrder(ChoreSortOrder.name);
      expect(container.read(sortStateProvider).order, ChoreSortOrder.name);
      expect(container.read(sortStateProvider).direction, SortDirection.descending);
    });
  });
}
