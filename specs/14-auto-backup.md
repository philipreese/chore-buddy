# Spec 14 — Auto-backup: scheduled rotating database exports (issue #21)

## Role

Implement. Report to `$AER_OUTPUT_DIR/changes.md`. ONE-SHOT: complete synchronously; write changes.md before finishing. Do NOT background long-running commands (`flutter test`, builds) — run them to completion in the foreground.

## Environment (stripped — set before builds)

- `ANDROID_HOME=C:\Android\sdk`, `ANDROID_NDK_HOME=C:\Android\sdk\ndk\28.2.13676358`, `JAVA_HOME=C:\Program Files\Android\openjdk\jdk-21.0.8`
- Flutter `C:\src\flutter\bin\flutter.bat`, Dart `C:\src\flutter\bin\dart.bat`

## Context

`app/lib/features/settings/domain/backup_service.dart` already implements manual export (writes a validated snapshot of the SQLite db) and hot-swap import with rollback. This spec adds an unattended periodic backup so a bad import, data corruption, or fat-fingered Delete All is recoverable without the user remembering to export. Read `docs/reviews/09` lessons (import rollback) before touching backup code.

NOTE: you may be working in a git WORKTREE in parallel with other slices — touch only `app/`; new strings go at the END of `app_strings.dart`/`superhero_strings.dart`; do not modify `app/lib/app.dart` beyond the minimal init hook if one is unavoidable (prefer wiring inside settings/backup modules).

## Scope (all inside `app/`) — allowed new package: `workmanager`

1. **Scheduled backup job**: a daily `workmanager` periodic task (Android only) that exports the database using the SAME snapshot/validation code path as manual export (extract/reuse the core; do not duplicate). The task runs in a background isolate — follow the `background_completion.dart` pattern: own db connection, `@pragma('vm:entry-point')` callback dispatcher, close the connection, no providers.
2. **Destination + rotation**: write to a `backups/` folder in the app's external files directory (path_provider `getExternalStorageDirectory()`, falling back to app documents if null) with timestamped names (`chorebuddy-auto-YYYYMMDD-HHmmss.db`). Keep the newest 5; delete older ones after a successful write. Never delete anything if the new export failed validation.
3. **Settings surface**: an "Auto-Backup" section in Settings — on/off toggle (persisted via the existing prefs service; default ON), last-successful-backup timestamp (persisted by the job; "never" state handled), and the destination path displayed read-only. A "Back Up Now" action that runs the same core in-process and updates the timestamp.
4. **Restore path**: the existing import flow can already pick any file; just verify the auto-backup files are importable through it (add a test asserting an auto-backup export passes the import validator).
5. Flavored copy via AppStrings (e.g. "Vault Sync" naming is up to you — stay in the superhero voice, strings at END of files).
6. Tests: rotation logic (5 kept, failure keeps old files) against a temp dir with a fake clock injected — plain `test()`, sync IO (`createTempSync`/`writeAsBytesSync` — real dart:io async hangs in testWidgets); the backup core against an in-memory→file db; the settings toggle round-trip. No platform channels in tests — the workmanager registration goes behind a thin fakeable wrapper like `WidgetDataWriter` does.

## Done criteria

- `flutter analyze` clean; `flutter test` fully green; `flutter build apk --debug` succeeds; changes.md lists files, the scheduling cadence/constraints chosen, and any deviation.
