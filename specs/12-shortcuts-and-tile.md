# Spec 12 — App shortcuts and quick-settings tile

## Role

Implement. Report to `$AER_OUTPUT_DIR/changes.md`. ONE-SHOT: complete synchronously; write changes.md before finishing.

## Environment (stripped — set before builds)

- `ANDROID_HOME=C:\Android\sdk`, `ANDROID_NDK_HOME=C:\Android\sdk\ndk\28.2.13676358`, `JAVA_HOME=C:\Program Files\Android\openjdk\jdk-21.0.8`
- Flutter `C:\src\flutter\bin\flutter.bat`, Dart `C:\src\flutter\bin\dart.bat`

## Context

Post-parity items from `docs/proposals/00-new-stack-ideas.md` §3.1 (App Shortcuts, Quick-Settings Tile), approved by ADR-0005's owner. Existing: go_router routes (`/chores/new`, `/chores`), notification deep-link pattern in `app.dart` (launch-details → provider), flavor strings.

NOTE: you may be working in a git WORKTREE checkout in parallel with other slices — do not touch `specs/`, `docs/`, or anything outside `app/`; keep your diff tight to minimize merge conflicts. Strings you add go at the END of `app_strings.dart`/`superhero_strings.dart`.

## Scope (all inside `app/`)

1. **App shortcuts** (long-press launcher icon): two static-or-dynamic shortcuts — "New Mission" → opens the app at `/chores/new`; "Overdue" → opens the Chores tab with... (keep simple: just opens the chores list). Use `quick_actions` (flutter favorite) — the ONE allowed new package for this item. Wire the launch intent through the same pending-navigation pattern the notification tap uses (don't invent a second mechanism).
2. **Quick-settings tile**: an Android TileService ("New Mission") that launches the app to `/chores/new`. This needs a small Kotlin `TileService` in `android/app/src/main/kotlin/...` + manifest `<service>` with `BIND_QUICK_SETTINGS_TILE` permission and tile icon (reuse `ic_notification`). The tile's tap fires the same deep-link intent as the New Mission shortcut (an intent extra the MainActivity/plugin layer translates to the route).
3. Flavored labels via AppStrings where they surface in Dart; the manifest/tile labels can use android resources with the same copy.
4. Tests: the pending-navigation provider handles a shortcut action string → routes to `/chores/new` (unit/widget, no platform channels); shortcut registration behind a thin fakeable wrapper.

## Done criteria

- `flutter analyze` clean; `flutter test` fully green; `flutter build apk --debug` succeeds (proves manifest + Kotlin compile); output in changes.md with any deviation.
