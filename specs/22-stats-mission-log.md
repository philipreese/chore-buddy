# Spec 22 — Stats: banner weekly line, streak chips, Mission Log page

## Role

Implement. Report to `$AER_OUTPUT_DIR/changes.md`. ONE-SHOT: complete synchronously; write changes.md before finishing. Do NOT background long-running commands (run `flutter test` in the foreground and wait for it).

## Environment (stripped — set before builds)

- `ANDROID_HOME=C:\Android\sdk`, `ANDROID_NDK_HOME=C:\Android\sdk\ndk\28.2.13676358`, `JAVA_HOME=C:\Program Files\Android\openjdk\jdk-21.0.8`
- Flutter `C:\src\flutter\bin\flutter.bat`, Dart `C:\src\flutter\bin\dart.bat`

## Context

Specs 19–21 landed before this: the chores tab has a primaryContainer banner with stat chips (19), settings are restructured (20), and recurrence supports customDays with a `recurrence_interval` column (21). This spec adds completion stats in three layers: an ambient line in the banner, streak chips in the chore detail screen, and a Mission Log stats page reached by tapping the banner line. All stats derive from the existing completions table — no new data collection, no schema change.

## Stats definitions (implement EXACTLY these; put them in a pure domain module, e.g. `features/chores/domain/stats_calculator.dart`)

- **Week**: Monday 00:00 local to next Monday. "This week" = completions with timestamp in the current week; comparison line vs the previous week.
- **Per-chore expected period (days)**: daily=1, everyOtherDay=2, weekly=7, monthly=30, customDays=its `recurrence_interval`; none/null → no expected period.
- **Per-chore streak**: walk completions newest→oldest; the streak grows while the gap between consecutive completions is ≤ expected period + 1 grace day. Chores with no expected period have no streak (show total completion count instead). A single completion = streak of 1.
- **Typical cadence**: median gap in days between consecutive completions, requires ≥ 3 completions; render as "every ~X days". With an expected period, append "on schedule" when median ≤ period + 1, else "running behind".
- **Heatmap intensity**: completions per calendar day bucketed 0 / 1 / 2 / 3+.

## Items

### 1. Banner weekly line (A)

- One line under the banner's stat chips: this week's completion count and the delta vs last week (e.g. "9 missions completed this week — 3 more than last"; delta variants: more / fewer / same / first-week-no-comparison). New parameterized strings on `AppStrings` + `SuperheroStrings`, superhero register, instantly parseable.
- The line is tappable → pushes the Mission Log page (item 3). Give it a subtle trailing chevron so it reads as tappable.
- Zero completions ever → line still renders with the zero-state string (it's the only door to the Mission Log).

### 2. Streak chips in chore detail (B)

- In the chore detail screen's completion-history section header row: a streak chip — flame + "N in a row" — when streak ≥ 2; for no-period chores, a neutral chip with total count ("N logged"). Chip colors from the dynamic scheme (warm container family for the flame chip).
- Below/near it, the typical-cadence line ("Typically done every ~7 days · on schedule") when the ≥3-completions condition holds; omit otherwise.
- Careful: spec 21 just modified this screen (recurrence editor). Rebase mentally on the current file content, not on any cached idea of it.

### 3. Mission Log page (C)

- New route (e.g. `/stats`), screen title from a new string ("Mission Log" register).
- Three blocks, scrolling column:
  1. **This week**: big number + "missions", plus best current streak across all chores ("best streak: N — <chore name>") when any streak ≥ 2.
  2. **Last 5 weeks**: bar chart, plain `Container`s in a `Row` (no chart package), height proportional to count, current week visually emphasized (outline), week labels minimal. Bars must be visible in both modes: fill = `primary`, track/background = `surfaceContainerHigh`.
  3. **This month**: calendar heatmap grid (7 columns, weeks as rows, current month), day cells 0/1/2/3+ intensity: 0 = `surfaceContainerHigh`, then `Color.alphaBlend` of `primary` at ~30% / ~60% / 100% over it. These four levels MUST pass a luminance-delta check (≥ 0.03 between adjacent levels, both light and dark schemes) — add it to the existing luminance tripwire test family.
- Empty data renders gracefully (zeros, empty grid — no crashes, no NaN bar heights).

### 4. Tests

- Pure unit tests for every definition above: week boundaries (Sunday/Monday edge, fake clock), streak growth/break/grace-day, single-completion streak, no-period fallback, median cadence + on-schedule/behind wording, heatmap bucketing.
- Widget tests: banner line shows count + delta and navigates to Mission Log; streak chip appears at streak ≥ 2 and not below; Mission Log renders with data and with empty data.
- Luminance-delta test for the heatmap levels.

## Done criteria

- `flutter analyze` clean; `flutter test` fully green (foreground); `flutter build apk --debug` succeeds.
- changes.md states: the stats module path, the route, and any deviation from the definitions.
- Nothing outside `app/`.
