# Adversarial review A — data layer & background paths

**Branch:** `20-device-feedback-round-1-polish-theme-simplification-identity` vs `main` (PR #24, slices 10–25)
**Domain:** database/migrations, backup & auto-backup, recurrence/snooze/completion/stats, notifications & background isolates, widget sync, voice.

**Verdict: FAIL — 3 blocking findings** (two data-loss, one permanent-corruption).

## Method note / limits

This session had **no Bash tool**, so I could not run `git diff main...HEAD`, `flutter test`, or throwaway probe tests. Every finding below is derived by reading the actual sources and reasoning arithmetically about the failure path; I have labelled which single step in B-3 rests on a drift-internal behaviour I could not execute (and framed that finding so it holds either way). No workspace files were modified — nothing outside the artifacts directory was touched, so `git status` is unchanged.

---

# BLOCKING

## B-1 — Import deletes its own rollback point before the imported database has ever been opened; every post-swap failure is unrecoverable

`app/lib/features/settings/domain/backup_service.dart:197-239`

The swap sequence is:

```
197   await stagingFile.rename(dbFile.path);   // live db is now the imported file
198   await onAfterSwap?.call();
200   if (await backupFile.exists()) {
201     await backupFile.delete();             // <-- rollback point destroyed
202   }
203 } catch (e) { ...restore path... }
230 } finally { ref.invalidate(appDatabaseProvider); }

236 await ref.read(appDatabaseProvider).repairInvalidCustomDaysRecurrence();
238 await ref.read(notificationServiceProvider).rescheduleAll();
239 await ref.read(widgetSyncServiceProvider).sync();
```

Line 236 is the **first time the imported file is ever opened as a database**. It sits *outside* the `try`. By then the pre-import backup is already gone (201) and the original file is already overwritten (197).

**Repro argument.** `isValidChoreBuddyDatabase` (`backup_validation.dart:22-36`) opens the candidate read-only and asserts only that `sqlite_master` lists four table names. It reads no page beyond the schema. So a file whose page 1 / `sqlite_master` is intact but whose `chores` b-tree pages are truncated or corrupt — a `.db3` produced by `exportDatabase` (`backup_service.dart:97`, a bare `dbFile.copy()` with **no** post-copy validation) onto an SD card that filled up, or any file the user hands the picker — passes validation.

1. User picks that file. Validation passes (`:156`).
2. Live db closed (`:175`), sidecars deleted (`:194`), staging renamed over the live file (`:197`).
3. Backup deleted (`:201`). Provider invalidated (`:231`).
4. `:236` opens the imported file → `SqliteException(11): database disk image is malformed` (or `NOT NULL constraint`/`no such column` for any schema surprise; see B-3 for the version case).
5. The exception is **not** an `ImportException` — it propagates raw out of `importDatabase` past a `reason` the UI knows how to explain, and the caller sees an unclassified crash.
6. The user's real database no longer exists on disk, and neither does the copy taken to protect it.

The same holds for a failure inside `rescheduleAll()` (`:238`) or `sync()` (`:239`) — less catastrophic, but they too escape uncaught and leave `_importInProgress` correctly reset while the UI has no `ImportFailureReason` to render.

This is the same failure class as the previously-caught disk-full import, relocated: the earlier fix hardened the window *inside* the `try` (`_isRestorableBackup`, `preSwapLength`) and left the window *after* it completely unguarded.

**Fix direction.** Move lines 236-239 inside the `try`, and move the `backupFile.delete()` (200-202) to after a successful reopen-and-read of the imported database. Give `_isRestorableBackup`'s rollback the chance to fire for reopen failures too. Consider adding a cheap `SELECT count(*) FROM chores` (or `PRAGMA quick_check`) to `isValidChoreBuddyDatabase` so structurally-corrupt files are rejected *before* the point of no return rather than after it.

---

## B-2 — A silently-failed WAL checkpoint followed by an unconditional `-wal` delete destroys committed data that the documented `swapFailed` rollback promises to preserve

`app/lib/features/settings/domain/backup_service.dart:170-176`, `:184-197`, `:247-251`

```
170  try {
171    await db.customStatement('PRAGMA wal_checkpoint(FULL);');
172  } catch (e, st) {
173    debugPrint('...checkpoint failed: $e\n$st');   // swallowed
174  } finally { await db.close(); }
...
184    preSwapLength = await dbFile.length();
185    await dbFile.copy(backupFile.path);            // main file ONLY, no -wal
194    await _deleteSidecarFiles(dbFile);             // deletes -wal unconditionally
197    await stagingFile.rename(dbFile.path);
```

Two compounding problems:

1. **`PRAGMA wal_checkpoint(FULL)` does not throw when it fails.** It returns a result row `(busy, log, checkpointed)` with `busy = 1` when another connection holds a read lock. `customStatement` sees a successful statement. So the `catch` at `:172` never fires and the `debugPrint` never prints — a failed checkpoint is completely invisible. Contention is real here, not hypothetical: `autoBackupCallbackDispatcher` (`auto_backup_task.dart:38`) and `notificationBackgroundResponseHandler` (`background_completion.dart:126`) each open their **own** `AppDatabase()` connection to the same file from separate background isolates.

2. The rollback copy at `:185` copies **only** `chore_buddy.sqlite`, and `:194` then deletes `chore_buddy.sqlite-wal`.

**Repro argument.** The WorkManager auto-backup job wakes and holds a read lock while the user taps Import.

1. `:171` checkpoint returns `busy = 1`. The last N committed transactions (recent completions, a chore the user just added) live only in `-wal`. No error surfaces.
2. `:185` copies the main file to `.pre-import.bak` — a snapshot **missing those transactions**.
3. `:194` deletes `-wal`. Those transactions are now gone from disk entirely.
4. `:197` `rename` fails (ENOSPC, a permissions quirk on an OEM build, the staging copy at `:188` having partially failed).
5. Restore path: `_isRestorableBackup` passes — same length as `preSwapLength` (measured at `:184`, also pre-WAL), tables present — and `backupFile` is copied back.
6. `ImportException(swapFailed)` is thrown, whose doc comment at `:26-29` states the pre-swap backup is restored. It was. But the state it restored is **not** the pre-swap state: everything that was WAL-only at step 1 is permanently lost, and nothing anywhere reports it.

`_isRestorableBackup`'s length check cannot catch this — it compares the backup to the same WAL-less main file it was copied from, so both sides are equally short.

**Fix direction.** Read the checkpoint's result row and treat `busy != 0` as a hard failure that aborts the import *before* `:184`, retrying or telling the user to try again. Additionally copy `-wal`/`-shm` alongside the main file into `backupFile`, and restore all three, so the rollback restores byte-for-byte what was there.

---

## B-3 — Import accepts a database from a *newer* schema version; the app then either dies past the point of no return or silently downgrades `user_version`, arming a permanent "duplicate column name" failure

`app/lib/features/settings/domain/backup_validation.dart:22-36`, `app/lib/core/database/app_database.dart:26-44`

`isValidChoreBuddyDatabase` checks table *names* only. It never reads `PRAGMA user_version`. Nothing else in the import path does either. So a `.db3` exported by a future build with `schemaVersion = 5` is accepted as a valid import candidate and swapped in at `backup_service.dart:197`.

The migration strategy is a chain of one-way guards:

```dart
onUpgrade: (Migrator m, int from, int to) async {
  if (from < 2) { await m.addColumn(tags, tags.emoji); }
  if (from < 3) { await m.addColumn(chores, chores.recurrenceInterval); }
  if (from < 4) { await m.addColumn(chores, chores.emoji); }
},
```

There is no `onDowngrade`, and no `from > to` guard. When the file's stored version (5) exceeds `schemaVersion` (4), exactly one of two things happens at the first open (`backup_service.dart:236`), and **both are bad**:

- **If drift routes the mismatch into `onUpgrade(m, 5, 4)`** (its `OpeningDetails.hadUpgrade` is a `versionBefore != versionNow` comparison, not `<`): all three guards are false, the migration is a silent no-op, and drift then stamps `user_version = 4` onto a file that is physically v5. The import "succeeds". Later, when the user updates to the build that *is* v5, `onUpgrade(m, 4, 5)` runs `addColumn` for a column that already exists → `SqliteException: duplicate column name` **on every open**, forever. The app cannot start and cannot self-repair; the only recovery is clearing app data, i.e. total loss.
- **If drift instead throws** on a downgrade: the throw lands at `backup_service.dart:236` — after the swap, after the backup was deleted. That is finding B-1, and the user's original database is gone.

I could not execute drift's open path to determine which branch fires (no shell in this session, and the pub cache was not readable). The finding does not depend on that: **nothing in this codebase rejects `user_version > schemaVersion`**, so whichever branch drift takes, the outcome is unrecoverable.

The upgrade paths themselves are correct — the `from < N` chain cannot double-add or skip a column for v1→v4, v2→v4, or v3→v4, and `database_migration_test.dart` covers all three. The gap is strictly the downgrade direction, which no test exercises.

**Fix direction.** In `isValidChoreBuddyDatabase` (or a sibling check on the import path), read `PRAGMA user_version` on the already-open read-only handle and reject anything `> AppDatabase().schemaVersion` with `integrityCheckFailed` — i.e. **before** the live file is touched. Add an explicit `if (from > to) throw` to `onUpgrade` as a belt-and-braces guard so this can never silently no-op.

---

# SHOULD-FIX

## S-1 — Week boundaries use `Duration` arithmetic across DST; completions fall into no week, or into two

`app/lib/features/chores/domain/stats_calculator.dart:11`, `:42`, `:71`, `:191`

`recurrence_calculator.dart:63-68` carries an explicit comment about exactly this hazard and uses calendar-component arithmetic (`_addDays`) to avoid it. `stats_calculator.dart` uses `Duration` throughout and does not.

**Repro (fall-back, drops a completion entirely).** `America/New_York`, DST ends Sun 2 Nov 2025 02:00 EDT → 01:00 EST.

- `now` = Fri 31 Oct 2025 12:00. `startOfWeek` → `Oct 27 00:00 EDT` (correct; no transition is crossed going back to Monday).
- `countCompletionsInWeek(_, Oct 27 00:00 EDT)` computes `weekEnd = weekStart.add(Duration(days: 7))` (`:42`). Oct 27 00:00 EDT = Oct 27 04:00 UTC; +168 h = Nov 3 04:00 UTC = **Sun Nov 2 23:00 EST**. The window ends an hour early because Nov 2 was a 25-hour day.
- A completion at Sun 2 Nov 23:30 EST: `!isBefore(weekStart)` ✓ but `isBefore(weekEnd)` ✗ → excluded from its own week.
- The following week: `startOfWeek` → Nov 3 00:00 EST, which is *after* Nov 2 23:30 → also excluded.
- **The completion is counted in zero weeks.** It vanishes from the banner's weekly line and from the Mission Log bar chart.

**Repro (spring-forward, double-counts).** Mirror case: `weekStart.add(168h)` across a 23-hour day lands an *hour past* the true next Monday 00:00, so completions in that hour are counted in both the outgoing and incoming week.

**Repro (`lastWeekStart`, `:71`).** `thisWeekStart(Nov 3 00:00 EST).subtract(Duration(days: 7))` = Nov 3 05:00 UTC − 168 h = Oct 27 05:00 UTC = **Oct 27 01:00 EDT**, not Oct 27 00:00. Anything completed on Monday Oct 27 between 00:00 and 01:00 is silently missing from the "last week" count that `weekDeltaKind` compares against.

`weeklyCompletionCounts` (`:191`) compounds it — `Duration(days: 7 * i)` over a 12-week window shifts every bucket boundary that spans a transition.

`startOfWeek` itself (`:11`) is safe only by accident: for a Monday-based week and a Sunday transition, walking back from any day to that week's Monday never crosses the transition. That accident does not hold in every locale (Iran transitions on a Friday; several jurisdictions transition at 00:00 rather than 02:00/03:00).

`stats_calculator_test.dart:26-39` covers only Monday/Tuesday/Sunday in a non-transition week.

**Fix direction.** Reuse the same calendar-component `_addDays` helper `recurrence_calculator.dart` already has (export it, or lift it into a shared date utility) for every week-boundary computation in this file.

## S-2 — `difference(...).inDays` between local midnights truncates on a 23-hour day: streaks over-count, median cadence under-reports

`app/lib/features/chores/domain/stats_calculator.dart:110-112`, `:131`

`_dateOnly(a).difference(_dateOnly(b)).inDays` measures elapsed hours ÷ 24, not calendar days. Across a spring-forward the interval is one hour short and truncates down.

**Repro (streak over-counts).** US spring-forward Sun 8 Mar 2026 02:00. Daily chore → `expectedPeriod = 1`, `maxGap = 2` (`:107`). Completions at Fri 6 Mar 09:00 and Mon 9 Mar 09:00 — a real gap of **3** calendar days, which exceeds the 2-day grace and should break the streak.
- `_dateOnly` → Mar 6 00:00 EST (= Mar 6 05:00 UTC) and Mar 9 00:00 EDT (= Mar 9 04:00 UTC).
- `difference` = 71 h → `.inDays` = **2** → `gap <= maxGap` → the streak continues.
- The user is credited with an unbroken daily streak they did not earn.

**Repro (median cadence under-reports).** Weekly chore, completions 7 calendar days apart spanning the same transition → 167 h → `.inDays` = **6**. `medianCadenceDays` returns 6.0 for a strictly weekly chore. Combined with `cadenceScheduleFor` (`:145-150`), a chore genuinely drifting to 8-day intervals can be reported `onSchedule`.

**Fix direction.** Compute day deltas as `(a.difference(b).inHours / 24).round()`, or better, derive the calendar-day index directly (e.g. `DateTime.utc(y, m, d)` normalisation before subtracting) so the local offset drops out.

## S-3 — Switching voice never reschedules notifications; already-scheduled reminders keep the old voice's copy

`app/lib/app.dart:110-123`

```dart
// ...recreating it with the new voice's name/description is enough for both
// already-scheduled and future reminders to pick up the new copy...
Future<void> _onVoiceChanged() async {
  final strings = ref.read(appStringsProvider);
  await ref.read(notificationSchedulerProvider).updateChannel(...);
  await ref.read(widgetSyncServiceProvider).sync();
}
```

The comment's claim is false for everything except the channel's own name/description in system settings. `scheduleChoreNotification` (`notification_service.dart:34-42`) bakes `strings.notificationTitle(chore.name)`, `strings.notificationBody`, `strings.notificationCompleteAction` and `strings.notificationSnoozeAction` into the `zonedSchedule` call, and `flutter_local_notifications` persists those strings with the pending alarm. `updateChannel` (`notification_scheduler.dart:141-164`) only recreates the `AndroidNotificationChannel`; it does not and cannot rewrite scheduled payloads.

**Repro.** Superhero voice active; a chore is due tomorrow, so a reminder is scheduled with Superhero title/body/action labels. User switches to Grandma. `_onVoiceChanged` updates the channel and syncs the widget. Tomorrow the reminder fires **in Superhero's voice**, with Superhero's "Complete"/"Not Today" button labels — the one surface where spec 24's voice is most visible. It stays wrong until that chore is next mutated by some other flow.

**Fix direction.** Add `await ref.read(notificationServiceProvider).rescheduleAll();` to `_onVoiceChanged` — the method already exists for exactly this shape of "re-evaluate everything" change — and correct the comment.

## S-4 — `@TableIndex` indexes are created only on fresh installs; every upgraded install and every imported legacy backup runs without them, permanently

`app/lib/core/database/app_database.dart:29-44`, `app/lib/core/database/tables.dart:33`, `:51`, `app/lib/core/database/app_database.g.dart:1413-1420`

`idx_completion_records_chore_id` and `idx_chore_tags_tag_id` are declared as `@TableIndex` and materialise in `allSchemaEntities`, which means `Migrator.createAll()` — i.e. **`onCreate` only** — creates them. `onUpgrade` adds columns and nothing else; there is no `m.create(index)` anywhere in the repo (grep for `createIndex` / `Index(` returns hits only in `tables.dart` and the generated file).

**Repro.** A user upgrades from a build predating those annotations: `onUpgrade` runs the three `addColumn` steps, `user_version` reaches 4, the app reports a fully-migrated schema, and both indexes are absent forever. **The import path makes this reachable on a brand-new install too**: importing a v1/v2/v3 backup routes through `onUpgrade` (never `onCreate`), so the swapped-in database is stamped v4 with no indexes. `watchHistoryForChore` and the Mission Log's per-chore completion grouping then table-scan `completion_records` for the life of the install, and the index's absence is invisible to `database_migration_test.dart`, which builds every fixture via `createAll` and only ever drops columns.

Note the generated DDL is plain `CREATE INDEX`, not `IF NOT EXISTS`, so a naive `m.createAll()` bolted onto `onUpgrade` would fail on an install that already has them — the fix has to be version-gated.

**Fix direction.** Bump `schemaVersion` to 5 and add a `if (from < 5) { await m.create(idxCompletionRecordsChoreId); await m.create(idxChoreTagsTagId); }` step (or use `Migrator.createIndex` with existence handling). Extend `database_migration_test.dart` with a case that asserts the index rows are present in `sqlite_master` *after* an upgrade, not just after a create.

## S-5 — Auto-backup can write and "validate" a snapshot that silently omits recent commits, then rotate good snapshots away

`app/lib/features/settings/domain/auto_backup_core.dart:64-82`, `:105`

Same root cause as B-2, different blast radius. `:64` issues `PRAGMA wal_checkpoint(FULL)` and ignores its result row. `:70` copies **only** `dbFile` — no `-wal`. `:72` validates the copy with `isValidChoreBuddyDatabase`, which reads `sqlite_master` and nothing else, so a snapshot missing the last week of completions validates as perfectly good. `:81` then calls `rotateAutoBackups`, which deletes everything past the newest 5.

**Repro.** The WorkManager job fires while the app is in the foreground with an open drift connection. The `FULL` checkpoint returns `busy = 1`; recent commits stay in `-wal`. The copy captures the main file only. Validation passes on table names. Rotation deletes the oldest snapshot. Repeat for 5 consecutive days of contention and **every retained snapshot is stale in the same way** — the user's recovery set is silently hollowed out, and `lastAutoBackupAt` (`auto_backup_task.dart:47`) tells them everything is fine.

**Fix direction.** Check the checkpoint result and return `null` (no rotation, no `lastAutoBackupAt` update) when `busy != 0`; or copy `-wal`/`-shm` alongside; or take the snapshot with sqlite's own `VACUUM INTO`, which is atomic and WAL-aware by construction.

---

# NITS / LOW

## N-1 — Background snooze racing a foreground completion can revert the completion's due-date advance

`app/lib/features/chores/domain/snooze_service.dart:28-42`

`snoozeChore` reads the row (`:28-32`) and writes (`:40-41`) with no enclosing transaction, unlike `CompletionService.completeChore` which deliberately wraps its read-modify-write (`completion_service.dart:62-92`). Two snoozes racing is benign (both compute "tomorrow at the same time-of-day"), but the notification isolate's snooze racing an in-app completion is not: snooze reads `nextDueDate = Jan 10`, the completion transaction commits `Jan 11`, then the snooze writes `Jan 11 (tomorrow-from-now)` derived from the stale read — clobbering the recurrence advance. The chore ends up completed with a snooze-derived due date. Narrow window; wrap the read+write in `db.transaction` and re-check the row for a cheap fix.

## N-2 — Widget's JSON parse is unguarded, unlike every other platform boundary in the codebase

`app/android/.../widget/ChoreWidgetRemoteViewsFactory.kt:39-43`, `:76-91`

`JSONArray(raw)` and each `obj.getInt`/`getString`/`getBoolean` throw `JSONException` on any malformed or shape-changed payload. `onDataSetChanged` runs in the app's process; an uncaught throw there kills it. Every Dart-side platform call in this branch is wrapped precisely to avoid this (`HomeWidgetDataWriter`, `PluginNotificationScheduler`, `WorkManagerAutoBackupScheduler`); the Kotlin side is the one place that isn't. Wrap `parseChores` and fall back to `emptyList()`.

## N-3 — Chore names that already start with an emoji get a second one prefixed

`app/lib/core/home_widget/widget_sync_service.dart:103-106`

`chore.emoji ?? guessChoreEmoji(chore.name)` is prepended unconditionally. A chore the user named `🗑️ Trash` with no explicit emoji guesses `🗑️` from the token `trash` and renders as `🗑️ 🗑️ Trash` in the widget row. Cheap guard: skip the prefix when the name's first rune is already an emoji/symbol.

## N-4 — `bestStreakAcrossChores` reports streaks for abandoned chores as current

`app/lib/features/chores/domain/stats_calculator.dart:256-280`

`computeStreak` walks newest-to-oldest and never checks that the newest completion is recent. A weekly chore completed 6 times in a row and then abandoned 14 months ago still returns a streak of 6, and the Mission Log presents it as the household's *current* best streak. Gate on `now.difference(newest) <= expectedPeriod + grace` before counting.

## N-5 — `rotateAutoBackups` matches on prefix only, ignoring the extension its own doc-comment leans on

`app/lib/features/settings/domain/auto_backup_core.dart:9-14`, `:100`

The comment justifies the `.db` extension as what keeps rotation from sweeping up `.db3` manual exports, but the filter is `basename.startsWith(kAutoBackupFilePrefix)` and never looks at the extension. It happens to be safe today because the two prefixes differ (`chorebuddy-auto-` vs `chorebuddy_backup_`), so the stated invariant and the enforced one have drifted apart. Also worth noting: `autoBackupFileName` has 1-second granularity, so two snapshots in the same second silently overwrite. Add the extension to the predicate so the code matches its documented reasoning.

---

# What I probed and found clean

- **Migration upgrade paths.** The `from < N` guard chain cannot double-add or skip a column on v1→v4, v2→v4 or v3→v4; `database_migration_test.dart` covers all three with fixtures derived from the real generated schema rather than a hand-maintained copy. Only the *downgrade* direction is unguarded (B-3).
- **`_addOneMonthClamped`** (`recurrence_calculator.dart:102-120`): Jan 31 → Feb 28/29 clamps correctly, including the Dec→Jan year rollover and `DateTime(year, month+1, 0)` for month 12.
- **`calculateNextDueDate` DST handling**: `_addDays`/`_dateOnly`/`_combine` all use calendar-component construction, correctly, and interval 365 across a transition lands on the right calendar day. A `customDays` row with a null or `< 1` interval degrades to `null` at `:35-37`, and `watchActiveChoresWithDetails` independently degrades an out-of-range interval to `RecurrenceType.none` (`app_database.dart:114-134`) — belt and braces, and `repairInvalidCustomDaysRecurrence` persists the fix after import.
- **Double-completion of an overdue chore**: `completeChore` re-reads inside a transaction (`completion_service.dart:62-65`); the second completion recomputes from the same completion date and produces the same next-due, so it is idempotent. `undoCompletion`'s conditional `equalsNullable` guard correctly refuses to clobber a user edit made during the undo window.
- **`DriftRemoteException` unwrapping** (`app_database.dart:410-430`): the walk terminates on every branch (`SqliteException` returns, `DriftWrappedException`/`DriftRemoteException` descend, everything else breaks) and cannot loop.
- **Voice/intent parsing** (`voice_command_service.dart`): absent, non-`String`, and unknown-value extras all degrade rather than throw (`:96`, `:101`, `:140`, `:201-212`); `_resolveActiveChore` prefers an exact case-insensitive match and refuses to act on an ambiguous prefix, which is the right default for a destructive-ish operation.
- **Persisted voice from a future version**: `settings_prefs_service.dart:77-86` scans `AppVoice.values` by name and leaves `voice` null on no match; `settings_hydration.dart:32-34` only applies non-null, and `background_completion.dart:129`/`:209` fall back to `AppVoice.superhero`. An unknown persisted enum name degrades cleanly on every path.
- **`kWidgetMaxEntries` overflow ordering**: `selectWidgetChores` filters to chores with a due date, sorts via the shared `sortChores` urgency comparator (total, with a lowercase-name tie-break at `chore_filter_sort.dart:82`) and then takes 6 — deterministic, no null-vs-non-null ordering hazard since nulls were filtered first.
- **`buildMonthHeatmap`**: leading-blank count is correct for both a Monday 1st (0 blanks) and a Sunday 1st (6 blanks); `DateTime(year, month + 1, 0).day` handles December; `DateTime` map keys match on both sides because both are produced by the same local-midnight construction.
- **`icon_guesser`**: word-token matching genuinely prevents the substring false-positives the doc-comment claims ("carpet" does not fire `car`), and the `_tokenForms` singularisation handles `-ies`/`-es`/`-s` without mangling `-ss`.
