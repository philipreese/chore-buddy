import 'package:chorebuddy/core/database/app_database.dart';
import 'package:chorebuddy/core/database/tables.dart';
import 'package:chorebuddy/features/chores/domain/stats_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ChoreEntity _chore(
  int id,
  String name,
  RecurrenceType recurrence, {
  int? interval,
}) {
  return ChoreEntity(
    id: id,
    name: name,
    isActive: true,
    nextDueDate: null,
    recurrence: recurrence,
    recurrenceInterval: interval,
    isNotificationEnabled: true,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('startOfWeek', () {
    test('Monday itself returns midnight of that same day', () {
      final monday = DateTime(2026, 8, 10, 15, 30); // Monday
      expect(startOfWeek(monday), equals(DateTime(2026, 8, 10)));
    });

    test('Sunday rolls back to the preceding Monday', () {
      final sunday = DateTime(2026, 8, 16, 23, 59); // Sunday
      expect(startOfWeek(sunday), equals(DateTime(2026, 8, 10)));
    });

    test("a midweek day rolls back to that week's Monday", () {
      final tuesday = DateTime(2026, 8, 11, 1, 0); // Tuesday
      expect(startOfWeek(tuesday), equals(DateTime(2026, 8, 10)));
    });
  });

  group('expectedPeriodDays', () {
    test('maps fixed recurrences to their day counts', () {
      expect(expectedPeriodDays(RecurrenceType.daily, null), equals(1));
      expect(
        expectedPeriodDays(RecurrenceType.everyOtherDay, null),
        equals(2),
      );
      expect(expectedPeriodDays(RecurrenceType.weekly, null), equals(7));
      expect(expectedPeriodDays(RecurrenceType.monthly, null), equals(30));
    });

    test('customDays uses the recurrence interval', () {
      expect(
        expectedPeriodDays(RecurrenceType.customDays, 12),
        equals(12),
      );
    });

    test('none has no expected period', () {
      expect(expectedPeriodDays(RecurrenceType.none, null), isNull);
    });

    test('customDays with a null/invalid interval has no expected period', () {
      expect(expectedPeriodDays(RecurrenceType.customDays, null), isNull);
      expect(expectedPeriodDays(RecurrenceType.customDays, 0), isNull);
    });
  });

  group('computeWeekCompletionStats / weekDeltaKind', () {
    final now = DateTime(2026, 8, 12, 9, 0); // Wednesday, week of Aug 10

    test('zero completions ever -> WeekDeltaKind.zero', () {
      final stats = computeWeekCompletionStats([], now);
      expect(stats.thisWeekCount, equals(0));
      expect(stats.hasAnyCompletions, isFalse);
      expect(weekDeltaKind(stats), equals(WeekDeltaKind.zero));
    });

    test('completions only within the current week -> firstWeek', () {
      final stats = computeWeekCompletionStats(
        [DateTime(2026, 8, 11), DateTime(2026, 8, 12)],
        now,
      );
      expect(stats.thisWeekCount, equals(2));
      expect(stats.hasHistoryBeforeThisWeek, isFalse);
      expect(weekDeltaKind(stats), equals(WeekDeltaKind.firstWeek));
    });

    test('more completions this week than last -> more', () {
      final stats = computeWeekCompletionStats(
        [
          DateTime(2026, 8, 3), // last week
          DateTime(2026, 8, 11),
          DateTime(2026, 8, 12),
          DateTime(2026, 8, 12),
        ],
        now,
      );
      expect(stats.thisWeekCount, equals(3));
      expect(stats.lastWeekCount, equals(1));
      expect(weekDeltaKind(stats), equals(WeekDeltaKind.more));
    });

    test('fewer completions this week than last -> fewer', () {
      final stats = computeWeekCompletionStats(
        [DateTime(2026, 8, 3), DateTime(2026, 8, 4), DateTime(2026, 8, 11)],
        now,
      );
      expect(weekDeltaKind(stats), equals(WeekDeltaKind.fewer));
    });

    test('same count this week and last -> same', () {
      final stats = computeWeekCompletionStats(
        [DateTime(2026, 8, 3), DateTime(2026, 8, 11)],
        now,
      );
      expect(stats.thisWeekCount, equals(1));
      expect(stats.lastWeekCount, equals(1));
      expect(weekDeltaKind(stats), equals(WeekDeltaKind.same));
    });

    test(
        'Sunday-edge: a completion late Sunday counts in the week that just '
        'ended, not the new one starting the following Monday', () {
      final sundayNow = DateTime(2026, 8, 9, 23, 0); // Sunday
      final stats = computeWeekCompletionStats(
        [DateTime(2026, 8, 9, 22, 0)],
        sundayNow,
      );
      expect(stats.thisWeekCount, equals(1));
    });

    test(
        'Monday-edge: a completion at 00:00 Monday belongs to the new week, '
        'not the previous one', () {
      final mondayNow = DateTime(2026, 8, 10, 0, 30); // Monday
      final stats = computeWeekCompletionStats(
        [DateTime(2026, 8, 10, 0, 0)],
        mondayNow,
      );
      expect(stats.thisWeekCount, equals(1));
      expect(stats.lastWeekCount, equals(0));
    });
  });

  group('computeStreak', () {
    test('no completions -> streak 0', () {
      expect(computeStreak([], 1), equals(0));
    });

    test('no expected period -> no streak even with many completions', () {
      final completions = [
        DateTime(2026, 8, 1),
        DateTime(2026, 8, 2),
        DateTime(2026, 8, 3),
      ];
      expect(computeStreak(completions, null), equals(0));
    });

    test('single completion -> streak of 1', () {
      expect(computeStreak([DateTime(2026, 8, 1)], 7), equals(1));
    });

    test('consecutive daily completions within grace grow the streak', () {
      final completions = [
        DateTime(2026, 8, 1),
        DateTime(2026, 8, 2),
        DateTime(2026, 8, 3),
        DateTime(2026, 8, 4),
      ];
      expect(computeStreak(completions, 1), equals(4));
    });

    test('a gap of exactly period + 1 (the grace day) still counts', () {
      // daily (period 1): a 2-day gap is within the 1-day grace.
      final completions = [DateTime(2026, 8, 1), DateTime(2026, 8, 3)];
      expect(computeStreak(completions, 1), equals(2));
    });

    test('a gap beyond period + 1 breaks the streak', () {
      final completions = [
        DateTime(2026, 8, 1),
        DateTime(2026, 8, 10),
        DateTime(2026, 8, 9),
        DateTime(2026, 8, 8),
      ];
      // Newest-first: 10th, 9th, 8th, 1st. 10->9 gap 1, 9->8 gap 1 (both
      // within daily's 1-day grace), 8->1 gap 7 (breaks it).
      expect(computeStreak(completions, 1), equals(3));
    });

    test('unordered input is sorted internally before walking', () {
      final completions = [
        DateTime(2026, 8, 3),
        DateTime(2026, 8, 1),
        DateTime(2026, 8, 2),
      ];
      expect(computeStreak(completions, 1), equals(3));
    });
  });

  group('medianCadenceDays / cadenceScheduleFor', () {
    test('fewer than 3 completions -> null', () {
      expect(medianCadenceDays([]), isNull);
      expect(medianCadenceDays([DateTime(2026, 8, 1)]), isNull);
      expect(
        medianCadenceDays([DateTime(2026, 8, 1), DateTime(2026, 8, 8)]),
        isNull,
      );
    });

    test('an odd number of gaps returns the middle gap', () {
      final completions = [
        DateTime(2026, 8, 1),
        DateTime(2026, 8, 8),
        DateTime(2026, 8, 15),
        DateTime(2026, 8, 22),
      ];
      expect(medianCadenceDays(completions), equals(7.0));
    });

    test('an even number of gaps averages the two middle gaps', () {
      final completions = [
        DateTime(2026, 8, 1),
        DateTime(2026, 8, 5), // gap 4
        DateTime(2026, 8, 15), // gap 10
      ];
      expect(medianCadenceDays(completions), equals(7.0));
    });

    test('on schedule when median <= period + 1', () {
      expect(cadenceScheduleFor(7.0, 7), equals(CadenceSchedule.onSchedule));
      expect(cadenceScheduleFor(8.0, 7), equals(CadenceSchedule.onSchedule));
    });

    test('running behind when median > period + 1', () {
      expect(cadenceScheduleFor(9.0, 7), equals(CadenceSchedule.behind));
    });

    test('no expected period -> no schedule verdict', () {
      expect(cadenceScheduleFor(9.0, null), isNull);
    });
  });

  group('heatmapLevelForCount', () {
    test('buckets 0 / 1 / 2 / 3+', () {
      expect(heatmapLevelForCount(0), equals(HeatmapLevel.none));
      expect(heatmapLevelForCount(1), equals(HeatmapLevel.low));
      expect(heatmapLevelForCount(2), equals(HeatmapLevel.medium));
      expect(heatmapLevelForCount(3), equals(HeatmapLevel.high));
      expect(heatmapLevelForCount(10), equals(HeatmapLevel.high));
    });
  });

  group('weeklyCompletionCounts', () {
    test('returns oldest-first counts for the requested window', () {
      final now = DateTime(2026, 8, 12); // week of Aug 10
      final completions = [
        DateTime(2026, 7, 20), // weeks ago
        DateTime(2026, 8, 11), // this week
        DateTime(2026, 8, 11),
      ];
      final counts = weeklyCompletionCounts(completions, now, 5);
      expect(counts.length, equals(5));
      expect(counts.last, equals(2)); // this week
    });

    test('empty completions -> all-zero counts, no crash', () {
      final counts = weeklyCompletionCounts([], DateTime(2026, 8, 12), 5);
      expect(counts, equals([0, 0, 0, 0, 0]));
    });
  });

  group('buildMonthHeatmap', () {
    test('every row has 7 cells and days outside the month are blank', () {
      final grid = buildMonthHeatmap([], DateTime(2026, 8, 1));
      for (final week in grid) {
        expect(week.length, equals(7));
      }
      // Aug 1, 2026 is a Saturday -> 5 leading blanks (Mon..Fri).
      expect(grid.first[0].day, isNull);
      expect(grid.first[5].day, equals(DateTime(2026, 8, 1)));
    });

    test('counts completions per day within the month only', () {
      final grid = buildMonthHeatmap(
        [
          DateTime(2026, 8, 5, 9, 0),
          DateTime(2026, 8, 5, 20, 0),
          DateTime(2026, 7, 31), // previous month, excluded
        ],
        DateTime(2026, 8, 1),
      );
      final cell = grid
          .expand((week) => week)
          .firstWhere((c) => c.day == DateTime(2026, 8, 5));
      expect(cell.count, equals(2));
    });

    test('empty completions produce an all-zero grid, no crash', () {
      final grid = buildMonthHeatmap([], DateTime(2026, 8, 1));
      for (final cell in grid.expand((week) => week)) {
        expect(cell.count, equals(0));
      }
    });
  });

  group('bestStreakAcrossChores', () {
    test('returns null when no chore has a streak >= 2', () {
      final chores = [_chore(1, 'Dishes', RecurrenceType.daily)];
      final result = bestStreakAcrossChores(chores, {
        1: [DateTime(2026, 8, 1)],
      });
      expect(result, isNull);
    });

    test('picks the highest-streak chore across chores', () {
      final chores = [
        _chore(1, 'Dishes', RecurrenceType.daily),
        _chore(2, 'Laundry', RecurrenceType.weekly),
      ];
      final result = bestStreakAcrossChores(chores, {
        1: [DateTime(2026, 8, 1), DateTime(2026, 8, 2)],
        2: [
          DateTime(2026, 8, 1),
          DateTime(2026, 8, 8),
          DateTime(2026, 8, 15),
        ],
      });
      expect(result?.choreId, equals(2));
      expect(result?.choreName, equals('Laundry'));
      expect(result?.streak, equals(3));
    });

    test('chores with no expected period never contribute a streak', () {
      final chores = [_chore(1, 'One-off', RecurrenceType.none)];
      final result = bestStreakAcrossChores(chores, {
        1: [DateTime(2026, 8, 1), DateTime(2026, 8, 2), DateTime(2026, 8, 3)],
      });
      expect(result, isNull);
    });
  });

  group('heatmap luminance tripwire (spec 22 item 3)', () {
    test(
        'adjacent heatmap levels clear a real luminance-delta floor in both '
        'light and dark schemes', () {
      for (final brightness in [Brightness.light, Brightness.dark]) {
        final scheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF415F91),
          brightness: brightness,
        );
        final colors = heatmapLevelColors(scheme);
        expect(colors.length, equals(4));
        for (var i = 1; i < colors.length; i++) {
          final delta =
              (colors[i].computeLuminance() - colors[i - 1].computeLuminance())
                  .abs();
          expect(
            delta,
            greaterThanOrEqualTo(0.03),
            reason:
                'heatmap level $i vs ${i - 1} luminance delta in '
                '$brightness was $delta, below the visibility floor',
          );
        }
      }
    });
  });
}
