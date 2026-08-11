import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/strings/flavor_provider.dart';
import '../domain/stats_calculator.dart';
import '../providers/chore_providers.dart';
import '../providers/stats_providers.dart';

/// The Mission Log page (spec 22): a household-wide view of completion
/// stats reached by tapping the chores banner's weekly line. Three blocks --
/// this week's total + best current streak, a 5-week bar chart, and a
/// calendar heatmap for the current month -- all derived from the
/// completions table, no new data collection.
class MissionLogScreen extends ConsumerWidget {
  const MissionLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final now = ref.watch(nowProvider);
    final completionsAsync = ref.watch(allCompletionsProvider);
    final choresAsync = ref.watch(allChoresForStatsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(strings.missionLogTitle)),
      body: completionsAsync.when(
        data: (completions) => choresAsync.when(
          data: (chores) => _MissionLogBody(
            strings: strings,
            now: now,
            completions: completions,
            chores: chores,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text(strings.genericError(err))),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(strings.genericError(err))),
      ),
    );
  }
}

class _MissionLogBody extends StatelessWidget {
  final AppStrings strings;
  final DateTime now;
  final List<CompletionRecordEntity> completions;
  final List<ChoreEntity> chores;

  const _MissionLogBody({
    required this.strings,
    required this.now,
    required this.completions,
    required this.chores,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final completedAts = completions.map((c) => c.completedAt).toList();

    final weekStats = computeWeekCompletionStats(completedAts, now);

    final completionsByChoreId = <int, List<DateTime>>{};
    for (final c in completions) {
      completionsByChoreId.putIfAbsent(c.choreId, () => []).add(c.completedAt);
    }
    final bestStreak = bestStreakAcrossChores(chores, completionsByChoreId);

    final weeklyCounts = weeklyCompletionCounts(completedAts, now, 5);
    final heatmapGrid = buildMonthHeatmap(completedAts, now);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildThisWeekBlock(context, colorScheme, weekStats, bestStreak),
        const SizedBox(height: 16),
        _buildBarChartBlock(context, colorScheme, weeklyCounts),
        const SizedBox(height: 16),
        _buildHeatmapBlock(context, colorScheme, heatmapGrid),
      ],
    );
  }

  Widget _card(BuildContext context, ColorScheme colorScheme, Widget child) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(padding: const EdgeInsets.all(16.0), child: child),
    );
  }

  Widget _buildThisWeekBlock(
    BuildContext context,
    ColorScheme colorScheme,
    WeekCompletionStats weekStats,
    ChoreStreakInfo? bestStreak,
  ) {
    final textTheme = Theme.of(context).textTheme;
    return _card(
      context,
      colorScheme,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.missionLogThisWeekLabel, style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${weekStats.thisWeekCount}',
                key: const Key('mission_log_week_count'),
                style: textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                strings.missionLogMissionsUnitLabel,
                style: textTheme.bodyLarge,
              ),
            ],
          ),
          if (bestStreak != null) ...[
            const SizedBox(height: 12),
            Text(
              strings.missionLogBestStreakLabel(
                bestStreak.choreName,
                bestStreak.streak,
              ),
              key: const Key('mission_log_best_streak'),
              style: textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBarChartBlock(
    BuildContext context,
    ColorScheme colorScheme,
    List<int> weeklyCounts,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final maxCount = weeklyCounts.isEmpty
        ? 0
        : weeklyCounts.reduce((a, b) => a > b ? a : b);
    const maxBarHeight = 80.0;

    return _card(
      context,
      colorScheme,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.missionLogLastFiveWeeksTitle,
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < weeklyCounts.length; i++)
                _buildBar(
                  context: context,
                  colorScheme: colorScheme,
                  count: weeklyCounts[i],
                  maxCount: maxCount,
                  maxBarHeight: maxBarHeight,
                  isCurrent: i == weeklyCounts.length - 1,
                  label: i == weeklyCounts.length - 1
                      ? 'Now'
                      : '-${weeklyCounts.length - 1 - i}w',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar({
    required BuildContext context,
    required ColorScheme colorScheme,
    required int count,
    required int maxCount,
    required double maxBarHeight,
    required bool isCurrent,
    required String label,
  }) {
    final fillHeight = maxCount == 0 ? 0.0 : (count / maxCount) * maxBarHeight;
    return Expanded(
      child: Column(
        children: [
          Text('$count', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Container(
            height: maxBarHeight,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(6),
              border: isCurrent
                  ? Border.all(color: colorScheme.primary, width: 2)
                  : null,
            ),
            alignment: Alignment.bottomCenter,
            child: Container(
              height: fillHeight,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }

  Widget _buildHeatmapBlock(
    BuildContext context,
    ColorScheme colorScheme,
    List<List<HeatmapCell>> grid,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final levelColors = heatmapLevelColors(colorScheme);
    const weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return _card(
      context,
      colorScheme,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.missionLogThisMonthTitle, style: textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: weekdayLabels
                .map(
                  (l) => Expanded(
                    child: Center(child: Text(l, style: textTheme.labelSmall)),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 4),
          for (final week in grid)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: week.map((cell) {
                  if (cell.day == null) {
                    return const Expanded(child: SizedBox(height: 28));
                  }
                  final level = heatmapLevelForCount(cell.count);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: levelColors[level.index],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
