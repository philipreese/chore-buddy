# Slice 05 review — completion, undo, haptics

**Verdict: FAIL** — one contract-1 breach (recurrence produces the wrong calendar day across a DST fall-back transition) plus one read-modify-write path that can leave a surviving completion record without its due-date advance. Everything else in the contract holds up.

Scope reviewed at HEAD (`c3f6380`): `completion_service.dart`, `recurrence_calculator.dart`, `completion_flow.dart`, `widgets/completion_dialog.dart`, `completion_providers.dart`, `haptics_service.dart`, and the three test files. Cross-checked against `ChoreBuddy/ViewModels/MainViewModel.cs:266-322`, `ChoreBuddy/Views/CompletionPopup.xaml.cs`, and `specs/05-completion-undo-haptics.md`.

I did not run `flutter analyze` / `flutter test` (read-only review, stripped env). All findings are from source reading; each is labelled CONFIRMED (mechanically derivable from the code) or PLAUSIBLE (depends on runtime/package behavior I could not inspect).

---

## Contract checklist

| # | Contract item | Result |
|---|---|---|
| 1 | Recurrence math mirrors MAUI | **BREACH** — see F1. Interval/time-of-day/clamping logic is otherwise exact. |
| 2 | Undo restores record + prior due date; second completion commits the first; no cross-revert | Holds. See "Cross-revert analysis". |
| 3 | Writes transactional; no record-without-advance | **BREACH (conditional)** — the transaction is correct, but the value it writes is computed from a stale snapshot. See F2/F3. |
| 4 | Haptics once, only when enabled, never on cancel/undo | Holds (deviates from MAUI by design — F6). Untested for the disabled case (F8). |
| 5 | Dialog defaults to now, null on cancel/barrier, trims note | Holds. |
| 6 | Tests test what they claim | Mostly. Two real gaps — F8. |
| 7 | All copy via AppStrings | Holds; casing differs from MAUI (F9). |

### None-recurrence: MAUI clears

`MainViewModel.cs:296-298` sets `chore.NextDueDate = null` for `RecurranceType.None`. `recurrence_calculator.dart:13-15` returns `null`. **Correct.** Note that `specs/05-completion-undo-haptics.md:24` asserts the opposite in its parenthetical ("None leaves due date untouched; replicate exactly") — the spec text is wrong, the implementation followed the MAUI source. The spec line should be corrected so a future slice doesn't "fix" this back.

### Cross-revert analysis (the `.closed.then` hunt item)

No reachable cross-revert. The sequence in `completion_flow.dart:35-53` is `clear()` → write → `set(token2)` → `hideCurrentSnackBar()`. The first snackbar's `.closed` therefore resolves *after* `pendingCompletionProvider` already holds token2, and the stale closure's guard (`completion_flow.dart:72`) compares token1 against token2 and correctly no-ops.

The guard is value equality (`completion_service.dart:21-27`) over `recordId`, so it would misfire if a record id were ever reused. It cannot be: drift emits `PRIMARY KEY AUTOINCREMENT` for `CompletionRecords.id` (`app_database.g.dart:498`), which forbids rowid reuse even after deletes. The safety of the undo guard thus rests on a schema detail nothing documents or enforces — `identical()` semantics (or a monotonic token counter) would make it structurally safe instead of incidentally safe. Not a finding; worth a comment.

Also checked and clean: tapping UNDO on the first snackbar during the second completion's DB write is a correct no-op (pending is `null` in that window, guard fails, first stays committed).

---

## Findings

### F1 — DST fall-back makes daily/everyOtherDay/weekly land on the wrong calendar day (CONFIRMED, high)

`app/lib/features/chores/domain/recurrence_calculator.dart:24,26,28`

```dart
return _combine(completedDate.add(const Duration(days: 1)), timeSource);
```

`Duration` addition on a **local** `DateTime` adds absolute elapsed time, not calendar days. `_combine` (`recurrence_calculator.dart:40-62`) then takes `.year/.month/.day` off that result. On a DST fall-back day (25 hours long), midnight + 24h lands at 23:00 *the same day*.

Concrete failure (US Eastern, DST ends 2026-11-01):
- chore is `daily`, prior due `2026-10-31 08:00`
- user completes at `2026-11-01 10:00`
- `_dateOnly` → `2026-11-01 00:00 EDT`; `+ Duration(days:1)` → `2026-11-01 23:00 EST`; `_combine` → **next due `2026-11-01 08:00`** — the same day it was completed, and already in the past.
- Weekly is hit the same way: completing on `2026-10-28` yields `2026-11-03` instead of `2026-11-04`.

C#'s `result.CompletedAt.Date.AddDays(1)` (`MainViewModel.cs:285`) is calendar arithmetic on a `DateTimeKind.Unspecified` value and does not shift. This is a direct contract-1 divergence, and it silently produces an overdue chore.

Fix: `DateTime(d.year, d.month, d.day + n)` (Dart normalizes overflow), same construction style already used correctly in `_addOneMonthClamped` (`recurrence_calculator.dart:66-84`), which is not affected.

### F2 — completion is computed from a stale card snapshot, not the row being written (CONFIRMED mechanism, PLAUSIBLE reachability, medium)

`app/lib/features/chores/presentation/completion_flow.dart:37-41` → `app/lib/features/chores/domain/completion_service.dart:46-51`

`completeChoreFlow` passes `chore.chore` — the `ChoreEntity` captured by the `ChoreCard` widget at its last build (`chore_card.dart:241-244`). `completeChore` reads `chore.nextDueDate` and `chore.recurrence` from that snapshot *outside* the transaction and then blindly overwrites the row inside it (`completion_service.dart:65-67`). Classic read-modify-write with the read outside the critical section: the transaction guarantees atomicity of the two writes but not that the value written is derived from current state.

Failure scenario: two completions of the same chore in quick succession. If the second card build hasn't yet received the first write from `watchActiveChoresWithDetails`, the second completion's `previousNextDueDate` is still `D0`. Undoing the second then restores `D0` while the first completion's record survives — a record with no corresponding due-date advance, which is exactly the contract-3 invariant. `completion_flow_test.dart:213-216` acknowledges this ordering sensitivity and calls `pumpAndSettle()` to avoid it, i.e. the test is written around the race rather than against it.

Reachability in production is limited by the modal dialog sitting between the two taps, which usually gives the stream time to propagate — hence PLAUSIBLE, not CONFIRMED. The fix is cheap and removes the class of bug: re-select the chore row inside `db.transaction` and compute the advance from that.

### F3 — undo blindly overwrites `nextDueDate`, clobbering any edit made during the 5s window (CONFIRMED, medium)

`app/lib/features/chores/domain/completion_service.dart:79-85`

`undoCompletion` writes `token.previousNextDueDate` with no check that the current value is still the one the completion wrote. The snackbar is shown on the ambient `ScaffoldMessenger` (`completion_flow.dart:52`) and survives navigation, so: complete a chore → tap through to its details page → change the due date → tap UNDO on the still-visible snackbar → the user's edit is silently reverted to the pre-completion value. Data loss of an explicit user action.

Guard the write on the expected current value (`..where((c) => c.id.equals(...) & c.nextDueDate.equalsNullable(expectedAfterCompletion))`) and skip the due-date restore when it doesn't match, or drop the token when the chore is edited.

### F4 — `ref` is used across async gaps and from callbacks that outlive the card (PLAUSIBLE, medium)

`app/lib/features/chores/presentation/completion_flow.dart:44,62,72`

`ref` is the `ChoreCard`'s `WidgetRef` (`chore_card.dart:20,243`). Line 44 reads `hapticsEnabledProvider` after `await completeChore(...)` with no mounted check (the only `context.mounted` check comes later, line 50). Lines 62 and 72 run from the snackbar action and from `.closed`, up to 5 seconds later — by which time the card can be gone: `Dismissible` swipe (`chore_card.dart:32`), a filter/search change dropping it from `filteredAndSortedChoresProvider`, or a tab switch (`tickerProvider`/`nowProvider` are `autoDispose`, `chore_providers.dart:145,153`).

I could not inspect the pinned `flutter_riverpod` source to confirm whether `WidgetRef.read` after unmount throws or silently uses a cached container, so this is PLAUSIBLE rather than CONFIRMED. Either way the pattern is wrong for a callback with a 5-second lifetime: capture `ref.read(hapticsEnabledProvider)`, the service, and the notifier into locals before the first `await` (the notifier already is, `completion_flow.dart:31`) and have the closures use only those.

### F5 — haptics is awaited before the snackbar, so a hung/failed vibration swallows the undo affordance (CONFIRMED, medium)

`app/lib/features/chores/presentation/completion_flow.dart:44-46`

```dart
if (ref.read(hapticsEnabledProvider)) {
  await ref.read(hapticsServiceProvider).completionFeedback();
}
```

The completion is already committed at this point. If the `HapticFeedback.vibrate()` platform call throws or stalls (no vibrator, OEM quirk), `showSnackBar` at line 54 is never reached: the write stands with no undo affordance and `pendingCompletionProvider` retains a token whose window can never be closed by the user. MAUI orders it the other way — snackbar first (`MainViewModel.cs:303-316`), haptics after (`MainViewModel.cs:318`). Show the snackbar first and fire haptics without awaiting (or wrap in try/catch).

### F6 — MAUI vibrates on undo; this doesn't (INFO, by design)

`MainViewModel.cs:309` calls `ProvideHapticFeedback(175)` inside the undo action. `completion_flow.dart:61-66` does not. The review contract (item 4: "never on cancel/undo") explicitly requires the new behavior, so the implementation is right — recording it so the divergence is a decision on the record rather than an oversight.

### F7 — 175ms pulse not reproducible (INFO, accepted)

`app/lib/core/services/haptics_service.dart:11-20`. `HapticFeedback.vibrate()` is a fixed-duration platform pulse; `specs/05-completion-undo-haptics.md:27` asks for 175ms. The deviation is documented in the doc comment and avoids a new dependency per the spec's "Do NOT". Fine.

### F8 — two real test gaps (CONFIRMED, medium)

1. **No timezone/DST coverage, and the existing date tests are environment-dependent.** `recurrence_calculator_test.dart:25-50` uses local `DateTime` and asserts against local `DateTime`, so the whole suite is evaluated in the host's zone. On a UTC CI box every case passes regardless of F1; on a developer machine in a DST zone the mid-transition cases would fail — but no such case is written, so F1 is invisible either way. `recurrence_calculator_test.dart:97-105` only covers UTC-ness preservation, which is the safe direction. Add a case pinned to a fall-back date, or make the calculator's day arithmetic calendar-based and assert `.day` explicitly.
2. **`hapticsEnabledProvider == false` is never exercised.** Contract item 4's "only when enabled" clause has no test. `completion_flow_test.dart:44` only overrides the *service*, never the enabled flag; a regression that dropped the `if` on `completion_flow.dart:44` would keep the whole suite green. Likewise nothing asserts haptics stays at 0 across an UNDO tap (`completion_flow_test.dart:172-180` checks db state only).

No polling-that-can't-fail or vacuous assertions found otherwise. The stacking test (`completion_flow_test.dart:185-231`) genuinely discriminates — it pins `historyAfterUndo.single.id == firstRecordId` (line 228), which fails if undo reverted the wrong completion. `unmount()` (lines 55-61) correctly drains the 5s timer.

Minor inconsistency worth reconciling: `completion_flow_test.dart:69-73` documents that `watchActiveChoresWithDetails().first` "can wait forever for a write that never comes", while `completion_service_test.dart:33,58,78,103,122` relies on exactly that call. Both can't be describing the same drift behavior; one of the two comments/patterns is stale.

### F9 — dialog copy loses MAUI's upper-casing (LOW)

`CompletionPopup.xaml.cs:24-25` upper-cases both the title and the button (`MISSION REPORT`, `LOG`). `superhero_strings.dart:97,103` render `Mission Report` / `Log`. `abortButton` is `'ABORT'` (line 105), so the casing is inconsistent even within the dialog. Cosmetic, but spec item 7 sources copy from the MAUI popup.

### F10 — barrier dismiss allowed where MAUI forbade it (INFO)

`completion_dialog.dart:20` uses `showDialog` with the default `barrierDismissible: true`; `CompletionPopup.xaml.cs:26` defaults `CanBeDismissedByTappingOutsideOfPopup` to `false`. Returning `null` on barrier dismiss is what review contract item 5 asks for and `completion_flow.dart:27` handles it, so no data risk — flagging only as a MAUI-parity difference.

---

## What's solid

- Transactionality on both paths (`completion_service.dart:56-70`, `79-85`) — no path writes the record without the due-date update or vice versa, given a correct input snapshot.
- Time-of-day preservation including the `previousDueDate ?? completedAt` fallback (`recurrence_calculator.dart:17`) matches `MainViewModel.cs:285-294`'s `(chore.NextDueDate?.TimeOfDay ?? result.CompletedAt.TimeOfDay)` exactly, sub-second components included.
- `_addOneMonthClamped` (`recurrence_calculator.dart:66-84`) is a faithful `DateTime.AddMonths(1)`, including the `DateTime(year, month + 1, 0)` last-day trick and the December→January rollover.
- Undo restoring the prior due date is a genuine improvement over MAUI, which only deleted the record (`MainViewModel.cs:307`) and left the advanced due date in place.
- Note trimming (`completion_dialog.dart:92`), initial value from `nowProvider` (`completion_flow.dart:25`), cancel → `null` → early return (`completion_dialog.dart:137`, `completion_flow.dart:27`).
- The slice-08 notification TODO is present and clearly marked (`completion_flow.dart:48`).

## Must fix before this slice is accepted

1. **F1** — calendar-day arithmetic in `recurrence_calculator.dart`, plus a DST regression test.
2. **F2** — compute the advance from the row read inside the transaction.
3. **F3** — make the undo due-date restore conditional on the expected current value.

F5 and F8 should land with them; they're each a few lines.
