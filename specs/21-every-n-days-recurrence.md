# Spec 21 — "Every N days" recurrence

## Role

Implement. Report to `$AER_OUTPUT_DIR/changes.md`. ONE-SHOT: complete synchronously; write changes.md before finishing. Do NOT background long-running commands (run `flutter test` in the foreground and wait for it).

## Environment (stripped — set before builds)

- `ANDROID_HOME=C:\Android\sdk`, `ANDROID_NDK_HOME=C:\Android\sdk\ndk\28.2.13676358`, `JAVA_HOME=C:\Program Files\Android\openjdk\jdk-21.0.8`
- Flutter `C:\src\flutter\bin\flutter.bat`, Dart `C:\src\flutter\bin\dart.bat`

## Context

Current recurrence options: none / daily / everyOtherDay / weekly / monthly. Real chores don't fit ("change sheets every 10 days"). Add a custom "every N days" recurrence.

## Hard constraints

- `RecurrenceType` is persisted as **enum index** (`EnumIndexConverter` in `app_database.g.dart`) and round-trips through JSON backups the same way. The new enum value MUST be appended at the END of `RecurrenceType.values`. Never reorder or remove existing values. `everyOtherDay` stays exactly as-is (redundant with interval=2 is fine; zero-risk beats a data migration).
- Spec 19 bumped `schemaVersion` (tags emoji column). Read the current number in `app_database.dart` and bump from THERE; write the drift migration additively.

## Items

### 1. Schema + model

- Append `RecurrenceType.customDays` (name it that or similar) at the end of the enum.
- New nullable integer column `recurrence_interval` on the chores table (drift `addColumn` migration, schemaVersion +1). Semantics: only meaningful when recurrence == customDays; valid range 1–365; null for every other recurrence type.
- Backup export/import: round-trip the interval; importing old backups without the field yields null (tolerated). Guard on import: a customDays chore with null/invalid interval falls back to `RecurrenceType.none` rather than crashing.

### 2. Recurrence math

- `recurrence_calculator.dart`: customDays advances the due date by `interval` days (same anchoring behavior as the daily/everyOtherDay cases — from the prior due date, per the existing file's contract). Interval null/`< 1` → treat as none (defensive; the UI prevents it).

### 3. Editor UI (`chore_detail_screen.dart`)

- The recurrence `DropdownButtonFormField` gains an "Every N days…" item (appended last). Selecting it reveals a compact number field (default 3, range 1–365, numeric keyboard, validation message on out-of-range). The stored label everywhere a recurrence is displayed (dropdown collapsed state, `_recurrenceLabel`, detail read views) renders as "Every 5 days" style via a new parameterized string.
- Editing an existing customDays chore pre-fills the interval. Switching away from customDays clears/nulls the interval on save.
- Strings on `AppStrings` + `SuperheroStrings`: the dropdown item label + the parameterized display label. Superhero register, instantly parseable.

### 4. Out of scope

- Voice commands: `_parseRecurrence` in `voice_command_service.dart` matches enum names and will simply never produce customDays — leave it; note it in changes.md as a known follow-up.
- Notifications/home widget: they consume `nextDueDate` and need no changes; do not touch them.

### 5. Tests

- Calculator: interval 1, 5, 365; null-interval fallback; anchoring matches the existing daily-case behavior.
- Migration test (new column, version bump).
- Backup round-trip with interval set and with legacy payload lacking the field; corrupt customDays-with-null-interval import falls back to none.
- Editor widget test: pick "Every N days", enter 10, save, reopen shows 10; out-of-range shows validation and blocks save.
- Completion flow: completing a customDays(10) chore advances due by 10 days (fake clock).

## Done criteria

- `flutter analyze` clean; `flutter test` fully green (foreground); `flutter build apk --debug` succeeds.
- changes.md states: new schemaVersion, the enum's final ordering, and any deviation.
- Nothing outside `app/`.
