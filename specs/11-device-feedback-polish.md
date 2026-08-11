# Spec 11 — First on-device feedback: polish and fixes

## Role

Implement. Report to `$AER_OUTPUT_DIR/changes.md`. ONE-SHOT: complete synchronously; write changes.md before finishing.

## Environment (stripped — set before builds)

- `ANDROID_HOME=C:\Android\sdk`, `ANDROID_NDK_HOME=C:\Android\sdk\ndk\28.2.13676358`, `JAVA_HOME=C:\Program Files\Android\openjdk\jdk-21.0.8`
- Flutter `C:\src\flutter\bin\flutter.bat`, Dart `C:\src\flutter\bin\dart.bat`

## Items (from Philip's device testing, in priority order)

### Bugs

1. **Completion dialog abort re-opens the keyboard.** After cancelling the "MISSION REPORT" dialog, the soft keyboard appears. Almost certainly focus restoration handing focus to a text-capable node (the note field's focus surviving the pop, or the M3 SearchBar reclaiming it). Reproduce the mechanism in a widget test if feasible, fix by unfocusing after the dialog closes in `completion_flow.dart` regardless of result. Verify the fix doesn't break normal search-bar focus behavior.
2. **The undo snackbar never auto-dismisses** despite `duration: 5s`. Investigate the real cause — candidates: the 1s ticker rebuilds interacting with the ScaffoldMessenger, the shell rebuilding and re-inserting the snackbar, or `hideCurrentSnackBar`/queue interference. Do not paper over it with a manual timer until the mechanism is understood; state the root cause in changes.md.
3. **Cards with no due date render a bare "Due: " line** — hide the row entirely when `nextDueDate` is null (`chore_card.dart`).

### UX

4. **The header (search + sort chips + filter chips) consumes too much vertical space.** Restructure the Chores tab as slivers: the search bar, sort chips, and tag filter row scroll away with the list (SliverAppBar/pinned=false or plain sliver children in a CustomScrollView), so a scrolled list gets the full screen. Keep the ticker-visibility and scroll-to-chore (index-based, uses the ScrollController) behavior working — the scroll-to logic must account for the new header sliver extents.
5. **Excessive horizontal margin around the completion history list** on chore details — align its cards with the form fields above (`chore_detail_screen.dart`).
6. **No way to delete all chores at once** (MAUI's menu had Delete All). Add a danger-zone action in Settings ("Delete All Chores", flavored confirm using the existing purge-style copy pattern; add strings) that deletes ALL chores active+archived (cascade wipes records/links) and cancels all notifications.

### Theme simplification (decision: Philip)

7. **Remove the 6 seed themes; Dynamic only.** Delete the seed picker; `themeProvider` becomes a **ThemeMode** selector (System / Light / Dark) persisted via the existing prefs service (migrate/ignore the old persisted theme key gracefully). Keep the documented fallback seed for devices without dynamic color. Settings shows a simple three-way mode control. Update tests (theme_picker_test, hydration round-trip) accordingly. Keep `AppThemeId`-related code only insofar as the fallback needs it; delete the rest (seed_colors list, swatch widgets).

### Identity

8. **App title**: launcher label and task-switcher title = "Chore Buddy" (AndroidManifest `android:label`, MaterialApp title).
9. **App icon + splash**: the MAUI icon/splash sources are at `archive/ChoreBuddy-maui/Resources/AppIcon/appicon.svg` and `Resources/Splash/splash.svg`. Generate launcher icons (all mipmap densities + adaptive icon) and a splash screen from them. You may add `flutter_launcher_icons` and `flutter_native_splash` as DEV dependencies to generate, running their generators; commit the generated resources. If the SVGs can't be rasterized in this environment, state it and fall back to a simple generated icon matching the app's dynamic-color look, flagged in changes.md.

## Done criteria

- `flutter analyze` clean; `flutter test` fully green (136 existing, updated where themes changed, + new tests for items 1/3/6); `flutter build apk --debug` succeeds; output in changes.md.
- changes.md states the root cause found for item 2.
- Nothing outside `app/` except this spec's own doc updates if needed.
