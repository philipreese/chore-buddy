# Spec 02b — Apply review fixes to the drift layer

## Role

Implement. Report to `$AER_OUTPUT_DIR/changes.md`.

## Environment (stripped — set before builds)

- `ANDROID_HOME=C:\Android\sdk`, `ANDROID_NDK_HOME=C:\Android\sdk\ndk\28.2.13676358`, `JAVA_HOME=C:\Program Files\Android\openjdk\jdk-21.0.8`
- Flutter `C:\src\flutter\bin\flutter.bat`, Dart `C:\src\flutter\bin\dart.bat`

## Task

An adversarial review of `app/lib/core/database/` found these defects. Apply each fix exactly; all inside `app/`. Line numbers refer to current file state.

### Required (review verdict blockers — all in `app/test/database_test.dart`)

1. **Reactivity test observes no reactivity** (~lines 219-287): every assertion is `await stream.first`, which opens a fresh subscription per read. Rewrite to hold ONE subscription for the duration (collect emissions from a single `.listen` into a list, or `expectLater(stream, emitsInOrder([...]))` with writes driven between expectations) and assert the sequence of emitted values as completion records are inserted/deleted. The test must fail if any of `completionRecords`/`choreTags` is removed from the chores query's `readsFrom` set.
2. **Cascade tests can't detect missing ChoreTags cascades**: after `deleteChore` and after `deleteTag`, assert the join table directly — `expect(await db.select(db.choreTags).get(), isEmpty)` — so an orphaned link row fails the test.
3. **Un-awaited async throws** (lines ~169, 178, 197, 209): change `expect(() => ..., throwsA(...))` on Future-returning calls to `await expectLater(..., throwsA(...))`.

### Also fix (in `app/lib/core/database/`)

4. `app_database.dart` (~214): duplicate-name classifier uses `e.toString().contains('2067')` — over-broad (a name containing "2067" failing for an unrelated reason would be misclassified). Match the typed error instead: unwrap to `SqliteException` and check `extendedResultCode == 2067`.
5. `app_database.dart` (~131, 169): `_guardUniqueName(() => ..., chore.name.value)` evaluates `.value` outside the guard, so an absent name throws a `TypeError` from the argument expression. Make the name argument lazy (e.g. `String? Function()` or pass `Value<String>` and read inside the catch) so an absent name surfaces as a database error, not an argument-evaluation crash.
6. `chore_with_details.dart` (~17-31): `==` compares `tags` element-wise but `hashCode` uses `tags.hashCode` (list identity) — contract violation. Use `Object.hash(..., Object.hashAll(tags))`.
7. `tables.dart`: add indexes on `completion_records.chore_id` and `chore_tags.tag_id` (SQLite doesn't auto-index FK child columns). Regenerate with `dart run build_runner build`.
8. `app_database.dart` (~73): `RecurrenceType.values[row.read<int>(...)]` throws `RangeError` on out-of-range stored values (reachable via imported databases later). Clamp/fallback to `RecurrenceType.none`.

## Done criteria

- `flutter analyze` clean; `flutter test` fully green — run both, include output in changes.md.
- Sanity check for fix 1: temporarily removing `completionRecords` from `readsFrom` makes the reactivity test fail (restore it afterwards; mention the check in changes.md).
- Only the files named above (plus regenerated `.g.dart` and pubspec if needed) change. Do not touch anything outside `app/`.
