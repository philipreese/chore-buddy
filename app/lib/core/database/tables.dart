import 'package:drift/drift.dart';

enum RecurrenceType {
  none,
  daily,
  everyOtherDay,
  weekly,
  monthly,
  customDays,
}

@DataClassName('ChoreEntity')
class Chores extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name =>
      text().customConstraint('NOT NULL UNIQUE COLLATE NOCASE')();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get nextDueDate => dateTime().nullable()();
  IntColumn get recurrence =>
      intEnum<RecurrenceType>().withDefault(const Constant(0))();
  // Only meaningful when recurrence == RecurrenceType.customDays (valid
  // range 1-365); null for every other recurrence type.
  IntColumn get recurrenceInterval => integer().nullable()();
  BoolColumn get isNotificationEnabled =>
      boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('CompletionRecordEntity')
@TableIndex(name: 'idx_completion_records_chore_id', columns: {#choreId})
class CompletionRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get choreId =>
      integer().references(Chores, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get completedAt => dateTime()();
  TextColumn get note => text().withDefault(const Constant(''))();
}

@DataClassName('TagEntity')
class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().customConstraint('NOT NULL UNIQUE')();
  IntColumn get colorIndex => integer().withDefault(const Constant(0))();
  TextColumn get emoji => text().nullable()();
}

@DataClassName('ChoreTagEntity')
@TableIndex(name: 'idx_chore_tags_tag_id', columns: {#tagId})
class ChoreTags extends Table {
  IntColumn get choreId =>
      integer().references(Chores, #id, onDelete: KeyAction.cascade)();
  IntColumn get tagId =>
      integer().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {choreId, tagId};
}
