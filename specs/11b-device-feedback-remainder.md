# Spec 11b — Device feedback remainder (continues spec 11)

## Role

Implement. Report to `$AER_OUTPUT_DIR/changes.md`. ONE-SHOT: complete synchronously; write changes.md before finishing. Do NOT background long-running commands (`flutter test`, builds) — run them to completion in the foreground.

## Environment (stripped — set before builds)

- `ANDROID_HOME=C:\Android\sdk`, `ANDROID_NDK_HOME=C:\Android\sdk\ndk\28.2.13676358`, `JAVA_HOME=C:\Program Files\Android\openjdk\jdk-21.0.8`
- Flutter `C:\src\flutter\bin\flutter.bat`, Dart `C:\src\flutter\bin\dart.bat`

## Context

Spec 11's first pass landed items 1 (keyboard-after-abort fix), 3 (bare "Due:" hidden), 4 (sliver header restructure in `chores_screen.dart`), 6 (Delete All Chores in Settings), and 8 (app title) — all committed, `flutter analyze` clean, full `flutter test` green. This spec is ONLY the remaining items. Do not redo the finished ones.

## Items

### 2. Undo snackbar never auto-dismisses (root cause + fix)

Prior investigation results (do not repeat these dead ends): the bug does NOT reproduce in widget tests — eight attempts including a minimal vanilla `MaterialApp` + `SnackBar(duration: 5s)` with real 6-second waits under `tester.runAsync` all behave per framework test semantics, so the mechanism is device-side. Leading hypotheses, in order:

1. `MediaQuery.accessibleNavigation == true` on the device: `ScaffoldMessengerState` deliberately never starts the auto-dismiss timer for a snackbar **with an action** (ours has UNDO) when accessible navigation is on. Any enabled accessibility service triggers this, not just TalkBack.
2. Repeated `MediaQuery` changes (e.g. viewInsets churn from the keyboard bug fixed in item 1) cancelling and recreating `_snackBarTimer` via `didChangeDependencies`, resetting the countdown.

Read the Flutter framework source (`ScaffoldMessengerState` in `packages/flutter/lib/src/material/scaffold.dart` of the local SDK) to confirm which mechanism applies; state the conclusion in changes.md. Regardless of which it is, the sanctioned fix is **deterministic dismissal**: keep `showSnackBar`, but explicitly close the snackbar (`ScaffoldFeatureController.close()` or `hideCurrentSnackBar`) from a timer tied to the SAME 5s undo-window constant the completion flow already uses, so UI lifetime and undo window can't drift apart. Make sure a snackbar replaced by a newer completion (queue case, existing stacking test) isn't double-closed. Widget test: after 5s of pumped time the snackbar is gone even when `MediaQuery` reports `accessibleNavigation: true` (wrap the test app in a `MediaQuery` override — this DOES reproduce the immortal behavior in tests if hypothesis 1 is right, giving you a red/green loop).

### 5. Completion history margins on chore details

`chore_detail_screen.dart`: the completion history list has noticeably more horizontal margin than the form fields above it. Align the history cards' outer edges with the form fields.

### 5b. Depth separation between header and list on the Chores tab

The search/sort/filter header (now a leading sliver, item 4 done) should read as a distinct surface from the scrolling chore list, clear in BOTH light and dark. Use M3 surface container tones — e.g. header block on `colorScheme.surfaceContainer`/`surfaceContainerLow` with the list on `surface`, or vice versa — Philip reports light mode is where it's currently washed out. Keep it tonal (no hard drop shadows).

### 7. Theme simplification: scrap seed themes, Dynamic only + ThemeMode picker

- Delete the 6-seed theme picker. `themeProvider` becomes a **ThemeMode** (System / Light / Dark) selector persisted via the existing prefs service; migrate or ignore the old persisted theme key gracefully (no crash on stale value).
- Keep dynamic color as the only color source, with the existing documented fallback seed for devices without dynamic color support. Keep only as much `AppThemeId`/seed plumbing as the fallback needs; delete the rest (seed list, swatch widgets, picker UI).
- Settings gets a simple three-way mode control (SegmentedButton is fine), flavored copy via AppStrings (new strings at the END of the strings files).
- Update tests: theme_picker_test, hydration round-trip, anything referencing deleted symbols.

### 9. App icon + splash screen

Sources: `archive/ChoreBuddy-maui/Resources/AppIcon/appicon.svg` and `archive/ChoreBuddy-maui/Resources/Splash/splash.svg`. Add `flutter_launcher_icons` and `flutter_native_splash` as DEV dependencies, configure them to generate all mipmap densities + adaptive icon + splash (including Android 12+ splash API), run the generators, commit the generated resources. If SVG rasterization is impossible in this environment, generate a simple placeholder icon matching the app's look and FLAG it clearly in changes.md.

## Done criteria

- `flutter analyze` clean; `flutter test` fully green; `flutter build apk --debug` succeeds; changes.md lists files, the item-2 root-cause conclusion, and any deviation.
- Nothing outside `app/` touched.
