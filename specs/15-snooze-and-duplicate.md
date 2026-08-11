# Spec 15 — Snooze chore + duplicate chore (issue #22)

## Role

Implement. Report to `$AER_OUTPUT_DIR/changes.md`. ONE-SHOT: complete synchronously; write changes.md before finishing. Do NOT background long-running commands (`flutter test`, builds) — run them to completion in the foreground.

## Environment (stripped — set before builds)

- `ANDROID_HOME=C:\Android\sdk`, `ANDROID_NDK_HOME=C:\Android\sdk\ndk\28.2.13676358`, `JAVA_HOME=C:\Program Files\Android\openjdk\jdk-21.0.8`
- Flutter `C:\src\flutter\bin\flutter.bat`, Dart `C:\src\flutter\bin\dart.bat`

## Context

Existing building blocks: `ChoreCard` (complete button + gestures), `chore_detail_screen.dart` (form), `notification_service.dart` (gates; cancel/replace by chore id), `background_completion.dart` (notification action → background isolate pattern, `AndroidNotificationAction` with `showsUserInterface: false`), `WidgetSyncService` (call beside every notification reschedule).

NOTE: you may be working in a git WORKTREE in parallel with other slices — touch only `app/`; new strings at the END of the strings files; keep the diff tight.

## Scope (all inside `app/`) — no new packages

### A. Snooze ("Not Today")

1. **Semantics**: snoozing sets `nextDueDate` to tomorrow at the chore's existing time-of-day (from the current due date; if the chore has no due date, snooze is unavailable). No CompletionRecord is written. Recurrence is untouched. Implement as a pure function beside `calculateNextDueDate` (calendar-day addition — reuse `_addDays`-style overflow construction, NOT `Duration`, see the DST comment there) + a small domain service method that updates the row, reschedules the notification from the fresh row, and syncs the widget.
2. **Card surface**: a snooze affordance on `ChoreCard` (an icon button or menu entry consistent with the card's current design). Only visible/enabled when the chore has a due date.
3. **Notification action**: a second `AndroidNotificationAction` ("Not Today") beside Complete. Background path mirrors `completeChoreFromNotification` — own connection, snooze core, cancel shown notification, reschedule from fresh row, widget sync. Reuse the same actionId-routing plumbing in the background/foreground response handlers.
4. **Undo is NOT required** for snooze (it's cheap to re-edit); do not build one.

### B. Duplicate chore

5. On the chore detail screen of an EXISTING chore, a "Duplicate" action that opens the new-chore form pre-filled with: name + a suffix that avoids the UNIQUE name constraint (e.g. "Water Plants II" — if that name exists too, increment), same recurrence, tags, notification flag; due date left empty. Nothing is written until the user saves the form (normal save path handles notifications/widget).

### C. Strings & tests

6. Flavored copy via AppStrings for the snooze/duplicate labels and any confirmations (END of files).
7. Tests: snooze date math (incl. a DST-crossing date and the no-due-date guard) as plain `test()`; snooze-from-card widget test (due date moves, no record inserted, reschedule + widget sync called on fakes); duplicate flow widget test (form pre-filled, unique-name suffix works, saving creates the new chore with tags). Follow existing harness patterns — providers overridden with the fakes in `test/fakes/`.

## Done criteria

- `flutter analyze` clean; `flutter test` fully green; `flutter build apk --debug` succeeds; changes.md lists files and deviations.
