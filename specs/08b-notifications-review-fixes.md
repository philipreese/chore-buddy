# Spec 08b — Apply review fixes to notifications

## Role

Implement. Report to `$AER_OUTPUT_DIR/changes.md`. ONE-SHOT: complete synchronously; write changes.md before finishing.

## Environment (stripped — set before builds)

- `ANDROID_HOME=C:\Android\sdk`, `ANDROID_NDK_HOME=C:\Android\sdk\ndk\28.2.13676358`, `JAVA_HOME=C:\Program Files\Android\openjdk\jdk-21.0.8`
- Flutter `C:\src\flutter\bin\flutter.bat`, Dart `C:\src\flutter\bin\dart.bat`

## Context

Read `docs/reviews/08-notifications-review.md` first — file:line evidence for every item.

## Required (blockers)

1. **F1 — index-based tap-to-scroll**: replace the GlobalKey/`ensureVisible` approach in `chores_screen.dart` with index-based scrolling via the existing `ListView.builder`'s `ScrollController` (index → offset estimate is acceptable for uniform-ish cards; or switch the list to `scrollable_positioned_list`-style logic WITHOUT adding a package — controller math is fine). Only clear `notificationTapChoreIdProvider` after the target index was actually resolved in the current list; if the chore isn't in the filtered list (e.g. filter active), clear filters/search first or fall back gracefully — state the chosen behavior.
2. **F2 — undo reschedules from fresh state**: in the undo snackbar action, after `undoCompletion`, re-read the chore (`db.getChoreById`) and schedule from that row (mirrors the save path). Apply the same to the post-completion reschedule for consistency.
3. **F3 — latches on success only**: `_initialized` and `_permissionRequested` must only latch after the guarded work succeeds; on failure stay false so the next call retries.
4. **F4 — a tap-to-scroll test that can fail**: ~40 chores, target initially off-screen (`findsNothing`/not hitTestable), assert visible (or scroll offset moved to it) after the tap event; assert the provider only cleared on success.

## Also fix

5. **F5**: make repeat taps for the same chore always notify — incrementing token or set-null-then-set in the tap provider; clear from the handling side.
6. **F6**: `catchError` (log) on the fire-and-forget toggle calls in `notifications_enabled_provider.dart`.

## Done criteria

- `flutter analyze` clean; `flutter test` fully green (98 existing + new); output in changes.md.
- Nothing outside `app/`; no new packages.
