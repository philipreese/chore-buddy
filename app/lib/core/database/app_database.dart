import 'package:drift/drift.dart';
import 'package:drift/native.dart';
// drift marks its remote API experimental, but drift_flutter's own
// driftDatabase() is built on it — unwrapping its exception type is
// unavoidable as long as the db runs over the background isolate.
// ignore: experimental_member_use
import 'package:drift/remote.dart' show DriftRemoteException;
import 'package:drift_flutter/drift_flutter.dart';
import 'tables.dart';
import 'chore_with_details.dart';
import 'exceptions.dart';

part 'app_database.g.dart';

/// The drift database file's base name (without the `.sqlite` extension
/// `drift_flutter` appends). Shared with [resolveDatabaseFile] so the
/// backup/import flow locates the exact same file drift opens.
const kDatabaseName = 'chore_buddy';

@DriftDatabase(tables: [Chores, CompletionRecords, Tags, ChoreTags])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e])
      : super(e ?? driftDatabase(name: kDatabaseName));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.addColumn(tags, tags.emoji);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON;');
        },
      );

  // Queries

  Stream<List<ChoreWithDetails>> watchActiveChoresWithDetails() {
    return _watchChoresWithDetails(
      isActive: true,
      orderBy: 'c.created_at ASC, c.id ASC',
    );
  }

  Stream<List<ChoreWithDetails>> watchArchivedChoresWithDetails() {
    return _watchChoresWithDetails(
      isActive: false,
      orderBy: 'c.name ASC',
    );
  }

  Stream<List<ChoreWithDetails>> _watchChoresWithDetails({
    required bool isActive,
    required String orderBy,
  }) {
    final queryStr =
        '''
      SELECT
        c.id AS chore_id,
        c.name AS chore_name,
        c.is_active AS chore_is_active,
        c.next_due_date AS chore_next_due_date,
        c.recurrence AS chore_recurrence,
        c.is_notification_enabled AS chore_is_notification_enabled,
        c.created_at AS chore_created_at,
        t.id AS tag_id,
        t.name AS tag_name,
        t.color_index AS tag_color_index,
        t.emoji AS tag_emoji,
        cr.completed_at AS last_completed,
        cr.note AS last_note
      FROM chores c
      LEFT JOIN chore_tags ct ON ct.chore_id = c.id
      LEFT JOIN tags t ON t.id = ct.tag_id
      LEFT JOIN (
        SELECT chore_id, completed_at, note
        FROM completion_records cr1
        WHERE cr1.id = (
          SELECT cr2.id
          FROM completion_records cr2
          WHERE cr2.chore_id = cr1.chore_id
          ORDER BY cr2.completed_at DESC, cr2.id DESC
          LIMIT 1
        )
      ) cr ON cr.chore_id = c.id
      WHERE c.is_active = ${isActive ? 1 : 0}
      ORDER BY $orderBy;
    ''';

    return customSelect(
      queryStr,
      readsFrom: {chores, tags, choreTags, completionRecords},
    ).watch().map((rows) {
      final Map<int, _ChoreWithDetailsBuilder> map = {};

      for (final row in rows) {
        final choreId = row.read<int>('chore_id');
        if (!map.containsKey(choreId)) {
          final rawRecurrence = row.read<int>('chore_recurrence');
          final recurrence = (rawRecurrence >= 0 &&
                  rawRecurrence < RecurrenceType.values.length)
              ? RecurrenceType.values[rawRecurrence]
              : RecurrenceType.none;

          final chore = ChoreEntity(
            id: choreId,
            name: row.read<String>('chore_name'),
            isActive: row.read<bool>('chore_is_active'),
            nextDueDate: row.readNullable<DateTime>('chore_next_due_date'),
            recurrence: recurrence,
            isNotificationEnabled:
                row.read<bool>('chore_is_notification_enabled'),
            createdAt: row.read<DateTime>('chore_created_at'),
          );

          final lastCompleted = row.readNullable<DateTime>('last_completed');
          final lastNote = row.readNullable<String>('last_note');

          map[choreId] = _ChoreWithDetailsBuilder(
            chore: chore,
            lastCompleted: lastCompleted,
            lastNote: lastNote,
          );
        }

        final tagId = row.readNullable<int>('tag_id');
        if (tagId != null) {
          final tag = TagEntity(
            id: tagId,
            name: row.read<String>('tag_name'),
            colorIndex: row.read<int>('tag_color_index'),
            emoji: row.readNullable<String>('tag_emoji'),
          );
          final builder = map[choreId]!;
          if (!builder.tags.any((t) => t.id == tag.id)) {
            builder.tags.add(tag);
          }
        }
      }

      return map.values.map((b) => b.build()).toList();
    });
  }

  Stream<List<ChoreEntity>> watchArchivedChores() {
    return (select(chores)
          ..where((c) => c.isActive.equals(false))
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .watch();
  }

  Stream<List<TagEntity>> watchTags() {
    return (select(tags)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  }

  Stream<List<CompletionRecordEntity>> watchHistoryForChore(int choreId) {
    return (select(completionRecords)
          ..where((c) => c.choreId.equals(choreId))
          ..orderBy([
            (c) => OrderingTerm.desc(c.completedAt),
            (c) => OrderingTerm.desc(c.id),
          ]))
        .watch();
  }

  Future<ChoreEntity?> getChoreById(int id) {
    return (select(chores)..where((c) => c.id.equals(id))).getSingleOrNull();
  }

  /// One-shot fetch of every active chore, used to re-evaluate notification
  /// scheduling for the whole set (e.g. when the global toggle turns on).
  Future<List<ChoreEntity>> getActiveChores() {
    return (select(chores)..where((c) => c.isActive.equals(true))).get();
  }

  /// One-shot fetch of every archived chore's id, used to cancel their
  /// notifications before a purge-all delete.
  Future<List<int>> getArchivedChoreIds() async {
    final rows =
        await (select(chores)..where((c) => c.isActive.equals(false))).get();
    return rows.map((c) => c.id).toList();
  }

  Future<List<int>> getTagIdsForChore(int id) async {
    final rows =
        await (select(choreTags)..where((ct) => ct.choreId.equals(id))).get();
    return rows.map((r) => r.tagId).toList();
  }

  /// Whether [name] is already taken, active or archived -- the chores
  /// table's UNIQUE constraint (COLLATE NOCASE) spans both, and this
  /// column's declared collation makes the comparison case-insensitive the
  /// same way. Used to find a free suffix when duplicating a chore, ahead
  /// of the insert so the new-chore form can be pre-filled with a name that
  /// will actually save.
  Future<bool> choreNameExists(String name) async {
    final match =
        await (select(chores)..where((c) => c.name.equals(name)))
            .getSingleOrNull();
    return match != null;
  }

  // Chore Mutations

  Future<int> insertChore(ChoresCompanion chore) {
    return _guardUniqueName(
      () => into(chores).insert(chore),
      () => chore.name.present ? chore.name.value : null,
    );
  }

  Future<bool> updateChore(ChoreEntity chore) {
    return _guardUniqueName(
      () => update(chores).replace(chore),
      () => chore.name,
    );
  }

  /// Inserts a chore and links its tags in a single transaction, so a tag
  /// write failure (e.g. a stale tag id) can never leave a chore committed
  /// with no tags.
  Future<int> insertChoreWithTags(ChoresCompanion chore, List<int> tagIds) {
    return transaction(() async {
      final id = await insertChore(chore);
      await setChoreTags(id, tagIds);
      return id;
    });
  }

  /// Updates only [updates]' present columns and links tags in a single
  /// transaction, mirroring [insertChoreWithTags].
  Future<void> updateChoreWithTags(
    int id,
    ChoresCompanion updates,
    List<int> tagIds,
  ) {
    return transaction(() async {
      await _guardUniqueName(
        () => (update(chores)..where((c) => c.id.equals(id))).write(updates),
        () => updates.name.present ? updates.name.value : null,
      );
      await setChoreTags(id, tagIds);
    });
  }

  Future<int> deleteChore(int id) {
    return (delete(chores)..where((c) => c.id.equals(id))).go();
  }

  Future<int> archiveChore(int id) {
    return (update(chores)..where((c) => c.id.equals(id)))
        .write(const ChoresCompanion(isActive: Value(false)));
  }

  Future<int> restoreChore(int id) {
    return (update(chores)..where((c) => c.id.equals(id)))
        .write(const ChoresCompanion(isActive: Value(true)));
  }

  /// Permanently removes every archived chore, cascading to their
  /// completion records and tag links.
  Future<int> deleteArchivedChores() {
    return transaction(() {
      return (delete(chores)..where((c) => c.isActive.equals(false))).go();
    });
  }

  /// One-shot fetch of every chore's id (active and archived), used to
  /// cancel their notifications before a delete-all-chores wipe.
  Future<List<int>> getAllChoreIds() async {
    final rows = await select(chores).get();
    return rows.map((c) => c.id).toList();
  }

  /// Permanently removes every chore, active and archived alike, cascading
  /// to their completion records and tag links.
  Future<int> deleteAllChores() {
    return transaction(() {
      return delete(chores).go();
    });
  }

  // CompletionRecord Mutations

  Future<int> insertCompletionRecord(CompletionRecordsCompanion record) {
    return into(completionRecords).insert(record);
  }

  Future<bool> updateCompletionRecord(CompletionRecordEntity record) {
    return update(completionRecords).replace(record);
  }

  Future<int> deleteCompletionRecord(int id) {
    return (delete(completionRecords)..where((c) => c.id.equals(id))).go();
  }

  // Tag Mutations

  Future<int> insertTag(TagsCompanion tag) {
    return _guardUniqueName(
      () => into(tags).insert(tag),
      () => tag.name.present ? tag.name.value : null,
    );
  }

  Future<bool> updateTag(TagEntity tag) {
    return _guardUniqueName(
      () => update(tags).replace(tag),
      () => tag.name,
    );
  }

  Future<int> deleteTag(int id) {
    return (delete(tags)..where((t) => t.id.equals(id))).go();
  }

  Future<int> updateTagEmoji(int id, String? emoji) {
    return (update(tags)..where((t) => t.id.equals(id)))
        .write(TagsCompanion(emoji: Value(emoji)));
  }

  Future<int> deleteAllTags() {
    return delete(tags).go();
  }

  Future<void> setChoreTags(int choreId, List<int> tagIds) {
    return transaction(() async {
      await (delete(choreTags)..where((ct) => ct.choreId.equals(choreId))).go();
      for (final tagId in tagIds) {
        await into(choreTags).insert(
          ChoreTagsCompanion.insert(
            choreId: choreId,
            tagId: tagId,
          ),
        );
      }
    });
  }

  Future<T> _guardUniqueName<T>(
      Future<T> Function() action, String? Function() getName) async {
    try {
      return await action();
    } catch (e) {
      if (_isUniqueConstraintError(e)) {
        throw DuplicateNameException(getName() ?? '');
      }
      rethrow;
    }
  }

  bool _isUniqueConstraintError(Object error) {
    Object? current = error;
    while (current != null) {
      if (current is SqliteException) {
        return current.extendedResultCode == 2067;
      }
      if (current is DriftWrappedException) {
        current = current.cause;
      } else if (current is DriftRemoteException) {
        // Production runs drift over a background isolate
        // (drift_flutter's driftDatabase), where the original exception
        // arrives wrapped in DriftRemoteException. Tests run an in-process
        // NativeDatabase and never hit this branch — which is exactly how
        // this went unnoticed until it escaped, raw, on a device.
        current = current.remoteCause;
      } else {
        break;
      }
    }
    return false;
  }
}

class _ChoreWithDetailsBuilder {
  final ChoreEntity chore;
  final List<TagEntity> tags = [];
  final DateTime? lastCompleted;
  final String? lastNote;

  _ChoreWithDetailsBuilder({
    required this.chore,
    this.lastCompleted,
    this.lastNote,
  });

  ChoreWithDetails build() {
    return ChoreWithDetails(
      chore: chore,
      tags: tags,
      lastCompleted: lastCompleted,
      lastNote: lastNote,
    );
  }
}
