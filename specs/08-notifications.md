# Spec 08 — Local notifications and boot rescheduling

## Role

Implement. Report to `$AER_OUTPUT_DIR/changes.md`. You are ONE-SHOT: run everything to completion synchronously this turn; write changes.md before finishing.

## Environment (stripped — set before builds)

- `ANDROID_HOME=C:\Android\sdk`, `ANDROID_NDK_HOME=C:\Android\sdk\ndk\28.2.13676358`, `JAVA_HOME=C:\Program Files\Android\openjdk\jdk-21.0.8`
- Flutter `C:\src\flutter\bin\flutter.bat`, Dart `C:\src\flutter\bin\dart.bat`

## Context (read first)

- `docs/behavior-inventory.md` §Notifications — the contract. MAUI reference: `ChoreBuddy/Services/NotificationService.cs`, `ChoreBuddy/App.xaml.cs:78-88` (tap → scroll-to-chore), `ChoreBuddy/Platforms/Android/AndroidManifest.xml` (permissions).
- Existing: `// TODO(slice-08)` hook in `completion_flow.dart`; per-chore `isNotificationEnabled` flag persisted (slice 06); chore save paths in `chore_detail_screen.dart`/`app_database.dart`; `chores_screen.dart` list (scroll target).
- ADR-0005 defers the notification "Complete" ACTION BUTTON to slice 10 — this slice is scheduling + tap-to-open only.

## Scope (all inside `app/`) — package `flutter_local_notifications` is explicitly allowed (the ONLY new package; add its timezone dep if required)

1. **NotificationService** (interface + real impl behind a provider, fully fakeable):
   - `scheduleForChore(chore)`: one-shot exact notification at the due instant, **notification id = chore id** (cancel/replace semantics), flavored title/body via AppStrings.
   - Gates (all four, matching MAUI): global toggle off, per-chore flag off, no due date, due date in the past → cancel any existing instead.
   - `cancelForChore(id)`, `cancelAll()`, `rescheduleAll()` (reads all active chores, applies the gates).
2. **Wiring** — every mutation that changes a due date or relevant flag reschedules: chore save (insert/update), completion (the slice-05 TODO), undo, archive (cancel), restore (reschedule), delete (cancel), purge-all (cancel those ids). Global toggle off → `cancelAll()`, on → `rescheduleAll()` (`notificationsEnabledProvider`, default on; Settings UI is slice 09).
3. **Tap → scroll-to-chore (PRESERVE)**: notification tap opens the app on the Chores tab and scrolls the list to that chore. Payload = chore id; handle both foreground tap and app-launch-from-notification (`getNotificationAppLaunchDetails`).
4. **Android setup**: manifest permissions (`POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`), plugin boot receiver for reschedule-after-reboot, runtime permission request on first schedule attempt (Android 13+), notification channel with flavored name, small icon (reuse launcher icon or add a monochrome drawable).
5. Exact-alarm fallback: if exact alarms are not permitted (Android 14 default-deny), fall back to inexact scheduling rather than crashing — note the behavior in changes.md.

## Tests

- Unit tests for the gating logic with a fake plugin/scheduler: each of the four gates; schedule uses id = chore id; reschedule-on-save/completion/undo/archive/restore paths call the right service methods (verify via the fake).
- Widget test: completion flow triggers a reschedule call (fake service injected).
- Real device scheduling is untestable here — state it; keep the plugin behind the interface so nothing in the test suite touches platform channels.

## Done criteria

- `flutter analyze` clean; `flutter test` fully green (89 existing + new); `flutter build apk --debug` succeeds (manifest/plugin integration check); output in changes.md.
- `$AER_OUTPUT_DIR/changes.md` lists files, deviations, and the exact-alarm fallback behavior.

## Do NOT

- No notification action buttons (slice 10). No Settings UI (slice 09). No other packages. Nothing outside `app/`.
