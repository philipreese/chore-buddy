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

  const UndoToken({
    required this.recordId,
    required this.choreId,
    required this.previousNextDueDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UndoToken &&
          runtimeType == other.runtimeType &&
          recordId == other.recordId &&
          choreId == other.choreId &&
          previousNextDueDate == other.previousNextDueDate;

  @override
  int get hashCode => Object.hash(recordId, choreId, previousNextDueDate);
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
    final previousNextDueDate = chore.nextDueDate;
    final nextDueDate = calculateNextDueDate(
      recurrence: chore.recurrence,
      completedAt: completedAt,
      previousDueDate: previousNextDueDate,
    );

    // Both writes touch tables that watchActiveChoresWithDetails() depends
    // on; a transaction ensures its subscribers see a single recompute
    // instead of two overlapping ones.
    final recordId = await db.transaction(() async {
      final recordId = await db.insertCompletionRecord(
        CompletionRecordsCompanion.insert(
          choreId: chore.id,
          completedAt: completedAt,
          note: Value(note),
        ),
      );

      await (db.update(db.chores)..where((c) => c.id.equals(chore.id))).write(
        ChoresCompanion(nextDueDate: Value(nextDueDate)),
      );

      return recordId;
    });

    return UndoToken(
      recordId: recordId,
      choreId: chore.id,
      previousNextDueDate: previousNextDueDate,
    );
  }

  Future<void> undoCompletion(UndoToken token) async {
    await db.transaction(() async {
      await db.deleteCompletionRecord(token.recordId);
      await (db.update(db.chores)..where((c) => c.id.equals(token.choreId)))
          .write(ChoresCompanion(nextDueDate: Value(token.previousNextDueDate)));
    });
  }
}
