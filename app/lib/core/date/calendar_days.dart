/// Calendar-day addition. `Duration`-based `add`/`subtract` on a local
/// `DateTime` adds elapsed time, which lands on the wrong calendar day
/// across a DST transition (a 25-hour fall-back day, or a 23-hour
/// spring-forward day); constructing with an overflowed/underflowed day
/// component matches calendar arithmetic instead. [days] may be negative.
/// Shared by `recurrence_calculator.dart` and `stats_calculator.dart` so
/// every week-boundary and due-date computation in the app uses the same
/// DST-safe arithmetic.
DateTime addCalendarDays(DateTime date, int days) {
  return date.isUtc
      ? DateTime.utc(date.year, date.month, date.day + days)
      : DateTime(date.year, date.month, date.day + days);
}

/// Calendar-day count between [a] and [b] (`a - b`), immune to the
/// elapsed-hours-divided-by-24 truncation `DateTime.difference(...).inDays`
/// exhibits across a DST transition: both sides are normalized to UTC
/// midnight of their own calendar day before subtracting, so the local UTC
/// offset cancels out instead of shaving an hour off a 23-hour day.
int calendarDayDifference(DateTime a, DateTime b) {
  final utcA = DateTime.utc(a.year, a.month, a.day);
  final utcB = DateTime.utc(b.year, b.month, b.day);
  return utcA.difference(utcB).inDays;
}
