# Spec 03 — Tag domain rules and tag management UI

## Role

Implement. Report to `$AER_OUTPUT_DIR/changes.md`.

## Environment (stripped — set before builds)

- `ANDROID_HOME=C:\Android\sdk`, `ANDROID_NDK_HOME=C:\Android\sdk\ndk\28.2.13676358`, `JAVA_HOME=C:\Program Files\Android\openjdk\jdk-21.0.8`
- Flutter `C:\src\flutter\bin\flutter.bat`, Dart `C:\src\flutter\bin\dart.bat`

## Context (read first)

- `CONTEXT.md` (Tag term), `docs/behavior-inventory.md` §Tags, `docs/adr/0005` (tags reachable via manage-chip + settings entry, NOT a tab).
- MAUI reference for behavior/copy: `ChoreBuddy/Views/TagsPage.xaml`, `ChoreBuddy/ViewModels/TagsViewModel.cs`, `ChoreBuddy/Models/ChoreTag.cs`.
- Existing code: `app/lib/core/database/` (slice 02 — use its DAOs/providers; note tag names are stored case-SENSITIVELY, so normalization below is the guard), `app/lib/core/strings/` (all copy via flavor keys), theme in `app/lib/core/theme/`.

## Scope (all inside `app/`)

1. **Domain rules** in a small tag service/notifier layer (not in widgets): names trimmed + lower-cased before any write (MAUI parity); max 22 chars; empty names rejected; duplicate names surface the DuplicateNameException as user-facing flavored copy ("Registry Conflict" pattern).
2. **Tag palette**: a fixed 12-swatch palette defined once in `core/theme/` as `colorIndex` 0..11 → Color, chosen to read acceptably against all 6 seed themes light+dark (the MAUI hexes in `TagsViewModel.cs` are the starting point; adjust only if a swatch is illegible on dark surfaces).
3. **TagManagerScreen** (`/tags` route, pushed — not a tab): create-tag field + 12-swatch selector with selected-state feedback, Add button; list of existing tags as colored chips with per-tag delete (confirm dialog) and delete-all action (confirm dialog); flavored empty state. Register the route; add the Settings-screen entry point ("Manage Tags") — the chores-tab filter-row chip entry arrives in slice 04.
4. **Providers**: tags stream already exists (`tagsProvider`); add mutation providers/notifiers for create/delete/delete-all wrapping the domain rules.
5. **Tests**: unit — normalization (trim, lowercase, 22-char cap, empty rejection) and duplicate rejection through the service layer; widget — TagManagerScreen creates a tag via the field+swatch flow, shows it as a chip, per-tag delete shows confirm and deletes, delete-all clears, empty state renders flavored copy. Use an in-memory database override.

## Done criteria

- `flutter analyze` clean; `flutter test` fully green (existing 14 + new); include output in changes.md.
- No raw user-facing string literals in widgets — every new string goes through `AppStrings` (add keys to the abstract class + superhero impl, sourced from MAUI copy where it exists).
- `$AER_OUTPUT_DIR/changes.md` lists files and deviations.

## Do NOT

- Touch anything outside `app/`; no chores-list UI (slice 04); no new packages.
- Put domain rules (normalization/validation) in widget code.
