import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../core/strings/flavor_provider.dart';
import '../../domain/due_status.dart';
import '../../domain/stats_calculator.dart';
import '../../providers/chore_providers.dart';
import '../../providers/stats_providers.dart';

/// Solid `primaryContainer` banner header for the chores tab: app title +
/// settings gear (absorbing the shell's AppBar for this tab only, see
/// AppShell), then a row of overdue/due-today/upcoming stat chips computed
/// from every active chore regardless of the current search/tag filter.
class ChoresBanner extends ConsumerWidget {
  final void Function(DueSection section) onStatTap;

  const ChoresBanner({super.key, required this.onStatTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final now = ref.watch(nowProvider);
    final activeAsync = ref.watch(activeChoresWithDetailsProvider);
    final completionsAsync = ref.watch(allCompletionsProvider);

    var overdueCount = 0;
    var todayCount = 0;
    var upcomingCount = 0;
    activeAsync.whenData((chores) {
      for (final item in chores) {
        switch (getDueSection(item.chore.nextDueDate, now)) {
          case DueSection.overdue:
            overdueCount++;
          case DueSection.today:
            todayCount++;
          case DueSection.upcoming:
            upcomingCount++;
          case DueSection.unscheduled:
            break;
        }
      }
    });

    var completedAts = <DateTime>[];
    completionsAsync.whenData((records) {
      completedAts = records.map((r) => r.completedAt).toList();
    });
    final weekStats = computeWeekCompletionStats(completedAts, now);
    final weeklyLineText = switch (weekDeltaKind(weekStats)) {
      WeekDeltaKind.zero => strings.bannerStatsZeroState,
      WeekDeltaKind.firstWeek => strings.bannerStatsFirstWeek(
        weekStats.thisWeekCount,
      ),
      WeekDeltaKind.more => strings.bannerStatsMore(
        weekStats.thisWeekCount,
        weekStats.thisWeekCount - weekStats.lastWeekCount,
      ),
      WeekDeltaKind.fewer => strings.bannerStatsFewer(
        weekStats.thisWeekCount,
        weekStats.lastWeekCount - weekStats.thisWeekCount,
      ),
      WeekDeltaKind.same => strings.bannerStatsSame(weekStats.thisWeekCount),
    };

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.appTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                color: colorScheme.onPrimaryContainer,
                tooltip: strings.settingsGearTooltip,
                onPressed: () => context.push('/settings'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  key: const Key('stat_chip_overdue'),
                  dotColor: colorScheme.error,
                  label: strings.statOverdueLabel,
                  count: overdueCount,
                  onTap: () => onStatTap(DueSection.overdue),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(
                  key: const Key('stat_chip_today'),
                  dotColor: warmAccentColor(colorScheme),
                  label: strings.statDueTodayLabel,
                  count: todayCount,
                  onTap: () => onStatTap(DueSection.today),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(
                  key: const Key('stat_chip_upcoming'),
                  dotColor: colorScheme.outline,
                  label: strings.statUpcomingLabel,
                  count: upcomingCount,
                  onTap: () => onStatTap(DueSection.upcoming),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('banner_weekly_line'),
              borderRadius: BorderRadius.circular(8),
              onTap: () => context.push('/stats'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        weeklyLineText,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: colorScheme.onPrimaryContainer.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final Color dotColor;
  final String label;
  final int count;
  final VoidCallback onTap;

  const _StatChip({
    super.key,
    required this.dotColor,
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = count > 0;

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Material(
        // A pill on `surface` so the chips pop off the primaryContainer
        // banner behind them -- a real color swap, not an adjacent tonal
        // step (see the luminance tripwire in theme_test.dart).
        color: colorScheme.surface,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
