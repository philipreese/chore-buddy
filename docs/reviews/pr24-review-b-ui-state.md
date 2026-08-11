# Adversarial review B — UI & state (PR #24, slices 10–25)

**Scope reviewed:** `app/lib/features/chores/presentation/`, `app/lib/features/settings/presentation/`,
`app/lib/features/tags/`, all nine voices in `app/lib/core/strings/`, `app/lib/features/shell/` +
`app/lib/core/router/`, plus the seams they touch (`app.dart`, `widget_sync_service.dart`,
`notification_service.dart`, `snooze_service.dart`).

**Method note / limitation:** no shell tool was available in this environment, so I could not run
`git diff main...HEAD` or `flutter test`. Every finding below is derived from reading the current
tree plus the existing test suite (to establish what is *not* covered). Nothing here required a
throwaway probe to write, and the working tree is untouched — `git status` is unchanged from the
start of the review. Findings that are reasoning-only rather than read-off-the-code are labelled
**SPECULATION**.

**Verdict: FAIL** — 1 blocking finding.

---

## Blocking

### B1 — Snooze confirmation always says "tomorrow", whatever target the user picked

*All nine voices; `snooze_flow.dart:52`.*

Spec 20 replaced the instant "snooze to tomorrow" tap with a picker offering four targets
(`snooze_options_sheet.dart:68-95`): Tomorrow, In 3 Days, Next Week, Pick a Date (up to a year out,
`snooze_options_sheet.dart:39`). `SnoozeService` honours the chosen `targetDate`
(`snooze_service.dart:34-38`). But the confirmation snackbar is still the parameterless getter
`strings.choreSnoozed`, and every voice hardcodes *tomorrow*:

| voice | `choreSnoozed` |
|---|---|
| standard | `Chore postponed to tomorrow` (`standard_strings.dart:408`) |
| superhero | `Mission postponed to tomorrow` (`superhero_strings.dart:408`) |
| wheelOfTime | `Thread postponed to tomorrow` (`wheel_of_time_strings.dart:416`) |
| missionControl | `Launch held until tomorrow` (`mission_control_strings.dart:404`) |
| noir | `Case shelved until tomorrow` (`noir_strings.dart:403`) |
| butler | `Duty postponed until tomorrow` (`butler_strings.dart:407`) |
| drillSergeant | `Task deferred to tomorrow` (`drill_sergeant_strings.dart:406`) |
| cozy | `Tucked away until tomorrow 🫖` (`cozy_strings.dart:406`) |
| grandma | `Pushed off until tomorrow... as expected.` (`grandma_strings.dart:408`) |

**Repro.** Chore due today. Tap the snooze icon → sheet → **Next Week**. The row's due date moves
+7 days (correct), and the snackbar reads "Chore postponed to tomorrow". Same for *In 3 Days* and
for any date chosen from *Pick a Date*. The user is told a due date that is not the one that was
written. Because `snoozeChoreFlow` is fire-and-forget (no undo token, by design —
`snooze_flow.dart:13-17`), the snackbar is the *only* feedback the action produces.

**Why the tests don't catch it.** `snooze_flow_test.dart:83` taps `snooze_option_tomorrow` and only
then asserts `find.text(strings.choreSnoozed)` at line 102 — the one path where the copy happens to
be true. `chores_screen_test.dart:808-811` asserts the other three options *exist* but never taps
them.

**Fix direction.** Make it parameterised — `String choreSnoozed(String date)` — and pass the
formatted target from `snooze_flow.dart` (`formatChoreDate(updated.nextDueDate)` is already in
scope after the re-read at line 43). A voice-neutral fallback ("Rescheduled") would also work but
loses information the user just chose. Add a `snooze_flow_test` case for the Next Week path.

**Related, same root cause (not separately counted):** `snoozeAction` — the card's snooze-button
tooltip — is also frozen at the pre-picker wording in several voices: `Not Today` (standard,
superhero), `Not Tonight` (noir), `Rest Until Tomorrow` (cozy, `cozy_strings.dart:404`), `Not Yet`
(wheelOfTime). The control now opens a sheet titled `snoozeSheetTitle` ("Reschedule Chore") that can
push a chore a year out.

---

## Should-fix

### S1 — `_animateToRowIndex`'s fixed 132 px row estimate only works for the minimal card

*`chores_screen.dart:34`, `:148-169`.*

`_estimatedItemExtent = 132` is applied to every `ChoreItemRow`. Actual `ChoreCard` height
(`chore_card.dart:126-309`) is not close to uniform:

- minimal (no tags, no history, no due date detail block): margin 12 + padding 32 + icon row 36 +
  10 + due line ~20 ≈ **110 px**
- \+ tag chips (`chore_card.dart:165-205`): +8 + ~32 ≈ **150 px**
- \+ the last-completed/note block (`chore_card.dart:207-248`, gated on `showDetailsOnCards`, which
  defaults **true** — `chore_providers.dart:94`): +10 + ~36 ≈ **196 px**

So the per-row error ranges from **+22 px** (minimal cards, overshoot) to **−64 px** (tagged card
with a history block, undershoot). At row 12 the undershoot is ~770 px — roughly a full viewport
below where the animation stops. The target chore is not on screen at all.

**Repro.** ~20 active chores, each with at least one tag and one logged completion (the ordinary
state of a used install). Tap a notification for a chore ~12 rows down. `_scrollToChore` resolves
the index correctly and `_animateToRowIndex` animates to `banner + header + 8 + 12*132`, which is
short of the real offset by ~770 px.

**Why the test passes anyway.** `chores_screen_test.dart:414-453` inserts 40 chores with **no tags
and no completion records** (uniform ~110 px) and targets **row 39 — the last one**. The 22 px/card
overshoot accumulates to ~860 px past the end, and `ClampingScrollPhysics` silently clamps it to
`maxScrollExtent`, landing at the bottom where the target happens to be. The test therefore
validates the clamp, not the offset math. Any mid-list target, or any non-minimal card, is
uncovered.

**Fix direction.** Either give the rows a real fixed extent (`SliverList` →
`SliverVariedExtentList`/`itemExtentBuilder`, with the builder returning the same per-row-type
extents the offset walk uses — that keeps the "one source of truth" property the doc comment claims),
or do the jump in two passes: `jumpTo(estimate)`, then in a post-frame callback use
`Scrollable.ensureVisible` on the now-built target's `GlobalKey` for the correction.

### S2 — Stat-chip tap is a silent no-op when a filter hides that section

*`chores_screen.dart:99-124` + `chores_banner.dart:26-45`.*

The banner's counts are deliberately computed from **unfiltered** actives
(`chores_banner.dart:15`, `:26-45`). `_scrollToSection` builds rows from
`filteredAndSortedChoresProvider` — the **filtered** list — and bails on `index == -1`
(`chores_screen.dart:121`) with no fallback.

**Repro.** Two overdue chores named "Bins" and "Gutters", plus one named "Zebra". Search "Zebra".
The overdue chip still reads **2** (unfiltered). Tap it. `setOrder(urgency, ascending)` fires, the
sort-change listener (`chores_screen.dart:192-200`) jumps the list to offset 0, `_scrollToSection`
finds no overdue header in the filtered rows and returns. The user tapped a chip reading "2" and
got a jump to the top of a list containing nothing overdue. If the sort was *already*
urgency-ascending, `SortState.==` (`chore_providers.dart:28-33`) suppresses the notification and
the tap does literally nothing — no visual response at all.

The sibling path already solves exactly this: `_scrollToChore` clears search + tag filters and
retries once rather than abandoning a chore the user can plainly reach
(`chores_screen.dart:79-88`).

**Fix direction.** Mirror `_scrollToChore`: on `index == -1`, clear
`choreSearchQueryProvider`/`selectedTagFilterIdsProvider` and retry once. Alternative (bigger
behaviour change): compute the chip counts from the filtered list so the number and the list agree —
but then the chip stops being the "everything you owe" summary it's documented as.

### S3 — Switching voice does not restate already-scheduled notifications; the code comment says it does

*`app.dart:110-123`, contradicted by `notification_service.dart:34-42`.*

`_onVoiceChanged` calls `updateChannel(...)` and syncs the widget. Its doc comment claims:

> the channel id doesn't change, so recreating it with the new voice's name/description is enough
> for both **already-scheduled and future reminders** to pick up the new copy

That is false. `scheduleChoreNotification` bakes `title`, `body`, `completeActionLabel` and
`snoozeActionLabel` into the platform schedule at schedule time
(`notification_service.dart:36-41`). The channel name/description only ever appear in Android's
per-app notification settings, never in a posted notification. A reminder scheduled under Superhero
fires — after a switch to Grandma — as "Mission: Water Plants" / "It's time to engage your next
mission." with a **COMPLETE** action, not "FINALLY".

**Repro.** Superhero voice, chore due in 10 minutes (reminder already scheduled). Switch to Grandma.
Wait for the reminder: old voice throughout.

**Fix direction.** Add `await ref.read(notificationServiceProvider).rescheduleAll()` to
`_onVoiceChanged`. That method already exists for exactly this shape of problem
(`notification_service.dart:59-61, 91-97`) and is already used when the global notifications toggle
flips back on. Also correct the comment.

**Same gap, second surface:** `_initShortcuts` registers the launcher long-press shortcuts with
`strings.shortcutNewMissionLabel` / `shortcutOverdueLabel` (`app.dart:137-148`) and
`_onVoiceChanged` never re-registers them, so the launcher keeps the old voice's labels until the
app is restarted.

### S4 — Mission Control: the overdue section header is semantically inverted, and collides with the snooze label

*`mission_control_strings.dart:61` and `:402`.*

```dart
String get sectionOverdueLabel => 'Holding at T-minus…';   // line 61
String get snoozeAction        => 'Holding at T-minus…';   // line 402
```

"Holding at T-minus" means a launch deliberately paused *before* liftoff — which is precisely what
**snoozing** does, and the opposite of "you are late". Rendered by `ChoreSectionHeader`
(`chore_section_header.dart:69`) in `colorScheme.error` and uppercased, the most urgent group on the
screen is captioned with the phrase for "intentionally on hold". The identical string is
simultaneously the snooze button's tooltip on every card in that section
(`chore_card.dart:287`), so the header and the control that *defers* a chore say the same thing.

**Fix direction.** Give overdue a late-reading phrase ("PAST LAUNCH WINDOW", "SCRUBBED", "OVERDUE —
NO-GO") and leave "Holding at T-minus…" to `snoozeAction` alone.

### S5 — Cozy: the archive swipe reads as a snooze, and permanent delete is indistinguishable from three non-destructive removals

*`cozy_strings.dart:351, 404, 183, 353, 145, 229`.*

```dart
String get archiveAction => 'Rest';                 // :351  swipe-right background label
String get snoozeAction  => 'Rest Until Tomorrow';  // :404  the snooze button
```

The swipe-right background (`chore_card.dart:42`) reads **Rest**; the button that actually defers a
chore by a day reads **Rest Until Tomorrow**. A user swiping right reasonably expects the temporal
one and gets the archive confirm instead. Archiving is reversible, so this is not blocking — but it
is a mislabelled swipe affordance on the one gesture that just got a confirm dialog added to it
because of accidental-archive feedback (`chore_card.dart:72-75`).

Separately, Cozy spends the word **Remove** on four different operations of wildly different
severity:

- `scrapConfirm` = `'Remove'` (`:183`) — permanently deletes the chore *and all its history*
- `deleteAction` = `'Remove'` (`:353`) — the red swipe-left background
- `expungeRecordConfirm` = `'Remove'` (`:145`) — deletes one history row
- `scrubTagConfirm` = `'Remove'` (`:229`) — deletes a tag

`scrapMessage` does carry the "cannot be undone" warning, so this is ambiguity rather than an
outright lie — but "Remove" is the one word in that dialog the eye lands on, and it reads as
"remove from the list" (i.e. archive), which is the *other* swipe.

**Fix direction.** Rename `archiveAction` to something restful-but-not-temporal ("Set Aside", "Put
Away" — it already uses "Put Away" for `decommissionConfirm` at `:176`, so the two disagree with
each other too), and make `scrapConfirm` unmistakably terminal ("Remove Forever", "Throw Out" à la
Grandma).

### S6 — Superhero (the default voice): the backup-overwrite confirm button reads "Sync Data"

*`superhero_strings.dart:290`, used at `backup_settings_screen.dart:91`.*

The import-backup dialog's action row is **ABORT** / **Sync Data**. Every other voice labels that
button "Restore". The operation is `backupService.importDatabase(path)`
(`backup_settings_screen.dart:98`) — a full overwrite of the live database. "Sync" is the standard
word for a *merging*, non-destructive reconciliation; it is the wrong verb for "replace everything
you have with this file". Superhero is the default voice (`voice_provider.dart:79-81`), so this is
the label most users see.

Mitigating: the dialog body does warn — "Warning: Importing external intel will overwrite your
current mission history. Proceed with data sync?" (`superhero_strings.dart:250-251`) — and the
cancel side says ABORT. That is why this is Should-fix rather than Blocking. The button label alone
still misrepresents the action.

**Fix direction.** `restoreConfirmAction => 'Overwrite Records'` (or 'Restore Archives', matching its
own dialog title at `:248`).

### S7 — Noir: "Close Case" is both "log a completion" and "archive the chore"

*`noir_strings.dart:160` (`logButton`) and `:175` (`decommissionConfirm`).*

The completion dialog's confirm button (`completion_dialog.dart:148`) and the archive-swipe confirm
button (`chore_card.dart:88`) render the identical string. The two produce opposite outcomes: one
records a completion and rolls the due date forward; the other removes the chore from the active
list. Different dialogs give some context, but the muscle-memory target is the same words in the
same position.

Also in Noir: `abortButton => 'DROP IT'` (`:162`) is the **cancel** on the completion dialog. "Drop
it" reads as "abandon this chore", not "dismiss this sheet".

**Fix direction.** Keep "CLOSE CASE" for the completion (it is the better fit) and move archive to
something filing-shaped — "Cold Storage", "File Away", "Shelve It".

### S8 — The "Overdue" launcher shortcut clears the search but not the tag filter

*`app.dart:155-163`.*

```dart
ref.read(sortStateProvider.notifier).setOrder(urgency, ascending);
ref.read(choreSearchQueryProvider.notifier).setQuery('');   // search only
```

The comment says "drop any active search so nothing hides them", but an active tag filter hides
overdue chores just as thoroughly (`filteredAndSortedChoresProvider` →
`filterChores(..., selectedTagIds)`, `chore_providers.dart:174-178`). Long-press → Overdue while a
tag filter is on lands on a list that may show nothing overdue at all.
`_scrollToChore` clears **both** for the same reason (`chores_screen.dart:83-84`).

**Fix direction.** Add `ref.read(selectedTagFilterIdsProvider.notifier).setTags({})` alongside.

---

## Nits

### N1 — Un-voiced English literals in a voice-driven UI

Four user-visible strings bypass `AppStrings` entirely, so they stay English-plain in all nine
voices:

- `settings_screen.dart:201` — `const SettingsSectionHeader(label: 'Voice')`, the only section
  header on that screen not sourced from `strings` (compare `:168`, `:204`, `:231`, `:256`). There
  is no `voiceSectionTitle` member on `AppStrings`.
- `chore_detail_screen.dart:1107` — the icon picker's `'None'` cell.
- `tag_manager_screen.dart:210` — `Text('Error: $error')` instead of `strings.genericError(error)`,
  which every other error surface uses (`chores_screen.dart:289`, `mission_log_screen.dart:37`,
  `chore_detail_screen.dart:1005`).
- `mission_log_screen.dart:181-182` — the bar-chart axis labels `'Now'` and `'-${n}w'`.

### N2 — Saving a chore with an empty name does nothing at all

`chore_detail_screen.dart:238-239`: `if (name.isEmpty) return;` — no error text, no snackbar, the
Save button stays enabled. Tapping it is indistinguishable from the app hanging. Compare the
interval field, which does surface `recurrenceIntervalRangeError` (`:259-262`). Suggest either
disabling the button on an empty name or setting an `errorText` on the name field.

### N3 — Duplicating a chore silently rewrites an out-of-range interval to 3

`chore_detail_screen.dart:367-369` passes `_displayedInterval`, which clamps anything outside 1–365
to `3` (`:229-233`). Typing `999` into the interval field and hitting **Duplicate** (rather than
Save, which would correctly block) produces a copy with interval 3 and no warning. Use the raw
parse and let the new screen's own `_save` validation reject it, or block Duplicate while
`_intervalErrorText` would be non-null.

### N4 — "Delete All Chores" is the one mutation with no explicit widget sync

`settings_screen.dart:40-45` deletes every chore and cancels every notification but never calls
`widgetSyncService.sync()`. Every other mutation site does — `chore_card.dart:124`,
`archived_chore_card.dart:50`, `chore_detail_screen.dart:312`, `completion_flow.dart:87,116`,
`snooze_flow.dart:46`, `backup_service.dart:239` — and `widget_sync_service.dart:148-154`
documents that as the contract. In practice the stale rows are corrected by the
`AppLifecycleState.paused` sync (`app.dart:91-92`) before the user can look at the home screen, which
is why this is a nit and not a bug: it works by accident of the lifecycle hook rather than by the
stated rule.

### N5 — `_buildTagPicker` mutates state during build

`chore_detail_screen.dart:592-594` assigns `_selectedTagIds = _selectedTagIds.intersection(...)`
inside `build()`, outside `setState`. It is idempotent so it cannot loop, but a state field written
during build is the kind of thing that stops being harmless the moment someone adds a second reader.
Move it into the `tagsProvider` listener or a `ref.listen`.

### N6 — Archive AppBar's purge tooltip is the confirm-button string

`app_shell.dart:68`: `tooltip: strings.purgeConfirm`. The tooltip on the *entry point* renders the
label of the *terminal* action — "Burn All Files" (noir), "Balefire All" (wheelOfTime), "PURGE ALL"
(drillSergeant). `purgeTitle` would be the right member.

### N7 — Undo on a superseded snackbar is silently inert — **SPECULATION**

`completion_flow.dart:72` clears the pending token before the `await completionService.completeChore`
at `:74`, but the previous completion's snackbar is not hidden until `:95`. In the window between,
the old snackbar is on screen with a live UNDO whose guard `pendingNotifier.current == token`
(`:106`) can no longer match. Tapping it does nothing and gives no feedback. Narrow (one DB write
wide) and non-destructive; I did not reproduce it.

### N8 — `ChoreCard.onDismissed` uses `ref` across two awaits — **SPECULATION**

`chore_card.dart:114-125` reads `widgetSyncServiceProvider` off the `ConsumerWidget`'s `ref` after
`await db.archiveChore(...)`, by which time the drift stream may have rebuilt the list without this
card and unmounted its element. `completeChoreFlow` explicitly captures every service *before* the
first await for exactly this reason (`completion_flow.dart:40-50`). The same pattern already exists
on `main` in `archived_chore_card.dart:50` and the app ships, so the timing evidently works out in
practice; flagging it as a latent inconsistency rather than a live crash.

### N9 — Stat chips are the only strings identical across all nine voices

`statOverdueLabel` / `statDueTodayLabel` / `statUpcomingLabel` are `'Overdue'` / `'Today'` /
`'Upcoming'` in every voice, while the sections they navigate to are heavily voiced. Tapping
**Overdue** in Wheel of Time lands on a header reading **THE SHADOW GROWS**; in Butler, **AWAITING
URGENT ATTENTION**; in Cozy, **WAITING PATIENTLY 🌿**. The tap target and its destination share no
words. Probably deliberate (chips are width-constrained), but it does make the navigation
relationship invisible.

### N10 — `guessChoreEmoji` priority is keyword-list order, not name order

`icon_guesser.dart:121-125` scans `_keywordEmojis` in declaration order, so the *earliest-declared*
keyword wins regardless of where it appears in the name. `'water'` is declared at index 8 and
`'filter'` at index 60, so **"Change water filter"** guesses 🪴 (potted plant) rather than 🌀.
Likewise "Fill the propane tank" → 🐠. The doc comment at `:6-8` describes the mechanism accurately,
so this is a data-ordering nit, not a code bug.

---

## Checks run that came back clean

- **No parameterised voice member drops its parameter.** Regex over `core/strings/` for
  `String \w+\([^)]+\) =>[^;$]*;` (an arrow body containing no `$` interpolation at all) returned
  zero matches across all nine files.
- **Both-parameter members use both parameters.** `bannerStatsMore(count, delta)`,
  `bannerStatsFewer(count, delta)` and `missionLogBestStreakLabel(choreName, streak)` verified
  individually across all nine voices — every one interpolates both.
- **`_scrollToSection` vs the sort-change jump-to-0 does not race.** `setOrder` notifies the
  `ref.listen` in `chores_screen.dart:192` synchronously, so `jumpTo(0)`'s post-frame callback is
  registered *before* `_scrollToSection`'s `animateTo` callback at `:104`. They run in that order in
  the same post-frame batch; the animation wins, as the comment at `:186-191` claims.
- **`_scrollToChore`'s clear-filters retry reads post-reorder rows.** `filteredAndSortedChoresProvider`
  is a synchronous `Provider` returning `AsyncValue` (`chore_providers.dart:166-185`), so clearing
  the filters recomputes it eagerly on the next `ref.read`; the recursive call re-registers a fresh
  post-frame callback rather than reading stale rows.
- **Interval field round-trip.** customDays(14) → weekly → customDays preserves 14: the dropdown's
  `onChanged` only seeds `'3'` when the controller is empty (`chore_detail_screen.dart:752-755`) and
  nothing clears it on the way out.
- **Confetti overlay.** `showCompletionConfetti` is re-entrant (each call inserts its own
  `OverlayEntry` with its own `removed` latch, `completion_confetti.dart:28-40`); the entry is
  `IgnorePointer`-wrapped so it cannot swallow a dialog's taps (`:132`); `disableAnimationsOf` is
  checked at call time only, so toggling it mid-flight just lets the current 900 ms burst finish.
- **Icon-picker dirty flag.** Duplicate-prefill and load-existing both set `_emojiDirty = true`
  (`chore_detail_screen.dart:111`, `:174`), so a later name edit cannot clobber a carried-over or
  stored icon; picking "None" also sets it (`:582`), so the guess does not come back on rename.
  Behaviour matches the documented intent in all three cases.
- **Voice persistence.** Round-trips through `settings.voice` (`settings_prefs_service.dart:53,
  77-86, 154-158`), is applied at startup before the first frame (`settings_hydration.dart:32-34`),
  and the background isolate resolves the same persisted voice rather than defaulting
  (`background_completion.dart:128-129`, `:208-209`).
- **Backup sub-page last-backup subtitle.** `settings_screen.dart:155-161` picks the later of manual
  and auto correctly, including the only-one-exists and neither-exists cases.
- **Router back-stack.** `/settings/backup` nests under `/settings` on the root navigator, so
  `context.push('/settings/backup')` pops back to `/settings`; `/chores/new` is declared before
  `/chores/:id` (`app_router.dart:68`, `:76`) so it cannot be swallowed by the `:id` pattern.
