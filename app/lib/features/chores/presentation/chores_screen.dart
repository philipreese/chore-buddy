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

  // Rows are close enough to uniform height that an index * estimated
  // extent offset lands on or near the target even though it was never
  // built (a GlobalKey/ensureVisible approach can't reach an unbuilt row at
  // all). Any inaccuracy is bounded by clamping to maxScrollExtent below.
  static const double _estimatedItemExtent = 132;

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
    final maxExtent = _scrollController.position.maxScrollExtent;
    final target = (index * _estimatedItemExtent).clamp(0.0, maxExtent);
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
        child: Column(
          children: [
            const SearchAndSortBar(),
            const TagFilterRow(),
            Expanded(
              child: choresAsync.when(
                data: (chores) {
                  if (chores.isEmpty) {
                    return ChoresEmptyState(isTotalEmpty: isTotalEmpty);
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: chores.length,
                    padding: const EdgeInsets.only(top: 8, bottom: 88),
                    itemBuilder: (context, index) {
                      final item = chores[index];
                      return ChoreCard(
                        key: ValueKey(item.chore.id),
                        chore: item,
                        onTap: () => context.push('/chores/${item.chore.id}'),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) =>
                    Center(child: Text(strings.genericError(err))),
              ),
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
