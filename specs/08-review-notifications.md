# Spec 08-review — Adversarial review of notifications

## Role

Review. Read-only. Write `report.md` and `verdict.json` to `$AER_OUTPUT_DIR`. ONE-SHOT: complete synchronously. verdict.json fields flat strings/bools/numbers; severity values exactly one of: "high", "medium", "low", "info".

## Subject (committed at HEAD, slice 08)

- `app/lib/core/notifications/` (4 files), `app/android/app/src/main/AndroidManifest.xml`, `app/android/app/src/main/res/drawable/ic_notification.xml`
- Wiring diffs in: `completion_flow.dart`, `chore_detail_screen.dart`, `chores_screen.dart`, `app_shell.dart`, `archived_chore_card.dart`, `archive_screen.dart`, `app_database.dart`, `app.dart`
- Tests: `notification_service_test.dart`, `fakes/fake_notification_service.dart`, updated widget tests

## Contract (verify adversarially vs `ChoreBuddy/Services/NotificationService.cs`, `App.xaml.cs:78-88`, behavior-inventory §Notifications, specs/08)

1. Four gates exact: global off / per-chore off / no due date / past due → cancel-instead-of-schedule in each case.
2. id = chore id everywhere; replace semantics (no duplicate notifications after N reschedules); payload carries chore id.
3. EVERY due-date-affecting mutation reschedules or cancels: save (both modes), completion, undo, archive, restore, delete, purge-all, global toggle both directions. Trace each call site — a missed one is a stale alarm.
4. Tap-to-scroll works from foreground AND cold launch; the pending-tap provider is consumed exactly once (no re-scroll on rebuild).
5. Timezone correctness: how is the local due DateTime converted for zonedSchedule? tz database initialized before first use? A due date at 14:00 local must fire at 14:00 local, including across DST.
6. Exact-alarm fallback: denied exact-alarm permission degrades to inexact, never crashes; POST_NOTIFICATIONS runtime request path sane on Android 13+ and pre-13.
7. The catch-all no-op degradation in the scheduler: verify it can't swallow errors silently in a way that masks total notification failure with no signal at all (a debug log at minimum).
8. Boot receiver: manifest-registered and actually able to reschedule (does the plugin's receiver restore zonedSchedule alarms by itself, or does the app need explicit ScheduledNotificationBootReceiver config? verify against the package's requirements).

## Also hunt for

- `completion_flow.dart:51-53` and the undo path schedule with `chore.chore.copyWith(nextDueDate: ...)` — the OTHER fields (isNotificationEnabled especially) come from the card's stale snapshot. Can a just-toggled-off reminder get rescheduled by a completion from a stale card?
- rescheduleAll: does it also cancel notifications for chores that now fail the gates (or only schedule passers)?
- The notification tap while app is on the details route: does scroll-to-chore navigation fight the router state?
- Test fakery per usual.

## Verdict

Fail on any contract breach, missed reschedule call site, or a path that leaves a stale/duplicate alarm. findings with file:line.
