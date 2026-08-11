import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/notifications/notification_tap_provider.dart';
import '../../../core/strings/flavor_provider.dart';
import '../domain/chore_filter_sort.dart';
import '../domain/chore_list_rows.dart';
import '../domain/due_status.dart';
import '../providers/chore_providers.dart';
import 'widgets/chore_card.dart';
import 'widgets/chore_section_header.dart';
import 'widgets/chores_banner.dart';
import 'widgets/chores_empty_state.dart';
import 'widgets/search_and_sort_bar.dart';

class ChoresScreen extends ConsumerStatefulWidget {
  const ChoresScreen({super.key});

  @override
  ConsumerState<ChoresScreen> createState() => _ChoresScreenState();
}

class _ChoresScreenState extends ConsumerState<ChoresScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _bannerKey = GlobalKey();
  final GlobalKey _headerKey = GlobalKey();

  // Rows are close enough to uniform height (per row type) that summing
  // estimated extents up to the target index lands on or near the target
  // even though the row was never built (a GlobalKey/ensureVisible approach
  // can't reach an unbuilt row at all) -- see _animateToRowIndex for why
  // this is intentionally not clamped to an early maxScrollExtent snapshot.
  static const double _estimatedItemExtent = 132;
  static const double _estimatedSectionHeaderExtent = 44;
  static const double _listTopPadding = 8;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Scrolls to [choreId]'s row by resolving its index in the currently
  // filtered/sorted list's flattened row model (see chore_list_rows.dart).
  // The pending id is only cleared once that resolution actually happens:
  //  - found: scroll to it, then clear.
  //  - hidden behind an active search/tag filter: clear the filters and
  //    retry once, so a chore the user can plainly reach isn't abandoned.
  //  - still missing after that (e.g. archived/deleted since the
  //    notification fired): nothing to scroll to, so clear and give up
  //    rather than leaving the id stuck forever.
  void _scrollToChore(int choreId, {bool retriedAfterClearingFilters = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final chores = ref
          .read(filteredAndSortedChoresProvider)
          .maybeWhen(data: (chores) => chores, orElse: () => null);

      if (chores != null) {
        final sortState = ref.read(sortStateProvider);
        final rows = buildChoreListRows(
          chores: chores,
          sortOrder: sortState.order,
          direction: sortState.direction,
          now: ref.read(nowProvider),
        );
        final index = rows.indexWhere(
          (row) => row is ChoreItemRow && row.chore.chore.id == choreId,
        );
        if (index != -1) {
          _animateToRowIndex(index, rows);
          ref.read(notificationTapChoreIdProvider.notifier).clear();
          return;
        }
      }

      if (!retriedAfterClearingFilters) {
        final hasSearch = ref.read(choreSearchQueryProvider).isNotEmpty;
        final hasTagFilter = ref.read(selectedTagFilterIdsProvider).isNotEmpty;
        if (hasSearch || hasTagFilter) {
          ref.read(choreSearchQueryProvider.notifier).setQuery('');
          ref.read(selectedTagFilterIdsProvider.notifier).setTags({});
          _scrollToChore(choreId, retriedAfterClearingFilters: true);
          return;
        }
      }

      ref.read(notificationTapChoreIdProvider.notifier).clear();
    });
  }

  // Forces urgency-ascending sort -- the exact mechanism the "Overdue" quick
  // action uses (see app.dart's _handleShortcutAction) -- then scrolls to
  // [section]'s header once the reordered rows exist, so a stat chip tap
  // lands the user on the group it names instead of just reordering the
  // list under them.
  void _scrollToSection(DueSection section) {
    ref
        .read(sortStateProvider.notifier)
        .setOrder(ChoreSortOrder.urgency, SortDirection.ascending);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final chores = ref
          .read(filteredAndSortedChoresProvider)
          .maybeWhen(data: (chores) => chores, orElse: () => null);
      if (chores == null) return;

      final rows = buildChoreListRows(
        chores: chores,
        sortOrder: ChoreSortOrder.urgency,
        direction: SortDirection.ascending,
        now: ref.read(nowProvider),
      );
      final index = rows.indexWhere(
        (row) => row is ChoreSectionHeaderRow && row.section == section,
      );
      if (index == -1) return;
      _animateToRowIndex(index, rows);
    });
  }

  // Single source of truth for row->offset math, shared by every caller
  // above: walks the same flattened row list the sliver builder renders, so
  // the two can never drift apart the way a bare `index * itemExtent`
  // guess and a builder with section headers interleaved would.
  void _animateToRowIndex(int index, List<ChoreListRow> rows) {
    if (!_scrollController.hasClients) return;

    // The banner and the search/sort bar now scroll away with the list as
    // leading slivers instead of sitting in a fixed header, so the target
    // offset has to start past their rendered height rather than from the
    // top of the viewport.
    final bannerExtent =
        (_bannerKey.currentContext?.findRenderObject() as RenderBox?)
                ?.size
                .height ??
            0.0;
    final searchBarExtent =
        (_headerKey.currentContext?.findRenderObject() as RenderBox?)
                ?.size
                .height ??
            0.0;

    var rowsOffset = 0.0;
    for (var i = 0; i < index && i < rows.length; i++) {
      rowsOffset += rows[i] is ChoreSectionHeaderRow
          ? _estimatedSectionHeaderExtent
          : _estimatedItemExtent;
    }

    // Deliberately NOT clamped to position.maxScrollExtent here: this early
    // in the scroll, that value is only a rough extrapolation from whatever
    // handful of rows the viewport has built so far, and mixing short
    // section headers in with much taller cards skews that extrapolation
    // low -- clamping to it can cap the target well short of the real
    // bottom. ClampingScrollPhysics already bounds the animation to the
    // true (continuously refined) max as more rows build while it scrolls,
    // so passing the raw estimate straight through lands at the real
    // bottom instead of wherever the early guess happened to cap it.
    final target = bannerExtent + searchBarExtent + _listTopPadding + rowsOffset;
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final choresAsync = ref.watch(filteredAndSortedChoresProvider);
    final isTotalEmpty = ref.watch(isTotalEmptyProvider);
    final strings = ref.watch(appStringsProvider);
    final sortState = ref.watch(sortStateProvider);
    final now = ref.watch(nowProvider);

    ref.listen<int?>(notificationTapChoreIdProvider, (previous, next) {
      if (next != null) {
        _scrollToChore(next);
      }
    });

    // A sort change re-orders the whole list, so whatever was under the
    // user's previous scroll position is no longer meaningful -- covers
    // both a manual chip tap and the "Overdue" shortcut/stat-chip, which
    // force urgency-ascending and then scroll to a specific row themselves
    // (see _scrollToSection): this jump-to-0 runs first in the same frame,
    // and the section scroll (registered afterwards) overrides it.
    ref.listen<SortState>(sortStateProvider, (previous, next) {
      if (previous != null && previous != next) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scrollController.hasClients) {
            _scrollController.jumpTo(0);
          }
        });
      }
    });

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: ChoresBanner(
                key: _bannerKey,
                onStatTap: _scrollToSection,
              ),
            ),
            SliverToBoxAdapter(
              // A tonal surface plus an explicit divider (not tone alone --
              // see item 1's card-depth fix) separates the header from the
              // scrolling list below, which sits on the Scaffold's default
              // `colorScheme.surface`. surfaceContainerHighest is the
              // strongest tonal step available so it reads as a distinct
              // layer even where an adjacent step washes out under dynamic
              // color.
              child: Container(
                key: _headerKey,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
                child: const SearchAndSortBar(),
              ),
            ),
            ...choresAsync.when(
              data: (chores) {
                if (chores.isEmpty) {
                  return [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: ChoresEmptyState(isTotalEmpty: isTotalEmpty),
                    ),
                  ];
                }
                final rows = buildChoreListRows(
                  chores: chores,
                  sortOrder: sortState.order,
                  direction: sortState.direction,
                  now: now,
                );
                return [
                  SliverPadding(
                    padding: const EdgeInsets.only(
                      top: _listTopPadding,
                      bottom: 88,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final row = rows[index];
                          return switch (row) {
                            ChoreSectionHeaderRow() => ChoreSectionHeader(
                                key: ValueKey('section_${row.section}'),
                                section: row.section,
                                count: row.count,
                              ),
                            ChoreItemRow() => ChoreCard(
                                key: ValueKey(row.chore.chore.id),
                                chore: row.chore,
                                onTap: () => context
                                    .push('/chores/${row.chore.chore.id}'),
                              ),
                          };
                        },
                        childCount: rows.length,
                      ),
                    ),
                  ),
                ];
              },
              loading: () => [
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (err, stack) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text(strings.genericError(err))),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/chores/new');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
