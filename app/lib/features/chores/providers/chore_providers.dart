import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/chore_with_details.dart';
import '../../../core/database/database_provider.dart';
import '../domain/chore_filter_sort.dart';

class SortState {
  final ChoreSortOrder order;
  final SortDirection direction;

  const SortState({
    this.order = ChoreSortOrder.urgency,
    this.direction = SortDirection.descending,
  });

  SortState copyWith({
    ChoreSortOrder? order,
    SortDirection? direction,
  }) {
    return SortState(
      order: order ?? this.order,
      direction: direction ?? this.direction,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SortState &&
          runtimeType == other.runtimeType &&
          order == other.order &&
          direction == other.direction;

  @override
  int get hashCode => Object.hash(order, direction);
}

class SortStateNotifier extends Notifier<SortState> {
  @override
  SortState build() => const SortState();

  void selectOrder(ChoreSortOrder newOrder) {
    if (state.order == newOrder) {
      final newDirection = state.direction == SortDirection.ascending
          ? SortDirection.descending
          : SortDirection.ascending;
      state = state.copyWith(direction: newDirection);
    } else {
      state = SortState(
        order: newOrder,
        direction: SortDirection.descending,
      );
    }
  }
}

class ChoreSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

class SelectedTagFilterNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => {};

  void toggleTag(int tagId) {
    if (state.contains(tagId)) {
      state = Set.from(state)..remove(tagId);
    } else {
      state = Set.from(state)..add(tagId);
    }
  }

  void setTags(Set<int> tags) {
    state = tags;
  }
}

class ShowDetailsOnCardsNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() {
    state = !state;
  }

  void setVisible(bool visible) {
    state = visible;
  }
}

final choreSearchQueryProvider =
    NotifierProvider<ChoreSearchQueryNotifier, String>(
  ChoreSearchQueryNotifier.new,
);

final selectedTagFilterIdsProvider =
    NotifierProvider<SelectedTagFilterNotifier, Set<int>>(
  SelectedTagFilterNotifier.new,
);

final sortStateProvider =
    NotifierProvider<SortStateNotifier, SortState>(
  SortStateNotifier.new,
);

final showDetailsOnCardsProvider =
    NotifierProvider<ShowDetailsOnCardsNotifier, bool>(
  ShowDetailsOnCardsNotifier.new,
);

class ChoresTabVisibleNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void setVisible(bool visible) {
    state = visible;
  }
}

final choresTabVisibleProvider =
    NotifierProvider<ChoresTabVisibleNotifier, bool>(
  ChoresTabVisibleNotifier.new,
);

final tickerStreamProvider = Provider.autoDispose<Stream<DateTime>>((ref) {
  final controller = StreamController<DateTime>.broadcast();
  final timer = Timer.periodic(const Duration(seconds: 1), (_) {
    if (!controller.isClosed) {
      controller.add(DateTime.now());
    }
  });
  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });
  return controller.stream;
});

final tickerProvider = StreamProvider.autoDispose<DateTime>((ref) {
  final isVisible = ref.watch(choresTabVisibleProvider);
  if (!isVisible) {
    return const Stream.empty();
  }
  return ref.watch(tickerStreamProvider);
});

final nowProvider = Provider.autoDispose<DateTime>((ref) {
  final tick = ref.watch(tickerProvider);
  return tick.value ?? DateTime.now();
});

final filteredAndSortedChoresProvider =
    Provider.autoDispose<AsyncValue<List<ChoreWithDetails>>>((ref) {
  final activeChoresAsync = ref.watch(activeChoresWithDetailsProvider);
  final searchQuery = ref.watch(choreSearchQueryProvider);
  final selectedTagIds = ref.watch(selectedTagFilterIdsProvider);
  final sortState = ref.watch(sortStateProvider);

  return activeChoresAsync.whenData((chores) {
    final filtered = filterChores(
      chores: chores,
      searchQuery: searchQuery,
      selectedTagIds: selectedTagIds,
    );
    return sortChores(
      chores: filtered,
      sortOrder: sortState.order,
      direction: sortState.direction,
    );
  });
});

final isTotalEmptyProvider = Provider.autoDispose<bool>((ref) {
  final activeChoresAsync = ref.watch(activeChoresWithDetailsProvider);
  return activeChoresAsync.when(
    data: (chores) => chores.isEmpty,
    loading: () => false,
    error: (err, stack) => false,
  );
});
