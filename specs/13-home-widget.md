# Spec 13 — Home-screen widget

## Role

Implement. Report to `$AER_OUTPUT_DIR/changes.md`. ONE-SHOT: complete synchronously; write changes.md before finishing.

## Environment (stripped — set before builds)

- `ANDROID_HOME=C:\Android\sdk`, `ANDROID_NDK_HOME=C:\Android\sdk\ndk\28.2.13676358`, `JAVA_HOME=C:\Program Files\Android\openjdk\jdk-21.0.8`
- Flutter `C:\src\flutter\bin\flutter.bat`, Dart `C:\src\flutter\bin\dart.bat`

## Context

The post-parity home-screen widget from `docs/proposals/00-new-stack-ideas.md` §3.2.2: overdue/today chores on the home screen with interactive complete checkboxes. Existing building blocks: `completeChoreFromNotification` in `app/lib/core/notifications/background_completion.dart` (background completion with its own db connection — REUSE this shape for widget-triggered completions), the four scheduling gates, `docs/reviews/08` lesson (always reschedule from a fresh row).

NOTE: you may be working in a git WORKTREE checkout in parallel with other slices — do not touch `specs/`, `docs/`, or anything outside `app/`; keep your diff tight. Strings go at the END of the strings files.

## Scope (all inside `app/`) — allowed new package: `home_widget`

1. **Widget UI** (native side): a RemoteViews-based AppWidget (ListView flavor) showing up to ~6 chores sorted by urgency — name + due state (overdue tinted) + a complete checkbox per row; a header with the app name and a "+" that deep-links to `/chores/new`; an empty state ("The Signal is Silent"). Keep the layout simple and battery-cheap: no Glance/Compose dependency unless `home_widget` requires it — plain XML RemoteViews + `AppWidgetProvider` + `RemoteViewsService` is fine and preferred for footprint.
2. **Data flow app → widget**: after any relevant db change while the app runs, serialize the top chores (id, name, due, overdue flag) via `home_widget`'s shared storage and trigger a widget update. Centralize this in one `WidgetSyncService` called from the same mutation call-sites that reschedule notifications (don't scatter — if there's a common post-mutation hook, use it; otherwise add the sync call beside the existing notification calls).
3. **Complete from the widget**: checkbox tap → background callback (`home_widget`'s interactivity API) → reuse the `completeChoreFromNotification` core (fresh db connection, CompletionService, gates, notification reschedule) → re-sync the widget data. No duplicated completion math.
4. **Tap a row** → open the app scrolled to that chore (reuse the notification tap-token mechanism).
5. **Staleness**: widget data refreshes on app resume/pause and after background completions; document the update cadence and its limits in changes.md (no periodic polling beyond AppWidget's own updatePeriodMillis minimum).
6. Tests: WidgetSyncService serialization (top-N selection, urgency order, overdue flag) against in-memory db; widget-completion core path (record inserted, due advanced, reschedule, re-sync triggered) with fakes; no platform channels in tests.

## Done criteria

- `flutter analyze` clean; `flutter test` fully green; `flutter build apk --debug` succeeds (native widget code compiles, manifest valid); output in changes.md.
