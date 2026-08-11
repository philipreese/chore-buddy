# Spec 09-review — Adversarial review of settings and backup hot-swap

## Role

Review. Read-only. Write `report.md` and `verdict.json` to `$AER_OUTPUT_DIR`. ONE-SHOT. verdict.json fields flat; severity exactly one of "high"/"medium"/"low"/"info".

## Subject (committed at HEAD, slice 09)

- `app/lib/core/settings/` (2), `app/lib/core/database/database_file_locator.dart`, `app/lib/features/settings/` (domain 2, providers 1, presentation 4), `app/lib/main.dart`, `app/lib/core/database/{app_database,database_provider}.dart` diffs
- Tests: `backup_service_test.dart`, `settings_hydration_test.dart`, `settings_prefs_service_test.dart`, `theme_picker_test.dart`, fakes

## Contract (vs specs/09, proposal §2.4, MAUI SettingsPage/MigrationService, review-02's close() caveat)

1. **Import is the priority — it can destroy the user's data.** Verify the §2.4 sequence exactly: integrity check on the CANDIDATE (read-only, cannot touch live db), pre-import backup created BEFORE any mutation of the live file, explicit checkpoint+close of the live connection BEFORE file replace (not relying on the fire-and-forget provider dispose noted in docs/reviews/02), atomic replace, invalidate, rescheduleAll. Hunt: any window where a failure leaves neither the old nor new db usable; the backup-restore path itself failing; import of a MAUI-era .db3 (different schema — MUST be rejected by the table check, not half-accepted); a second import racing the first; streams/queries in flight during the swap.
2. Export: WAL checkpoint before copy (a missed checkpoint exports a stale main file); timestamp persisted only on success.
3. Hydration: all five fields round-trip; first frame reflects persisted values; a changed setting persists (listener wiring); corrupted/missing prefs default sanely.
4. Theme picker: selection updates + persists; Dynamic option behavior when dynamic colors unavailable.
5. Notifications toggle wiring unchanged in behavior (cancelAll/rescheduleAll).
6. All copy via AppStrings; About ports the MAUI copy incl. the joke button.
7. Tests test what they claim; the import failure-path tests genuinely exercise failure (not just happy path with a fake that can't fail).

## Verdict

Fail on any data-loss window in import/export or contract breach. findings with file:line.
