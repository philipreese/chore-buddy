# Spec 28 — Device feedback round 5: voice dropdown, icon polish, time-based overdue, exact alarms

## Role

Implement. Report to `$AER_OUTPUT_DIR/changes.md`. ONE-SHOT: complete synchronously; write changes.md before finishing. Run `flutter test` FOREGROUND to a log file (healthy ~30s; minutes = failures, each stalls ~10min in teardown; never pipe through tail/head).

## Environment (stripped — set before builds)

- `ANDROID_HOME=C:\Android\sdk`, `ANDROID_NDK_HOME=C:\Android\sdk\ndk\28.2.13676358`, `JAVA_HOME=C:\Program Files\Android\openjdk\jdk-21.0.8`
- Flutter `C:\src\flutter\bin\flutter.bat`, Dart `C:\src\flutter\bin\dart.bat`

## Items (Philip's on-device feedback + two findings from the notification-fix investigation)

### 1. Voice picker becomes a dropdown

Replace the settings Voice section's column of nine radio rows with a single dropdown-style control (e.g. `DropdownMenu` or an `ExposedDropdown`-style field): collapsed state shows the current voice's glyph chip + display name; the expanded menu lists all nine with glyph + name (signature line optional in menu entries if it fits cleanly — dropping it there is fine, it's on the collapsed row's subtitle if anywhere). Selection semantics unchanged (instant apply, persisted). Keep the voice-dependent section header as is.

### 2. Icon grid: bigger glyphs

The 48-icon grid sheet's emoji render too small relative to their cells — bump the glyph font size noticeably (target roughly 60-70% of cell height) while keeping 6 columns and comfortable tap targets.

### 3. Icon picker field layout

In the chore editor, the icon control currently shows label above, chip, and a two-line helper caption below ("Shown on this thread's card"), which makes the row tall and lopsided next to the name field. Remove the helper caption entirely; vertically center the chip with the label (label + chip only). The name field and icon control should read as one aligned row.

### 4. Completion history rows span full width

In the chore detail screen's Completion History section, the record rows render at a fixed/intrinsic width instead of stretching to the screen width. Make them span the full available width (minus the screen's standard horizontal padding), matching the form fields above.

### 5. Overdue is time-based, not calendar-day-based

Philip: a chore due 10 minutes ago shows under "Due Today"; the widget correctly says overdue. `getDueSection` (due_status.dart) buckets by calendar day; the widget/card path (`getDueStatus`) compares against `now`. Unify: **overdue = nextDueDate < now** (same instant-based rule getDueStatus uses), Due Today = due today at or after now, Upcoming = after today, Unscheduled unchanged. This automatically fixes the banner stat chips and section headers (they share getDueSection). The list rebuilds on the existing ticker, so a chore crossing its due time moves to Overdue live — assert that in a test (fake clock stepping across the due instant). Check the Mission Log/stat tests for calendar-day assumptions and update.

### 6. Search popover height

The expanded search surface is slightly taller than the collapsed search/sort/filter row, so opening/closing search makes the header jump. Equalize the heights (pick one fixed height for both states of that row) so toggling search causes no vertical shift. Widget test: measure the header extent with search open vs closed, assert equal.

### 7. Exact alarms (from the notification investigation)

Reminders are currently scheduled inexactly — dumpsys shows `window=+1h`, so a reminder may legally arrive up to an hour late. Fix:
- Add `SCHEDULE_EXACT_ALARM` (and `USE_EXACT_ALARM` — this is a personal sideloaded app, Play policy is not a constraint) to the manifest.
- Schedule with `AndroidScheduleMode.exactAllowWhileIdle`, falling back to the current inexact mode if exact alarms are not permitted at runtime (`canScheduleExactNotifications` / plugin equivalent — do not crash on denial).
- State in changes.md which mode actually results on a fresh emulator install.

### 8. Background-isolate permission-request guard (from the same investigation)

`PluginNotificationScheduler._requestPermissionsOnce` runs during `zonedSchedule` and throws when invoked from the background isolate (notification-action completion path — no activity to request from). It's caught today, but guard it properly: skip the permission request when there is no foreground activity context (or track "already granted" via the existing settings prefs), so background rescheduling never even attempts it. The background completion path must schedule the next reminder without error output.

## Tests

Per item 5 the ticker-crossing test; per item 6 the extent-equality test; item 7's fallback logic unit-tested with a fake permission gate; item 8 covered by extending the background-completion test to assert no-throw and a scheduled next reminder. Everything existing stays green in normal time.

## Done criteria

- `flutter analyze` clean; `flutter test` green (~30s); `flutter build apk --debug` succeeds.
- changes.md maps each item → change + test, lists deviations/disputes.
- Nothing outside `app/` except AndroidManifest.xml for item 7.
