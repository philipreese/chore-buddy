import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/flavor_provider.dart';
import '../providers/chore_providers.dart';
import 'widgets/chore_card.dart';
import 'widgets/chores_empty_state.dart';
import 'widgets/search_and_sort_bar.dart';
import 'widgets/tag_filter_row.dart';

class ChoresScreen extends ConsumerWidget {
  const ChoresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final choresAsync = ref.watch(filteredAndSortedChoresProvider);
    final isTotalEmpty = ref.watch(isTotalEmptyProvider);
    final strings = ref.watch(appStringsProvider);

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
                      return ChoreCard(
                        key: ValueKey(item.chore.id),
                        chore: item,
                        onTap: () => context.push('/chores/${item.chore.id}'),
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
