# Spec 27 — Review-B fixes: snooze feedback, scroll math, voice copy, UI seams

## Role

Implement. Report to `$AER_OUTPUT_DIR/changes.md`. ONE-SHOT: complete synchronously; write changes.md before finishing. Run `flutter test` FOREGROUND to a log file (healthy ~30s; minutes = failures; never pipe through tail/head).

## Environment (stripped — set before builds)

- `ANDROID_HOME=C:\Android\sdk`, `ANDROID_NDK_HOME=C:\Android\sdk\ndk\28.2.13676358`, `JAVA_HOME=C:\Program Files\Android\openjdk\jdk-21.0.8`
- Flutter `C:\src\flutter\bin\flutter.bat`, Dart `C:\src\flutter\bin\dart.bat`

## Context

Adversarial review B (FULL DETAIL in `docs/reviews/pr24-review-b-ui-state.md` + `pr24-review-b-verdict.json` — READ IT FIRST) failed the branch with 1 blocker. This spec fixes the UI/state/voice findings. Do NOT touch `backup_service.dart`, `backup_validation.dart`, `stats_calculator.dart`, `auto_backup_core.dart`, `snooze_service.dart`, `app_database.dart`/`tables.dart`, or anything under `android/` — those belong to the parallel spec 26. (`snooze_flow.dart` is YOURS; the service under it is not — if the service needs a signature change to expose the written date, coordinate by NOT changing it: it already accepts targetDate, so the flow knows the date it requested.)

## Fix items

### Blocker

1. **Snooze snackbar lies**: replace `choreSnoozed` usage in `snooze_flow.dart` with a new parameterized `AppStrings` member (e.g. `choreSnoozedUntil(String date)`) rendering the ACTUAL chosen day via the existing `formatChoreDate`-style formatting; implement in ALL NINE voice files, each in its own register. Keep the old member only if something else uses it; otherwise remove it everywhere.

### Should-fix

2. **Scroll estimate**: `_animateToRowIndex`'s uniform 132px item estimate under-shoots tall cards (tags + details block). Make the per-row estimate content-aware: compute each row's estimated extent from its data (base + tags-present + details-visible increments; header rows keep theirs) and sum — same shared row-model walk the builder uses. Update/extend the scroll test to include tall cards (the review notes the current test passes only via physics clamping — make the new test actually assert landing within one card of the target with mixed-height rows).
3. **Stat-chip no-op under filters**: mirror the scroll-to-chore path — if the target section is missing because search/tag filters hide it, clear the filters and retry once (chores_screen.dart, `_scrollToSection`).
4. **Voice-change follow-through** (app.dart `_onVoiceChanged`): add `rescheduleAll()` so pending notifications restate in the new voice; also refresh launcher shortcut labels if the shortcut API exposes labels from strings (it does — find where shortcuts are registered and re-register). Correct the over-claiming comment.
5. **Voice copy defects** — fix each in place, keeping the voice's register but restoring semantic truth:
   - Mission Control: overdue section header must read as LATE (not "Holding…"), distinct from its snooze label.
   - Cozy: archive swipe label must read as archiving (not a snooze); differentiate the four "Remove"-labeled operations by severity.
   - Superhero: import-backup action must read as a destructive restore/overwrite, not "Sync Data".
   - Noir: completion vs archive must be distinct strings.
6. **Overdue shortcut**: clear the tag filter as well as the search query (app.dart:162 area).

### Lows (all in scope)

7. The four hardcoded user-visible strings (settings_screen.dart:201 area per report) move onto `AppStrings` (all nine voices).
8. Empty-name save: disable the save button when the trimmed name is empty (clear affordance instead of silent no-op).
9. Delete All Chores triggers a widget sync like every other mutation.
10. Archive purge tooltip uses the dialog-title string, not the confirm-button string (app_shell.dart:68).
11. `_buildTagPicker` build-time State-field write → proper state handling (chore_detail_screen.dart:593).
12. `ChoreCard.onDismissed`: capture everything needed from `ref` BEFORE the awaits (chore_card.dart:124).
13. **Section count pill visibility** (Philip's device feedback): in `chore_section_header.dart` the Upcoming/Unscheduled count pill uses `surfaceContainerHighest`, which is imperceptible against `surface` under dynamic color (the Overdue/Today pills read fine via their container colors). Give the neutral sections' pills a background that actually reads in both modes — `secondaryContainer` with `onSecondaryContainer` text, or keep the tone but add a hairline `outlineVariant` border; verify against the luminance-delta tripwire family so it can't regress.
14. `guessChoreEmoji`: resolve by earliest keyword POSITION in the name, not map-declaration order ("Water the dog" should guess dog... actually it should guess by first word hit: 'water' comes first in the name → plant. The rule: earliest matching token in the name wins; among forms of the same token, keyword map order breaks ties). Update guesser tests accordingly.

## Explicitly deferred (do NOT fix; list in changes.md as acknowledged)

- Duplicate-prefill silently normalizing an out-of-range interval to 3 (accepted behavior).
- Undo-inert-during-write-window on superseded completion snackbars (accepted narrow race).

## Tests

Blocker gets per-option snackbar-date tests (tomorrow/3 days/next week/picked date). Scroll test per item 2. Stat-chip-with-filters widget test. Voice-change reschedule test (fake scheduler records restated notifications). String-audit canary: extend the completeness test to assert the four de-hardcoded strings differ per voice or at least resolve via AppStrings. Full suite green in normal time.

## Done criteria

- `flutter analyze` clean; `flutter test` green (~30s); `flutter build apk --debug` succeeds; changes.md maps finding → fix + test, disputes listed with reasoning.
- Nothing outside `app/`.
