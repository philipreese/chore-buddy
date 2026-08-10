# Adversarial review — slice 02 drift persistence layer

**Verdict: FAIL** (one contract claim is false; no data-corruption path found)

The schema and DAO implementation are, with small exceptions, correct and faithful to
`docs/proposals/00-new-stack-ideas.md` §2 and `specs/02-drift-schema-dao.md`. The failure is
Claim 6: **the test suite does not test what it claims**. Reactivity is never observed (the
"reactive" test polls a fresh subscription each time), and two of the three cascade paths are
asserted in a way that passes identically whether or not the cascade exists. The production code
looks right; the tests do not prove it, and would not catch a regression that broke it.

Note on method: I have no shell in this review, so I could not execute `flutter test` or inspect
SQLite behaviour empirically. Everything below is from reading the sources and `app_database.g.dart`.

---

## Claim-by-claim

### Claim 1 — Schema. **PASS**

- NOCASE-unique chore name: `app/lib/core/database/tables.dart:14-15`, emitted verbatim into the
  DDL as `$customConstraints: 'NOT NULL UNIQUE COLLATE NOCASE'`
  (`app/lib/core/database/app_database.g.dart:32`). SQLite applies the column's declared collation
  to the implicit UNIQUE index regardless of constraint ordering, so the index is NOCASE.
- Cascades: `tables.dart:29` (CompletionRecords→Chores), `tables.dart:44` (ChoreTags→Chores),
  `tables.dart:46` (ChoreTags→Tags). Generated as `REFERENCES chores (id) ON DELETE CASCADE` /
  `REFERENCES tags (id) ON DELETE CASCADE` at `app_database.g.dart:512, 1053, 1065`.
- Composite PK on ChoreTags: `tables.dart:48-49` → `app_database.g.dart:1102`
  (`$primaryKey => {choreId, tagId}`).
- `RecurrenceType` order `none, daily, everyOtherDay, weekly, monthly` (`tables.dart:3-9`) matches
  the proposal's `0..4` mapping (`docs/proposals/00-new-stack-ideas.md:94, 103-109`).
  `intEnum<RecurrenceType>().withDefault(const Constant(0))` (`tables.dart:18-19`) is equivalent to
  the proposal's `Constant(RecurrenceType.none.index)`.
- FK pragma on **every** connection: `app_database.dart:18-22` uses `MigrationStrategy.beforeOpen`,
  which drift runs on each open of the underlying executor — not a one-shot at creation. This is the
  correct hook, and it applies equally to the in-memory test database. Overriding `migration` without
  an `onCreate` is safe: drift's default `onCreate` is `m.createAll()`.

Minor: the proposal annotates `Tags.name` as "lower-cased, <= 22 chars"
(`docs/proposals/00-new-stack-ideas.md:133`). Neither constraint is enforced anywhere in the layer.
That comment is prose that enforces nothing; if it matters, it needs a CHECK constraint or a
validated mutation path. Also note the asymmetry that follows from it: chore names are NOCASE-unique,
tag names are case-**sensitive** unique (`tables.dart:37`), so `Kitchen` and `kitchen` can coexist as
two tags. That matches the proposal, so it is not a contract breach — but it is a latent product bug.

### Claim 2 — Derived `lastCompleted`/`lastNote`. **PASS (implementation) / UNVERIFIED (reactivity)**

Neither field exists on `Chores` (`tables.dart:12-23`); both are computed by the correlated subquery
at `app_database.dart:44-54` and read per row at `app_database.dart:79-80`. Drift stream dependencies
are declared correctly: `readsFrom: {chores, tags, choreTags, completionRecords}`
(`app_database.dart:61`), so a write touching only `completion_records` or only `chore_tags` does
invalidate the chores stream. `setChoreTags`' writes happen inside a transaction
(`app_database.dart:185`) and drift dispatches table updates on commit, so that path notifies too.
The typed streams (`app_database.dart:107-126`) get their dependencies inferred by drift.

So the code is right. But nothing in the suite exercises it — see Claim 6. Delete `completionRecords`
and `choreTags` from that `readsFrom` set and every test still passes.

### Claim 3 — Duplicate names. **PASS**

Constraint-catch, not check-then-insert: `_guardUniqueName` (`app_database.dart:198-208`) wraps the
actual write and translates the SQLite failure, so there is no TOCTOU window. It is applied on both
the insert and the update/rename path for chores (`app_database.dart:131, 135`) and for tags
(`app_database.dart:169, 173`). Case-insensitivity for chores comes from the NOCASE index, so the
rename path is covered by the same mechanism as insert. No raw `SqliteException` leaks.

Two defects in the classifier, neither fatal:

1. **Substring match on `'2067'` is over-broad** (`app_database.dart:214`). Drift wraps the driver
   exception and its `toString()` includes the causing statement and bound variables. A chore or tag
   whose name contains `2067` (`"Party 2067"`, `"Reunion 2067"`) that fails for an *unrelated* reason
   — a NOT NULL violation, say — is misreported to callers as `DuplicateNameException`. Match on the
   typed code instead: `e is SqliteException && e.extendedResultCode == 2067`.
2. **The name argument is evaluated outside the guard** (`app_database.dart:131`):
   `_guardUniqueName(() => ..., chore.name.value)` reads `.value` before the try block, so
   `insertChore(ChoresCompanion())` with an absent name throws a null-cast `TypeError` from the
   argument list rather than surfacing a database error. Same at `app_database.dart:169`.

### Claim 4 — Mutation coverage. **PASS**

Chore insert/update/delete (`app_database.dart:130-140`), archive/restore (`142-150`), completion
record insert/update/delete (`154-164`), tag CRUD incl. `deleteAllTags` (`168-182`), and
`setChoreTags` (`184-196`). All present.

### Claim 5 — Provider invalidatable for backup hot-swap. **PASS, with a caveat**

`appDatabaseProvider` (`database_provider.dart:5-11`) holds no static/top-level instance and registers
`ref.onDispose` to close the connection, so `ref.invalidate` disposes cleanly and the four dependent
`StreamProvider`s (`database_provider.dart:13-33`) re-subscribe against the new instance. No leaked
singleton.

Caveat: `ref.onDispose` is synchronous, so `database.close()` at `database_provider.dart:8` is
fire-and-forget — its future is neither awaited nor stored. The proposal's import flow
(`docs/proposals/00-new-stack-ideas.md:182-184`) closes the executor and swaps the file *before*
invalidating, so the ordering works out there. But if a future caller invalidates first and replaces
the file after, the old connection may still be open against the file being replaced. The provider
offers no handle to await disposal. Worth addressing when slice 09 lands, not now.

### Claim 6 — Tests test what they claim. **FAIL**

**6a. The reactivity test does not observe reactivity.** `app/test/database_test.dart:227` captures
the stream once, then every assertion is `await stream.first` (lines 228, 242, 256, 270, 277, 284).
Each `.first` opens a *new* subscription, drift runs the query fresh, emits once, and `.first`
cancels. No existing subscriber is ever held open across a write, so no re-emission is ever observed.
This is precisely the "polling the same value" pattern the contract rules out. It validates the
*derivation* (latest-record selection, tie-breaking, fallback after delete — all genuinely covered)
but proves nothing about stream dependencies. A correct test holds one subscription and asserts the
sequence of emissions, e.g. via `expectLater(stream, emitsInOrder([...]))` with the writes driven
between expectations, or by collecting emissions into a list from a single `listen`.

**6b. Two of three cascades would pass with cascades absent.**

- CompletionRecords→Chores *is* genuinely tested: `database_test.dart:132` deletes the chore,
  `137-138` asserts the history is empty. Without the cascade the rows survive (or the DELETE throws
  on the FK) — either way the test fails. Good.
- ChoreTags→Chores is **not** tested. After `deleteChore` at line 132, the only assertions are that
  `watchActiveChoresWithDetails` is empty (line 135) and history is empty (138). An orphaned
  `chore_tags` row referencing the deleted chore is invisible to both, because the chore row itself is
  gone. Nothing queries `chore_tags` directly.
- ChoreTags→Tags is **not** meaningfully tested. Line 155 deletes the tag; line 158 asserts
  `detailsAfterTagDelete.first.tags` is empty. But the details query reads tag fields via
  `LEFT JOIN tags t ON t.id = ct.tag_id` (`app_database.dart:43`) and projects `t.id AS tag_id`
  (`app_database.g.dart`-independent, `app_database.dart:36`); the Dart mapper skips rows where
  `tag_id` is null (`app_database.dart:89-90`). With the cascade removed, the orphaned `chore_tags`
  row joins to no `tags` row, `t.id` is NULL, and the assertion still passes. The test cannot
  distinguish "link deleted" from "link orphaned".

  Fix both by asserting on the join table directly, e.g.
  `expect(await db.select(db.choreTags).get(), isEmpty)` after each delete.

**6c. Un-awaited async `throwsA`.** `database_test.dart:169, 178, 197, 209` use
`expect(() => db.insertChore(...), throwsA(...))` on functions returning `Future`. This is the
classic async-expectation trap: the callback returns rather than throws synchronously, and whether
this passes, fails, or reports late depends on package:matcher's future handling. Use
`await expectLater(..., throwsA(...))` so the assertion is deterministic and ordered relative to the
subsequent writes in the same test. As written, the two failed-insert attempts at 169-185 and the
failed rename at 197-200 are not sequenced against the `insertTag` that follows.

---

## Other findings

**No data-corruption path found.** `setChoreTags` (`app_database.dart:184-196`) wraps the
delete-then-reinsert in `transaction()`, so a mid-loop failure rolls the deletion back — the specific
hazard the brief called out is not present. It is the only multi-table write in the layer;
`deleteChore` and `deleteTag` rely on FK cascade, which is atomic within the statement. No missing
transactionality.

**Latest-completion subquery is correct** (`app_database.dart:44-54`). `ORDER BY cr2.completed_at
DESC, cr2.id DESC LIMIT 1` gives a deterministic winner on `completed_at` ties (highest id, i.e. most
recently inserted), and matching on `cr1.id = (...)` rather than on `MAX(completed_at)` avoids the
classic bare-column bug where `note` could come from a different row than `completed_at`. The
`watchHistoryForChore` ordering (`app_database.dart:121-124`) uses the same tie-break, so history and
derived-latest agree.

**Missing indexes.** SQLite does not auto-index the child side of a foreign key.
`completion_records.chore_id` has no index, so the correlated subquery at `app_database.dart:47-53`
scans and the per-chore history query (`app_database.dart:120`) scans. `chore_tags`' composite PK
indexes `(chore_id, tag_id)`, which serves the chore-side join but leaves `tag_id` lookups —
including the `ON DELETE CASCADE` from `tags` — unindexed. At household chore-list scale this is
irrelevant; it becomes relevant if history grows to thousands of rows. Cheap to add now.

**`ChoreWithDetails` violates the hashCode/equals contract**
(`app/lib/core/database/chore_with_details.dart:17-31`). `==` compares `tags` deeply via
`_listEquals` (line 22), but `hashCode` uses `tags.hashCode` (line 29), which is List identity. Two
equal instances therefore hash differently, breaking `Set`/`Map` membership. Riverpod's rebuild
short-circuit uses `==` so nothing is broken today, but this is a trap for any consumer. Use
`Object.hashAll(tags)` — and note the same line's `^` chaining is a weak mix; `Object.hash(...)` is
better.

**Unchecked enum index** (`app_database.dart:73`). `RecurrenceType.values[row.read<int>(...)]` throws
`RangeError` on an out-of-range stored value. Only reachable via a corrupted or externally-imported
database — which is exactly what slice 09's import feature will introduce. Consider clamping to
`none`.

**Dead locals in tests.** `database_test.dart:234` (`rec1Id`) is used at 282, but the pattern of
capturing ids and re-deriving entities via `watchActiveChoresWithDetails().first`
(`database_test.dart:194-195`) is roundabout; a direct `select` would be clearer and would not couple
the duplicate-name test to the details query.

---

## What would flip this to PASS

1. Rewrite the reactivity assertions in `database_test.dart:219-287` to hold a single subscription and
   assert on emitted values in order.
2. Assert `chore_tags` contents directly after `deleteChore` and after `deleteTag` so both ChoreTags
   cascades genuinely fail when removed.
3. `await expectLater` for the four `throwsA` assertions.

The classifier substring match (`app_database.dart:214`) and the `hashCode` bug should be fixed too,
but neither is a contract failure on its own.
