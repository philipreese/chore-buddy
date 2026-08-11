# Spec 07 — Archive surface

## Role

Implement. Report to `$AER_OUTPUT_DIR/changes.md`. You are ONE-SHOT: run everything to completion synchronously this turn; write changes.md before finishing.

## Environment (stripped — set before builds)

- `ANDROID_HOME=C:\Android\sdk`, `ANDROID_NDK_HOME=C:\Android\sdk\ndk\28.2.13676358`, `JAVA_HOME=C:\Program Files\Android\openjdk\jdk-21.0.8`
- Flutter `C:\src\flutter\bin\flutter.bat`, Dart `C:\src\flutter\bin\dart.bat`

## Context (read first)

- `docs/behavior-inventory.md` §Archive + §"Settings / About" (the MAUI menu's "Delete All" purges archived chores — it moves to this screen per ADR-0005's menu removal).
- MAUI reference: `ChoreBuddy/Views/ArchivePage.xaml`, `ChoreBuddy/ViewModels/ArchiveViewModel.cs`.
- Existing: `archivedChoresProvider` stream (slice 02), `ChoreCard` (slice 04 — reuse or a simplified read-only variant), flavored strings already present: `restoreChore`/`restoreDialogTitle`/`restoreDialogMessage`, `purgeTitle`/`purgeMessage`/`purgeConfirm`, `emptyArchiveTitle`/`emptyArchiveDescription`.

## Scope (all inside `app/`) — replace the Archive tab placeholder

1. **Read-only archived cards**: name, tags, last-completed info; no complete button, no tap-to-edit navigation, no delete swipe. Muted/`onSurfaceVariant` styling to read as inactive.
2. **Swipe right = restore** (`restoreChore` on the DAO). MAUI restores without a confirm — keep that (the restore-dialog strings exist but the behavior contract is the inventory row; leave them unused or use for an optional undo-style snackbar instead — implementer's choice, state it in changes.md).
3. **Purge all**: app-bar action (delete-forever icon) → flavored confirm (`purgeTitle`/`purgeMessage`/`purgeConfirm`) → permanently deletes ALL archived chores (cascade removes their records/links). Needs a DAO method if none exists (`deleteArchivedChores`), transactional.
4. **Flavored empty state** (`emptyArchiveTitle`/`Description`).
5. All copy via AppStrings.

## Tests

- Widget (in-memory db, ticker/now overridden per project convention): archived chores render and active ones don't; swipe-right restores (row leaves archive, appears in active stream — assert db via one-shot selects); purge-all confirms then empties archived set while leaving active chores untouched; cancel keeps them; empty state renders.
- DAO test for `deleteArchivedChores`: only archived rows (and their records/links via cascade) are removed.

## Done criteria

- `flutter analyze` clean; `flutter test` fully green (83 existing + new); output in changes.md.
- `$AER_OUTPUT_DIR/changes.md` lists files and deviations.

## Do NOT

- Touch anything outside `app/`; no new packages; no navigation to the editor from archived cards.
