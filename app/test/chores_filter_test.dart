import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/chore_with_details.dart';
import 'package:chorebuddy/core/database/tables.dart';
import 'package:chorebuddy/features/chores/domain/chore_filter_sort.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 8, 10, 12, 0);

  final tag1 = const TagEntity(id: 10, name: 'Kitchen', colorIndex: 0);
  final tag2 = const TagEntity(id: 20, name: 'Yard', colorIndex: 1);
  final tag3 = const TagEntity(id: 30, name: 'Daily', colorIndex: 2);

  final chore1 = ChoreWithDetails(
    chore: ChoreEntity(
      id: 1,
      name: 'Clean Countertops',
      isActive: true,
      nextDueDate: now,
      recurrence: RecurrenceType.daily,
      isNotificationEnabled: false,
      createdAt: now,
    ),
    tags: [tag1, tag3],
  );

  final chore2 = ChoreWithDetails(
    chore: ChoreEntity(
      id: 2,
      name: 'Mow the Lawn',
      isActive: true,
      nextDueDate: now,
      recurrence: RecurrenceType.weekly,
      isNotificationEnabled: false,
      createdAt: now,
    ),
    tags: [tag2],
  );

  final chore3 = ChoreWithDetails(
    chore: ChoreEntity(
      id: 3,
      name: 'Sweep Kitchen Floor',
      isActive: true,
      nextDueDate: now,
      recurrence: RecurrenceType.daily,
      isNotificationEnabled: false,
      createdAt: now,
    ),
    tags: [tag1],
  );

  final allChores = [chore1, chore2, chore3];

  group('Chore Filtering & Search', () {
    test('returns all chores when search is empty and no tag filters selected', () {
      final result = filterChores(
        chores: allChores,
        searchQuery: '',
        selectedTagIds: {},
      );

      expect(result.length, 3);
    });

    test('search query matches case-insensitive contains', () {
      final result = filterChores(
        chores: allChores,
        searchQuery: 'KITCHEN',
        selectedTagIds: {},
      );

      expect(result.length, 1);
      expect(result.first.chore.id, 3);
    });

    test('tag filter enforces multi-select OR semantics', () {
      final result = filterChores(
        chores: allChores,
        searchQuery: '',
        selectedTagIds: {10, 20},
      );

      expect(result.length, 3);

      final yardOnly = filterChores(
        chores: allChores,
        searchQuery: '',
        selectedTagIds: {20},
      );

      expect(yardOnly.length, 1);
      expect(yardOnly.first.chore.id, 2);
    });

    test('combined search query AND tag filter', () {
      final result = filterChores(
        chores: allChores,
        searchQuery: 'Clean',
        selectedTagIds: {10},
      );

      expect(result.length, 1);
      expect(result.first.chore.id, 1);
    });
  });
}
