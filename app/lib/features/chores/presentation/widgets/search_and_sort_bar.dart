import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/strings/flavor_provider.dart';
import '../../domain/chore_filter_sort.dart';
import '../../providers/chore_providers.dart';

class SearchAndSortBar extends ConsumerStatefulWidget {
  const SearchAndSortBar({super.key});

  @override
  ConsumerState<SearchAndSortBar> createState() => _SearchAndSortBarState();
}

class _SearchAndSortBarState extends ConsumerState<SearchAndSortBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(choreSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(choreSearchQueryProvider, (previous, next) {
      if (_searchController.text != next) {
        _searchController.text = next;
      }
    });

    final strings = ref.watch(appStringsProvider);
    final sortState = ref.watch(sortStateProvider);
    final searchQuery = ref.watch(choreSearchQueryProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Column(
        children: [
          SearchBar(
            controller: _searchController,
            hintText: strings.searchPlaceholder,
            leading: const Icon(Icons.search),
            trailing: [
              if (searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(choreSearchQueryProvider.notifier).setQuery('');
                  },
                ),
            ],
            onChanged: (value) {
              ref.read(choreSearchQueryProvider.notifier).setQuery(value);
            },
            elevation: WidgetStateProperty.all(1.0),
          ),
          const SizedBox(height: 8.0),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _SortChoiceChip(
                  label: strings.sortUrgency,
                  sortOrder: ChoreSortOrder.urgency,
                  currentSortState: sortState,
                ),
                const SizedBox(width: 8),
                _SortChoiceChip(
                  label: strings.sortName,
                  sortOrder: ChoreSortOrder.name,
                  currentSortState: sortState,
                ),
                const SizedBox(width: 8),
                _SortChoiceChip(
                  label: strings.sortLastCompleted,
                  sortOrder: ChoreSortOrder.lastCompleted,
                  currentSortState: sortState,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SortChoiceChip extends ConsumerWidget {
  final String label;
  final ChoreSortOrder sortOrder;
  final SortState currentSortState;

  const _SortChoiceChip({
    required this.label,
    required this.sortOrder,
    required this.currentSortState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = currentSortState.order == sortOrder;
    final isAscending = currentSortState.direction == SortDirection.ascending;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      avatar: isSelected
          ? Icon(
              isAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
            )
          : null,
      onSelected: (_) {
        ref.read(sortStateProvider.notifier).selectOrder(sortOrder);
      },
    );
  }
}
