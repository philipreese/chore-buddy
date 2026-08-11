import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/strings/app_strings.dart';
import '../../../../core/strings/flavor_provider.dart';
import '../../domain/chore_filter_sort.dart';
import '../../providers/chore_providers.dart';
import 'tag_filter_row.dart';

/// The chores tab's dense header row: search collapses to an icon (or a
/// dismissible chip once a query is active) so sort and tag-filter access
/// fit on the same line instead of stacking below a full-width search field.
class SearchAndSortBar extends ConsumerStatefulWidget {
  const SearchAndSortBar({super.key});

  @override
  ConsumerState<SearchAndSortBar> createState() => _SearchAndSortBarState();
}

class _SearchAndSortBarState extends ConsumerState<SearchAndSortBar> {
  late final TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();
  bool _searchExpanded = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(choreSearchQueryProvider),
    );
    _searchFocusNode.addListener(() {
      // Losing focus with an empty query collapses back to the icon; with a
      // non-empty query it collapses to the dismissible summary chip
      // instead, both of which are plain rebuilds off the same state.
      if (!_searchFocusNode.hasFocus) {
        setState(() => _searchExpanded = false);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _searchExpanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(choreSearchQueryProvider.notifier).setQuery('');
    setState(() => _searchExpanded = false);
  }

  void _openTagFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const TagFilterSheet(),
    );
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
    final activeTagCount = ref.watch(selectedTagFilterIdsProvider).length;
    final colorScheme = Theme.of(context).colorScheme;

    final expanded = _searchExpanded || _searchFocusNode.hasFocus;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          if (expanded)
            Expanded(
              child: SearchBar(
                focusNode: _searchFocusNode,
                controller: _searchController,
                hintText: strings.searchPlaceholder,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _searchFocusNode.unfocus(),
                ),
                trailing: [
                  if (searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch,
                    ),
                ],
                onChanged: (value) {
                  ref.read(choreSearchQueryProvider.notifier).setQuery(value);
                },
                onSubmitted: (_) => _searchFocusNode.unfocus(),
                // Mode-stable: a real elevation shadow renders in light mode
                // but vanishes entirely in dark, so the two brightnesses
                // disagreed about how the bar was layered. A flat fill with
                // a hairline border reads identically in both, and sits on
                // plain `surface` rather than the header's own
                // surfaceContainerHighest so the field still reads as a
                // distinct control rather than blending into the header.
                elevation: const WidgetStatePropertyAll(0),
                backgroundColor: WidgetStatePropertyAll(colorScheme.surface),
                side: WidgetStatePropertyAll(
                  BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
            )
          else if (searchQuery.isNotEmpty)
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  key: const Key('search_summary_chip'),
                  avatar: const Icon(Icons.search, size: 18),
                  label: Text(searchQuery, overflow: TextOverflow.ellipsis),
                  onPressed: _openSearch,
                  onDeleted: _clearSearch,
                ),
              ),
            )
          else
            IconButton(
              key: const Key('search_icon_button'),
              icon: const Icon(Icons.search),
              tooltip: strings.searchPlaceholder,
              onPressed: _openSearch,
            ),
          if (!expanded) ...[
            const SizedBox(width: 4),
            _SortMenuButton(sortState: sortState, strings: strings),
            const SizedBox(width: 4),
            _TagFilterButton(
              activeCount: activeTagCount,
              tooltip: strings.filterButtonLabel,
              onPressed: _openTagFilterSheet,
            ),
          ],
        ],
      ),
    );
  }
}

class _SortMenuButton extends ConsumerWidget {
  final SortState sortState;
  final AppStrings strings;

  const _SortMenuButton({required this.sortState, required this.strings});

  String _labelFor(ChoreSortOrder order) {
    switch (order) {
      case ChoreSortOrder.urgency:
        return strings.sortUrgency;
      case ChoreSortOrder.name:
        return strings.sortName;
      case ChoreSortOrder.lastCompleted:
        return strings.sortLastCompleted;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAscending = sortState.direction == SortDirection.ascending;

    return PopupMenuButton<ChoreSortOrder>(
      key: const Key('sort_menu_button'),
      tooltip: strings.sortButtonLabel,
      onSelected: (order) {
        ref.read(sortStateProvider.notifier).selectOrder(order);
      },
      itemBuilder: (context) => ChoreSortOrder.values.map((order) {
        final isSelected = sortState.order == order;
        return PopupMenuItem(
          value: order,
          child: Row(
            children: [
              SizedBox(
                width: 20,
                child: isSelected
                    ? Icon(
                        isAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 16,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Text(_labelFor(order)),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort, size: 18, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              _labelFor(sortState.order),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(width: 2),
            Icon(
              isAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _TagFilterButton extends StatelessWidget {
  final int activeCount;
  final String tooltip;
  final VoidCallback onPressed;

  const _TagFilterButton({
    required this.activeCount,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Badge(
      label: Text('$activeCount'),
      isLabelVisible: activeCount > 0,
      child: IconButton(
        key: const Key('tag_filter_button'),
        icon: const Icon(Icons.filter_list),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
