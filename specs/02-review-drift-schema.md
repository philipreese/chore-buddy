# Spec 02-review — Adversarial review of the drift persistence layer

## Role

Review. Read-only. Write `report.md` and `verdict.json` to `$AER_OUTPUT_DIR`.

## Subject

The persistence layer just implemented (uncommitted working-tree changes; all files below are new except the two pubspec files):

- `app/lib/core/database/tables.dart`
- `app/lib/core/database/app_database.dart`
- `app/lib/core/database/database_provider.dart`
- `app/lib/core/database/exceptions.dart`
- `app/lib/core/database/chore_with_details.dart`
- `app/lib/core/database/app_database.g.dart` (generated — skim only for consistency)
- `app/test/database_test.dart`
- `app/pubspec.yaml` (drift deps added)

## Contract being claimed (verify each adversarially)

The implementer claims conformance to `specs/02-drift-schema-dao.md` and `docs/proposals/00-new-stack-ideas.md` §2. Specifically:

1. Schema: NOCASE-unique chore names; FK cascades on CompletionRecords and both ChoreTags FKs; composite PK on ChoreTags; RecurrenceType int enum in the proposal's order; FK pragma actually enabled on every connection (not just once).
2. `lastCompleted`/`lastNote` are derived (never stored) and the watch streams emit updated values when completion records are inserted/deleted — check the queries genuinely re-fire (drift stream dependencies cover the joined tables, incl. updates that only touch `CompletionRecords` or `ChoreTags` while watching chores).
3. Duplicate-name detection is case-insensitive and surfaced as `DuplicateNameException` for BOTH insert and rename/update paths, without race (check-then-insert vs constraint-catch).
4. All mutations from the spec exist: chore CRUD, archive/restore, completion record insert/update/delete, tag CRUD incl. delete-all, set chore↔tag links.
5. The database provider is structured so a later backup import can `ref.invalidate` it safely (connection closed on dispose, no leaked singletons).
6. Tests actually test what they claim — no fakery: stream assertions await real emissions rather than polling the same value; cascade test would fail if cascades were absent.

## Also hunt for

- Anything in the layer that would corrupt data or silently drop rows (e.g. `setChoreTags` deleting links non-transactionally).
- Missing transactionality where multi-table writes occur.
- Query correctness of the latest-completion subquery (ties, ordering by id vs completedAt).

## Verdict

`verdict.json`: overall pass/fail plus per-claim findings with file:line evidence. Fail the verdict if any claim in §"Contract being claimed" is false, or a data-corruption path exists.
