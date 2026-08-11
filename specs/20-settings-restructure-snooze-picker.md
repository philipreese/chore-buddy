# Spec 20 — Settings restructure + snooze picker

## Role

Implement. Report to `$AER_OUTPUT_DIR/changes.md`. ONE-SHOT: complete synchronously; write changes.md before finishing. Do NOT background long-running commands (run `flutter test` in the foreground and wait for it).

## Environment (stripped — set before builds)

- `ANDROID_HOME=C:\Android\sdk`, `ANDROID_NDK_HOME=C:\Android\sdk\ndk\28.2.13676358`, `JAVA_HOME=C:\Program Files\Android\openjdk\jdk-21.0.8`
- Flutter `C:\src\flutter\bin\flutter.bat`, Dart `C:\src\flutter\bin\dart.bat`

## Context

The settings screen (`app/lib/features/settings/presentation/settings_screen.dart`) has grown into a catch-all (~14 rows). Philip wants it restructured, plus a snooze picker replacing the fixed snooze-to-tomorrow. Spec 19 (banner + sections visual identity) landed just before this — match its section-header styling where this spec says so, and reuse its strings register.

## Items

### 1. Backup & restore sub-page

- Move ALL backup rows off the main settings screen: manual export, manual import, auto-backup toggle + subtitle, destination label, last-auto-backup label, backup-now button.
- New screen `BackupSettingsScreen` (route under the existing settings route, e.g. `/settings/backup`), containing those rows grouped Manual / Automatic, behavior byte-for-byte identical (same providers, same dialogs, same snackbars).
- The main settings screen gets ONE row: "Backup & restore" (new string; superhero register consistent with existing copy) with a chevron and a subtitle showing the most recent backup of either kind — reuse `lastBackupAtLabel`/`lastBackupNeverLabel` semantics; most-recent = max(manual last-backup timestamp, auto last-backup timestamp), whichever exists.
- Update/relocate the existing settings widget tests that exercise backup rows so they run against the sub-page; add a test that the main-screen row navigates there.

### 2. Manage-tags second door

- The tag-filter bottom sheet on the chores screen (opened from the filter icon in `SearchAndSortBar`) gets a trailing "Manage tags" affordance (text button or list row at the bottom of the sheet) that closes the sheet and pushes the existing manage-tags screen. The settings entry stays.
- Widget test: open filter sheet, tap manage tags, assert the manage-tags screen is shown.

### 3. Settings visual pass

- Restyle the main settings screen's section headers to match the section-header treatment spec 19 introduced on the chores list (same label style/count-pill-free variant — visually the same family). Sections: Appearance (theme picker), Behavior (haptics / notifications / show-details toggles), Tags, Backup & restore (the single row), Danger zone (unchanged semantics, stays last, keeps its error-color treatment).
- No new functionality here — layout/typography only.

### 4. Snooze picker

- Tapping the snooze button on a chore card (and anywhere else `snoozeChoreFlow` is invoked with UI context) now opens a modal bottom sheet instead of instantly snoozing: options **Tomorrow**, **In 3 days**, **Next week** (+7 days), **Pick a date…** (opens `showDatePicker`, min tomorrow, max +1 year). NO long-press interactions anywhere.
- Semantics identical to today's snooze otherwise: new due = chosen day at the chore's existing time-of-day (same anchoring `SnoozeService` uses now), no completion record, recurrence untouched, notification reschedule + widget sync after.
- `SnoozeService.snoozeChore` gains a target-date (or days-offset) parameter; the no-UI call path in `background_completion.dart` (notification snooze action) keeps snoozing to tomorrow — do not touch its behavior, just adapt it to the new signature with the tomorrow default.
- Cancelling the sheet/date-picker snoozes nothing.
- Strings: four option labels + sheet title, superhero register but instantly parseable.
- Tests: sheet shows all four options; each fixed option produces the expected due date at preserved time-of-day (fake clock); cancel path leaves the chore untouched; background snooze still lands on tomorrow (existing test keeps passing).

## Done criteria

- `flutter analyze` clean; `flutter test` fully green (foreground); `flutter build apk --debug` succeeds.
- changes.md states: the backup sub-page route, where the manage-tags door lives in the sheet, and any deviation.
- Nothing outside `app/`.
