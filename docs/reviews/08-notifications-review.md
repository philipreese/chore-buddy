# Slice 08 review — local notifications and boot rescheduling

**Ref:** `18-migrate-chorebuddy-from-net-maui-to-flutter-android-only` @ `83f19b1` (slice 08 implementation is `6c40b46`)
**Verdict: FAIL** — one PRESERVE-tagged behavior (tap → scroll to chore) does not work for the common case, and the widget test that nominally covers it cannot fail. Two further defects leave a stale/incorrect alarm reachable.

The scheduling core is genuinely good: the gate order, cancel/replace semantics, id discipline, timezone handling and exact-alarm fallback all check out against the MAUI original. The problems are in the tap path and in two "captured snapshot" / "latch set too early" mistakes.

---

## Contract walkthrough

### 1. Four gates — PASS

`notification_service.dart:40-58` cancels unconditionally *first* (`:41`) and then returns early on global-off (`:43`), per-chore-off (`:44`), null due date (`:47`), past due date (`:48`). This is an exact structural match for `ChoreBuddy/Services/NotificationService.cs:28-45`, including the "cancel instead of schedule" property in all four cases. Covered by real tests at `notification_service_test.dart:132-169`, each asserting both `scheduled` empty and `canceled` containing the id.

One deliberate divergence from MAUI, correct: `NotificationService.cs:67-72` guards `choreId <= 0`; the Dart version does not need to, since ids come from drift autoincrement.

### 2. id = chore id, replace semantics, payload — PASS

`notification_service.dart:52` (`id: chore.id`) and `:56` (`payload: chore.id.toString()`); parsed back at `app.dart:41`. Every call site funnels through `scheduleForChore`/`cancelForChore(choreId)`, so there is no path that invents an id. `scheduler.cancel(chore.id)` before every schedule plus same-id replace in the plugin means N reschedules leave exactly one pending alarm. Asserted at `notification_service_test.dart:124-129`.

### 3. Every due-date-affecting mutation — PASS (all sites traced)

| Mutation | Site | Call |
|---|---|---|
| Save (insert) | `chore_detail_screen.dart:186-194`, `:211-214` | `scheduleForChore(saved)` re-read from DB |
| Save (update) | `chore_detail_screen.dart:199-208`, `:211-214` | same |
| Completion | `completion_flow.dart:54-56` | `scheduleForChore(copyWith(nextDueDate))` — see F2 |
| Undo | `completion_flow.dart:73-77` | same — see F2 |
| Archive | `chore_card.dart:99-100` | `cancelForChore` |
| Delete | `chore_card.dart:102-103` | `cancelForChore` |
| Restore | `archived_chore_card.dart:45-48` | `scheduleForChore` (gates re-cancel if the due date is now past) |
| Purge-all | `app_shell.dart:43-47` | ids snapshotted *before* the delete, then cancelled — correct ordering |
| Global toggle on/off | `notifications_enabled_provider.dart:19` | `rescheduleAll()` / `cancelAll()` |

I looked for a missed site and did not find one. `completeChoreFlow` has exactly one caller (`chore_card.dart:245`). `updateCompletionRecord` / `deleteCompletionRecord` (`app_database.dart:248-254`) touch only the `completionRecords` table and never recompute `nextDueDate`, so the record edit/delete paths in the detail screen correctly need no reschedule. `archiveChore`/`restoreChore`/`deleteChore`/`deleteArchivedChores` have no callers other than the four listed above (`app_database.dart:220-240`).

`rescheduleAll` (`notification_service.dart:67-72`) delegates to `scheduleForChore` per chore, so it **does** cancel gate-failers rather than only scheduling passers — `notification_service_test.dart:210` asserts exactly that for the past-due and reminder-off rows. Archived chores are excluded, which is right: their alarms were cancelled at archive time.

### 4. Tap → scroll — **FAIL** (F1)

Foreground taps (`notification_scheduler.dart:76-78` → `app.dart:40-45`) and cold launch (`app.dart:36-37` via `getNotificationAppLaunchDetails`) both feed the same provider, and `app.dart:53-57` switches to the chores branch. That wiring is right. The consumption is not — see F1 below.

The routing question raised in the brief is fine: `router.go('/chores')` on a `StatefulShellRoute` branch resets that branch's navigator to its root, so a tap while sitting on `/chores/5` pops the detail screen and lands on the list. No fight with router state, no double navigation (the chores-screen listener only scrolls, it never navigates).

### 5. Timezone — PASS

`notification_scheduler.dart:127` converts via `tz.TZDateTime.from(scheduledDate.toUtc(), tz.UTC)`. The comment is accurate: `TZDateTime.from` converts through the absolute instant, and `DateTime(y,m,d,h,m)` built at `chore_detail_screen.dart:171-177` already carries the correct UTC offset *for that future local date* (Dart resolves the zone rules at construction), so a 14:00 local due date in November scheduled in August still resolves to the right instant across a DST boundary. The plugin passes the instant to `AlarmManager` as epoch millis, so nothing re-derives wall-clock fields later. `tz_data.initializeTimeZones()` runs at `:67`, before any `TZDateTime` construction; and `tz.UTC` is a built-in `Location` that does not depend on the database anyway, so even a schedule that races ahead of `initialize()` is safe.

Residual (info, matches MAUI): the alarm is pinned to an absolute instant, so if the user changes device timezone after scheduling, it fires at the original instant rather than re-anchoring to 14:00 in the new zone.

### 6. Exact-alarm fallback / POST_NOTIFICATIONS — PASS with a caveat (F3)

`notification_scheduler.dart:150-167` catches `PlatformException` with code `exact_alarms_not_permitted` — the correct code from `flutter_local_notifications` — and retries with `inexactAllowWhileIdle`; anything else rethrows into the outer catch, so no crash escapes either way. `SCHEDULE_EXACT_ALARM` is declared (`AndroidManifest.xml:49`) and `USE_EXACT_ALARM` correctly is not (this is not an alarm-clock app; it would be a Play policy violation).

Runtime permission: `_requestPermissionsOnce` (`:173-185`) is invoked lazily from the first schedule attempt, which is what the spec asked for. `requestNotificationsPermission()` is a no-op-returning-true below API 33 in the plugin, so the pre-13 path is sane. Caveat in F3.

Minor (info): the permission result is discarded, so a denied POST_NOTIFICATIONS still schedules an alarm that Android silently drops at fire time, with no signal to the user or the log.

### 7. Catch-all degradation — PASS, narrowly

Every `catch` in `notification_scheduler.dart` (`:93`, `:105`, `:168`, `:182`, `:191`, `:200`) emits a `debugPrint` with the exception *and* stack trace. `debugPrint` is not stripped in release, so total notification failure does leave a log trail — the contract's "a debug log at minimum" bar is met. It is still invisible above the scheduler (the `NotificationService` API is all `Future<void>` and cannot report failure), which is a deliberate and defensible trade: a completion must not fail because a reminder could not be scheduled.

### 8. Boot receiver — PASS

`AndroidManifest.xml:37-45` declares both `ScheduledNotificationReceiver` and `ScheduledNotificationBootReceiver`, the latter with `BOOT_COMPLETED`, `MY_PACKAGE_REPLACED` and both QUICKBOOT actions, plus `RECEIVE_BOOT_COMPLETED` at `:50`. That is the configuration `flutter_local_notifications` documents for reschedule-after-reboot: the plugin persists each `zonedSchedule` request and its boot receiver replays them into `AlarmManager` — the app does not need to run any Dart on boot, and correctly does not try to. The declarations are redundant with the plugin's own manifest in v22 (they merge cleanly since the attributes match), so this is belt-and-braces rather than a defect. `ic_notification.xml` exists and is referenced consistently at `:70` and `:133`.

---

## Findings

### F1 — HIGH — Tap-to-scroll silently no-ops for any chore outside the built viewport, and consumes the pending id anyway

`app/lib/features/chores/presentation/chores_screen.dart:26-41`

```dart
void _scrollToChore(int choreId) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final key = _itemKeys[choreId];
    final context = key?.currentContext;
    if (context != null) { Scrollable.ensureVisible(...); }
    if (mounted) { ref.read(notificationTapChoreIdProvider.notifier).clear(); }   // :37-39
  });
}
```

`_itemKeys` is populated by `_keyFor` from inside `ListView.builder`'s `itemBuilder` (`:73`), so a `GlobalKey` only acquires a `currentContext` once that row has actually been built — i.e. only for rows in or near the current viewport. `Scrollable.ensureVisible` is therefore unreachable for exactly the chores a user needs it for: the ones far enough down the list that they are not already on screen. Worse, the `clear()` at `:38` runs unconditionally on the same frame, so the pending id is consumed whether or not the scroll happened; there is no retry on the next frame and no fallback.

Failure scenario: 40 chores; the notification for chore #35 fires; the user taps it. `app.dart:55` switches to the chores branch, the listener at `:49-53` fires `_scrollToChore(35)`, the post-frame callback finds `_itemKeys[35] == null` (row never built), does nothing, and clears the provider. The user lands at the top of an unscrolled list. This is the `PRESERVE`-tagged MAUI behavior from `behavior-inventory.md:83` ("Tap → open app → scroll chore list to that chore") and it does not work.

The cold-launch variant is the same and slightly worse: `_initNotifications` resolves the launch payload asynchronously after the first frame, so the list is freshly mounted at scroll offset 0 with only the first screenful built.

Fix direction: drive the scroll from the item's *index* in the resolved `chores` list with a `ScrollController`/`ItemScrollController` (index → offset works for unbuilt rows) rather than from a `GlobalKey`'s context, and only clear the provider once the target has actually been resolved.

### F2 — MEDIUM — Completion and undo reschedule from a stale chore snapshot; the undo window is long enough for the snapshot to be wrong

`app/lib/features/chores/presentation/completion_flow.dart:54-56` and `:73-77`

Both calls build the entity as `chore.chore.copyWith(nextDueDate: Value(...))`. Only `nextDueDate` is refreshed; `isNotificationEnabled`, `name` (used for the notification title at `notification_service.dart:53`) and everything else come from the `ChoreWithDetails` captured when `ChoreCard` last built.

For the completion at `:54` the window is effectively closed — the modal completion dialog blocks any competing mutation — so that call is fine in practice.

The undo at `:73-77` is not. The snackbar action runs up to 5 seconds later and, importantly, `messenger` is the root `ScaffoldMessenger` (`:60`), so the snackbar survives `context.push('/chores/<id>')` onto the detail screen. Reachable sequence:

1. Complete chore 7 → snackbar with Undo appears, 5s timer starts.
2. Tap chore 7 → detail screen → toggle the reminder off → Save. `chore_detail_screen.dart:213` re-reads from the DB and correctly cancels the alarm.
3. Tap **Undo** on the still-visible snackbar. `completion_flow.dart:73` schedules `chore.chore.copyWith(...)` with the pre-edit `isNotificationEnabled == true` — the per-chore gate at `notification_service.dart:44` passes, and a reminder the user just switched off is resurrected.

The same shape re-arms a *pre-edit due date* if step 2 changed the date instead of the flag: undo writes `token.previousNextDueDate` back, and the stale snapshot's other fields go along with it, leaving an alarm that no longer matches the persisted chore. Answering the brief's question directly: yes, a just-toggled-off reminder can be rescheduled by the undo path from a stale card snapshot.

Fix direction: in the undo callback, re-read the chore (`db.getChoreById(chore.chore.id)`) after `undoCompletion` and schedule from that, exactly as the save path already does at `chore_detail_screen.dart:211-214`.

### F3 — MEDIUM — `_initialized` / `_permissionRequested` latch before the work they guard, so one transient failure disables the feature for the process

`app/lib/core/notifications/notification_scheduler.dart:61-62` and `:174-175`

```dart
if (_initialized) return;
_initialized = true;      // set BEFORE the try
try { ... await _plugin.initialize(...); } catch (e, st) { debugPrint(...); }
```

If `_plugin.initialize` throws — a plugin registration hiccup, a channel-creation failure on an OEM build — the flag is already `true`, so a later `initialize()` returns immediately without retrying. The consequence is specific and bad: `onDidReceiveNotificationResponse` was never registered, so **every foreground notification tap is dead for the rest of the process**, with only a `debugPrint` as evidence. The notification channel may also be missing, in which case `Importance.high` posts are silently downgraded/dropped by Android.

`_requestPermissionsOnce` has the identical shape at `:174-175`: the latch is set before the awaited request, so a throwing/interrupted permission dialog is never retried and the user is never asked again this process — subsequent schedules then quietly produce alarms that Android discards.

Fix direction: set the latch in the success path (or in a `finally` only for the genuinely idempotent case), and on failure leave it false so the next attempt retries.

### F4 — MEDIUM — The tap-to-scroll widget test cannot fail

`app/test/chores_screen_test.dart:341-364`

The test inserts **one** chore, sets the provider, pumps, and asserts `find.text('Tapped Chore')` is present and the provider is null. The first assertion holds whether or not any scrolling occurred (a single-item list is trivially on screen); the second only proves `clear()` ran, which F1 shows happens unconditionally. There is no assertion on scroll offset, no `ensureVisible` observation, and no list long enough to require scrolling — so the test passes verbatim against an implementation where `_scrollToChore`'s body is deleted apart from the `clear()`. It is precisely the test that should have caught F1.

Fix direction: insert ~40 chores, assert the target row is off-screen before the tap (`findsNothing` / `hitTestable`), then assert it is visible after — or assert the scroll position changed.

### F5 — LOW — Failed consumption of the pending tap id can wedge repeat taps for the same chore

`app/lib/core/notifications/notification_tap_provider.dart:12-14`, `app/lib/features/chores/presentation/chores_screen.dart:37-39`

`clear()` is guarded by `if (mounted)`. If `ChoresScreen` is disposed between the listener firing and the post-frame callback, the id is never cleared. `NotifierProvider` suppresses same-value updates, so a *second* tap on the same chore's notification (`set(choreId)` with an unchanged value) notifies nobody — `app.dart:53` never navigates and `chores_screen.dart:49` never scrolls. Tap-to-open is then silently dead for that chore id until the value happens to change. Narrow window, but the failure is sticky and silent.

Fix direction: clear the provider from the listener side after handling, or have `set` reset to null first / use an incrementing request token so identical ids always notify.

### F6 — LOW — Fire-and-forget global toggle discards errors

`app/lib/core/notifications/notifications_enabled_provider.dart:19` wraps `rescheduleAll()`/`cancelAll()` in `unawaited(...)` with no `catchError`. `NotificationServiceImpl.rescheduleAll` awaits `db.getActiveChores()` (`notification_service.dart:68`), which is not inside the scheduler's catch-all — a DB failure there becomes an unhandled async error. I checked the off→on→off interleaving the brief implies: it is benign, because `scheduleForChore` re-reads `notificationsEnabledProvider` per iteration (`:43`), so any iteration running after a subsequent toggle-off cancels rather than schedules, and `cancelAll` mops up anything already scheduled. No stale alarm — just an unguarded async error path.

### F7 — INFO — Untestable surfaces are genuinely untested, as the spec allowed

Nothing covers the timezone conversion (`notification_scheduler.dart:127`), the exact-alarm fallback (`:150-167`), the permission request, or boot rescheduling. Spec 08 line 33 explicitly permits this ("Real device scheduling is untestable here — state it"), and the interface boundary does keep the suite off platform channels. Worth stating plainly rather than treating as covered: **the exact-alarm fallback and boot rescheduling have not been executed, only read**. The fallback in particular depends on an error-code string (`exact_alarms_not_permitted`) that a plugin upgrade could rename with no compile-time or test-time signal.

---

## Test integrity

Apart from F4, the tests are honest. `FakeNotificationScheduler` (`notification_service_test.dart:31-74`) and `FakeNotificationService` (`fakes/fake_notification_service.dart`) both `implements` the real interfaces, record arguments rather than just call counts, and are asserted against with real content — ids, payloads, dates. The gating tests assert both halves of each gate (nothing scheduled *and* a cancel issued), which is the assertion that actually pins "cancel instead of schedule". `notification_service_test.dart:200-211` uses a real in-memory drift database and verifies the archived chore is excluded from `rescheduleAll`, which is a real behavioral claim. Widget-level coverage exists for save (`chore_detail_screen_test.dart:111`, `:429`), completion and undo (`completion_flow_test.dart:127`, `:209-213`), archive and delete (`chores_screen_test.dart:185`, `:247`), restore (`archive_screen_test.dart:117`) and purge (`archive_screen_test.dart:164`) — that is the full call-site matrix from contract item 3, which is why I have reasonable confidence no site is missing.

`chore_detail_screen_test.dart:429-430` deserves a nod: it asserts that saving with the reminder *off* still calls `scheduleForChore` (with `isNotificationEnabled: false`), i.e. that the cancel-through-the-gates path is exercised rather than short-circuited at the call site. That is the right shape.
