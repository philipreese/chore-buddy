# ADR-0001: Migrate to Flutter, Android-only, in-repo

Date: 2026-08-10 · Status: accepted

## Decision

Rewrite ChoreBuddy as a Flutter app targeting Android only. The MAUI code stays in this repo as the behavioral reference (see `docs/behavior-inventory.md`), moves to an archive folder during the migration, and is deleted in a single commit at the end. No Play Store: distribution is local `adb install` plus GitHub Actions building signed release APKs on tags.

## Context

- Extensive MAUI perf workarounds accumulated (17 cataloged); most compensate for MAUI's rendering/DI pipeline rather than implement product behavior.
- Personal-use app; only Android devices matter. No surviving install means no legacy data migration.
- UX gets a structural-but-anchored rethink: same feature set, Android-native (Material 3) patterns where MAUI shaped the design. Redesign candidates are tracked as issues, not folded silently into ports.

## Consequences

- The behavior inventory, not the MAUI code style, is the parity contract. QUIRK-tagged behaviors must not be recreated.
- Backup (db export/import) is in v1 scope — it is the only data-loss protection without store infrastructure.
