# Spec 23 — Device feedback round 4: banner line wrap, app icon in header/widget, chore-level icons with name guessing

## Role

Implement. Report to `$AER_OUTPUT_DIR/changes.md`. ONE-SHOT: complete synchronously; write changes.md before finishing. Run `flutter test` in the FOREGROUND and wait. NOTE: the healthy full suite runs in 15–30 seconds — if a run takes minutes, tests are FAILING and each failure stalls ~10 minutes in teardown (dangling `_initNotifications` future). Stream test output to a file, never through `tail`/`head` pipes.

## Environment (stripped — set before builds)

- `ANDROID_HOME=C:\Android\sdk`, `ANDROID_NDK_HOME=C:\Android\sdk\ndk\28.2.13676358`, `JAVA_HOME=C:\Program Files\Android\openjdk\jdk-21.0.8`
- Flutter `C:\src\flutter\bin\flutter.bat`, Dart `C:\src\flutter\bin\dart.bat`

## Context (Philip's on-device feedback, Pixel 10a, dark mode)

Slices 19–22 shipped: banner + sections + icon chips + confetti, settings restructure, snooze picker, every-N-days, stats. Round-4 feedback below.

## Items

### 1. Banner weekly line: wrap, don't truncate

The line ("87 missions completed this week — your first week on t…") ellipsizes and there's no way to read the rest — tapping opens the Mission Log. Fix both ends:
- Let the line wrap: `maxLines: 2`, keep the trailing chevron vertically centered against the wrapped text.
- Tighten the copy so two lines is genuinely enough at 87-missions scale: shorten the first-week variant (e.g. "87 missions completed this week — first week on the job" or shorter); review every variant (`bannerStatsZeroState`/`FirstWeek`/`More`/`Fewer`/`Same`) for length. Strings live in `app_strings.dart`/`superhero_strings.dart`.
- Widget test: a long variant renders without RenderFlex overflow in a narrow (320dp-wide) harness and still navigates on tap.

### 2. App icon in the banner and the home-screen widget

- Banner (`chores_banner.dart`): a small leading app-icon image (~28–32dp) before the "Chore Buddy" title. Use `assets/icon/icon_foreground.png` — an `assets:` section must be added to `pubspec.yaml` (currently commented out). Tasteful: no border/badge, modest padding, vertically centered with the title baseline row.
- Widget (`app/android/.../widget/` layout XML only): small ImageView with the launcher mipmap at the start of the widget's header/title row, `contentDescription="@null"` (decorative). LAYOUT-ONLY — do not touch tap wiring, fill-in intents, or the provider/receiver/factory Kotlin beyond what the layout id requires (slice-18 precedent: layout/drawable changes are safe while the tap bug is under separate investigation).

### 3. Icons belong to CHORES, not tags

Slice 19 put an optional emoji on tags; Philip: "I don't want icons associated with a tag. I want icons associated with a chore. It needs to be clear that that is what the field is for, and it would be super cool if it could guess an icon based off the chore name."

- **Schema**: add nullable `emoji` TEXT column to the chores table. `schemaVersion` 3 → 4, additive `addColumn` migration. Backup round-trips it; legacy imports tolerate absence. The existing `tags.emoji` column stays in the schema (dropping a column is a table rewrite; not worth it) but becomes dormant — note this in changes.md.
- **Fixture law** (learned slice 21): any test that fakes an old-version database by stripping columns must drop ALL columns newer than the target version — for a fake v1 that is now `tags.emoji`, `chores.recurrence_interval`, AND `chores.emoji` — or the migration replay hits "duplicate column name". Update the existing migration/legacy-backup fixtures for v4 and add the v3→v4 case.
- **Guesser**: new pure domain module `features/chores/domain/icon_guesser.dart`: `String? guessChoreEmoji(String name)` — case-insensitive keyword/substring map, ~40 sensible household entries (trash/garbage→🗑️, recycle→♻️, dish→🍽️, plant/water→🪴, litter/cat→🐈, dog/walk→🐕, laundry/clothes→🧺, sheets/bed→🛏️, vacuum→🧹, mop/floor→🧽, bathroom/toilet→🚽, shower→🚿, window→🪟, dust→🪶, cook/dinner→🍳, grocery/shop→🛒, car/oil→🚗, lawn/mow/grass→🌱, garden→🌻, mail→📬, bill/pay→💸, gym/exercise→💪, med/pill→💊, filter→🌀, battery/smoke→🔋, fridge→🧊, oven→🔥, fish/tank→🐠, bird→🦜, plant-generic fallback etc. — your judgment on the exact map, first match wins, word-ish matching so "car" doesn't fire on "carpet").
- **Editor** (`chore_detail_screen.dart`): a compact, clearly-labeled icon field next to/near the name field — label like "Icon", helper text like "Shown on this mission's card" (strings via AppStrings, superhero register but unambiguous). Behavior: as the user types the NAME, if they have never manually edited the icon field this session, live-prefill it with `guessChoreEmoji(name)` (empty when no guess); once the user types in the icon field themselves, stop auto-filling (dirty flag). Editing an existing chore shows its stored emoji without auto-overwriting. Saving persists whatever is in the field (trimmed; empty → null).
- **Card chip** (`chore_card.dart`): glyph resolution becomes `chore.emoji ?? guessChoreEmoji(chore.name) ?? first letter`. Tint stays as-is (first tag color over secondaryContainer).
- **Widget rows**: `widget_sync_service.dart` resolves the same `chore.emoji ?? guess ?? none` at write time and prepends it to the entry title text ("🗑️ Trash Patrol") so the widget matches the app without any Kotlin logic. Data/text change only — no RemoteViews wiring changes.
- **Tag manager** (`tag_manager_screen.dart`): REMOVE the per-tag emoji UI added in slice 19 (creation-form emoji field and per-row emoji field) — rows return to swatch + name + delete. Keep `updateTagEmoji`/`setTagEmoji` db/service code (dormant, harmless) or remove if trivially clean; state which in changes.md. Remove/adapt the tag-emoji UI tests; db-level emoji round-trip tests may stay.

### 4. Tests

Guesser unit tests (hits, misses, word-boundary case like carpet/car); editor prefill + dirty-flag + edit-existing tests; migration v3→v4 + updated fixtures; backup round-trip with chore emoji; card glyph fallback chain test; widget-sync entry title includes emoji; banner wrap test (item 1); everything existing stays green.

## Done criteria

- `flutter analyze` clean; `flutter test` fully green in normal time (~30s); `flutter build apk --debug` succeeds.
- changes.md states: new schemaVersion, the guesser map size, tag-emoji removal scope, and any deviation.
- Nothing outside `app/` except the widget layout XML under `app/android/`.
