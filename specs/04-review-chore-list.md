# Spec 04-review — Adversarial review of the chore list surface

## Role

Review. Read-only. Write `report.md` and `verdict.json` to `$AER_OUTPUT_DIR`. For `verdict.json`, keep every field a plain string/bool/number per the ReviewVerdict schema — no nested objects in `claim`.

## Subject (committed at HEAD, slice 04)

- `app/lib/features/chores/domain/chore_filter_sort.dart`, `due_status.dart`, `date_formatter.dart`
- `app/lib/features/chores/providers/chore_providers.dart`
- `app/lib/features/chores/presentation/chores_screen.dart`, `chore_detail_screen.dart`, `widgets/` (4 files)
- `app/test/chores_sort_test.dart`, `chores_filter_test.dart`, `chores_screen_test.dart`
- Modified: `app/lib/core/router/app_router.dart`, `app/lib/core/database/database_provider.dart`, `app/test/widget_test.dart`

## Contract (verify adversarially)

Behavior contract is `docs/behavior-inventory.md` §"Chore list" (FEATURE/PRESERVE rows) and `specs/04-chore-list-surface.md`. Specifically:

1. Sort semantics match MAUI: tap active chip flips direction; switching sort keys resets to DESCENDING; null due dates / never-completed sort LAST in BOTH directions (check the comparator actually does this when direction flips — the classic bug is nulls flipping to first on ascend).
2. Search is name-only, case-insensitive, live; clearing resets. Filter chips are OR semantics. Search+filter compose (AND between the two mechanisms).
3. Due-tint thresholds faithfully port `ChoreBuddy/Converters/DueToColorConverter.cs` (compare against the MAUI source — thresholds, not just ordering) and colors come from the M3 scheme, not hardcoded.
4. The 1s ticker only runs while the Chores tab is visible; no timer leaks (provider disposal); recolor happens when a chore crosses its due instant. Confirm the widget tree doesn't rebuild the whole list every tick (per-card watch vs list-level watch — flag if every card rebuilds every second as an efficiency finding, since the MAUI app deliberately avoided that).
5. Swipe directions: archive = no confirm, delete = confirm dialog; a cancelled confirm leaves the item in place (Dismissible must not have already removed it — the classic confirmDismiss bug).
6. No QUIRK-tagged MAUI behavior recreated (manual diffing, scroll suppression, color caches).
7. Tests test what they claim: the ticker test uses fake/injected time not real sleeps; the swipe-cancel path is covered or its absence flagged; sort tests cover both directions for null handling.
8. All user-facing strings via AppStrings (grep widgets for raw literals).

## Also hunt for

- Provider graph correctness: does `filteredAndSortedChoresProvider` recompute on every tick even when nothing crossed a due boundary?
- `chore_detail_screen.dart` placeholder: must not pretend to save anything.
- Router: `/chores/:id` parsing, bad-id handling.

## Verdict

Fail if any contract row is false or a swipe can lose data (delete without confirm / archive deleting). Report findings with file:line.
