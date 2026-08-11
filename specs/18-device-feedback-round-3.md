# Spec 18 — Device feedback round 3: depth that's actually visible, compact header, button-like widget affordance

## Role

Implement. Report to `$AER_OUTPUT_DIR/changes.md`. ONE-SHOT: complete synchronously; write changes.md before finishing. Do NOT background long-running commands.

## Environment (stripped — set before builds)

- `ANDROID_HOME=C:\Android\sdk`, `ANDROID_NDK_HOME=C:\Android\sdk\ndk\28.2.13676358`, `JAVA_HOME=C:\Program Files\Android\openjdk\jdk-21.0.8`
- Flutter `C:\src\flutter\bin\flutter.bat`, Dart `C:\src\flutter\bin\dart.bat`

## Context — why round 2's fix failed on-device

Slice 17 separated the chore cards from the list background with `elevation: 0` + `surfaceContainerLow` on `surface`. Philip (Pixel 10a, real wallpaper-derived dynamic palettes): "I don't see any visual change in terms of surface depth or anything." Adjacent M3 tonal steps are a few percent of luminance apart under dynamic color — tonal-only separation is imperceptible. This is the SECOND time subtle-tonal failed on this device (round 1: the header on surfaceContainer was "washed out"). Do not reach for adjacent tonal steps again.

## Items

### 1. Depth you can actually see

- Chore cards (and archive/history cards): `elevation: 1` with the real shadow (`shadowColor` default, not transparent) PLUS a hairline `outlineVariant` border, on `surfaceContainerHigh` (two steps from `surface`, not one). In dark mode the shadow disappears by nature — the border + bigger tonal jump must carry it; verify the two-step jump is visible against `surface` in both brightnesses by comparing the actual resolved colors of `ColorScheme.fromSeed(seedColor: 0xFF415F91)` light/dark in a unit test that asserts a minimum luminance delta (>= 0.03) between card color and surface — a cheap tripwire against regressing to imperceptible.
- The chores-tab header area gets the inverse treatment so list and header read as different layers: header stays on `surface` while cards pop, OR header on `surfaceContainerHighest` with a bottom `outlineVariant` divider — pick one, state which in changes.md.

### 1b. Mode-stable search bar + chip glyph fixes (screenshot evidence)

Philip's light/dark screenshots show:
- The M3 `SearchBar` renders with a strong elevation shadow in light mode that vanishes entirely in dark — the two modes disagree about layering. Give it a mode-stable treatment: elevation 0 with a `outlineVariant` border, or a tonal fill (`surfaceContainerHighest`) — same recipe both modes. (This applies to whatever compact search control item 2 produces.)
- The sort chips and tag-filter chips show OVERLAPPING glyphs: M3's automatic selected-state checkmark is drawn on top of the custom leading avatar/icon (e.g. the "Urgency" chip's circle avatar with a check smashed over it; a selected tag chip's colored dot with a check over it). Fix: either drop the custom leading icons and let the standard checkmark be the selected indicator, or keep the custom leading icon and set `showCheckmark: false` — one indicator, never two. Apply consistently to sort chips AND tag chips.
- The chore card boundary is INVISIBLE in both screenshots — the card reads as loose floating text, not "subtle". Item 1's border + elevation + two-step tone is confirmed necessary; treat the screenshots as the acceptance bar (a visible enclosing surface in both modes).

### 2. Compact header (search / sort / filter)

Philip: the header still takes too much vertical space even though it scrolls away. Restructure to ONE dense row at rest:
- Search collapses to an icon: use Material's `SearchAnchor`/`SearchBar` icon-triggered pattern (or an expand-on-tap field) — full-width search UI only when active; active search shows as a dismissible chip/summary in the row.
- Sort control and tag-filter access live in the same single row (sort as the existing chips if they fit ONE line, otherwise a compact dropdown/menu; tag filter behind a filter icon-button with a badge showing the active-filter count, opening a bottom sheet with the tag chips).
- Preserve ALL existing behavior: ticker visibility, scroll-to-chore header-extent math in `_animateToIndex` (update the measured extent — it shrinks), Overdue-shortcut sort application, search semantics. Update affected widget tests; the header-extent scroll test must still pass with the new geometry.

### 3. Widget: make the check affordance look tappable

The stateless check icon from round 2 reads as a status glyph, not a button. Give it a button treatment in RemoteViews terms: circular tonal background (a shape drawable filled with the accent-container dynamic color from the existing values-v31 palette, static fallback pre-31), the check glyph on top in the on-container color, comfortable 40dp tap target, `android:contentDescription` retained. Do NOT change the tap wiring (fill-in intents) — it is under separate on-device investigation; layout/drawable changes only.

### 4. Tests

Per item 1 the luminance-delta tripwire; per item 2 updated header/scroll tests; `flutter build apk --debug` covers item 3's drawables.

## Done criteria

- `flutter analyze` clean; `flutter test` fully green; `flutter build apk --debug` succeeds; changes.md states the header-layer choice, the resolved card/surface color pairs (light+dark) with their luminance deltas, and any deviation.
- Nothing outside `app/`.
