import '../../../core/database/chore_with_details.dart';
import 'chore_filter_sort.dart';
import 'due_status.dart';

/// One row of the chores list. The chores screen's sliver builder and its
/// scroll-offset math (`_animateToIndex`) both walk the exact same
/// `List<ChoreListRow>` produced by [buildChoreListRows] -- neither can
/// drift out of sync with the other because there is only one place that
/// decides what row sits at what index.
sealed class ChoreListRow {
  const ChoreListRow();
}

class ChoreSectionHeaderRow extends ChoreListRow {
  final DueSection section;
  final int count;

  const ChoreSectionHeaderRow({required this.section, required this.count});
}

class ChoreItemRow extends ChoreListRow {
  final ChoreWithDetails chore;

  const ChoreItemRow(this.chore);
}

const _ascendingSectionOrder = [
  DueSection.overdue,
  DueSection.today,
  DueSection.upcoming,
  DueSection.unscheduled,
];

/// Flattens [chores] (already filtered/sorted) into the rows the list
/// renders. Under urgency sort, chores are grouped into section headers
/// (empty sections omitted); every other sort order stays a flat list of
/// items with no headers. Within a section, [chores]' existing order is
/// preserved -- callers pass in a list already run through [sortChores].
List<ChoreListRow> buildChoreListRows({
  required List<ChoreWithDetails> chores,
  required ChoreSortOrder sortOrder,
  required SortDirection direction,
  required DateTime now,
}) {
  if (sortOrder != ChoreSortOrder.urgency) {
    return chores.map(ChoreItemRow.new).toList();
  }

  final buckets = <DueSection, List<ChoreWithDetails>>{
    for (final section in DueSection.values) section: [],
  };
  for (final chore in chores) {
    buckets[getDueSection(chore.chore.nextDueDate, now)]!.add(chore);
  }

  final sectionOrder = direction == SortDirection.ascending
      ? _ascendingSectionOrder
      : _ascendingSectionOrder.reversed;

  final rows = <ChoreListRow>[];
  for (final section in sectionOrder) {
    final items = buckets[section]!;
    if (items.isEmpty) continue;
    rows.add(ChoreSectionHeaderRow(section: section, count: items.length));
    rows.addAll(items.map(ChoreItemRow.new));
  }
  return rows;
}
