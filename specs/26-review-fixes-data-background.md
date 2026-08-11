# Spec 26 — Review-A fixes: backup/import data-loss windows, DST stats, migrations

## Role

Implement. Report to `$AER_OUTPUT_DIR/changes.md`. ONE-SHOT: complete synchronously; write changes.md before finishing. Run `flutter test` FOREGROUND to a log file (healthy ~30s; minutes = failures, each stalls ~10min in teardown; never pipe through tail/head).

## Environment (stripped — set before builds)

- `ANDROID_HOME=C:\Android\sdk`, `ANDROID_NDK_HOME=C:\Android\sdk\ndk\28.2.13676358`, `JAVA_HOME=C:\Program Files\Android\openjdk\jdk-21.0.8`
- Flutter `C:\src\flutter\bin\flutter.bat`, Dart `C:\src\flutter\bin\dart.bat`

## Context

Adversarial review A (FULL DETAIL with repro arguments and fix directions in `docs/reviews/pr24-review-a-data-background.md` + `pr24-review-a-verdict.json` — READ IT FIRST) failed the branch with 3 blockers. This spec fixes the data/background findings. Do NOT touch `app/lib/app.dart` or any `lib/core/strings/` voice file — those findings belong to the parallel spec 27.

## Fix items (review finding → requirement)

### Blockers

1. **B-1 import rollback window**: move the post-swap reopen/repair/reschedule/sync (backup_service.dart:236-239) inside the try; delete `backupFile` only AFTER a successful reopen-and-read of the imported db; add a data-touching check to `isValidChoreBuddyDatabase` (`PRAGMA quick_check` or `SELECT count(*)` from each required table) so corrupt-pages files are rejected before the swap. Any post-swap failure must classify into an `ImportFailureReason` the UI can render, with the rollback restored.
2. **B-2 WAL checkpoint**: read `PRAGMA wal_checkpoint(FULL)`'s result row; `busy != 0` aborts the import before the rollback copy is taken (user-facing retryable failure reason). Copy and restore `-wal`/`-shm` alongside the main file for the rollback so it is byte-faithful regardless.
3. **B-3 downgrade guard**: `isValidChoreBuddyDatabase` reads `PRAGMA user_version` and rejects anything greater than the app's `schemaVersion` (new failure reason, clear message); `onUpgrade` additionally throws on `from > to` as a belt.

### Should-fix

4. **DST week math** (stats_calculator.dart): every week-boundary computation (weekEnd, last-week start, weekly buckets) via calendar-component day arithmetic (reuse/extract recurrence_calculator's `_addDays` into a shared helper) — no `Duration(days: 7)` arithmetic on local DateTimes anywhere in the file afterward.
5. **DST day-gap truncation**: `computeStreak`/`medianCadenceDays` gaps via UTC-normalized date-only subtraction (`DateTime.utc(y,m,d)`) or rounded hour delta — a 23-hour calendar day must count as 1 day.
6. **Missing indexes**: schemaVersion 4 → 5; `if (from < 5)` creates the two `@TableIndex` indexes; migration test asserts their presence in `sqlite_master` after upgrade AND after a legacy-backup import (fixture law: fake old dbs must also DROP the indexes createAll gave them, plus all newer columns).
7. **Auto-backup WAL** (auto_backup_core.dart): check the checkpoint result row; on busy, return null (no snapshot, no rotation, no lastAutoBackupAt update). Keep it simple — no VACUUM INTO rewrite required.

### Lows (all small, all in scope)

8. Snooze read-modify-write inside `db.transaction` with the re-read inside (mirror completeChore).
9. Widget factory Kotlin: wrap `parseChores` in try/catch → emptyList() fallback (ChoreWidgetRemoteViewsFactory.kt:39).
10. Widget emoji prefix: skip when the name already starts with a non-alphanumeric symbol/emoji rune (widget_sync_service.dart:103).
11. `bestStreakAcrossChores`: a streak counts as current only when `now - newestCompletion <= expectedPeriod + grace`.
12. `rotateAutoBackups` predicate: prefix AND `.db` extension (enforce the doc-comment's invariant); include the timestamp-collision nit only if trivial (seconds → also millis in filename).

## Explicitly deferred (do NOT fix)

- Anything in app.dart (voice-change reschedule, shortcut filters) — spec 27's.
- Any voice string copy — spec 27's.

## Tests

Every blocker gets a regression test reproducing the review's scenario (corrupt-pages import rejected pre-swap; busy checkpoint aborts with sidecar-faithful rollback; v(N+1) backup rejected). DST tests: mirror recurrence_calculator_test's existing approach for transition arithmetic. Index-presence assertions per item 6. Full suite green in normal time.

## Done criteria

- `flutter analyze` clean; `flutter test` green (~30s); `flutter build apk --debug` succeeds; changes.md maps each finding ID → fix + test, and lists any finding you dispute (with reasoning) instead of fixing.
- Nothing outside `app/`.
