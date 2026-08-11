import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import 'recurrence_calculator.dart';

/// Domain-layer mutation for "Not Today": defers a chore's due date to
/// tomorrow without writing a CompletionRecord or touching recurrence. No
/// undo token -- unlike completing a chore, this is cheap enough to just
/// re-edit.
class SnoozeService {
  final AppDatabase db;

  const SnoozeService(this.db);

  /// Re-reads [choreId] rather than trusting a caller-supplied snapshot
  /// (mirroring CompletionService.completeChore, which does the same for
  /// the same reason -- the caller's snapshot may predate a concurrent
  /// write) and sets its due date to [targetDate] (defaulting to tomorrow
  /// when omitted -- the no-UI notification snooze action keeps that
  /// default), preserving the existing time-of-day. Returns false without
  /// writing anything if the chore is missing or has no due date to snooze
  /// from.
  ///
  /// The read and write are wrapped in a single transaction, again
  /// mirroring [CompletionService.completeChore]: without it, the
  /// notification isolate's snooze can race an in-app completion --
  /// snooze reads the pre-completion due date, the completion commits its
  /// recurrence advance, and the snooze's write (derived from its now-stale
  /// read) clobbers that advance.
  Future<bool> snoozeChore({
    required int choreId,
    DateTime? now,
    DateTime? targetDate,
  }) async {
    final effectiveNow = now ?? DateTime.now();
    return db.transaction(() async {
      final current = await (db.select(db.chores)
            ..where((c) => c.id.equals(choreId)))
          .getSingleOrNull();
      final previousDueDate = current?.nextDueDate;
      if (current == null || previousDueDate == null) return false;

      final snoozedDate = calculateSnoozeDueDate(
        now: effectiveNow,
        previousDueDate: previousDueDate,
        targetDate: targetDate,
      );

      await (db.update(db.chores)..where((c) => c.id.equals(choreId)))
          .write(ChoresCompanion(nextDueDate: Value(snoozedDate)));
      return true;
    });
  }
}
