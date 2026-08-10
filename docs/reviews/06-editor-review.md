# Slice 06 adversarial review — chore editor and history

**Verdict: FAIL** — contract item 1 ("check the save path can't half-write") is breached. Everything else in the contract holds; the remaining findings are medium/low.

Reviewed at HEAD (`0843d78` + `65b8674`) against `ChoreBuddy/Views/ChoreDetailsPage.xaml`, `ChoreBuddy/ViewModels/ChoreDetailViewModel.cs`, `specs/06-chore-editor-history.md`, `docs/behavior-inventory.md` §"Chore details".

---

## Blocking

### F1 — `_save` can half-write: chore persisted, tag links fail, no error surfaced, no rollback

`app/lib/features/chores/presentation/chore_detail_screen.dart:147-191`

The save path is two independent writes with only a `DuplicateNameException` catch:

- `chore_detail_screen.dart:150` / `:161` — insert or update the chore
- `chore_detail_screen.dart:172` — `await db.setChoreTags(choreId, _selectedTagIds.toList())`

`setChoreTags` is internally transactional (`app_database.dart:213-225`), but the *chore write and the tag write are not in a shared transaction*, and any exception that is not `DuplicateNameException` escapes `_save` entirely as an unhandled async error — no alert, no snackbar, no pop, no rollback.

Concrete failure, fully reachable through the UI:

1. New-chore form, type a name, select tag "kitchen".
2. Tap the `+` button (`chore_detail_screen.dart:339-344`) → pushes `/tags` onto the **root** navigator (`app_router.dart:50-53`), so the detail screen stays alive with its state.
3. In the tag manager, delete that tag or use "Delete All Tags" (`tag_manager_screen.dart:94`, `:119`).
4. Return. The chip is gone from the reactive `tagsProvider` list, but `_selectedTagIds` still holds the dead id — nothing ever reconciles it (see F2).
5. Tap Save. `insertChore` succeeds and **commits**. `setChoreTags` then violates the `chore_tags.tag_id → tags.id` foreign key (`tables.dart:47`; FKs are enforced, `app_database.dart:21`). The exception propagates out of `_save`.

Result: the chore exists in the database with no tags; the screen stays open with the Save button apparently doing nothing. The user taps Save again → `insertChore` now hits the UNIQUE name constraint → the app shows **"Registry Conflict"** for a mission the user is certain they never created. In edit mode the same path silently commits the name/due/recurrence changes while the tag edits are discarded.

MAUI is no better here (`ChoreDetailViewModel.cs:371-381` is the same two-step), but the spec explicitly asks the port to close it, and the failure loses user input.

Fix shape: wrap both writes in one `db.transaction(...)`, and add a catch-all around `_save` that surfaces an error to the user instead of dropping it on the floor.

---

## Medium

### F2 — `_selectedTagIds` is never reconciled against the live tag list

`chore_detail_screen.dart:31`, `:298-337`

`_selectedTagIds` is seeded once from `getTagIdsForChore` (`:75`) and mutated only by chip taps. `tagsProvider` is watched reactively (`:298`) — correct, and the QUIRK-free replacement for MAUI's `ReturningFromTagsMessage` reload — but the selection set is never intersected with the tags that actually still exist. Besides feeding F1, this means a stale id round-trips into `setChoreTags` for any tag deleted while the editor is open. One line inside the `data:` branch (drop ids not present in `tags`) removes the entire class.

### F3 — Save is a silent no-op when the chore failed to load

`chore_detail_screen.dart:159-160` — `final original = _originalChore; if (original == null) return;`

`_loadExisting` (`:60-86`) has no error handling and tolerates a null result: if the chore was deleted (or the read threw), `_loading` still flips false and the user gets a *blank, editable form* whose Save button does nothing, forever, with no message. Typing a name and tapping Save loses the input on back-navigation. MAUI's equivalent at least materialises a new `Chore` object (`ChoreDetailViewModel.cs:116-119`). Minimum fix: surface "not found" and close, or treat a null load as an error state.

### F4 — Tests do not cover three things the contract calls out

`app/test/chore_detail_screen_test.dart`

- **Mission Reminder flag**: no test asserts `isNotificationEnabled` is persisted, in either mode. The implementation is correct (`:155`, `:166`, default `true` at `:36` matching `ChoreBuddy/Models/Chore.cs:42`) — but it is entirely unenforced, so a regression is free.
- **Registry Conflict on insert**: contract item 2 says *both* insert and rename. Only the rename path is tested (`chore_detail_screen_test.dart:135-176`). The insert path works (`insertChore` → `_guardUniqueName`, `app_database.dart:147-152`) but is untested.
- **Keyboard dismissal** is a PRESERVE row (`behavior-inventory.md:50`) with zero test coverage. Hard to test in a widget test, but then it should be stated as a known gap rather than silently absent.

Everything the tests *do* claim, they genuinely assert: DB checks go through one-shot selects (`:51-54`, `:262-264`, `:311`, `:331`), the pop assertion is real (`:87-88`), the record-edit test verifies the prefill before editing (`:250-254`).

### F5 — New-chore due date defaults to *now*, MAUI defaults to *tomorrow*

`chore_detail_screen.dart:33` (`_selectedDate = DateTime.now()`) vs `ChoreDetailViewModel.cs:73` (`SelectedDate = DateTime.Today.AddDays(1)`).

Flipping the due-date switch on a new chore therefore produces a chore due at the current instant — immediately overdue, red on the list the moment it is created. MAUI's default lands a day out. User-visible behavioral divergence, trivially fixed.

---

## Low

### F6 — Edit-mode save writes a snapshot taken at load time

`chore_detail_screen.dart:161-168` uses `original.copyWith(...)` with `update(chores).replace(...)` (`app_database.dart:154-159`), which writes *every* column. `createdAt` and `isActive` come from `_originalChore`, captured in `initState`. The contract ("edit updates without touching createdAt/isActive") is satisfied for the normal flow, and I found no reachable path that mutates those columns while the full-screen detail route is on top of the shell — but it is a lost-update by construction rather than by intent. A targeted `update(...).write(ChoresCompanion(...))` with only the four edited columns would make it structurally safe.

### F7 — No in-flight guard on Save

`chore_detail_screen.dart:274-279` — the button has no disabled/`_saving` state and `_save` is re-entrant. Two activations inside the async window would double-insert (new mode) or double-`context.pop()` (edit mode; `mounted` stays true through the pop transition). In practice `_ModalScopeState` ignores pointer events on a route animating in reverse, which makes this hard to hit — reported as plausible, not confirmed.

### F8 — Keyboard dismissal is only genuinely handled on the save path

`chore_detail_screen.dart:129` unfocuses *before* `context.pop()` — correct, and no platform-channel hack (spec item 5 satisfied in letter).

`chore_detail_screen.dart:247-252`, however, unfocuses inside `onPopInvokedWithResult` with `didPop == true` — i.e. *after* the route is already gone. At that point `primaryFocus` is likely the destination route's node, so the call does nothing for the departing keyboard and can plausibly steal focus from the screen being returned to. Unfocusing before initiating the pop (or on `deactivate`) would match the PRESERVE intent more directly.

### F9 — This test file diverges from the project's ticker convention

`chore_detail_screen_test.dart:27-31` overrides only `appDatabaseProvider`. Every other widget test in the repo also overrides `tickerProvider`/`nowProvider` (`completion_flow_test.dart:47-48`, `chores_screen_test.dart:48-52`) because `chore_card.dart:21` watches `nowProvider`, which spins up a live `Timer.periodic(1s)` (`chore_providers.dart:131-143`).

I checked this specifically (contract item 6). It does not hang: pushing the detail route flips `choresTabVisibleProvider` false via the router listener (`app_router.dart:76-85`), which swaps the ticker for `Stream.empty()` (`chore_providers.dart:145-151`), and `pumpAndSettle` exits on the first quiet frame regardless. The `unmount` helper (`:46-49`) disposes the scope so no pending timer trips the test teardown. So: safe, but safe by two indirections. Overriding the ticker like the sibling tests do would make it safe by construction.

### F10 — `app_router.dart:65-68` hardcodes "Not Found" / "Chore not found"

Outside the reviewed diff and pre-existing, but it is the one user-visible copy on this route family that does not go through `AppStrings`.

---

## Verified clean

- **Registry Conflict**, both paths: insert (`app_database.dart:147-152`) and rename (`:154-159`) both funnel through `_guardUniqueName`; `COLLATE NOCASE` on the name column (`tables.dart:15`) gives MAUI's case-insensitivity. On conflict `setChoreTags` is never reached, no `context.pop()` runs, and no form state is touched — input fully preserved (asserted at `chore_detail_screen_test.dart:169-173`). Copy matches MAUI verbatim, including "Roger That" (`superhero_strings.dart:218`).
- **Due-switch off** clears `nextDueDate` *and* resets recurrence to `none` (`chore_detail_screen.dart:134-145`), exactly matching `ChoreDetailViewModel.cs:359-368`.
- **History**: date + note both persisted through `updateCompletionRecord` (`chore_detail_screen.dart:206-213`), dialog prefilled from the record (`completion_dialog.dart:55-58`) — the same MAUI reuse of `CompletionPopup`. Delete confirms with Expunge/Keep Record (`:216-240`), cancel returns `false` from `confirmDismiss` so the row stays. Empty state renders only in edit mode with zero records; the whole history block is gated on `!_isNew` (`:280-290`), so new-chore mode renders no history section at all — matches `ChoreDetailsPage.xaml:174` and inventory row 47.
- **Derived last-completed reordering**: no cached value anywhere. `watchActiveChoresWithDetails` (`app_database.dart:45-55`) recomputes the latest record per chore and the query `readsFrom: completionRecords`, so editing a record's date reorders the list card reactively. This is strictly better than MAUI's forward-only `record.CompletedAt >= Chore.LastCompleted` patch (`ChoreDetailViewModel.cs:325-330`), which leaves a stale `LastCompleted` when the newest record is edited *backwards*. No `ChoresDataChangedMessage` equivalent needed.
- **Ordering ties**: both the derivation subquery (`app_database.dart:52`) and the history list (`app_database.dart:128-131`) break ties on `id DESC`. Editing `completedAt` into a tie is deterministic and consistent between the two.
- **`/tags` round-trip**: reactive `tagsProvider`, no reload message, no `IsReturningFromSubPage` flag. QUIRK avoided.
- **No QUIRK recreation** anywhere in the screen: no prefetch/`ApplyPrefetchedData` split, no deferred collection swap, no opacity-0.01 measurement, no message bus, no busy-gated empty state race.
- **Recurrence display names and order** match MAUI exactly — `None / Daily / Every Other Day / Weekly / Monthly` (`tables.dart:3-9`, `superhero_strings.dart:76-84` vs `ChoreBuddy/Models/Chore.cs:7-15`).
- **All copy via `AppStrings`** in the reviewed files; no hardcoded user-visible strings in `chore_detail_screen.dart`.
- **Back-navigation mid-save** is guarded: `if (!mounted) return;` before both the pop (`:174`) and the conflict dialog (`:177`).
- **`getChoreById` / `getTagIdsForChore`** (`app_database.dart:135-143`) are plain one-shot selects — no stream, no `.first` hang hazard.
