# Spec 17 — Device feedback round 2: widget robustness/theming, hierarchy, sort & shortcut fixes

## Role

Implement. Report to `$AER_OUTPUT_DIR/changes.md`. ONE-SHOT: complete synchronously; write changes.md before finishing. Do NOT background long-running commands (`flutter test`, builds) — run them to completion in the foreground.

## Environment (stripped — set before builds)

- `ANDROID_HOME=C:\Android\sdk`, `ANDROID_NDK_HOME=C:\Android\sdk\ndk\28.2.13676358`, `JAVA_HOME=C:\Program Files\Android\openjdk\jdk-21.0.8`
- Flutter `C:\src\flutter\bin\flutter.bat`, Dart `C:\src\flutter\bin\dart.bat`

## Context

Second round of on-device feedback (Pixel 10a, Android 17). The home-screen widget's checkbox completion path's root cause is under separate investigation (do NOT restructure the background completion chain) — but items 1–2 below are design fixes that hold regardless. Read `app/lib/core/home_widget/`, the Kotlin under `android/app/src/main/kotlin/.../widget/`, `chore_filter_sort.dart`, `core/shortcuts/`, and `chore_card.dart` first.

## Items

### 1. Widget: stateless complete affordance

The per-row CompoundButton checkbox visually toggles client-side even when the tap achieves nothing, and reads as persistent state when the action is a one-shot trigger. Replace it with a stateless tap target (an outlined check-circle ImageView/ImageButton drawable, no checked state) that fires the same fill-in intent. Rows must never render "checked".

### 2. Widget: dynamic-color theming

The widget's colors are hardcoded (`values/colors.xml`: white surface etc.) and don't match the app's wallpaper-derived Material 3 theme. Re-theme using Android's dynamic color resources on API 31+ (`@android:color/system_accent1_*` / `system_neutral1_*` / `system_neutral2_*` families) with the existing static palette as the pre-31 fallback, and correct dark variants via `values-night(-v31)`. Header, background, row text, overdue tint, and the new check affordance should all read as the same family as the app on the same wallpaper. Verify by building and eyeballing the layout XMLs — no screenshots required.

### 3. App visual hierarchy ("everything is flat")

With many chores/tags/due dates the screen reads as one undifferentiated plane. Introduce clear M3 tonal levels WITHOUT loud elevation shadows:
- Chore cards on `surfaceContainerLow` (or `surfaceContainer`) against the `surface` list background, with slightly larger radius; the existing header sliver stays a distinct level.
- Tag chips as proper contained chips (`secondaryContainer`/`onSecondaryContainer` family via the existing tag palette) rather than flat text.
- Typographic hierarchy inside the card: name = titleMedium, due line visually secondary EXCEPT overdue (error color + medium weight so it pops), history line tertiary/muted.
- Keep the archive card visually consistent.
Apply the same treatment on the chore detail screen's history cards. This is tuning, not redesign — no layout re-architecture.

### 4. Sort defaults and directions

Philip: "the default sorting for urgency and last done should put the most urgent on top, and the most recently done on top." Audit `chore_filter_sort.dart` + `SortState` (chore_providers.dart): whatever the enum's direction semantics are, the DEFAULT state and the state after selecting each chip must yield: urgency → most urgent (most overdue/soonest due) first; last-done → most recently completed first; name → A→Z. Re-tapping a chip still flips direction. Fix the sort chips' direction indicator if it now lies. Update tests to pin the corrected defaults.

### 5. "Overdue" app shortcut actually does something

Today it just opens the chores list. Make it: open the chores list with sort set to urgency (most urgent first) and any active search cleared, then scroll to top. Implement by extending the existing pending-shortcut mechanism (e.g. the handler sets sortStateProvider before/UPON navigation) — do not invent a second channel. Rename its label if that helps honesty (e.g. keep "Overdue").

### 6. Shortcut-launched New Mission backs out into the list

Cold-launching via the New Mission shortcut (and the QS tile, and the widget "+") lands on the new-chore form with an empty back stack, so back exits the app. Ensure the stack is [/chores, /chores/new] in every entry path (go to /chores first, then push /chores/new — check how the pending-route handler and `_handleWidgetUri` navigate today). Back (or abandoning the form) must land on the chore list. Widget row taps should similarly land with /chores under the detail screen if they don't already.

### 7. Tests

Update/extend: sort default tests (item 4), pending-shortcut → sort-state test (item 5), a router-stack test for the shortcut/new-mission path (item 6 — assert popping /chores/new lands on /chores, using the fake shortcuts/channel harnesses that already exist). Items 1–2 are covered by `flutter build apk --debug` compiling the layouts/drawables.

## Done criteria

- `flutter analyze` clean; `flutter test` fully green; `flutter build apk --debug` succeeds; changes.md lists files, the exact sort-semantics decision table (default + per-toggle for each order), and any deviation.
- Nothing outside `app/`.
