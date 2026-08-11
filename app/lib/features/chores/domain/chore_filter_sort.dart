import '../../../core/database/chore_with_details.dart';

enum ChoreSortOrder {
  urgency,
  name,
  lastCompleted,
}

enum SortDirection {
  ascending,
  descending,
}

/// The direction each [ChoreSortOrder] should default to (both on first
/// load and whenever a chip switches TO that order) so the chip reads as
/// "most useful first" without the user ever having to flip it:
///  - urgency ascending puts the earliest due date first, which is the most
///    overdue chore (or soonest upcoming one) -- "most urgent on top".
///  - lastCompleted descending puts the latest completion timestamp first --
///    "most recently done on top".
///  - name ascending is plain A-Z.
SortDirection defaultSortDirection(ChoreSortOrder order) {
  switch (order) {
    case ChoreSortOrder.lastCompleted:
      return SortDirection.descending;
    case ChoreSortOrder.urgency:
    case ChoreSortOrder.name:
      return SortDirection.ascending;
  }
}

List<ChoreWithDetails> filterChores({
  required List<ChoreWithDetails> chores,
  required String searchQuery,
  required Set<int> selectedTagIds,
}) {
  final query = searchQuery.trim().toLowerCase();

  return chores.where((item) {
    if (query.isNotEmpty) {
      final name = item.chore.name.toLowerCase();
      if (!name.contains(query)) {
        return false;
      }
    }

    if (selectedTagIds.isNotEmpty) {
      final hasMatchingTag =
          item.tags.any((tag) => selectedTagIds.contains(tag.id));
      if (!hasMatchingTag) {
        return false;
      }
    }

    return true;
  }).toList();
}

List<ChoreWithDetails> sortChores({
  required List<ChoreWithDetails> chores,
  required ChoreSortOrder sortOrder,
  required SortDirection direction,
}) {
  final sorted = List<ChoreWithDetails>.from(chores);

  sorted.sort((a, b) {
    switch (sortOrder) {
      case ChoreSortOrder.urgency:
        final aDue = a.chore.nextDueDate;
        final bDue = b.chore.nextDueDate;

        if (aDue == null && bDue == null) {
          return a.chore.name.toLowerCase().compareTo(b.chore.name.toLowerCase());
        }
        if (aDue == null) return 1;
        if (bDue == null) return -1;

        final cmp = direction == SortDirection.ascending
            ? aDue.compareTo(bDue)
            : bDue.compareTo(aDue);
        if (cmp != 0) return cmp;
        return a.chore.name.toLowerCase().compareTo(b.chore.name.toLowerCase());

      case ChoreSortOrder.name:
        final nameA = a.chore.name.toLowerCase();
        final nameB = b.chore.name.toLowerCase();
        final cmp = direction == SortDirection.ascending
            ? nameA.compareTo(nameB)
            : nameB.compareTo(nameA);
        if (cmp != 0) return cmp;
        return a.chore.id.compareTo(b.chore.id);

      case ChoreSortOrder.lastCompleted:
        final aDone = a.lastCompleted;
        final bDone = b.lastCompleted;

        if (aDone == null && bDone == null) {
          return a.chore.name.toLowerCase().compareTo(b.chore.name.toLowerCase());
        }
        if (aDone == null) return 1;
        if (bDone == null) return -1;

        final cmp = direction == SortDirection.ascending
            ? aDone.compareTo(bDone)
            : bDone.compareTo(aDone);
        if (cmp != 0) return cmp;
        return a.chore.name.toLowerCase().compareTo(b.chore.name.toLowerCase());
    }
  });

  return sorted;
}
