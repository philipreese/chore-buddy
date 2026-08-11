# Spec 24 — Voices: persisted picker + Standard + Wheel of Time

## Role

Implement. Report to `$AER_OUTPUT_DIR/changes.md`. ONE-SHOT: complete synchronously; write changes.md before finishing. Run `flutter test` in the FOREGROUND. The healthy suite runs in 15–30s — minutes means failures (each stalls ~10 min in teardown). Stream test output to a file; never pipe through `tail`/`head`.

## Environment (stripped — set before builds)

- `ANDROID_HOME=C:\Android\sdk`, `ANDROID_NDK_HOME=C:\Android\sdk\ndk\28.2.13676358`, `JAVA_HOME=C:\Program Files\Android\openjdk\jdk-21.0.8`
- Flutter `C:\src\flutter\bin\flutter.bat`, Dart `C:\src\flutter\bin\dart.bat`

## Context

`AppStrings` (abstract, ~190 members) with one implementation (`SuperheroStrings`) and a hardcoded `flavorProvider` (`flavor_provider.dart`, `AppFlavor.superhero`) — to be renamed. Philip wants a full voice system: a persisted picker in Settings and eight new flavors total. This spec builds the infrastructure plus the first two new voices; spec 25 adds the remaining six as pure add-on files.

## Items

### 1. Voice infrastructure (the user-facing and code-level name is "voice", NOT "flavor")

- RENAME the existing concept: `AppFlavor` → `AppVoice`, `flavorProvider` → `voiceProvider`, `flavor_provider.dart` → `voice_provider.dart`, `appStringsProvider` internals updated; sweep every reference (`ref.watch(appStringsProvider)` call sites don't change). User-facing copy says "Voice" everywhere.
- Extend `AppVoice` with `standard` and `wheelOfTime` (superhero stays the default for existing installs).
- Persist the choice the same way the theme mode is persisted (find the existing theme persistence — shared_preferences — and mirror it exactly, including load-on-startup).
- Each voice exposes, from the voice-agnostic layer (NOT dependent on the currently-active voice): a display name ("Superhero", "Standard", "Wheel of Time"), a glyph emoji (🦸 / 📋 / ☸️), and a signature line — one short characteristic quote. The signature line comes from a new `AppStrings` member `String get voiceSignature` (superhero: something like "Every chore is a mission."; standard: "Simple, clear, no costumes."; WoT: "The Wheel weaves as the Wheel wills."). Adding the member forces all implementations — good.
- Settings screen: new "Voice" section (using `SettingsSectionHeader`) between Appearance and Behavior. Picker = a column of selectable rows (radio-style selected state), each row: the glyph emoji in a small tinted circle chip (same visual language as the chore icon chips — emoji over `secondaryContainer`), the display name, and the signature line as subtitle. Selecting applies instantly (Riverpod rebuild) — verify the chores banner title/snackbars swap live.
- Notification channel name/description come from strings: ensure the channel is re-created (same channel id, new name) after a voice change so notifications follow. Widget text follows automatically via `widget_sync_service` — trigger a widget sync on voice change.
- Architecture note: keep a registry `Map<AppVoice, AppStrings>` (const instances) plus per-voice metadata (display name, glyph) in one place so spec 25 can add voices by adding a file + one registry entry + one enum value.

### 2. StandardStrings

`lib/core/strings/standard_strings.dart` — plain, friendly, zero-theatrics: "Chores", "New Chore", "Chore complete", "Archive", "Statistics", "Delete all chores?", etc. Every member direct and unambiguous; superhero-specific metaphors ("Hall of Rest", "The signal is silent", "mission") all become plain equivalents. Tab labels, empty states, dialogs, notifications, snooze options, stats page, voice-command responses — everything.

### 3. WheelOfTimeStrings

`lib/core/strings/wheel_of_time_strings.dart` — Robert Jordan's Wheel of Time, played straight and loving, but every string still INSTANTLY parseable (flavor in tone, never riddles — a user must always know what a button does). Anchor vocabulary:
- Chores/missions → threads in the Pattern; chores tab title ~"The Pattern"; app tagline register: "The Wheel weaves as the Wheel wills."
- New chore → "Weave a New Thread" (or similar).
- Completion → "The Wheel weaves as the Wheel wills." / "Woven." for the snackbar; undo stays clear ("Unravel").
- Tags → Ajahs (tag manager = "The Ajahs"; tag chips unchanged mechanically).
- Archive tab → something restful-but-clear (e.g. "The Stilled" or "Set Aside"); restore → clear.
- DELETE (permanent) → Balefire ("Balefire this thread? It will be as if it never was." — perfect semantic match, use it).
- Overdue section → e.g. "The Shadow Grows"; Due Today → clear ("Due Today" can stay literal); Upcoming → e.g. "Threads to Come"; Unscheduled → e.g. "Unwoven".
- Stats page → "The Pattern" or "The Great Weave"; streak → e.g. "ta'veren streak" only if it stays readable, else plain "streak".
- Snooze sheet → "Not yet" register; options themselves stay literal (Tomorrow / In 3 Days / Next Week / Pick a Date) for parseability.
- Notifications → "The Wheel turns: <chore>" register.
- Keep proper nouns to flavor text, never on destructive-action confirm buttons EXCEPT Balefire (which is self-explanatory in context with the explanatory message above).

### 4. Tests

- Voice persistence round-trip (set → restart provider container → still set).
- Picker widget test: switch voice, banner title text changes accordingly; each row shows glyph + name + signature.
- A completeness meta-test: for every `AppVoice`, resolving its `AppStrings` returns distinct non-empty `appTitle`/`choresTitle` (cheap canary; the compiler enforces the interface anyway).
- Existing tests keep passing — they run under the default superhero voice and must not need edits (default unchanged).

## Done criteria

- `flutter analyze` clean; `flutter test` green in normal time; `flutter build apk --debug` succeeds.
- changes.md: persistence mechanism used, registry location, any string slots where the WoT voice deliberately stays literal, deviations.
- Nothing outside `app/`.
