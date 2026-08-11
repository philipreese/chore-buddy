# Spec 04 — Active chore list surface: cards, search, sort, filter, live overdue

## Role

Implement. Report to `$AER_OUTPUT_DIR/changes.md`.

## Environment (stripped — set before builds)

- `ANDROID_HOME=C:\Android\sdk`, `ANDROID_NDK_HOME=C:\Android\sdk\ndk\28.2.13676358`, `JAVA_HOME=C:\Program Files\Android\openjdk\jdk-21.0.8`
- Flutter `C:\src\flutter\bin\flutter.bat`, Dart `C:\src\flutter\bin\dart.bat`

## Context (read first)

- `docs/behavior-inventory.md` §"Chore list" — the FEATURE/PRESERVE rows are the contract; the QUIRK rows must NOT be recreated.
- `docs/adr/0005` (SearchBar + sort chips layout), `docs/proposals/00-new-stack-ideas.md` §1.2.
- MAUI reference: `ChoreBuddy/Views/MainPage.xaml`, `ChoreBuddy/ViewModels/MainViewModel.cs` (sort/filter/search/timer logic), `ChoreBuddy/Converters/DueToColorConverter.cs` (due-tint thresholds).
- Existing: slice 02 streams (`activeChoresWithDetailsProvider`), slice 03 tags/palette, flavor strings.

## Scope (all inside `app/`)

Replace the Chores tab placeholder with the real list surface:

1. **Chore card**: due-tinted clock icon (port the MAUI DueToColorConverter thresholds against the M3 scheme — overdue/soon/ok colors from the theme, not hardcoded), name, tag chips (palette colors), last-completed + last-note block (visible per a `showDetailsOnCards` provider defaulting true; persistence arrives in slice 09), due-date row. Material press feedback (InkWell). No complete button yet (slice 05).
2. **Search**: M3 `SearchBar` — live name-only case-insensitive contains filter; clearing/closing resets.
3. **Sort chips** under the search bar: Urgency (due date, default) / Name / Last Completed; tap active chip flips direction; switching sorts resets to descending; null due dates and never-completed sort last in both directions.
4. **Tag filter row**: multi-select chips with OR semantics, plus the trailing "Manage Tags" chip → `/tags` (ADR-0005).
5. **Live overdue recolor**: a 1-second ticker active only while the Chores tab is visible; per-minute full refresh is NOT needed — recompute due-tint when a chore crosses its due instant (PRESERVE row; implementation is free, e.g. a periodic provider the cards watch).
6. **Swipes**: swipe one way = delete with flavored confirm dialog; other way = archive (no confirm, matching MAUI). Use `Dismissible` with distinct backgrounds.
7. **Empty states**: distinct flavored empty views for "no chores at all" vs "filters/search matched nothing" (copy from MAUI MainPage empty views).
8. **FAB "+"** → pushes `/chores/new` — register the route with a minimal placeholder screen (real editor is slice 06).
9. All new copy through `AppStrings` (superhero flavor from MAUI strings).

## Tests

- Sort logic unit tests: each order, direction flip, reset-to-descending on switch, nulls-last both directions.
- Filter/search unit tests: OR semantics, case-insensitive contains, combined search+filter.
- Widget tests (in-memory db override): cards render name/tags/due; overdue chore shows the overdue tint and a not-due chore doesn't; swipe-delete shows confirm and deletes; swipe-archive removes from list; both empty states; search narrows the list; ticker recolor — pump past a due instant and assert the tint changes (use fake time / short-interval injection, do not sleep real seconds).

## Done criteria

- `flutter analyze` clean; `flutter test` fully green (existing 24 + new); output summary in changes.md.
- No QUIRK-tagged MAUI behavior recreated (no manual list diffing, no scroll suppression hacks, no color caches).
- `$AER_OUTPUT_DIR/changes.md` lists files and deviations.

## Do NOT

- Touch anything outside `app/`; no completion flow (slice 05), no chore editor (slice 06), no notifications (slice 08); no new packages.
