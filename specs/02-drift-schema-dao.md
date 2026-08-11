# Spec 02 — Drift database schema and reactive DAOs

## Role

Implement. You write code in the workspace and report to `$AER_OUTPUT_DIR/changes.md`.

## Environment (your env is stripped — set these before any build)

- `ANDROID_HOME=C:\Android\sdk`
- `ANDROID_NDK_HOME=C:\Android\sdk\ndk\28.2.13676358`
- `JAVA_HOME=C:\Program Files\Android\openjdk\jdk-21.0.8`
- Flutter: `C:\src\flutter\bin\flutter.bat` (3.41.9 stable), Dart: `C:\src\flutter\bin\dart.bat`

## Context (read first)

- `docs/proposals/00-new-stack-ideas.md` **§2** — the adopted schema design (table definitions, derived fields, cascade rules). Implement that design.
- `CONTEXT.md` (domain terms), `docs/adr/0002` (drift replaces repository+cache; reactive queries), `docs/behavior-inventory.md` (data-model section).
- Existing app code in `app/` from slice 01 (Riverpod conventions, `core/` + `features/` layout).

## Scope

All work inside `app/`. Add the persistence layer only — no UI changes beyond nothing (placeholders stay as-is).

1. Dependencies: `drift`, `drift_flutter` (runtime), `drift_dev` (dev). Run codegen via `dart run build_runner build`.
2. Tables per proposal §2.2: `Chores` (name NOT NULL UNIQUE COLLATE NOCASE; isActive default true; nullable nextDueDate; `RecurrenceType` int enum none/daily/everyOtherDay/weekly/monthly; isNotificationEnabled default true; createdAt), `CompletionRecords` (choreId FK cascade, completedAt, note), `Tags` (unique name, colorIndex int), `ChoreTags` (composite PK, both FKs cascade). Enable foreign keys pragma.
3. Database class in `app/lib/core/database/` with `drift_flutter` file setup; expose via a Riverpod provider designed so the provider can later be invalidated for backup hot-swap (ADR-0005 / proposal §2.4 — do NOT implement import/export yet).
4. DAOs with reactive queries:
   - `watchActiveChoresWithDetails()` → stream of chore + its tags + derived `lastCompleted`/`lastNote` (latest completion via join/subquery — these fields are NOT stored).
   - `watchArchivedChores()`, `watchTags()`, `watchHistoryForChore(id)`.
   - Mutations: insert/update/delete chore (delete cascades), archive/restore, insert/update/delete completion record, tag CRUD incl. delete-all, set chore↔tag links.
   - Case-insensitive unique-name violation surfaced as a typed result (e.g. sealed result or thrown domain exception), not a raw SqliteException leaking to callers.
5. Tests (pure Dart, in-memory database — `NativeDatabase.memory()`): CRUD round-trips; cascade delete removes records+links; unique name conflict (case-insensitive) reported as the typed failure; derived lastCompleted/lastNote reflect the latest record and update reactively when a record is inserted/deleted; archive/restore flips visibility between the two watch streams.

## Done criteria

- `flutter analyze` clean, `flutter test` fully green (existing 7 tests plus the new suite) — run them; include output summary in changes.md.
- Generated `.g.dart` files committed alongside sources (do not gitignore them).
- `$AER_OUTPUT_DIR/changes.md` lists files and any deviations.

## Do NOT

- Touch anything outside `app/`.
- Wire the database into any screen, add notification/backup logic, or add packages beyond the three drift ones.
- Store `lastCompleted`/`lastNote` on the chores table.
