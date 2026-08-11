# Slice 04 review — active chore list surface

**Verdict: FAIL** (three contract rows false: live-ticker scoping, test honesty, AppStrings coverage). No data-loss swipe path was found — archive archives, delete deletes, cancel leaves the row in place.

---

## Contract rows

### 1. Sort semantics — PASS

`sortChores` (`app/lib/features/chores/domain/chore_filter_sort.dart:41-94`) handles nulls *before* applying direction:

- urgency: `if (aDue == null) return 1; if (bDue == null) return -1;` (`:57-58`) — direction is only consulted at `:60-62`, after the null branch has already returned. Nulls therefore stay last in both directions. Same shape for `lastCompleted` at `:81-82`.
- Matches MAUI `MainViewModel.SortChores` (`ChoreBuddy/ViewModels/MainViewModel.cs:183-203`), which achieves the same with `OrderBy(!HasValue)` / `OrderByDescending(HasValue)` plus a `.ThenBy(Name)` tiebreak. The Dart port replicates the name tiebreak (`:64`, `:89`).
- Chip behaviour: `SortStateNotifier.selectOrder` (`app/lib/features/chores/providers/chore_providers.dart:44-56`) flips direction on the active order and hard-resets to `descending` on switch — identical to `MainViewModel.cs:421-433`.

One deliberate deviation, spec-sanctioned: MAUI defaults to `LastCompleted`/`Descending` (`MainViewModel.cs:68-71`); the Flutter default is `urgency`/`descending` (`chore_providers.dart:14-16`), which is what spec 04 §3 asks for. Not a defect, but worth recording as an intentional behaviour change.

Dead code: `SortStateNotifier.toggleDirection` (`chore_providers.dart:58-63`) has no caller and no test.

### 2. Search + filter — PASS

`filterChores` (`chore_filter_sort.dart:14-39`): trim + `toLowerCase().contains()` on `chore.name` only (`:19-26`), tag match is `any(selectedTagIds.contains)` = OR (`:29-35`), and the two predicates are `&&`-composed by falling through the same `where`. Faithful to `MainViewModel.cs:174-178`. Clearing resets via the trailing clear button and `onChanged` (`app/lib/features/chores/presentation/widgets/search_and_sort_bar.dart:51-62`).

Minor: `_SearchAndSortBarState.build` assigns `_searchController.text` during build (`search_and_sort_bar.dart:38-40`). It is guarded by an inequality check so it does not loop today, but mutating a controller inside `build` is a latent cursor-reset/notify-during-build hazard.

### 3. Due-tint thresholds — PASS

`getDueStatus` (`app/lib/features/chores/domain/due_status.dart:10-15`) is a line-for-line port of `DueToColorConverter.Convert` (`ChoreBuddy/Converters/DueToColorConverter.cs:19-31`): `now > nextDue` → overdue; `nextDue - now <= 24h` → due soon; else on-time; null → no tint. Boundary handling matches (`isAfter` vs `>`, `<=` on the 24h span).

Colors come from the M3 scheme (`due_status.dart:20-27`: `colorScheme.error` / `.tertiary` / `.primary`), and are resolved per build from `Theme.of(context)` (`chore_card.dart:27`) — no `DueColorCache` equivalent, so the MAUI QUIRK is correctly *not* recreated.

### 4. Live ticker — **FAIL** (scoping) + efficiency finding

**4a. The 1s timer keeps running when the Chores tab is not visible.** The shell is `StatefulShellRoute.indexedStack` (`app/lib/core/router/app_router.dart:19-41`) rendering `navigationShell` as the Scaffold body (`app/lib/features/shell/presentation/app_shell.dart:33`). An `IndexedStack` keeps every branch mounted; the non-selected branch is merely offstage. So when the user switches to the Archive tab — or pushes `/settings`, `/tags`, `/chores/:id` on the root navigator — the `ChoreCard`s stay in the tree, keep their `ref.watch(nowProvider)` subscription (`chore_card.dart:24`), `tickerProvider.autoDispose` is never released, and `Timer.periodic(const Duration(seconds: 1))` (`chore_providers.dart:144`) keeps firing and rebuilding offstage widgets forever. The PRESERVE row (`docs/behavior-inventory.md:29`) and spec §5 both say "timer runs only while page visible". Nothing in the slice observes route/tab visibility.

Not a leak in the strict sense — `ref.onDispose` does cancel the timer and close the controller (`chore_providers.dart:149-152`) — but disposal only happens when the last card unmounts, which for the indexed stack means app teardown.

**4b. Every card rebuilds every second.** `nowProvider` yields a fresh `DateTime` on each tick (`chore_providers.dart:156-159`) and *every* `ChoreCard` watches it at `chore_card.dart:24`. With N visible cards that is N widget rebuilds per second regardless of whether any chore crossed its due instant — the MAUI app deliberately avoided per-second churn. The card-level watch is at least better than a list-level watch (the list is not rebuilt, and `filteredAndSortedChoresProvider` correctly does **not** depend on `nowProvider`, `chore_providers.dart:161-180`, so no re-filter/re-sort per tick), but the recolor could be driven off a coarser derived provider (e.g. `select` on the card's own `DueStatus`) so a rebuild only happens on an actual status transition.

### 5. Swipe directions — PASS on the contract, one robustness finding

`chore_card.dart:69-99`: `startToEnd` (swipe right) returns `true` immediately → archive with no confirm; `endToStart` (swipe left) shows the flavored `scrapTitle`/`scrapMessage` dialog and returns `confirm ?? false` (`:90`) — so cancel *and* barrier-dismiss both leave the item in place, and because this is `confirmDismiss` (not `onDismissed`) the row was never removed. The classic confirmDismiss bug is absent. Backgrounds map correctly: `background` (amber, "Archive", left-aligned) for startToEnd, `secondaryBackground` (error, "Delete", right-aligned) for endToStart, matching MAUI's swipe-left-deletes (`docs/behavior-inventory.md:24`). `archiveChore` writes `isActive: false` and `deleteChore` deletes (`app/lib/core/database/app_database.dart:151-158`) — no crossed wires.

Robustness: `onDismissed` (`chore_card.dart:92-99`) fires and returns before the awaited db write completes, so between dismissal and the next drift stream emission the list still contains the item. That is exactly the state that produces Flutter's "A dismissed Dismissible widget is still part of the tree" assertion in debug. Tests don't hit it because the in-memory drift stream turns around inside `pumpAndSettle`; a slow real device write is a different story.

### 6. No QUIRK behaviour recreated — PASS

No manual list diffing (plain `ListView.builder` off an immutable sorted list, `chores_screen.dart:31-42`), no scroll suppression, no color cache, no precomputed `IsHistoryVisible` — `showDetailsOnCardsProvider` is watched per card (`chore_card.dart:25`, `chore_providers.dart:92-103`). No 80px footer quirk; the 88px bottom padding at `chores_screen.dart:33` is ordinary FAB clearance.

### 7. Tests test what they claim — **FAIL**

**7a. The ticker test does not exercise the ticker.** `chores_screen_test.dart:267-298` overrides `nowProvider` outright (`:49`) with a test notifier and then changes that notifier's value. It proves `ChoreCard` recolors when `nowProvider` changes — which is a real assertion, and it does use injected time rather than real sleeps as required — but it never touches `tickerProvider`'s timer, its 1s period, or its disposal. There is no test anywhere that the ticker actually emits.

**7b. Production code branches on test detection.** `_isTestEnvironment()` (`chore_providers.dart:125-136`) makes `tickerProvider` return `Stream.value(DateTime.now())` — a single event, never a tick — whenever it thinks it's under test, using `Zone` symbols and `WidgetsBinding.instance.runtimeType.toString().contains('test')`, and returning `true` on any exception. This is shipped code whose live-recolor behaviour is gated on runtime environment sniffing; if the heuristic ever false-positives (binding renamed, binding not yet initialised) the recolor silently dies in production with no test able to catch it. The same helper is duplicated verbatim in `app/lib/core/database/database_provider.dart:9-20`. `widget_test.dart` relies on both of these implicitly (it constructs `ChoreBuddyApp` with no overrides at all, `widget_test.dart:9-13`), which is why the hack exists — the fix is an injectable clock/db override in the test, not a branch in the product.

**7c. The swipe-cancel path is uncovered.** `chores_screen_test.dart:150-179` covers confirm-then-delete; nothing taps Cancel and asserts the chore survives. Given that this is the single most data-destructive interaction in the slice, its absence is a gap the spec explicitly asked to flag.

Sort tests do cover nulls-last in both directions for both urgency and lastCompleted (`chores_sort_test.dart:73-133`) and the reset-to-descending rule (`:164-172`). Filter tests cover OR, case-insensitivity, and the combined AND (`chores_filter_test.dart:66-105`). Those claims hold.

### 8. All user-facing strings via AppStrings — **FAIL**

`chore_card.dart` bypasses the flavor system entirely: it hardcodes `const strings = SuperheroStrings()` at `:28` instead of `ref.watch(appStringsProvider)`, so the card is pinned to one flavor while every sibling widget (`search_and_sort_bar.dart:34`, `tag_filter_row.dart:17`, `chores_empty_state.dart:16`) resolves through the provider. Add a flavor and the card silently doesn't follow.

Raw literals in the same file:

- `'Archive'` — `chore_card.dart:41`
- `'Delete'` — `chore_card.dart:58`
- `'Cancel'` — `chore_card.dart:81`, despite `AppStrings.cancel` existing (`app/lib/core/strings/app_strings.dart:91`, `superhero_strings.dart:187`)
- `'Last completed: '` — `chore_card.dart:178`
- `'Note: "…"'` — `chore_card.dart:190`, despite `AppStrings.noteLabel` existing (`app_strings.dart:50`)
- `'Due: '` — `chore_card.dart:208`

Also `'Error: $err'` in `chores_screen.dart:48`.

Hardcoded colors in the swipe affordances too — `Colors.amber.shade700` and three `Colors.white` (`chore_card.dart:33, 38, 42, 60, 65`) sit outside the M3 scheme. Contract row 3 only governs the due tint, so this is adjacent rather than a row failure, but it will not follow a theme.

---

## Also-hunt items

- **Provider graph.** Clean on this axis: `filteredAndSortedChoresProvider` (`chore_providers.dart:161-180`) depends only on the chores stream, query, tag set, and sort state — not on `nowProvider` — so a tick does not re-filter or re-sort. The waste is entirely at card level (see 4b).
- **`chore_detail_screen.dart`.** Honest placeholder: renders a title and `'$title Placeholder (ID: $choreId)'` (`:24-29`), no form fields, no save affordance, no writes. It does not pretend to save anything. Its one raw literal is developer-facing placeholder text that slice 06 replaces.
- **Router.** `/chores/new` is declared before `/chores/:id` (`app_router.dart:52-64`), so go_router matches the literal first — correct. But `:id` is never parsed or validated: `state.pathParameters['id'] ?? ''` is passed through as a `String` (`:61-62`), so `/chores/not-a-number` renders an "Edit" placeholder rather than a not-found, and the new-vs-edit decision is a string comparison against `'new'` or `'0'` (`chore_detail_screen.dart:17`). Harmless while the screen does no lookup; it becomes a crash or a bogus-record path the moment slice 06 does `int.parse`.

---

## Findings, ranked

| # | Severity | Location | Finding |
|---|---|---|---|
| 1 | High | `chore_providers.dart:125-154` | Live-recolor behaviour gated on runtime test sniffing in production code; no test can exercise the real ticker. Contract 7. |
| 2 | High | `app_router.dart:19-41` + `chore_card.dart:24` | 1s timer keeps firing while the Chores tab is offstage (IndexedStack) or covered by a pushed route. Contract 4 / PRESERVE row. |
| 3 | High | `chore_card.dart:28` | `SuperheroStrings()` hardcoded instead of `appStringsProvider` — card ignores the flavor system. Contract 8. |
| 4 | Medium | `chore_card.dart:41, 58, 81, 178, 190, 208`; `chores_screen.dart:48` | Seven raw user-facing literals, two of which have existing `AppStrings` members. Contract 8. |
| 5 | Medium | `chores_screen_test.dart` | No test for cancelling the delete confirm — the most destructive path is unguarded. Contract 7. |
| 6 | Medium | `chore_card.dart:24` | Every card rebuilds every second regardless of due-status transitions. Contract 4 efficiency. |
| 7 | Low | `chore_card.dart:92-99` | `onDismissed` returns before the awaited db write; window for "dismissed Dismissible still in the tree" on slow writes. |
| 8 | Low | `chore_card.dart:33-65` | Swipe backgrounds use `Colors.amber`/`Colors.white` rather than the M3 scheme. |
| 9 | Low | `app_router.dart:61` | `/chores/:id` accepts any string; no parse or not-found handling. |
| 10 | Low | `search_and_sort_bar.dart:38-40` | `TextEditingController.text` mutated during `build`. |
| 11 | Info | `chore_providers.dart:58-63` | `toggleDirection` is dead code, untested. |
| 12 | Info | `chore_providers.dart:14-16` | Default sort differs from MAUI (`urgency` vs `LastCompleted`) — intentional per spec §3, recorded as a behaviour deviation. |

## What would clear the fail

1. Drive the ticker from a real injectable clock (`Provider<Stream<DateTime>>` overridden in tests with `FakeAsync` or a controlled `StreamController`), delete `_isTestEnvironment()` from `chore_providers.dart`, and add a test asserting the timer emits and is cancelled on dispose.
2. Tie the ticker's lifetime to Chores-tab visibility — e.g. a `VisibilityDetector`-free approach: watch the shell's `currentIndex`/route and only subscribe to `nowProvider` when the branch is selected; assert with a test that the subscription drops on tab switch.
3. Route `chore_card.dart` strings through `ref.watch(appStringsProvider)` and add the missing `AppStrings` members (`archiveAction`, `deleteAction`, `lastCompletedLabel`, `dueLabel`).
4. Add the swipe-cancel test.
