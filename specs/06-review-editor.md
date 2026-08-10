# Spec 06-review — Adversarial review of the chore editor and history

## Role

Review. Read-only. Write `report.md` and `verdict.json` to `$AER_OUTPUT_DIR`. You are ONE-SHOT: complete everything synchronously this turn. Keep verdict.json fields flat strings/bools/numbers.

## Subject (committed at HEAD, slice 06)

- `app/lib/features/chores/presentation/chore_detail_screen.dart` (rewritten)
- `app/lib/features/chores/presentation/widgets/completion_dialog.dart` (prefill added)
- `app/lib/core/database/app_database.dart` (getChoreById, getTagIdsForChore added)
- `app/lib/core/strings/*` (new keys)
- `app/test/chore_detail_screen_test.dart` (new)

## Contract (verify adversarially vs `ChoreBuddy/Views/ChoreDetailsPage.xaml`, `ChoreDetailViewModel.cs`, `specs/06-chore-editor-history.md`, ADR-0005)

1. Save semantics: new-chore inserts with chosen tags/due/recurrence/reminder flag; edit updates without touching createdAt/isActive; due-switch off clears due date; tag links written via setChoreTags (transactional). Check the save path can't half-write (chore saved but tags failed).
2. Registry Conflict on BOTH insert and rename; form state fully preserved after the alert; no navigation on failure.
3. History: edit-record persists date AND note; delete confirmed, cancel keeps; empty state only in edit mode with zero records; new mode renders no history section.
4. Keyboard dismissal on save and navigate-away without platform hacks.
5. No QUIRK recreation (prefetch, deferred swaps, measure/opacity, reload messages).
6. Tests test what they claim; DB assertions via one-shot selects; no real-sleep/pumpAndSettle-with-live-ticker hazards (the screen embeds no ticker, but the route sits behind the shell — check).
7. All copy via AppStrings; recurrence display names match MAUI.

## Also hunt for

- The reminder flag: persisted correctly for both modes and defaulting true as MAUI does?
- Editing a record's date: does the chore's derived lastCompleted/lastNote reorder correctly (it's derived, but does the UI reflect it — any cached value)?
- `updateCompletionRecord` misuse: can editing set completedAt such that ordering ties break the latest-record derivation?
- The `/tags` push from the picker: state on return (should be reactive, no reload message).
- Race: saving while the history dialog is open, back-navigation mid-save.

## Verdict

Fail on contract breach or any path that loses/corrupts user input. findings with file:line.
