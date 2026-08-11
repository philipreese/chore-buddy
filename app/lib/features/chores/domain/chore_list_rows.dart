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

// Approximate ChoreCard extents by content, derived from chore_card.dart's
// layout: a minimal card (no tags, no details block) renders at roughly this
// height, with each optional block adding its own increment on top.
const double estimatedMinimalCardExtent = 110;
const double estimatedTagsIncrement = 40;
const double estimatedDetailsIncrement = 46;
const double estimatedSectionHeaderExtent = 44;

/// Estimated extent for [row], used by the chores screen's scroll-offset
/// math (`_animateToRowIndex`) to sum up to a target index without having
/// built the rows in between. Content-aware rather than uniform: a
/// [ChoreItemRow] with tags and/or a visible details block is taller than a
/// bare one, so its estimate grows with the same data chore_card.dart reads
/// to decide what to render.
double estimateRowExtent(ChoreListRow row, {required bool showDetailsOnCards}) {
  if (row is ChoreSectionHeaderRow) return estimatedSectionHeaderExtent;
  final chore = (row as ChoreItemRow).chore;
  var extent = estimatedMinimalCardExtent;
  if (chore.tags.isNotEmpty) extent += estimatedTagsIncrement;
  if (showDetailsOnCards &&
      (chore.lastCompleted != null || chore.lastNote != null)) {
    extent += estimatedDetailsIncrement;
  }
  return extent;
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
