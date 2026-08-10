# Spec 05 — Chore completion, undo snackbar, haptics

## Role

Implement. Report to `$AER_OUTPUT_DIR/changes.md`.

## Environment (stripped — set before builds)

- `ANDROID_HOME=C:\Android\sdk`, `ANDROID_NDK_HOME=C:\Android\sdk\ndk\28.2.13676358`, `JAVA_HOME=C:\Program Files\Android\openjdk\jdk-21.0.8`
- Flutter `C:\src\flutter\bin\flutter.bat`, Dart `C:\src\flutter\bin\dart.bat`

## Context (read first)

- `docs/behavior-inventory.md` §"Chore list" completion rows + `CONTEXT.md` (Recurrence, Undo Window terms).
- MAUI reference: `ChoreBuddy/ViewModels/MainViewModel.cs:266-322` (CompleteChore — the exact behavior contract), `ChoreBuddy/Views/CompletionPopup.xaml` (fields + copy).
- Existing: slice 02 DAOs (`insertCompletionRecord`, chore update), slice 04 card/providers. `app/` layout conventions.

## Scope (all inside `app/`)

1. **Complete button on the chore card** (trailing check affordance, as MAUI had).
2. **Completion dialog** (M3 dialog, flavored "Mission Report" copy): date picker + time picker defaulting to now, optional note field, confirm/cancel. Returns the completion data; cancel completes nothing.
3. **Completion service** (domain layer, not widgets):
   - Insert the CompletionRecord.
   - Advance `nextDueDate` per recurrence from the COMPLETION date (not the old due date), preserving the existing due date's time-of-day exactly as `MainViewModel.cs:282-299` does (None CLEARS the due date — `MainViewModel.cs:296-298` sets it null; the earlier revision of this spec stated the opposite and was wrong). EveryOtherDay = +2 days, Weekly = +7, Monthly = +1 calendar month (clamp end-of-month like DateTime.AddMonths).
   - Return an undo token capturing prior state (record id, previous nextDueDate).
4. **Undo snackbar**: 5-second flavored snackbar with UNDO; undo deletes the record and restores the previous nextDueDate. New completion while one is pending commits the prior one (no stacking bugs).
5. **Haptics**: 175ms vibration on completion via a `hapticsEnabledProvider` (default true; persistence in slice 09). Use HapticFeedback/Vibration through a thin service so tests can fake it.
6. Notification rescheduling: leave a clearly-marked TODO hook (slice 08). No notification code.
7. All copy via AppStrings (superhero flavor from MAUI CompletionPopup/MainViewModel strings).

## Tests

- Recurrence calculator unit tests: every RecurrenceType; time-of-day preserved; month-end clamping (Jan 31 + monthly); None behavior matching MAUI.
- Completion service: record inserted, due date advanced, undo restores record-free state AND prior due date.
- Widget: complete → dialog → confirm inserts and shows snackbar; cancel does nothing; UNDO within window reverts (list reflects it); haptic service called once on completion (faked).

## Done criteria

- `flutter analyze` clean; `flutter test` fully green (existing 47 + new); output in changes.md.
- `$AER_OUTPUT_DIR/changes.md` lists files and deviations.

## Do NOT

- Touch anything outside `app/`; no notification scheduling; no settings persistence; no new packages unless haptics genuinely requires one (prefer Flutter's built-in HapticFeedback).
