# Spec 19 — Visual identity: banner canvas + sectioned list + icon chips + completion confetti

## Role

Implement. Report to `$AER_OUTPUT_DIR/changes.md`. ONE-SHOT: complete synchronously; write changes.md before finishing. Do NOT background long-running commands (run `flutter test` in the foreground and wait for it).

## Environment (stripped — set before builds)

- `ANDROID_HOME=C:\Android\sdk`, `ANDROID_NDK_HOME=C:\Android\sdk\ndk\28.2.13676358`, `JAVA_HOME=C:\Program Files\Android\openjdk\jdk-21.0.8`
- Flutter `C:\src\flutter\bin\flutter.bat`, Dart `C:\src\flutter\bin\dart.bat`

## Context

Philip picked a visual direction after two pitch rounds: **banner canvas + sectioned list + tinted icon chips + confetti on completion**. Hard-won constraints from rounds 1–3 of device feedback (Pixel 10a, wallpaper-derived dynamic color):

- Adjacent M3 tonal steps are INVISIBLE on this device. Every element below is a solid container color, a hard border, or a real shadow — never tonal-step-only separation. The luminance tripwire test (`test/` — search `luminance`) must keep passing; extend it if you add any new surface-on-surface pairing.
- Everything derives from the dynamic `ColorScheme` (no fixed brand colors).
- The compact one-row header from slice 18 (`SearchAndSortBar`) survives — it re-homes below the banner and keeps scrolling away with the list.

## Items

### 1. Banner canvas header (chores tab only)

A solid `primaryContainer` banner at the top of the chores tab:

- Rounded bottom corners (~28dp), content in `onPrimaryContainer`.
- Row 1: app title (existing `strings.appTitle`) + the existing settings-gear action. If the shell currently gives the chores tab an `AppBar`, absorb it into the banner **for this tab only** (archive/settings tabs keep their current app bars).
- Row 2: three stat chips — overdue / due-today / upcoming counts, computed from active chores (upcoming = has due date, later than today; unscheduled chores are not counted). Each chip: small colored dot (`error` / a warm amber derived per item 2's section colors / `outline`) + label + count, on a `surface`-colored pill so they pop off the banner.
- Stat chip tap: force urgency sort (reuse the exact mechanism the Overdue shortcut uses via `sortStateProvider`), then scroll to that group's section header (item 2). If the count is 0, the chip renders disabled (reduced opacity, no tap).
- The banner is a leading sliver ABOVE the `SearchAndSortBar` sliver in `chores_screen.dart` — it scrolls away with the content just like the header does today. Update `_headerKey`-based extent math accordingly (see item 5).
- The `SearchAndSortBar` container keeps its `surfaceContainerHighest` + bottom divider treatment.

### 2. Sectioned list under urgency sort

When `sortStateProvider` is urgency (either direction):

- Group the filtered list into sections: **Overdue** (due < today), **Today** (due today), **Upcoming** (due later), **Unscheduled** (no due date). Ordering of sections follows the sort direction (urgency-ascending = Overdue first ... Unscheduled last; descending reversed). Within a section, preserve the existing comparator's order.
- Section header row: small uppercase label + count pill, colored — Overdue in `error`, Today in a warm tone (use `tertiary` if the scheme's tertiary reads warm, otherwise blend toward amber the way `getDueColor` does — reuse/extend `due_status.dart` so the card due-text color and the section color come from ONE function), Upcoming/Unscheduled in `onSurfaceVariant`. Count pill background = the matching container color.
- Empty sections are omitted entirely (no zero-count headers).
- Under name / last-completed sorts: flat list exactly as today, no sections. Banner stats still show.
- New strings on `AppStrings` + `SuperheroStrings` for the four section labels and the three stat-chip labels. Keep the superhero voice consistent with existing copy (e.g. missions/signals register) but the words must stay instantly parseable — "Overdue" beats a clever synonym; flavor goes in tone, not riddles.

### 3. Tinted icon chips (+ tag emoji)

- Schema: add nullable `emoji` TEXT column to the tags table. Bump `schemaVersion`, write the drift migration (additive `addColumn`), and extend the JSON backup export/import so emoji round-trips (absent/null tolerated when importing old backups). Update backup round-trip tests.
- Tag management UI (settings): each tag row gets a small optional emoji field (plain `TextField`, maxLength 2 visual chars is fine — don't over-engineer grapheme validation; store what's typed, render as-is).
- `ChoreCard`: replace the leading `Icons.schedule` clock with a ~36dp rounded-square (radius ~10) icon chip:
  - Background: first tag's palette color alpha-blended over `secondaryContainer` (same recipe the tag chips already use in `chore_card.dart`). No tags → plain `secondaryContainer`.
  - Glyph: first tag's emoji if set; else the chore name's first character, uppercased, in `onSecondaryContainer` w600.
- The due-date urgency color no longer has the clock icon as a carrier — the due text line (already colored by `getDueColor`/status) remains the per-card urgency signal. Do not add stripes.
- Widget (`home_widget` RemoteViews) is OUT OF SCOPE — no changes under `android/.../widget/`.

### 4. Confetti on completion

- After a successful completion logged through `completion_flow.dart` (the same spot the snackbar fires), play a short confetti burst (~1s, 20–40 particles, colors sampled from the dynamic scheme: primary, tertiary, error, plus a yellow) overlaying the screen, non-interactive (`IgnorePointer`), auto-disposing.
- Implement with a `CustomPainter` + `AnimationController` (no new package) OR the `confetti` pub package — your call; state the choice in changes.md. If a package: latest stable, and it must not require platform setup.
- Skip entirely when `MediaQuery.disableAnimationsOf(context)` is true.
- Fires for card-check completions and detail-screen completions (both route through `completeChoreFlow`). Notification/widget/voice completions (no UI context) are unaffected.

### 5. Scroll math + tests

- `_animateToIndex` in `chores_screen.dart` currently assumes `headerExtent + index * _estimatedItemExtent`. With the banner sliver and section headers this breaks. Fix properly: compute the target offset from the flattened row list (section headers get their own smaller estimated extent) — i.e. build one list model (`List<Object>` of headers+chores or a sealed row type) that BOTH the sliver builder and the offset math consume, so they can't drift apart.
- Stat-chip tap scrolls to the section header's flattened index via the same math.
- Tests: section grouping unit tests (boundaries: due yesterday/today/tomorrow/null, both sort directions, empty sections omitted); stat counts; stat-chip tap forces urgency sort; migration test for the emoji column; backup round-trip with and without emoji; confetti smoke test (complete a chore, pump, no exceptions, overlay gone after settle); update every existing widget test broken by the new header geometry (scroll-to-chore/header-extent tests included).

## Done criteria

- `flutter analyze` clean; `flutter test` fully green (run in foreground); `flutter build apk --debug` succeeds.
- changes.md states: confetti implementation choice, the section-color source function, new schemaVersion number, and any deviation from this spec.
- Nothing outside `app/`.
