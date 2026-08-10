# Spec 00 — Advisory: architecture & feature ideas native to the new stack

## Role

You are an advisor. You write no application code. Your deliverable is a single report.

## Context (read these first, in the workspace root)

1. `CONTEXT.md` — domain glossary and non-goals
2. `docs/behavior-inventory.md` — every behavior of the old app, tagged FEATURE / PRESERVE / QUIRK / RETHINK
3. `docs/adr/0001`–`0004` — decided: Flutter Android-only in-repo, Riverpod + drift + go_router + Material 3, 6 seed themes + dynamic with flavor-keyed copy, baton execution model

The old .NET MAUI implementation is in `ChoreBuddy/` — consult it only to resolve ambiguity about behavior; it is not an architectural model.

## Task

The decided stack and behavior contract are fixed. Within them, propose:

1. **Navigation / information architecture** for the RETHINK-tagged items: recommend a concrete structure (tab set, where Archive/Tags/Settings live, edit-chore surface — bottom sheet vs screen, search/sort presentation) using current Material 3 Android patterns. One recommended design, alternatives only where the call is genuinely close.
2. **A drift schema** for the redesigned database (ADR-0002 lists the known warts to fix: denormalized LastCompleted/LastNote, RecurranceType misspelling, hex-string tag colors). Include the export/import approach (drift can hot-swap; the old app required a restart).
3. **New-stack-native feature ideas**: things that were impractical in MAUI but cheap/idiomatic in Flutter+Android and fit a local-first personal chore app (examples to evaluate, not prescribe: home-screen widget, quick-settings tile, app shortcuts, notification actions like complete-from-notification, predictive back, Wear tile). For each: value, cost (S/M/L), and whether it belongs in v1 or post-parity.
4. **Slice plan sanity check**: given all of the above, propose the ordered list of implementation slices (spec files) for the migration, smallest first.

## Constraints

- Do NOT modify any file except your report.
- Write the report to `docs/proposals/00-new-stack-ideas.md` in the workspace. If you cannot write to the workspace, return the full report as your output instead.
- No accounts/sync/network features — the app stays fully local (see CONTEXT.md non-goals).
- Flutter 3.41 stable / Dart 3.11 era idioms.

## Done

The report exists, covers all four sections, and every recommendation is concrete enough to turn into a slice spec without further research.
