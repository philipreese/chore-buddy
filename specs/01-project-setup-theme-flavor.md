# Spec 01 — Flutter project scaffold, theme engine, flavor-keyed strings

## Role

Implement. You write code in the workspace and report to `$AER_OUTPUT_DIR/changes.md`.

## Environment (your env is stripped — set these before any build)

- `ANDROID_HOME=C:\Android\sdk`
- `ANDROID_NDK_HOME=C:\Android\sdk\ndk\28.2.13676358`
- `JAVA_HOME=C:\Program Files\Android\openjdk\jdk-21.0.8`
- Flutter: `C:\src\flutter\bin\flutter.bat` (3.41.9 stable), Dart: `C:\src\flutter\bin\dart.bat`

## Context (read first)

- `CONTEXT.md`, `docs/adr/0001`–`0005`, `docs/proposals/00-new-stack-ideas.md` (§1 IA, §4 Slice 01)
- Existing MAUI theme colors for seed extraction: `ChoreBuddy/Resources/Styles/Themes/` — themes to port as seeds: Chambray (default), Blue Stone, Russet, Affair, Spicy Mustard, Woodland. Use each theme's primary color as its seed.
- Superhero copy to seed the flavor layer: browse `ChoreBuddy/Views/*.xaml` and `ChoreBuddy/ViewModels/*.cs` for user-facing strings (e.g. "Mission Report", "Hall of Rest", "Intel Secured", "Registry Conflict", empty-state copy).

## Scope

Create the Flutter app at `app/` (repo root). Nothing outside `app/` may be touched.

1. `flutter create` with org `com.philipreese`, project name `chorebuddy`, Android-only (`--platforms android`). Dart 3.11 / Flutter 3.41 idioms, null-safe, lints enabled.
2. Dependencies: `flutter_riverpod` + `riverpod_annotation` (+ codegen dev deps), `go_router`. Nothing else yet.
3. **Theme engine**: Material 3, `ColorScheme.fromSeed`, light+dark, 6 named seed themes (from the MAUI primaries above) + a Dynamic option using `dynamic_color`. Selected theme exposed via a Riverpod provider (persistence arrives in a later slice — default Chambray for now).
4. **Flavor-keyed strings**: an `AppStrings` abstraction where every user-facing string is a keyed lookup on the active flavor; one flavor implemented, `superhero`, seeded with the real MAUI copy. No raw string literals in widgets. Expose via provider.
5. **Shell skeleton**: go_router `StatefulShellRoute` with the two tabs (Chores, Archive) showing placeholder screens using flavor strings, app-bar with a Settings gear routing to a placeholder Settings screen. Predictive back enabled (`android:enableOnBackInvokedCallback` + default `PopScope` behavior).
6. Tests: theme provider generates distinct schemes per seed; flavor lookup resolves every defined key; a widget smoke test that the shell renders both tabs.

## Done criteria

- `flutter analyze` clean and `flutter test` green in `app/` (run them; include output summary in changes.md).
- `flutter build apk --debug` succeeds.
- No raw user-facing string literals in widget code.
- `$AER_OUTPUT_DIR/changes.md` lists every file created and any deviation from this spec.

## Do NOT

- Touch anything outside `app/` (no edits to `ChoreBuddy/`, `docs/`, `specs/`).
- Add database, notification, or state persistence packages — later slices.
- Invent copy: use the MAUI app's actual strings for the superhero flavor wherever one exists.
