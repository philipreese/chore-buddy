# Spec 09b — Apply review fixes to settings and backup

## Role

Implement. Report to `$AER_OUTPUT_DIR/changes.md`. ONE-SHOT: complete synchronously; write changes.md before finishing.

## Environment (stripped — set before builds)

- `ANDROID_HOME=C:\Android\sdk`, `ANDROID_NDK_HOME=C:\Android\sdk\ndk\28.2.13676358`, `JAVA_HOME=C:\Program Files\Android\openjdk\jdk-21.0.8`
- Flutter `C:\src\flutter\bin\flutter.bat`, Dart `C:\src\flutter\bin\dart.bat`

## Context

Read `docs/reviews/09-settings-backup-review.md` first. Apply all findings:

## Required (blocker)

1. **F1 — rollback must never destroy an intact db**: track `swapAttempted` (set immediately before the staging rename); the catch restores the backup ONLY when the live file was actually replaced; validate the backup before trusting it (length match vs pre-copy `dbFile.length()` AND the existing read-only table check). A failed pre-mutation step (backup copy, staging copy) must leave everything untouched and just clean up partial artifacts.

## Also required (mediums)

2. **F2**: wrap the restore in its own try/catch; on restore failure surface a distinct reason including the backup's on-disk path; align the doc comment with actual guarantees.
3. **F3**: reentrancy: set `_busy` before the picker (guard the whole `_handleImport`/`_handleExport`), and add an in-service guard in `BackupService` (single in-flight import).
4. **F4**: wrap the hydration await in main() with try/catch → fall back to defaults; settings failure degrades settings, never startup.
5. **F5 test**: construct a default `AppDatabase()` under a faked `PathProviderPlatform`, write a row, assert `resolveDatabaseFile()` points at an existing file — pins the locator to drift's real path.
6. **F6 tests**: (a) rescheduleAll-after-import test using real `NotificationServiceImpl` + fake scheduler asserting scheduled ids come from the IMPORTED data; (b) assert `.pre-import.bak` is actually created during a successful swap (before cleanup) — e.g. via a hook/observable in the service or by asserting mid-failure state in the provoked-failure test.

## Worth doing (lows)

7. **F7**: delete `-wal`/`-shm` sidecars immediately BEFORE the rename (MAUI's order).
8. **F8**: move the export checkpoint to after the directory picker returns.
9. **F9**: stage into a uniquely-named temp file (timestamped) and clean up by type, so an undeletable path can't brick imports forever.
10. **F10**: About — add the Developer row ("Philip Reese") and card header from MAUI; move the tech-stack chip labels behind AppStrings.
11. **F11**: SettingsScreen widget tests: busy guard blocks double-tap import, destructive import requires the confirm dialog, success/failure dialog routing, last-backup label renders.

## Done criteria

- `flutter analyze` clean; `flutter test` fully green (120 existing + new); output in changes.md.
- Nothing outside `app/`; no new packages (the dev-only path_provider fake is already present).
