# Adversarial review A — data layer & background paths (PR #24, slices 10–25)

## Role

Review. You are an adversarial reviewer: your job is to FIND REAL BUGS, not to summarize. Write findings to `$AER_OUTPUT_DIR/report.md` and the verdict to `$AER_OUTPUT_DIR/verdict.json`. Past reviews on this repo caught DST recurrence corruption and a disk-full import that destroyed intact data — that is the bar. A review that only says "looks good" without demonstrating hostile probing is a failed review.

## Scope

Branch `20-device-feedback-round-1-polish-theme-simplification-identity` vs `main` (`git diff main...HEAD`), restricted to the DATA & BACKGROUND domain:

- `app/lib/core/database/` — schema v1→v4 migrations (tags.emoji, chores.recurrence_interval, chores.emoji), raw-SQL watch queries, DriftRemoteException unwrapping
- `app/lib/features/settings/domain/backup_service.dart` + auto-backup — file-copy backup/restore across schema versions, corrupt/legacy imports
- `app/lib/features/chores/domain/` — recurrence_calculator (customDays, DST, month clamping), snooze_service (targetDate), completion_service, stats_calculator (week boundaries, streak/grace, median cadence), icon_guesser
- `app/lib/core/notifications/` — scheduling, background completion/snooze action paths, channel re-creation on voice change
- `app/lib/core/home_widget/widget_sync_service.dart` + `app/android/.../widget/` — payload writing, emoji prefixing, RemoteViews layouts
- `app/lib/core/voice/voice_command_service.dart` — intent parsing, duplicate handling
- `app/lib/core/strings/voice_provider.dart` persistence (stale/unknown persisted values)

## Hostile questions to actually chase (non-exhaustive — add your own)

1. Migrations: can any upgrade path (v1→v4 direct, v2→v4, v3→v4) double-add a column or skip one? What does a DOWNGRADE (newer db file imported via backup into an older... or current) do — is user_version trusted blindly?
2. Backup import: what happens importing a v4 backup, a corrupt file, a file that is valid sqlite but not this app's schema? Is there still a window where a failed import leaves the live db destroyed?
3. Recurrence: customDays interval 365 across a DST boundary; monthly on Jan 31; completing an overdue chore twice quickly; interval null via hand-edited row.
4. Snooze targetDate: date-only anchoring vs stored time-of-day across DST; snoozing a chore with no due date; background (notification) snooze racing a foreground snooze.
5. Stats: week boundary exactly Monday 00:00; completions with identical timestamps; streak when recurrence changed between completions; median with 2 vs 3 completions; heatmap on a month whose 1st is Monday vs Sunday.
6. Widget sync: chore names containing emoji already; very long names + emoji prefix; kWidgetMaxEntries overflow ordering.
7. Voice change: notification channel rename timing; widget sync failure mid-change; persisted voice value from a future version (unknown enum name).
8. Voice/intent parsing: malformed extras, absent extras, duplicate chore names.

## Method requirements

- Read the actual diff and the surrounding unchanged code — bugs live at the seams.
- For each suspected bug, WRITE A MINIMAL REPRO ARGUMENT (inputs → wrong behavior) referencing exact file:line; speculation clearly labeled as such.
- You may run `flutter test` (foreground; healthy suite ~30s) and add throwaway probe tests in a scratch file to CONFIRM a suspicion, but do NOT leave any workspace modifications: `git status` must be clean at the end (checkout/delete your probes).
- verdict.json: {"verdict": "PASS" | "FAIL", "blocking_findings": <count>} — FAIL if any finding is data-loss, data-corruption, crash, or silently-wrong-schedule severity.

## Output contract

- `$AER_OUTPUT_DIR/report.md`: findings ordered by severity (Blocking / Should-fix / Nit), each with file:line, repro argument, and suggested fix direction.
- `$AER_OUTPUT_DIR/verdict.json` as above.
