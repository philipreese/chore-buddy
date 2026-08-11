import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/notifications/notification_tap_provider.dart';
import '../../../core/strings/flavor_provider.dart';
import '../providers/chore_providers.dart';
import 'widgets/chore_card.dart';
import 'widgets/chores_empty_state.dart';
import 'widgets/search_and_sort_bar.dart';
import 'widgets/tag_filter_row.dart';

class ChoresScreen extends ConsumerStatefulWidget {
  const ChoresScreen({super.key});

  @override
  ConsumerState<ChoresScreen> createState() => _ChoresScreenState();
}

class _ChoresScreenState extends ConsumerState<ChoresScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _headerKey = GlobalKey();

  // Rows are close enough to uniform height that an index * estimated
  // extent offset lands on or near the target even though it was never
  // built (a GlobalKey/ensureVisible approach can't reach an unbuilt row at
  // all). Any inaccuracy is bounded by clamping to maxScrollExtent below.
  static const double _estimatedItemExtent = 132;
  static const double _listTopPadding = 8;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Scrolls to [choreId]'s row by resolving its index in the currently
  // filtered/sorted list. The pending id is only cleared once that
  // resolution actually happens:
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
      final index = chores == null
          ? -1
          : chores.indexWhere((item) => item.chore.id == choreId);

      if (index != -1) {
        _animateToIndex(index);
        ref.read(notificationTapChoreIdProvider.notifier).clear();
        return;
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

  void _animateToIndex(int index) {
    if (!_scrollController.hasClients) return;
    // The search bar, sort chips, and tag filter row now scroll away with
    // the list as a leading sliver instead of sitting in a fixed header, so
    // the target offset has to start past their rendered height rather than
    // from the top of the viewport.
    final headerExtent =
        (_headerKey.currentContext?.findRenderObject() as RenderBox?)
                ?.size
                .height ??
            0.0;
    final maxExtent = _scrollController.position.maxScrollExtent;
    final target = (headerExtent + _listTopPadding + index * _estimatedItemExtent)
        .clamp(0.0, maxExtent);
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

    ref.listen<int?>(notificationTapChoreIdProvider, (previous, next) {
      if (next != null) {
        _scrollToChore(next);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              // A tonal surface (not a shadow) separates the header from the
              // scrolling list below -- the list sits on the Scaffold's
              // default `colorScheme.surface`. surfaceContainer reads as
              // washed-out-to-white in light mode against plain `surface`
              // without an explicit background here.
              child: Container(
                color: Theme.of(context).colorScheme.surfaceContainer,
                child: Column(
                  key: _headerKey,
                  children: const [
                    SearchAndSortBar(),
                    TagFilterRow(),
                  ],
                ),
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
                return [
                  SliverPadding(
                    padding: const EdgeInsets.only(
                      top: _listTopPadding,
                      bottom: 88,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = chores[index];
                          return ChoreCard(
                            key: ValueKey(item.chore.id),
                            chore: item,
                            onTap: () =>
                                context.push('/chores/${item.chore.id}'),
                          );
                        },
                        childCount: chores.length,
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
