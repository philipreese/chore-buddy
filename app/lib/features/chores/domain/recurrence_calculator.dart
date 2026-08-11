import '../../../core/database/tables.dart';
import '../../../core/date/calendar_days.dart';

/// Computes the next due date for a chore after a completion, mirroring
/// MainViewModel.cs:282-299 in the MAUI reference: the interval is added to
/// the completion date, and the existing due date's time-of-day is
/// preserved (falling back to the completion time-of-day when there was no
/// prior due date). RecurrenceType.none clears the due date entirely.
DateTime? calculateNextDueDate({
  required RecurrenceType recurrence,
  required DateTime completedAt,
  DateTime? previousDueDate,
  int? recurrenceInterval,
}) {
  if (recurrence == RecurrenceType.none) {
    return null;
  }

  final timeSource = previousDueDate ?? completedAt;
  final completedDate = _dateOnly(completedAt);

  switch (recurrence) {
    case RecurrenceType.none:
      return null;
    case RecurrenceType.daily:
      return _combine(addCalendarDays(completedDate, 1), timeSource);
    case RecurrenceType.everyOtherDay:
      return _combine(addCalendarDays(completedDate, 2), timeSource);
    case RecurrenceType.weekly:
      return _combine(addCalendarDays(completedDate, 7), timeSource);
    case RecurrenceType.monthly:
      return _combine(_addOneMonthClamped(completedDate), timeSource);
    case RecurrenceType.customDays:
      // The UI only ever offers 1-365, but a corrupt/hand-edited row could
      // carry anything -- treat an unusable interval as if it were none.
      if (recurrenceInterval == null || recurrenceInterval < 1) {
        return null;
      }
      return _combine(addCalendarDays(completedDate, recurrenceInterval), timeSource);
  }
}

/// Computes the due date for a snooze: [targetDate] if given (its
/// calendar day only -- any time-of-day component is discarded), otherwise
/// tomorrow relative to [now] (calendar-day addition, not a stale due date
/// that may be days in the past for an overdue chore). Either way the
/// result preserves [previousDueDate]'s time-of-day. Reuses [addCalendarDays] for
/// the same DST-safe calendar arithmetic as [calculateNextDueDate] -- see
/// its comment.
DateTime calculateSnoozeDueDate({
  required DateTime now,
  required DateTime previousDueDate,
  DateTime? targetDate,
}) {
  final day = targetDate != null
      ? _dateOnly(targetDate)
      : addCalendarDays(_dateOnly(now), 1);
  return _combine(day, previousDueDate);
}

DateTime _dateOnly(DateTime dt) {
  return dt.isUtc
      ? DateTime.utc(dt.year, dt.month, dt.day)
      : DateTime(dt.year, dt.month, dt.day);
}

DateTime _combine(DateTime date, DateTime timeSource) {
  return date.isUtc
      ? DateTime.utc(
          date.year,
          date.month,
          date.day,
          timeSource.hour,
          timeSource.minute,
          timeSource.second,
          timeSource.millisecond,
          timeSource.microsecond,
        )
      : DateTime(
          date.year,
          date.month,
          date.day,
          timeSource.hour,
          timeSource.minute,
          timeSource.second,
          timeSource.millisecond,
          timeSource.microsecond,
        );
}

/// Mirrors C#'s DateTime.AddMonths(1): clamps to the last day of the target
/// month when the source day doesn't exist there (e.g. Jan 31 -> Feb 28).
DateTime _addOneMonthClamped(DateTime date) {
  var year = date.year;
  var month = date.month + 1;
  if (month > 12) {
    month = 1;
    year += 1;
  }

  final daysInTargetMonth =
      (date.isUtc
              ? DateTime.utc(year, month + 1, 0)
              : DateTime(year, month + 1, 0))
          .day;
  final day = date.day > daysInTargetMonth ? daysInTargetMonth : date.day;

  return date.isUtc
      ? DateTime.utc(year, month, day)
      : DateTime(year, month, day);
}
