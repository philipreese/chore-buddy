import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../../core/date/calendar_days.dart';

/// Monday 00:00 local for the week containing [date] (spec 22: "Week" runs
/// Monday 00:00 local to the next Monday). Calendar-day arithmetic, not
/// `Duration`, so this stays correct even in locales/times where the
/// transition back to Monday crosses a DST boundary.
DateTime startOfWeek(DateTime date) {
  final dayOnly = DateTime(date.year, date.month, date.day);
  final daysSinceMonday = (dayOnly.weekday - DateTime.monday) % 7;
  return addCalendarDays(dayOnly, -daysSinceMonday);
}

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

/// Per-chore expected period, in days, for [recurrence]/[recurrenceInterval].
/// Null means the chore has no expected cadence (none, or a customDays row
/// with no usable interval) -- callers fall back to a total-count display
/// instead of a streak.
int? expectedPeriodDays(RecurrenceType recurrence, int? recurrenceInterval) {
  switch (recurrence) {
    case RecurrenceType.none:
      return null;
    case RecurrenceType.daily:
      return 1;
    case RecurrenceType.everyOtherDay:
      return 2;
    case RecurrenceType.weekly:
      return 7;
    case RecurrenceType.monthly:
      return 30;
    case RecurrenceType.customDays:
      return (recurrenceInterval != null && recurrenceInterval >= 1)
          ? recurrenceInterval
          : null;
  }
}

/// Number of [completedAts] falling within the 7-day window starting at
/// [weekStart] (inclusive of the start, exclusive of the following week).
int countCompletionsInWeek(List<DateTime> completedAts, DateTime weekStart) {
  final weekEnd = addCalendarDays(weekStart, 7);
  return completedAts
      .where((c) => !c.isBefore(weekStart) && c.isBefore(weekEnd))
      .length;
}

class WeekCompletionStats {
  final int thisWeekCount;
  final int lastWeekCount;
  final bool hasAnyCompletions;
  final bool hasHistoryBeforeThisWeek;

  const WeekCompletionStats({
    required this.thisWeekCount,
    required this.lastWeekCount,
    required this.hasAnyCompletions,
    required this.hasHistoryBeforeThisWeek,
  });
}

/// This-week/last-week completion counts, plus enough context to pick the
/// right banner wording (see [weekDeltaKind]) -- in particular,
/// [hasHistoryBeforeThisWeek] distinguishes "nothing happened last week"
/// from "there's no prior week to compare against yet".
WeekCompletionStats computeWeekCompletionStats(
  List<DateTime> completedAts,
  DateTime now,
) {
  final thisWeekStart = startOfWeek(now);
  final lastWeekStart = addCalendarDays(thisWeekStart, -7);

  return WeekCompletionStats(
    thisWeekCount: countCompletionsInWeek(completedAts, thisWeekStart),
    lastWeekCount: countCompletionsInWeek(completedAts, lastWeekStart),
    hasAnyCompletions: completedAts.isNotEmpty,
    hasHistoryBeforeThisWeek: completedAts.any(
      (c) => c.isBefore(thisWeekStart),
    ),
  );
}

enum WeekDeltaKind { zero, firstWeek, more, fewer, same }

/// Which banner-line variant [stats] calls for. [WeekDeltaKind.zero] is the
/// no-completions-ever zero state; [WeekDeltaKind.firstWeek] is "there's
/// nothing before this week to compare against" (distinct from a genuine
/// zero last week, which still compares normally).
WeekDeltaKind weekDeltaKind(WeekCompletionStats stats) {
  if (!stats.hasAnyCompletions) return WeekDeltaKind.zero;
  if (!stats.hasHistoryBeforeThisWeek) return WeekDeltaKind.firstWeek;
  if (stats.thisWeekCount > stats.lastWeekCount) return WeekDeltaKind.more;
  if (stats.thisWeekCount < stats.lastWeekCount) return WeekDeltaKind.fewer;
  return WeekDeltaKind.same;
}

/// Per-chore streak: walks [completedAts] (any order) from newest to
/// oldest, counting how many consecutive completions have a calendar-day
/// gap of at most [expectedPeriod] + 1 grace day. A single completion is
/// always a streak of 1. Chores with no expected period ([expectedPeriod]
/// null) have no streak -- returns 0, and callers should show the total
/// completion count instead.
int computeStreak(List<DateTime> completedAts, int? expectedPeriod) {
  if (completedAts.isEmpty || expectedPeriod == null) return 0;

  final sorted = [...completedAts]..sort((a, b) => b.compareTo(a));
  final maxGap = expectedPeriod + 1;
  var streak = 1;
  for (var i = 0; i < sorted.length - 1; i++) {
    final gap = calendarDayDifference(sorted[i], sorted[i + 1]);
    if (gap <= maxGap) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
}

/// Median gap, in days, between consecutive completions in [completedAts].
/// Null when there are fewer than 3 completions (spec 22's cadence
/// definition requires at least that many).
double? medianCadenceDays(List<DateTime> completedAts) {
  if (completedAts.length < 3) return null;

  final sorted = [...completedAts]..sort();
  final gaps = [
    for (var i = 1; i < sorted.length; i++)
      calendarDayDifference(sorted[i], sorted[i - 1]),
  ]..sort();

  final mid = gaps.length ~/ 2;
  return gaps.length.isOdd
      ? gaps[mid].toDouble()
      : (gaps[mid - 1] + gaps[mid]) / 2.0;
}

enum CadenceSchedule { onSchedule, behind }

/// Whether [medianDays] is on-schedule for [expectedPeriod] (median <=
/// period + 1 grace day) or running behind. Null when the chore has no
/// expected period -- the cadence line then omits the schedule verdict.
CadenceSchedule? cadenceScheduleFor(double medianDays, int? expectedPeriod) {
  if (expectedPeriod == null) return null;
  return medianDays <= expectedPeriod + 1
      ? CadenceSchedule.onSchedule
      : CadenceSchedule.behind;
}

enum HeatmapLevel { none, low, medium, high }

/// Buckets a single day's completion [count] into a heatmap intensity
/// level: 0 / 1 / 2 / 3+.
HeatmapLevel heatmapLevelForCount(int count) {
  if (count <= 0) return HeatmapLevel.none;
  if (count == 1) return HeatmapLevel.low;
  if (count == 2) return HeatmapLevel.medium;
  return HeatmapLevel.high;
}

/// The four heatmap fill colors for [colorScheme], ordered
/// none -> low -> medium -> high (see [HeatmapLevel]): blends of `primary`
/// at ~30%/~60%/100% over `surfaceContainerHigh`.
List<Color> heatmapLevelColors(ColorScheme colorScheme) {
  final base = colorScheme.surfaceContainerHigh;
  return [
    base,
    Color.alphaBlend(colorScheme.primary.withAlpha(77), base),
    Color.alphaBlend(colorScheme.primary.withAlpha(153), base),
    colorScheme.primary,
  ];
}

Color heatmapColorForLevel(ColorScheme colorScheme, HeatmapLevel level) =>
    heatmapLevelColors(colorScheme)[level.index];

/// Weekly completion counts for the [weeks] most recent weeks (including
/// the current one), oldest first.
List<int> weeklyCompletionCounts(
  List<DateTime> completedAts,
  DateTime now,
  int weeks,
) {
  final currentWeekStart = startOfWeek(now);
  return [
    for (var i = weeks - 1; i >= 0; i--)
      countCompletionsInWeek(
        completedAts,
        addCalendarDays(currentWeekStart, -7 * i),
      ),
  ];
}

class HeatmapCell {
  /// Null for a blank cell padding out the grid to a full week (a day
  /// outside the current month).
  final DateTime? day;
  final int count;

  const HeatmapCell({this.day, this.count = 0});
}

/// A calendar-month grid of [HeatmapCell]s for the month containing
/// [monthAnchor]: 7 columns (Monday-first) by however many week-rows the
/// month spans, padded with blank cells so every row has exactly 7 entries.
List<List<HeatmapCell>> buildMonthHeatmap(
  List<DateTime> completedAts,
  DateTime monthAnchor,
) {
  final year = monthAnchor.year;
  final month = monthAnchor.month;
  final firstOfMonth = DateTime(year, month, 1);
  final daysInMonth = DateTime(year, month + 1, 0).day;

  final countsByDay = <DateTime, int>{};
  for (final c in completedAts) {
    final day = _dateOnly(c);
    if (day.year == year && day.month == month) {
      countsByDay[day] = (countsByDay[day] ?? 0) + 1;
    }
  }

  final leadingBlanks = (firstOfMonth.weekday - DateTime.monday) % 7;
  final cells = <HeatmapCell>[
    for (var i = 0; i < leadingBlanks; i++) const HeatmapCell(),
    for (var d = 1; d <= daysInMonth; d++)
      HeatmapCell(
        day: DateTime(year, month, d),
        count: countsByDay[DateTime(year, month, d)] ?? 0,
      ),
  ];
  while (cells.length % 7 != 0) {
    cells.add(const HeatmapCell());
  }

  return [for (var i = 0; i < cells.length; i += 7) cells.sublist(i, i + 7)];
}

class ChoreStreakInfo {
  final int choreId;
  final String choreName;
  final int streak;

  const ChoreStreakInfo({
    required this.choreId,
    required this.choreName,
    required this.streak,
  });
}

/// The highest current streak (>= 2) across [chores], or null when none
/// qualifies. [completionsByChoreId] maps each chore's id to its completion
/// timestamps. A streak only counts as *current* -- as opposed to a
/// long-abandoned chore's historical best -- when its newest completion is
/// within [expectedPeriod] + grace day of [now]; otherwise it's excluded
/// entirely rather than presented as the household's current best.
ChoreStreakInfo? bestStreakAcrossChores(
  List<ChoreEntity> chores,
  Map<int, List<DateTime>> completionsByChoreId, {
  DateTime? now,
}) {
  final effectiveNow = now ?? DateTime.now();
  ChoreStreakInfo? best;
  for (final chore in chores) {
    final period = expectedPeriodDays(
      chore.recurrence,
      chore.recurrenceInterval,
    );
    if (period == null) continue;
    final completions = completionsByChoreId[chore.id] ?? const [];
    if (completions.isEmpty) continue;
    final newest = completions.reduce((a, b) => a.isAfter(b) ? a : b);
    if (calendarDayDifference(effectiveNow, newest) > period + 1) continue;

    final streak = computeStreak(completions, period);
    if (streak >= 2 && (best == null || streak > best.streak)) {
      best = ChoreStreakInfo(
        choreId: chore.id,
        choreName: chore.name,
        streak: streak,
      );
    }
  }
  return best;
}
