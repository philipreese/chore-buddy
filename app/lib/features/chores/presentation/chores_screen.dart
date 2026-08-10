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
  final Map<int, GlobalKey> _itemKeys = {};

  GlobalKey _keyFor(int choreId) =>
      _itemKeys.putIfAbsent(choreId, () => GlobalKey());

  void _scrollToChore(int choreId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _itemKeys[choreId];
      final context = key?.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          alignment: 0.5,
        );
      }
      if (mounted) {
        ref.read(notificationTapChoreIdProvider.notifier).clear();
      }
    });
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
                    itemCount: chores.length,
                    padding: const EdgeInsets.only(top: 8, bottom: 88),
                    itemBuilder: (context, index) {
                      final item = chores[index];
                      return KeyedSubtree(
                        key: _keyFor(item.chore.id),
                        child: ChoreCard(
                          key: ValueKey(item.chore.id),
                          chore: item,
                          onTap: () =>
                              context.push('/chores/${item.chore.id}'),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (err, stack) => Center(
                  child: Text(strings.genericError(err)),
                ),
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
