# Slice 09 review — settings, persistence, theme picker, backup hot-swap

**Ref:** `18-migrate-chorebuddy-from-net-maui-to-flutter-android-only` @ `de31c2a` (subject commit `ac22a6c`)
**Verdict: FAIL** — one data-loss window in the import rollback path (finding 1).

The shape of the slice is right. The §2.4 sequence is followed in the correct order, the integrity check is genuinely read-only and genuinely rejects a MAUI-era `.db3`, and the failure-path tests exercise real failures rather than a fake that can't fail. What fails the review is a single unguarded rollback branch that can destroy an intact database in response to an error that never touched it.

---

## 1. Import — the §2.4 sequence

Read line by line against the proposal's 8 steps (`docs/proposals/00-new-stack-ideas.md:179-186`):

| § | Step | Where | OK |
|---|---|---|---|
| 1 | pick file | `settings_screen.dart:51` | ✅ |
| 2 | verify integrity/schema | `backup_service.dart:84-89`, `140-157` | ✅ |
| 3 | `PRAGMA wal_checkpoint(FULL)` | `backup_service.dart:97` | ✅ |
| 4 | `await db.close()` | `backup_service.dart:101` | ✅ explicit, awaited — the review-02 caveat is honoured |
| 5 | atomic replace | `backup_service.dart:110-111` | ✅ same-directory `rename` |
| 6 | `ref.invalidate` | `backup_service.dart:127` (`finally`) | ✅ on every exit path |
| 7 | streams reconnect | `database_provider.dart:26-46` all `ref.watch` | ✅ |
| 8 | `rescheduleAll()` | `backup_service.dart:130` | ✅ (but see finding 6) |

The integrity check is the strongest part of the change. `sqlite3.OpenMode.readOnly` (`backup_service.dart:143-146`) genuinely cannot mutate the candidate, and the comment at `:133-139` correctly identifies why opening through `AppDatabase` would be unsafe — the migration strategy would *create* the tables it was supposed to be checking for. **MAUI-era `.db3` rejection is confirmed**: the MAUI build is sqlite-net over `ChoreBuddy/Models/{Chore,Tag,CompletionRecord,ChoreTag}.cs`, so its tables are PascalCase singulars; `_requiredTables` (`backup_service.dart:159-164`) is `{chores, tags, completion_records, chore_tags}` and `sqlite_master` name matching here is exact-case, so a MAUI backup fails the check and never reaches the swap. Rejected outright, not half-accepted.

### Finding 1 (HIGH, data loss) — the rollback fires even when the live file was never touched, and restores from a possibly-partial backup

`app/lib/features/settings/domain/backup_service.dart:106-125`

```dart
try {
  if (await dbFile.exists()) {
    await dbFile.copy(backupFile.path);   // <-- FIRST statement in the try
  }
  await sourceFile.copy(stagingFile.path);
  await stagingFile.rename(dbFile.path);
  ...
} catch (e) {
  if (await stagingFile.exists()) { await stagingFile.delete(); }
  if (await backupFile.exists()) {
    await backupFile.copy(dbFile.path);   // <-- unconditional restore
    await backupFile.delete();
  }
  throw ImportException(ImportFailureReason.swapFailed, e);
}
```

The `catch` restores unconditionally, with no record of whether the swap was ever attempted and no check that the backup copy completed. The staging copy is the first thing that can plausibly fail *because* the pre-import backup just doubled the database's disk footprint — so the disk-full case is not exotic, it is the expected one.

Failure scenario: the device is near-full. `dbFile.copy(backupFile.path)` (`:108`) creates `.pre-import.bak`, streams part of the database, and throws `ENOSPC`. **At this instant the live database is completely intact — nothing has mutated it.** Control reaches `:117`. `stagingFile` doesn't exist. `backupFile.exists()` returns `true` — Dart's `File.copy` leaves the partially-written destination on disk, and `exists()` does not care that it's truncated. Line `:122` then copies that truncated file over the intact live database, and `:123` deletes the only other copy of the lost bytes. The user's database is now a truncated sqlite file; the app reports "Sync Failed" and there is nothing to recover from.

The same branch also misfires benignly-but-wrongly whenever `dbFile.copy` fails for any pre-mutation reason (permissions, EIO): a *complete* rollback is performed for an operation that changed nothing.

Fix direction: track how far the swap actually got (a `swapAttempted` flag set immediately before `stagingFile.rename`), only restore when the live file was actually replaced, and validate the backup before trusting it as a rollback source (length match against the pre-copy `dbFile.length()`, or ideally the read-only table check already implemented at `:140`).

### Finding 2 (MEDIUM) — the rollback path has no error handling of its own

`app/lib/features/settings/domain/backup_service.dart:117-125`

Every statement in the `catch` can throw. If `backupFile.copy(dbFile.path)` (`:122`) fails, the raw `FileSystemException` propagates instead of `ImportException(swapFailed)`, and the `finally` still invalidates the provider. The end state is: `dbFile` gone or replaced, `.pre-import.bak` still on disk (this is the one good part — it isn't deleted), and no user-facing path to it. `_handleImport`'s bare `catch (_)` (`settings_screen.dart:78`) does swallow it, so the app doesn't crash — but the declared contract at `:78-81` ("a failed swap restores the pre-import backup ... the current database is left untouched either way") is not true in this branch. Either wrap the restore in its own try/catch and surface a distinct "restore failed, backup is at `<path>`" reason, or at minimum stop documenting a guarantee the code doesn't make.

### Finding 3 (MEDIUM) — no reentrancy guard; the `_busy` flag is set too late to serve as one

`app/lib/features/settings/presentation/settings_screen.dart:46-73`

`_handleImport` checks `_busy` at `:47` but doesn't set it until `:73` — *after* `pickImportFile()` (`:51`) and the confirmation dialog (`:54-70`). Two taps on the Import tile landing in the same frame both pass the guard and both proceed. `BackupService.importDatabase` has no guard at all.

Two concurrent `importDatabase` calls share `${dbFile.path}.importing` and a single `.pre-import.bak`. Interleavings that lose data:
- Both reach `sourceFile.copy(stagingFile.path)` (`:110`) → two writers on one path → the renamed-in database is a mix of two write streams.
- A completes and deletes `backupFile` (`:114-116`); B then fails at `:111` (staging already renamed away) and finds no backup to restore from — it throws `swapFailed` having already lost its rollback point.
- B's `dbFile.copy(backupFile.path)` at `:108` runs *after* A's rename, so the "pre-import backup" is a copy of the already-imported file — the original is unrecoverable.

The Android file-picker activity makes this hard to hit deliberately, which is why it's medium rather than high, but the double-tap-in-one-frame window is real and the mitigation is one boolean in `BackupService`.

### Finding 7 (LOW) — sidecars are deleted after the rename, not before

`app/lib/features/settings/domain/backup_service.dart:111-112`

`stagingFile.rename(dbFile.path)` puts the new database in place while the old connection's `-wal`/`-shm` are still on disk; `_deleteSidecarFiles` runs afterwards. Within the process this is fine — nothing reopens in between. But a crash or kill in that window leaves a database file paired with a WAL belonging to a different database, which is exactly the state sqlite's salt check is there to catch and exactly the state you don't want to gamble on. Delete the sidecars immediately before the rename (they're already checkpointed and the connection is already closed by `:101`). Note MAUI did it in this safer order — `MigrationService.cs:99-101` deletes main, `-wal` and `-shm` before writing.

### Finding 9 (LOW) — an undeletable staging path permanently bricks import

`app/lib/features/settings/domain/backup_service.dart:118-120`

`stagingFile` is a `File`; if a *directory* occupies `${dbFile.path}.importing`, `File.exists()` returns false, the cleanup is skipped, and every subsequent import fails forever at `:110` with no way to recover from inside the app. This isn't hypothetical — `backup_service_test.dart:221` creates precisely that state to provoke the failure, and never cleans it up. Use `FileSystemEntity.typeSync` / delete recursively, or stage into a uniquely-named temp file.

---

## 2. Export

`backup_service.dart:47-65`. Checkpoint before copy ✅ (`:49`), file-existence guard ✅ (`:52`), cancel returns `false` without touching state ✅ (`:56`), timestamp set **only** after the copy returns ✅ (`:63`), and any copy exception propagates past `:63` so a failed export can't record a success. Contract 2 is met.

### Finding 8 (LOW) — the checkpoint is stale by the time the copy runs

`app/lib/features/settings/domain/backup_service.dart:49-61`

The `wal_checkpoint(FULL)` at `:49` fires before the directory picker at `:54-56`, which can sit open indefinitely. Any write landing during that window is WAL-only at `:61` and silently absent from the exported file. In practice the picker is a separate Android activity and the only writer is the blocked UI, so exposure is small — but moving the checkpoint to just after the picker returns costs nothing.

The directory-picker-instead-of-save-dialog deviation from spec 09 line 23 is documented and justified at `file_dialog_service.dart:19-26` (`file_selector_android` has no `getSaveLocation`) — accepted.

---

## 3. Hydration & persistence

All five fields round-trip (`settings_prefs_service.dart:42-102`, tests `settings_prefs_service_test.dart:24-77`). First frame reflects persisted values — `main.dart:10` awaits `settingsHydrationProvider.future` before `runApp`. Listener wiring is correct and, importantly, registered *after* the initial applies (`settings_hydration.dart:26-36` then `:38-61`), so hydration doesn't echo itself back to disk. Unrecognised theme names degrade to `null` rather than throwing (`settings_prefs_service.dart:46-55`, test at `settings_prefs_service_test.dart:79-87`). Contract 3 met.

### Finding 4 (MEDIUM) — a settings-load failure prevents the app from starting at all

`app/lib/main.dart:6-17`, `app/lib/core/settings/settings_hydration.dart:22-24`

`await container.read(settingsHydrationProvider.future)` has no error handling, and `prefs.load()` (`:24`) is a platform-channel call that can throw — corrupted preference store, plugin registration failure, a `getString` on a key whose stored type changed. If it throws, the exception escapes `main()` and `runApp` is never reached: a black screen with no route to recovery, because the persistence layer is the thing that's broken. Wrap the hydration await in a try/catch and fall back to defaults; failing to read settings should degrade the settings, not the app.

---

## 4. Theme picker

`theme_picker_row.dart` renders all 7 `AppThemeId` values, tap wires straight to `themeProvider.notifier.setThemeId` (`:54-55`), and persistence rides the hydration listener — asserted end-to-end at `theme_picker_test.dart:42-46`. The Dynamic-unavailable path is handled twice and consistently: the swatch falls back to `ColorScheme.fromSeed` when `dynamicScheme` is null (`theme_picker_row.dart:38-47`), and the applied theme falls back the same way (`app_theme.dart:10-17`, `:31-38`) using the documented fallback seed (`seed_colors.dart:47-48`). Selecting Dynamic on a device without dynamic colour is a no-visual-change but correctly-persisted selection — acceptable and matches ADR-0003. Contract 4 met.

## 5. Notifications toggle

`notifications_enabled_provider.dart` is unchanged in behaviour — same `cancelAll`/`rescheduleAll` branch (`:19-26`), same error swallowing. The settings screen just calls `setEnabled` (`settings_screen.dart:141-143`). The only new interaction is hydration calling `setEnabled` at startup (`settings_hydration.dart:31-32`), which is a no-op when the persisted value equals the default thanks to the `if (state == enabled) return` early-out at `:16`. Contract 5 met.

## 6. Copy / About

All settings-screen strings go through `AppStrings`. The joke button is ported faithfully — `AboutPage.xaml.cs:23` `"My Website"` / `"Coming... soon?"` / `" OH - OK"` maps to `superhero_strings.dart:260-264`; tagline and copyright match `AboutPage.xaml:43` and `:163`.

### Finding 10 (LOW) — About drops two pieces of MAUI copy and hardcodes the chip labels

`app/lib/features/settings/presentation/widgets/about_section.dart:15`, `:110-114`

`_InfoGrid` ports Version/Build/Package but omits the **Developer / "Philip Reese"** row (`AboutPage.xaml:104-111`) and the "Application Info" card header (`:69`). Last Backup moved to the backup section, which is a reasonable relocation, but the Developer row just vanished. Separately, `_techStack` (`:15`) is a hardcoded literal list of user-visible strings, which conflicts with spec 09 line 26 ("All copy via AppStrings") — the contents are correctly updated to the new stack, they're just not flavourable.

---

## 7. Tests

The good news first: **the failure-path tests are real**, which is the thing this contract most needed checking. `backup_service_test.dart:159-187` uses actual garbage bytes and asserts no backup was staged; `:189-206` builds a genuine sqlite file with the wrong tables; `:208-240` provokes a real mid-swap I/O failure by occupying the staging path and then asserts the *content* ('Keep Me') survived through a fresh provider read. That is not happy-path theatre.

### Finding 5 (MEDIUM, test-coverage) — nothing pins `resolveDatabaseFile()` to the file drift actually opens

`app/lib/core/database/database_file_locator.dart:12-15`, `app/test/backup_service_test.dart:68-71`

The entire export/import feature rests on the claim in the comment at `database_file_locator.dart:8-11` — that `driftDatabase(name: kDatabaseName)` resolves to `<app documents>/chore_buddy.sqlite`. That claim is enforced by nothing. Every test overrides `appDatabaseProvider` with `AppDatabase(NativeDatabase(dbFile))` pointed at the very path `resolveDatabaseFile()` returns, so the production wiring is assumed, not exercised. If `drift_flutter` changes its default directory (or a future `DriftNativeOptions` is added), export silently returns `false` forever and import writes a file the app never opens — a "successful" import that discards the user's chosen backup — and the whole suite stays green. This is prose standing in as enforcement. A test that constructs a default `AppDatabase()` under a faked `PathProviderPlatform`, writes a row, and asserts `await (await resolveDatabaseFile()).exists()` would close it.

### Finding 6 (MEDIUM, test-coverage) — step 8 is asserted as a call count, not as behaviour, and the backup-created assertion is inverted

`app/test/backup_service_test.dart:134-157`

`rescheduleAll` is verified only as `rescheduleAllCallCount == 1` against `FakeNotificationService` (`fake_notification_service.dart:29-31`), which never touches a database. The real `NotificationServiceImpl` holds `db` as a captured field (`notification_service.dart:30`, `:68`), so whether `rescheduleAll` reads the *imported* data or a closed handle depends entirely on `ref.read(notificationServiceProvider)` at `backup_service.dart:130` seeing the invalidation from `:127` and rebuilding. That is the single most consequential ordering assumption in the flow and no test touches it. A test using the real `NotificationServiceImpl` with a fake `NotificationScheduler`, asserting the scheduled chore ids come from the imported file, would.

Also: spec 09 line 32 asks that the test prove "backup file created". The only assertions are `expect(await backupFile.exists(), isFalse)` at `:156` and `:235` — i.e. that it's *cleaned up*. Nothing anywhere proves `.pre-import.bak` was ever written, which is the safety net finding 1 is about.

### Finding 11 (LOW, test-coverage) — `SettingsScreen` has no widget test

There is no test for `settings_screen.dart` at all. The `_busy` guard, the confirmation-dialog gate before a destructive import, the success/failure dialog routing, and the last-backup label all ship unverified. This is also why finding 3's late `_busy` assignment went unnoticed.

---

## Non-findings / observed, not counted against the slice

- `showDetailsOnCards` defaults to `true` in the new persistence layer (`settings_prefs_service.dart:17`) while MAUI defaulted `ShowHistoryOnCardsKey` to **false** (`SettingsService.cs:39`). The divergence originates in `ShowDetailsOnCardsNotifier.build()` (`chore_providers.dart:86`), which predates this slice — slice 09 only mirrors it. Flagging for the parity ledger, not as a slice-09 defect.
- `AppThemeIdExtension.displayName` (`seed_colors.dart:14-31`) is user-visible copy outside `AppStrings`, also pre-existing.
- `database_provider.dart:11-22`'s guarded fire-and-forget dispose is the right response to the review-02 caveat: import closes explicitly and awaits, and the dispose close is a no-op whose error is swallowed deliberately.
- Streams erroring during the close→invalidate window is expected and self-heals via `ref.watch` on rebuild; no action needed.

## Required before this passes

Finding 1 only. Findings 2–4 are strongly recommended in the same pass since they sit in the same two functions.
