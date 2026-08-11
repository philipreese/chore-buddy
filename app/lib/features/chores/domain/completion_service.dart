import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import 'recurrence_calculator.dart';

/// Captures the state needed to reverse a completion within the undo
/// window: the inserted record and the chore's due date prior to
/// completion.
class UndoToken {
  final int recordId;
  final int choreId;
  final DateTime? previousNextDueDate;

  /// The due date the completion wrote. Undo only restores
  /// [previousNextDueDate] while the row still holds this value, so a due
  /// date the user edited during the undo window is never clobbered.
  final DateTime? nextDueDateAfterCompletion;

  const UndoToken({
    required this.recordId,
    required this.choreId,
    required this.previousNextDueDate,
    required this.nextDueDateAfterCompletion,
  });

  // Value equality over recordId is safe against reuse only because
  // CompletionRecords.id is AUTOINCREMENT (no rowid reuse after deletes).
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UndoToken &&
          runtimeType == other.runtimeType &&
          recordId == other.recordId &&
          choreId == other.choreId &&
          previousNextDueDate == other.previousNextDueDate &&
          nextDueDateAfterCompletion == other.nextDueDateAfterCompletion;

  @override
  int get hashCode => Object.hash(
      recordId, choreId, previousNextDueDate, nextDueDateAfterCompletion);
}

/// Domain-layer orchestration for completing a chore: inserts the
/// completion record, advances the chore's due date per its recurrence,
/// and supports reverting both via [undoCompletion].
class CompletionService {
  final AppDatabase db;

  const CompletionService(this.db);

  Future<UndoToken> completeChore({
    required ChoreEntity chore,
    required DateTime completedAt,
    String note = '',
  }) async {
    // Both writes touch tables that watchActiveChoresWithDetails() depends
    // on; a transaction ensures its subscribers see a single recompute
    // instead of two overlapping ones. The chore row is re-read inside the
    // transaction: the caller's ChoreEntity is a UI snapshot that may
    // predate a concurrent completion, and the advance must derive from
    // current state.
    return db.transaction(() async {
      final current = await (db.select(db.chores)
            ..where((c) => c.id.equals(chore.id)))
          .getSingle();

      final previousNextDueDate = current.nextDueDate;
      final nextDueDate = calculateNextDueDate(
        recurrence: current.recurrence,
        completedAt: completedAt,
        previousDueDate: previousNextDueDate,
        recurrenceInterval: current.recurrenceInterval,
      );

      final recordId = await db.insertCompletionRecord(
        CompletionRecordsCompanion.insert(
          choreId: current.id,
          completedAt: completedAt,
          note: Value(note),
        ),
      );

      await (db.update(db.chores)..where((c) => c.id.equals(current.id)))
          .write(ChoresCompanion(nextDueDate: Value(nextDueDate)));

      return UndoToken(
        recordId: recordId,
        choreId: current.id,
        previousNextDueDate: previousNextDueDate,
        nextDueDateAfterCompletion: nextDueDate,
      );
    });
  }

  Future<void> undoCompletion(UndoToken token) async {
    await db.transaction(() async {
      await db.deleteCompletionRecord(token.recordId);
      // Restore the prior due date only if the row still holds the value
      // this completion wrote; an edit made during the undo window wins.
      await (db.update(db.chores)
            ..where((c) =>
                c.id.equals(token.choreId) &
                c.nextDueDate.equalsNullable(token.nextDueDateAfterCompletion)))
          .write(ChoresCompanion(nextDueDate: Value(token.previousNextDueDate)));
    });
  }
}
