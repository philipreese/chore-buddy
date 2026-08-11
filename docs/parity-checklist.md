# Parity checklist — MAUI reference → Flutter (`app/`)

Walks every `FEATURE`/`PRESERVE` row in `docs/behavior-inventory.md` and names where it lives in `app/`. `QUIRK` and `RETHINK`-only rows are out of scope by definition (see that doc's tag legend) and are omitted here. "Changed" rows are intentional, documented deviations, not gaps.

Legend: ✅ implemented as specified · 🔁 implemented, intentionally changed (reason given) · ⚠️ gap

## Chore list (main surface)

| Row | Status | File |
|---|---|---|
| Card: due-tinted clock icon, name, tag chips, optional last-note/last-completed, due date row, complete button | ✅ | `lib/features/chores/presentation/widgets/chore_card.dart` |
| "Show details on cards" setting toggles the last-note/completed block | ✅ | `chore_card.dart` (`showDetailsOnCardsProvider` gate) + `lib/features/settings/presentation/settings_screen.dart` (toggle) |
| Swipe left = delete (confirm), swipe right = archive | ✅ | `chore_card.dart` (`Dismissible`, `confirmDismiss`/`onDismissed`) |
| Tag-filter chip row, multi-select, OR semantics | ✅ | `lib/features/chores/presentation/widgets/tag_filter_row.dart` + `lib/features/chores/domain/chore_filter_sort.dart` (`filterChores`) |
| Search: in-memory, name-only, case-insensitive contains | 🔁 | `lib/features/chores/presentation/widgets/search_and_sort_bar.dart` + `chore_filter_sort.dart`. Changed per ADR-0005: an M3 `SearchBar` is always visible on the Chores tab rather than toggling to replace the sort row (inventory called this scope "RETHINK-able"); filter semantics (name-only, case-insensitive, clearing on empty) are unchanged. |
| Sort: Urgency/Name/Last Done; tap active chip flips direction; switching resets to descending; nulls sort last | ✅ | `search_and_sort_bar.dart` + `chore_filter_sort.dart` (`sortChores`) + `lib/features/chores/providers/chore_providers.dart` (`SortStateNotifier`) |
| Complete → completion popup (date/time + note) → 5s UNDO snackbar → haptic → reschedule notification | ✅ | `lib/features/chores/presentation/completion_flow.dart` (orchestration), `widgets/completion_dialog.dart` (popup), `domain/completion_service.dart` (write), `core/services/haptics_service.dart` (haptic), `core/notifications/notification_service.dart` (reschedule) |
| Live overdue recoloring within ~1s, timer only while page visible (PRESERVE) | ✅ | `chore_providers.dart` (`tickerProvider` gated on `choresTabVisibleProvider`, `nowProvider`) + `chore_card.dart` / `lib/features/chores/domain/due_status.dart` (color derivation) |
| Distinct empty states: no chores at all vs. filter matched nothing | ✅ | `lib/features/chores/presentation/widgets/chores_empty_state.dart` (`isTotalEmpty` branch) |
| FAB "+" → new chore | ✅ | `lib/features/chores/presentation/chores_screen.dart` (`FloatingActionButton` → `/chores/new`) |
| Scroll-to-chore when a notification is tapped (PRESERVE) | ✅ | `chores_screen.dart` (`_scrollToChore`, index-based via `ScrollController`) + `core/notifications/notification_tap_provider.dart`. Slice 08 review flagged this as broken for off-screen rows (F1); fixed since — index-based scroll reaches unbuilt rows, and a filter/search-clearing retry handles chores hidden by an active filter. |
| Snackbar-anchored undo deleting the record and reloading | ✅ | `completion_flow.dart` (`SnackBarAction` → `completionService.undoCompletion`) |

## Chore details

| Row | Status | File |
|---|---|---|
| Edit panel: name, tag picker, due date/time, recurrence, "Mission Reminder" switch, save | ✅ | `lib/features/chores/presentation/chore_detail_screen.dart` |
| Unique name enforced case-insensitive → "Registry Conflict" alert | ✅ | `chore_detail_screen.dart` (`DuplicateNameException` catch) + `lib/core/database/app_database.dart` (`_guardUniqueName`, unique-index collation) |
| History list: date + note cards; tap to edit (date and note); swipe to delete | ✅ | `chore_detail_screen.dart` (`_buildHistorySection`, `_editRecord`, `_confirmDeleteRecord`) |
| New-chore mode suppresses the empty-history state | ✅ | `chore_detail_screen.dart` (`if (!_isNew) ...` wraps the entire history section) |
| Reliable keyboard dismissal on save/navigate (PRESERVE) | ✅ | `chore_detail_screen.dart` (`deactivate()` calls `FocusManager.instance.primaryFocus?.unfocus()`; also explicit unfocus in `_save()`) |

## Tags

| Row | Status | File |
|---|---|---|
| Create tag: name (≤22 chars, lower-cased/trimmed) + one of 12 preset colors with selection feedback | ✅ | `lib/features/tags/domain/tag_service.dart` (validation/normalization) + `lib/features/tags/presentation/tag_manager_screen.dart` (form, swatch selection) + `lib/core/theme/tag_palette.dart` (12 swatches) |
| Delete one tag / delete all (confirm) | ✅ | `tag_manager_screen.dart` (`_confirmDeleteTag`, `_confirmDeleteAll`) + `tag_service.dart` |

## Archive

| Row | Status | File |
|---|---|---|
| Read-only archived cards; swipe right = restore | ✅ | `lib/features/archive/presentation/archive_screen.dart` + `widgets/archived_chore_card.dart` (`Dismissible`, `startToEnd` only → `restoreChore` + reschedule) |

## Settings / About

| Row | Status | File |
|---|---|---|
| Theme picker | 🔁 | `lib/features/settings/presentation/widgets/theme_picker_row.dart` + `core/theme/seed_colors.dart`/`app_theme.dart`. New form per inventory: 6 named Material seed colors (Chambray, Blue Stone, Russet, Affair, Spicy Mustard, Woodland) + Dynamic (Material You), swatch pickers instead of MAUI's pie-wedge previews; Material 3 `ColorScheme.fromSeed` generates the palette. |
| Haptics toggle, global notifications toggle (off cancels all), show-details toggle | ✅ | `lib/features/settings/presentation/settings_screen.dart` + `core/services/haptics_service.dart` (`hapticsEnabledProvider`) + `core/notifications/notifications_enabled_provider.dart` (`cancelAll()`/`rescheduleAll()`) + `chore_providers.dart` (`showDetailsOnCardsProvider`) |
| Export db via file-saver (after WAL checkpoint); import db (replace-all); last-backup timestamp on About | 🔁 | `lib/features/settings/domain/backup_service.dart` + `settings_screen.dart` (export/import buttons, last-backup label) + `about_section.dart`. Changed per ADR-0005/inventory: import hot-swaps the live drift connection (`ref.invalidate(appDatabaseProvider)`) instead of requiring a full app restart — an intentional improvement, not a gap. |
| About: version/build/package grid, "Powered By" chips, joke website button | ✅ | `lib/features/settings/presentation/widgets/about_section.dart` |

## Notifications

| Row | Status | File |
|---|---|---|
| One-shot notification per chore at its due instant; id = chore id (cancel/replace semantics) | ✅ | `lib/core/notifications/notification_service.dart` (`scheduleChoreNotification`) + `notification_scheduler.dart` |
| Not scheduled when: global off, per-chore off, no due date, or due date past | ✅ | `notification_service.dart` (`scheduleChoreNotification` gate order) |
| Tap → open app → scroll chore list to that chore (PRESERVE) | ✅ | `notification_scheduler.dart` (`onDidReceiveNotificationResponse`) → `app.dart` (`_handleTapPayload`) → `chores_screen.dart` (`_scrollToChore`); see the chore-list row above for the F1 fix |
| Exact-alarm + boot-completed permissions | ✅ | `notification_scheduler.dart` (`exact_alarms_not_permitted` fallback) + `android/app/src/main/AndroidManifest.xml` (`ScheduledNotificationBootReceiver`, `RECEIVE_BOOT_COMPLETED`). Verified by reading (slice 08 review, item 8) — the plugin persists scheduled alarms and replays them on boot without app-side Dart code; not exercised on a physical device/reboot in this repo. |

## Cross-cutting

| Row | Status | File |
|---|---|---|
| Superhero flavor copy everywhere, incl. themed empty states with bespoke copy per surface | ✅ | `lib/core/strings/app_strings.dart` (interface) + `superhero_strings.dart` (copy) + `flavor_provider.dart` |
| 10 hand-built themes with light/dark variants, status bar follows theme | 🔁 | `core/theme/seed_colors.dart`/`app_theme.dart`. New form per inventory: 6 seeds + Dynamic, Material 3 generates light/dark palettes from each seed instead of 10 hand-built XAML dictionaries. Status bar icon brightness follows the active theme automatically via Flutter Material's default `SystemUiOverlayStyle` derivation — no bespoke code needed. |
| WAL mode, tables auto-created on first run | ✅ | `lib/core/database/app_database.dart` (drift `MigrationStrategy`, `drift_flutter`'s `driftDatabase()` opens in WAL mode by default) |

## Beyond parity — ADR-0005 v1 native features

Not behavior-inventory rows (the inventory predates these), listed for completeness:

| Feature | File |
|---|---|
| Predictive back gestures | `android/app/src/main/AndroidManifest.xml` (`android:enableOnBackInvokedCallback="true"`) — done in slice 01, per ADR-0005 |
| "Complete" notification action (background completion write + reschedule, no app launch) | `lib/core/notifications/background_completion.dart` (`completeChoreFromNotification`, `notificationBackgroundResponseHandler`) + `notification_scheduler.dart` (`AndroidNotificationAction`, `showsUserInterface: false`) — added in slice 10 |

## Known caveats (not gaps, documented per spec)

- **Drift streams don't self-refresh across connections.** The background "Complete" action opens its own `AppDatabase()` connection (a separate sqlite handle from the running app's, per slice 10 scope item 2). Drift's `watch()` streams only notice writes made through the *same* connection, not the underlying file changing on disk, so a background completion is invisible to an already-running (but backgrounded, not killed) app instance until something forces a reconnect. `app.dart`'s `_ChoreBuddyAppState` now handles this: `didChangeAppLifecycleState` invalidates `appDatabaseProvider` on `AppLifecycleState.resumed`, which disposes and recreates the connection so every `watch()` stream reissues its query against current on-disk state — the same hot-swap pattern `BackupService.importDatabase` already used for import. A cold start (process was evicted while backgrounded) also picks up the change automatically, since `main()` opens a fresh connection regardless.
- **Haptic duration.** The MAUI reference fired an explicit 175ms vibration; Flutter has no built-in API for a custom-duration one-shot, so `SystemHapticsService` uses `HapticFeedback.vibrate()` (`lib/core/services/haptics_service.dart`) as the closest built-in equivalent rather than adding a package for one call site.
- **Notification timezone.** Per slice 08 review (item 5): an alarm is pinned to an absolute instant, so changing device timezone after scheduling does not re-anchor it to the original local time in the new zone. Matches MAUI behavior; not a regression.
