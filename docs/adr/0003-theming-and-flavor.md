# ADR-0003: Seed-color themes + flavor-keyed copy

Date: 2026-08-10 · Status: accepted

## Decision

- **Themes**: 6 seed colors — Chambray (default), Blue Stone, Russet, Affair, Spicy Mustard, Woodland — plus a Dynamic option (Material You wallpaper color). Material 3 `ColorScheme.fromSeed` generates full light/dark palettes; the MAUI per-theme resource dictionaries are not ported.
- **Copy**: every user-facing string lives behind a **flavor key** (a voice-pack layer, distinct from i18n locale). V1 ships one flavor: "Superhero" (the existing mission-themed copy). The architecture allows themes to bind to flavors later so a theme change can change the app's voice, not just its colors.

## Context

The MAUI app hand-built 10 themes × light/dark. Seed generation keeps the theme-picker feature at a fraction of the cost. The owner wants themes to eventually carry personality (color + voice); writing six voice packs now would stall the migration, but retrofitting a string layer later is expensive — so the layer is v1, the content is post-parity.

## Consequences

- No raw string literals in widgets; all copy goes through the flavor layer from the first screen.
- Tag colors (12 preset swatches in MAUI) should be re-derived to work across all 6 themes + dynamic.
