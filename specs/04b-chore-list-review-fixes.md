# Spec 04b — Apply review fixes to the chore list surface

## Role

Implement. Report to `$AER_OUTPUT_DIR/changes.md`.

## Environment (stripped — set before builds)

- `ANDROID_HOME=C:\Android\sdk`, `ANDROID_NDK_HOME=C:\Android\sdk\ndk\28.2.13676358`, `JAVA_HOME=C:\Program Files\Android\openjdk\jdk-21.0.8`
- Flutter `C:\src\flutter\bin\flutter.bat`, Dart `C:\src\flutter\bin\dart.bat`

## Context

Full review: `docs/reviews/04-chore-list-review.md` — read it first; it has exact file:line evidence for every item below.

## Required fixes (verdict blockers)

1. **Delete `_isTestEnvironment()` everywhere** (`chore_providers.dart:125-136`, duplicated in `database_provider.dart:9-20`). Production code must not branch on test detection. Replace with an injectable clock: expose the ticker as a plain provider (e.g. `Provider<Stream<DateTime>>` or a `clockProvider`) that tests override with a controlled `StreamController`/`FakeAsync`. `widget_test.dart` must pass its own overrides instead of relying on the sniffing.
2. **Scope the ticker to Chores-tab visibility** (review F2): the IndexedStack shell keeps cards mounted offstage, so `Timer.periodic` currently runs forever. Gate the `nowProvider` subscription on the shell's selected branch (watch the navigation shell index, or have `ChoresScreen` toggle a `choresTabVisibleProvider` from route/tab callbacks) so the timer is cancelled when Archive is selected or a root route is pushed. Add a test asserting the ticker subscription drops on tab switch.
3. **Flavor compliance in `chore_card.dart`**: replace `const strings = SuperheroStrings()` (line 28) with `ref.watch(appStringsProvider)`; move all raw literals through AppStrings — `'Archive'`, `'Delete'`, `'Cancel'` (member exists), `'Last completed: '`, `'Note: …'` (member exists), `'Due: '`, and `'Error: $err'` in `chores_screen.dart:48`. Add missing members (`archiveAction`, `deleteAction`, `lastCompletedLabel`, `dueLabel`, generic error) to `AppStrings` + superhero impl using MAUI copy where it exists.
4. **Add the swipe-cancel test**: swipe to delete, tap Cancel, assert the chore is still present in list and db. Add a real ticker test: timer emits under fake time and is cancelled on dispose.

## Also fix (from the review's ranked list)

5. Swipe backgrounds: replace `Colors.amber.shade700`/`Colors.white` with M3 scheme roles (e.g. `tertiaryContainer`/`onTertiaryContainer` for archive, `errorContainer`/`onErrorContainer` for delete).
6. `search_and_sort_bar.dart:38-40`: stop mutating `TextEditingController.text` in `build`; sync it in a listener/initState or use the controller as the single source of truth.
7. `app_router.dart:61`: parse `:id` — non-numeric (and non-`new`) ids get a simple not-found screen rather than a bogus edit placeholder.
8. Remove dead `toggleDirection` (`chore_providers.dart:58-63`).

## Done criteria

- `flutter analyze` clean; `flutter test` fully green (all existing + new tests); output summary in changes.md.
- `git grep -n "_isTestEnvironment" app/` returns nothing.
- Only files needed for the items above change; nothing outside `app/`.
