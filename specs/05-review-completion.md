# Spec 05-review — Adversarial review of completion, undo, haptics

## Role

Review. Read-only. Write `report.md` and `verdict.json` to `$AER_OUTPUT_DIR`. You are one-shot: run everything to completion in this turn, never background work or wait for notifications. Keep `verdict.json` fields flat strings/bools/numbers.

## Subject (committed at HEAD, slice 05)

- `app/lib/features/chores/domain/completion_service.dart`, `recurrence_calculator.dart`
- `app/lib/features/chores/presentation/completion_flow.dart`, `widgets/completion_dialog.dart`
- `app/lib/features/chores/providers/completion_providers.dart`, `app/lib/core/services/haptics_service.dart`
- Tests: `completion_flow_test.dart`, `completion_service_test.dart`, `recurrence_calculator_test.dart`

## Contract (verify adversarially against `ChoreBuddy/ViewModels/MainViewModel.cs:266-322` and specs/05)

1. Recurrence: next due = completion date + interval, preserving the PREVIOUS due date's time-of-day exactly as MAUI does; EveryOtherDay +2d, Weekly +7d, Monthly +1 calendar month with end-of-month clamping; None matches MAUI's behavior precisely (check the MAUI source — does None clear, keep, or skip?).
2. Undo restores BOTH the record (deleted) and the prior nextDueDate; a second completion during the undo window commits the first (its record survives) and undo then only reverts the second. Check UndoToken equality/identity semantics can't cross-revert.
3. Completion writes are transactional; undo writes are transactional; no path leaves a record without the due-date advance or vice versa.
4. Haptics fire exactly once per completion, only when enabled, and never on cancel/undo.
5. Dialog defaults to now, returns null on cancel/barrier dismiss, trims the note.
6. Tests test what they claim (no polling-that-can't-fail, no assertions that pass regardless).
7. All copy via AppStrings.

## Also hunt for

- The `.closed.then` on the snackbar: any path where a stale closure clears a NEWER pending token.
- `chore.chore` staleness: the card's captured ChoreWithDetails vs current db state at completion time — can a stale nextDueDate produce a wrong advance or wrong undo restore?
- DST edges in date math (adding days across DST — DateTime is local).

## Verdict

Fail on any contract breach or data-loss/corruption path. findings with file:line.
