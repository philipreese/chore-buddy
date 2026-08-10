# Spec 09 — Settings, persistence, theme picker, backup hot-swap

## Role

Implement. Report to `$AER_OUTPUT_DIR/changes.md`. ONE-SHOT: complete synchronously; write changes.md before finishing.

## Environment (stripped — set before builds)

- `ANDROID_HOME=C:\Android\sdk`, `ANDROID_NDK_HOME=C:\Android\sdk\ndk\28.2.13676358`, `JAVA_HOME=C:\Program Files\Android\openjdk\jdk-21.0.8`
- Flutter `C:\src\flutter\bin\flutter.bat`, Dart `C:\src\flutter\bin\dart.bat`

## Context (read first)

- `docs/behavior-inventory.md` §"Settings / About"; `docs/proposals/00-new-stack-ideas.md` §2.4 (the adopted hot-swap import flow — follow it step by step); ADR-0003 (6 seeds + dynamic); ADR-0005 (About lives inside Settings).
- MAUI reference: `ChoreBuddy/Views/SettingsPage.xaml`, `SettingsViewModel.cs`, `Services/SettingsService.cs`, `Services/MigrationService.cs` (export/import incl. WAL checkpoint), `Views/AboutPage.xaml`, `Views/ThemePickerView.xaml` (pie-wedge previews).
- Existing to wire: `themeProvider` (in-memory), `hapticsEnabledProvider`, `notificationsEnabledProvider`, `showDetailsOnCardsProvider`, `appDatabaseProvider` (built for `ref.invalidate` hot-swap — review 02 noted `close()` is fire-and-forget on dispose; make the import path close/checkpoint explicitly BEFORE swapping, per the proposal), `rescheduleAll()`.
- Strings already present: `intelSecuredTitle/Message`, `restoreArchivesTitle/Message`; add what's missing via the flavor system.

## Scope (all inside `app/`) — allowed new packages, each justified in changes.md: `shared_preferences` (settings persistence), `file_selector` (export/import file dialogs), `package_info_plus` (About version info)

1. **Settings persistence layer**: a small prefs-backed service + provider init that hydrates the four existing providers (theme, haptics, notifications, show-details) at startup and persists on change. Keep the providers' existing APIs so no consumer changes.
2. **Settings screen** (replace placeholder): theme picker — horizontal selector of the 6 seed themes + Dynamic, each swatch showing a small multi-tone preview of its scheme (the MAUI pie-wedge idea, any tasteful M3 form); three toggles (haptics, notifications — wires the cancelAll/rescheduleAll behavior that already exists, show details on cards); Manage Tags entry (exists); Backup section (export / import buttons + last-backup timestamp); About section (app name, version/build via package_info_plus, package id, "Powered By" chips, the joke website button with its "Coming... soon?" alert — port the copy).
3. **Export**: WAL-checkpoint then copy the db file via `file_selector`'s save dialog; on success show flavored confirmation (`intelSecuredTitle/Message`) and persist the last-backup timestamp.
4. **Import (hot-swap, proposal §2.4)**: pick `.db3`/`.sqlite` file → flavored warning confirm (`restoreArchivesTitle/Message`) → basic integrity check (open read-only, verify expected tables exist) → checkpoint + close current connection explicitly → replace the file atomically → `ref.invalidate(appDatabaseProvider)` → streams reconnect → `rescheduleAll()` → success feedback. NO app restart. A failed integrity check must leave the current db untouched.
5. **Import safety net**: before replacing, copy the current db aside (`.pre-import.bak` in app support dir); on any failure during swap, restore it and surface the error.
6. All copy via AppStrings.

## Tests

- Prefs service: round-trips each setting; hydration applies persisted values to providers at startup.
- Theme picker widget test: selecting a seed updates themeProvider and persists.
- Import flow logic test (service-level, temp files, in-memory-adjacent): valid file swaps and old data becomes visible through a fresh provider read; invalid file (garbage bytes / missing tables) rejected with current db intact; backup file created.
- Notifications toggle test already exists — extend only if wiring changed.
- File dialogs are untestable — keep them behind a thin interface, fake in tests.

## Done criteria

- `flutter analyze` clean; `flutter test` fully green (100 existing + new); `flutter build apk --debug` succeeds; output in changes.md.
- Nothing outside `app/`.
