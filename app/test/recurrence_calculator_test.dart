import 'package:chorebuddy/core/database/tables.dart';
import 'package:chorebuddy/features/chores/domain/recurrence_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calculateNextDueDate', () {
    test('none clears the due date regardless of a prior due date', () {
      final result = calculateNextDueDate(
        recurrence: RecurrenceType.none,
        completedAt: DateTime(2026, 8, 10, 9, 30),
        previousDueDate: DateTime(2026, 8, 9, 14, 0),
      );
      expect(result, isNull);
    });

    test('none clears the due date when there was none to begin with', () {
      final result = calculateNextDueDate(
        recurrence: RecurrenceType.none,
        completedAt: DateTime(2026, 8, 10, 9, 30),
        previousDueDate: null,
      );
      expect(result, isNull);
    });

    test('daily adds 1 day from the completion date, preserving prior due time-of-day', () {
      final result = calculateNextDueDate(
        recurrence: RecurrenceType.daily,
        completedAt: DateTime(2026, 8, 10, 9, 30),
        previousDueDate: DateTime(2026, 8, 9, 14, 0),
      );
      expect(result, equals(DateTime(2026, 8, 11, 14, 0)));
    });

    test('everyOtherDay adds 2 days from the completion date', () {
      final result = calculateNextDueDate(
        recurrence: RecurrenceType.everyOtherDay,
        completedAt: DateTime(2026, 8, 10, 9, 30),
        previousDueDate: DateTime(2026, 8, 9, 14, 0),
      );
      expect(result, equals(DateTime(2026, 8, 12, 14, 0)));
    });

    test('weekly adds 7 days from the completion date', () {
      final result = calculateNextDueDate(
        recurrence: RecurrenceType.weekly,
        completedAt: DateTime(2026, 8, 10, 9, 30),
        previousDueDate: DateTime(2026, 8, 9, 14, 0),
      );
      expect(result, equals(DateTime(2026, 8, 17, 14, 0)));
    });

    test('monthly adds 1 calendar month from the completion date', () {
      final result = calculateNextDueDate(
        recurrence: RecurrenceType.monthly,
        completedAt: DateTime(2026, 8, 10, 9, 30),
        previousDueDate: DateTime(2026, 7, 5, 14, 0),
      );
      expect(result, equals(DateTime(2026, 9, 10, 14, 0)));
    });

    test('monthly clamps to the last day of the target month (Jan 31 completion -> Feb 28)', () {
      final result = calculateNextDueDate(
        recurrence: RecurrenceType.monthly,
        completedAt: DateTime(2026, 1, 31, 8, 0),
        previousDueDate: DateTime(2025, 12, 31, 8, 0),
      );
      expect(result, equals(DateTime(2026, 2, 28, 8, 0)));
    });

    test('monthly clamps into a leap-year February (Jan 31 2024 completion -> Feb 29)', () {
      final result = calculateNextDueDate(
        recurrence: RecurrenceType.monthly,
        completedAt: DateTime(2024, 1, 31, 8, 0),
        previousDueDate: null,
      );
      expect(result, equals(DateTime(2024, 2, 29, 8, 0)));
    });

    test('monthly rolls across a year boundary (Dec completion -> Jan)', () {
      final result = calculateNextDueDate(
        recurrence: RecurrenceType.monthly,
        completedAt: DateTime(2026, 12, 15, 8, 0),
        previousDueDate: DateTime(2026, 11, 15, 8, 0),
      );
      expect(result, equals(DateTime(2027, 1, 15, 8, 0)));
    });

    test('falls back to completion time-of-day when there was no prior due date', () {
      final result = calculateNextDueDate(
        recurrence: RecurrenceType.daily,
        completedAt: DateTime(2026, 8, 10, 9, 30),
        previousDueDate: null,
      );
      expect(result, equals(DateTime(2026, 8, 11, 9, 30)));
    });

    test('preserves UTC-ness of the completion date', () {
      final result = calculateNextDueDate(
        recurrence: RecurrenceType.weekly,
        completedAt: DateTime.utc(2026, 8, 10, 9, 30),
        previousDueDate: DateTime.utc(2026, 8, 9, 14, 0),
      );
      expect(result!.isUtc, isTrue);
      expect(result, equals(DateTime.utc(2026, 8, 17, 14, 0)));
    });

    test('advances by calendar days across a DST fall-back transition', () {
      // 2026-11-01 is the US fall-back date (25-hour day). Duration-based
      // addition (+24h) lands on Nov 1 23:00 in a US zone — the same
      // calendar day — instead of Nov 2. Calendar arithmetic must be
      // host-timezone independent: assert exact .day components so this
      // fails in a DST zone if elapsed-time addition ever comes back.
      final daily = calculateNextDueDate(
        recurrence: RecurrenceType.daily,
        completedAt: DateTime(2026, 11, 1, 10, 0),
        previousDueDate: DateTime(2026, 10, 31, 8, 0),
      )!;
      expect(daily.year, 2026);
      expect(daily.month, 11);
      expect(daily.day, 2);
      expect(daily.hour, 8);

      final weekly = calculateNextDueDate(
        recurrence: RecurrenceType.weekly,
        completedAt: DateTime(2026, 10, 28, 10, 0),
        previousDueDate: DateTime(2026, 10, 28, 8, 0),
      )!;
      expect(weekly.month, 11);
      expect(weekly.day, 4);
      expect(weekly.hour, 8);
    });
  });

  group('calculateSnoozeDueDate', () {
    test('moves to tomorrow relative to now, preserving the due time-of-day',
        () {
      final result = calculateSnoozeDueDate(
        now: DateTime(2026, 8, 10, 9, 0),
        previousDueDate: DateTime(2026, 8, 9, 14, 30),
      );
      expect(result, equals(DateTime(2026, 8, 11, 14, 30)));
    });

    test('ignores an overdue due date\'s stale calendar day -- always tomorrow relative to now',
        () {
      // The chore was due 5 days ago (overdue); snoozing must land on
      // tomorrow from *now*, not tomorrow from the stale due date.
      final result = calculateSnoozeDueDate(
        now: DateTime(2026, 8, 10, 9, 0),
        previousDueDate: DateTime(2026, 8, 5, 14, 30),
      );
      expect(result, equals(DateTime(2026, 8, 11, 14, 30)));
    });

    test('advances by a calendar day across a DST fall-back transition', () {
      // See the DST comment on calculateNextDueDate's test above: Duration-
      // based +24h would land on the same US calendar day (Nov 1) during
      // the fall-back's 25-hour day instead of Nov 2.
      final result = calculateSnoozeDueDate(
        now: DateTime(2026, 11, 1, 10, 0),
        previousDueDate: DateTime(2026, 10, 31, 8, 0),
      );
      expect(result.year, 2026);
      expect(result.month, 11);
      expect(result.day, 2);
      expect(result.hour, 8);
    });
  });
}
