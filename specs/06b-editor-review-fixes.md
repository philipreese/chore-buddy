# Spec 06b — Apply review fixes to the chore editor

## Role

Implement. Report to `$AER_OUTPUT_DIR/changes.md`. You are ONE-SHOT: run everything to completion synchronously this turn; write changes.md before finishing.

## Environment (stripped — set before builds)

- `ANDROID_HOME=C:\Android\sdk`, `ANDROID_NDK_HOME=C:\Android\sdk\ndk\28.2.13676358`, `JAVA_HOME=C:\Program Files\Android\openjdk\jdk-21.0.8`
- Flutter `C:\src\flutter\bin\flutter.bat`, Dart `C:\src\flutter\bin\dart.bat`

## Context

Read `docs/reviews/06-editor-review.md` first — exact file:line evidence for every item. Apply:

## Required (verdict blockers)

1. **F1 — atomic save + surfaced errors** (`chore_detail_screen.dart:147-191`): wrap the chore insert/update AND `setChoreTags` in one `db.transaction(...)` (add a service/DAO method if cleaner — widgets shouldn't orchestrate transactions). Add a catch-all in `_save` that surfaces unexpected failures via a flavored generic-error alert (AppStrings.genericError exists) instead of letting the exception vanish; form stays open.

## Also required (mediums)

2. **F2**: intersect `_selectedTagIds` with the live `tagsProvider` list in the `data:` branch so deleted tags drop out of the selection.
3. **F3**: edit-mode load failure / missing chore → show the not-found state (route family already has one) instead of a blank form with a dead Save.
4. **F5**: new-chore due date defaults to tomorrow (`DateTime.now() + 1 day`, date component), matching MAUI `ChoreDetailViewModel.cs:73`.
5. **F4 tests**: (a) Mission Reminder flag persisted in both modes; (b) Registry Conflict on the INSERT path; (c) add a comment in the test file noting keyboard dismissal as a known widget-test gap.

## Worth doing (lows)

6. **F7**: `_saving` guard disabling Save while in flight.
7. **F8**: unfocus BEFORE initiating pops (back button/gesture: use `onPopInvokedWithResult` with didPop false? — simplest correct form: unfocus in `deactivate()` and before explicit pops; remove the after-the-fact unfocus).
8. **F9**: override `tickerProvider`/`nowProvider` in `chore_detail_screen_test.dart` like the sibling tests.
9. **F10**: route the router's "Not Found"/"Chore not found" strings through AppStrings.
10. **F6**: change edit-save to a targeted `update(...).write(ChoresCompanion(...))` with only name/nextDueDate/recurrence/isNotificationEnabled, instead of full-row replace.

## Done criteria

- `flutter analyze` clean; `flutter test` fully green (78 existing + new); output in changes.md.
- A new widget test for F1's class: with a selected tag deleted before Save, saving either succeeds with the remaining valid tags or fails atomically with the error alert — no half-written chore (assert via one-shot selects).
- Only files needed for the above change; nothing outside `app/`.
