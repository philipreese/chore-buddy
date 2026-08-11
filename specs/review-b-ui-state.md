# Adversarial review B — UI & state (PR #24, slices 10–25)

## Role

Review. You are an adversarial reviewer: FIND REAL BUGS, don't summarize. Write findings to `$AER_OUTPUT_DIR/report.md` and verdict to `$AER_OUTPUT_DIR/verdict.json`. A review without demonstrated hostile probing is a failed review.

## Scope

Branch `20-device-feedback-round-1-polish-theme-simplification-identity` vs `main` (`git diff main...HEAD`), restricted to the UI & STATE domain:

- `app/lib/features/chores/presentation/` — chores_screen (banner sliver, sectioned rows via chore_list_rows, `_animateToRowIndex` offset math, `_scrollToSection`, scroll-to-chore-from-notification), chore_card (icon chip fallback chain, dismiss confirms), completion_flow + confetti overlay, snooze sheet, chore_detail_screen (recurrence interval field state, icon grid picker + dirty-flag guessing, duplicate prefill), mission_log_screen
- `app/lib/features/settings/presentation/` — settings restructure, backup sub-page, voice picker
- `app/lib/features/tags/` — tag manager after emoji-UI removal
- `app/lib/core/strings/` — all nine voice implementations: spot-check ~15 high-traffic members across every voice for swapped/nonsensical/ambiguous strings, parameterized strings that drop their parameter, destructive confirm buttons that became unclear, and any voice string that would MISLEAD (e.g. a cancel label reading like a confirm)
- `app/lib/features/shell/` + `app/lib/core/router/` — chores-tab AppBar removal, /stats /settings/backup routes, back-stack behavior

## Hostile questions to actually chase (non-exhaustive)

1. Scroll math: `_animateToRowIndex` with mixed header/item extents — off-by-one at section boundaries? `_scrollToSection` immediately after forcing a sort change (does it read pre-reorder rows)? Scroll-to-chore for a chore inside a later section while filters were just cleared?
2. Banner stat chips: counts computed from unfiltered actives while the list below is filtered — tap "1 overdue" with a search active: where does it scroll?
3. Confetti overlay: rapid double-completion (two overlays?); completing from detail screen then popping immediately (overlay outliving context? `IgnorePointer` covering a dialog?); disableAnimations mid-flight.
4. Icon grid picker: dirty-flag reset semantics on duplicate-prefill; picking None then renaming (does guess return?); editing existing chore, clearing name, retyping.
5. Interval field: switching customDays→weekly→customDays (interval preserved or reset?); saving with the field focused and invalid; duplicate-prefill of a customDays chore.
6. Voice switch live: open snooze sheet, switch voice via... (can't mid-sheet, but) — switch voice with a snackbar showing; notification fired before switch tapped after switch (which voice's strings?); widget text after switch without opening app again.
7. Settings: backup sub-page while auto-backup runs; last-backup subtitle when only auto exists vs only manual.
8. Dismissible confirms: swipe both directions queued; confirm dialog while another dialog open.
9. String audit: every voice's `scrapConfirm`/`decommissionConfirm`/`purgeConfirm`/`wipeAllChoresConfirm` — is the destructive action always unmistakable? Any `%s`-style parameter dropped in any voice's parameterized members?

## Method requirements

- Read the diff plus surrounding code; bugs live at seams.
- Minimal repro argument per finding with file:line; label speculation.
- You may run `flutter test` (healthy ~30s) and add throwaway probes to confirm, but leave `git status` clean at the end.
- verdict.json: {"verdict": "PASS" | "FAIL", "blocking_findings": <count>} — FAIL for crash, stuck-UI, wrong-data-displayed, or misleading-destructive-action severity.

## Output contract

- `$AER_OUTPUT_DIR/report.md`: findings by severity (Blocking / Should-fix / Nit) with file:line + repro + fix direction.
- `$AER_OUTPUT_DIR/verdict.json` as above.
