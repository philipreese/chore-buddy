# Spec 06 — Chore detail/edit screen and history management

## Role

Implement. Report to `$AER_OUTPUT_DIR/changes.md`. You are ONE-SHOT: run everything to completion synchronously in this turn — never background a task, never wait for a notification, and write changes.md before finishing.

## Environment (stripped — set before builds)

- `ANDROID_HOME=C:\Android\sdk`, `ANDROID_NDK_HOME=C:\Android\sdk\ndk\28.2.13676358`, `JAVA_HOME=C:\Program Files\Android\openjdk\jdk-21.0.8`
- Flutter `C:\src\flutter\bin\flutter.bat`, Dart `C:\src\flutter\bin\dart.bat`

## Context (read first)

- `docs/behavior-inventory.md` §"Chore details" — FEATURE/PRESERVE rows are the contract; QUIRK rows must not be recreated; the edit-panel-as-CollectionView-header layout is RETHINK — replaced by a proper form screen per ADR-0005.
- MAUI reference: `ChoreBuddy/Views/ChoreDetailsPage.xaml`, `ChoreBuddy/ViewModels/ChoreDetailViewModel.cs` (behavior + copy), `ChoreBuddy/Views/CompletionPopup.xaml` (reused there for editing history records).
- Existing: slice 02 DAOs, slice 03 tag providers/palette, slice 05 `CompletionDialog` (REUSE it for history-record editing — MAUI reused its popup the same way), flavor strings, `/chores/:id` + `/chores/new` routes with placeholder screen.

## Scope (all inside `app/`) — replace the placeholder `chore_detail_screen.dart`

1. **Edit form** (full-screen route, M3): name field; tag picker (chips from existing tags, multi-select, colored per palette; entry point to /tags to create new ones); "due date" switch revealing date + time pickers; recurrence dropdown (None/Daily/Every Other Day/Weekly/Monthly display names); "Mission Reminder" per-chore notification switch (persist the flag; actual scheduling is slice 08); Save.
2. **New-chore mode** (`/chores/new`): empty form, no history section at all, Save creates and pops back.
3. **Edit mode** (`/chores/:id`): loads current values; Save updates. Unique-name violation (insert AND rename) → flavored "Registry Conflict" alert, form stays open with input preserved.
4. **History section** (edit mode only): reactive list of completion records (date + note cards, newest first); tap a record → reuse `CompletionDialog` prefilled → update record's date and note; swipe record → confirm → delete. Flavored empty state when a chore has no records.
5. **Keyboard dismissal (PRESERVE)**: keyboard reliably dismisses on save and on navigation away — use standard Flutter focus APIs (`FocusManager`/`FocusScope.unfocus`), NOT platform channel hacks.
6. Chore card tap navigates to `/chores/:id` (wire it if not already).
7. All copy via AppStrings (superhero flavor from the MAUI pages).

## Tests

- Widget (in-memory db): new-chore save creates with chosen tags/due/recurrence and pops; edit-mode loads existing values; rename to an existing name shows Registry Conflict and preserves input; due-date switch off clears the due date on save; history renders records; editing a record via the dialog persists new date+note; swipe-delete a record with confirm removes it and cancel keeps it; new-chore mode shows no history section.
- Keep provider-only timer/stream tests out of testWidgets (project convention: fakeAsync in plain test()); use one-shot selects for db assertions in widget tests, not watch-stream `.first` (known hang, see completion_flow_test.dart comments).

## Done criteria

- `flutter analyze` clean; `flutter test` fully green (existing 70 + new); output in changes.md.
- No QUIRK recreation: no prefetch hacks, no deferred collection swaps, no measure/opacity tricks, no message-bus reload patterns.
- `$AER_OUTPUT_DIR/changes.md` lists files and deviations.

## Do NOT

- Touch anything outside `app/`; no notification scheduling (slice 08); no new packages.
