// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ChoresTable extends Chores with TableInfo<$ChoresTable, ChoreEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE COLLATE NOCASE',
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _nextDueDateMeta = const VerificationMeta(
    'nextDueDate',
  );
  @override
  late final GeneratedColumn<DateTime> nextDueDate = GeneratedColumn<DateTime>(
    'next_due_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<RecurrenceType, int> recurrence =
      GeneratedColumn<int>(
        'recurrence',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<RecurrenceType>($ChoresTable.$converterrecurrence);
  static const VerificationMeta _recurrenceIntervalMeta =
      const VerificationMeta('recurrenceInterval');
  @override
  late final GeneratedColumn<int> recurrenceInterval = GeneratedColumn<int>(
    'recurrence_interval',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isNotificationEnabledMeta =
      const VerificationMeta('isNotificationEnabled');
  @override
  late final GeneratedColumn<bool> isNotificationEnabled =
      GeneratedColumn<bool>(
        'is_notification_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_notification_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
    'emoji',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    isActive,
    nextDueDate,
    recurrence,
    recurrenceInterval,
    isNotificationEnabled,
    createdAt,
    emoji,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chores';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChoreEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('next_due_date')) {
      context.handle(
        _nextDueDateMeta,
        nextDueDate.isAcceptableOrUnknown(
          data['next_due_date']!,
          _nextDueDateMeta,
        ),
      );
    }
    if (data.containsKey('recurrence_interval')) {
      context.handle(
        _recurrenceIntervalMeta,
        recurrenceInterval.isAcceptableOrUnknown(
          data['recurrence_interval']!,
          _recurrenceIntervalMeta,
        ),
      );
    }
    if (data.containsKey('is_notification_enabled')) {
      context.handle(
        _isNotificationEnabledMeta,
        isNotificationEnabled.isAcceptableOrUnknown(
          data['is_notification_enabled']!,
          _isNotificationEnabledMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('emoji')) {
      context.handle(
        _emojiMeta,
        emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChoreEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChoreEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      nextDueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_due_date'],
      ),
      recurrence: $ChoresTable.$converterrecurrence.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}recurrence'],
        )!,
      ),
      recurrenceInterval: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recurrence_interval'],
      ),
      isNotificationEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_notification_enabled'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      emoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emoji'],
      ),
    );
  }

  @override
  $ChoresTable createAlias(String alias) {
    return $ChoresTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<RecurrenceType, int, int> $converterrecurrence =
      const EnumIndexConverter<RecurrenceType>(RecurrenceType.values);
}

class ChoreEntity extends DataClass implements Insertable<ChoreEntity> {
  final int id;
  final String name;
  final bool isActive;
  final DateTime? nextDueDate;
  final RecurrenceType recurrence;
  final int? recurrenceInterval;
  final bool isNotificationEnabled;
  final DateTime createdAt;
  final String? emoji;
  const ChoreEntity({
    required this.id,
    required this.name,
    required this.isActive,
    this.nextDueDate,
    required this.recurrence,
    this.recurrenceInterval,
    required this.isNotificationEnabled,
    required this.createdAt,
    this.emoji,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || nextDueDate != null) {
      map['next_due_date'] = Variable<DateTime>(nextDueDate);
    }
    {
      map['recurrence'] = Variable<int>(
        $ChoresTable.$converterrecurrence.toSql(recurrence),
      );
    }
    if (!nullToAbsent || recurrenceInterval != null) {
      map['recurrence_interval'] = Variable<int>(recurrenceInterval);
    }
    map['is_notification_enabled'] = Variable<bool>(isNotificationEnabled);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || emoji != null) {
      map['emoji'] = Variable<String>(emoji);
    }
    return map;
  }

  ChoresCompanion toCompanion(bool nullToAbsent) {
    return ChoresCompanion(
      id: Value(id),
      name: Value(name),
      isActive: Value(isActive),
      nextDueDate: nextDueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(nextDueDate),
      recurrence: Value(recurrence),
      recurrenceInterval: recurrenceInterval == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceInterval),
      isNotificationEnabled: Value(isNotificationEnabled),
      createdAt: Value(createdAt),
      emoji: emoji == null && nullToAbsent
          ? const Value.absent()
          : Value(emoji),
    );
  }

  factory ChoreEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChoreEntity(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      nextDueDate: serializer.fromJson<DateTime?>(json['nextDueDate']),
      recurrence: $ChoresTable.$converterrecurrence.fromJson(
        serializer.fromJson<int>(json['recurrence']),
      ),
      recurrenceInterval: serializer.fromJson<int?>(json['recurrenceInterval']),
      isNotificationEnabled: serializer.fromJson<bool>(
        json['isNotificationEnabled'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      emoji: serializer.fromJson<String?>(json['emoji']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'isActive': serializer.toJson<bool>(isActive),
      'nextDueDate': serializer.toJson<DateTime?>(nextDueDate),
      'recurrence': serializer.toJson<int>(
        $ChoresTable.$converterrecurrence.toJson(recurrence),
      ),
      'recurrenceInterval': serializer.toJson<int?>(recurrenceInterval),
      'isNotificationEnabled': serializer.toJson<bool>(isNotificationEnabled),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'emoji': serializer.toJson<String?>(emoji),
    };
  }

  ChoreEntity copyWith({
    int? id,
    String? name,
    bool? isActive,
    Value<DateTime?> nextDueDate = const Value.absent(),
    RecurrenceType? recurrence,
    Value<int?> recurrenceInterval = const Value.absent(),
    bool? isNotificationEnabled,
    DateTime? createdAt,
    Value<String?> emoji = const Value.absent(),
  }) => ChoreEntity(
    id: id ?? this.id,
    name: name ?? this.name,
    isActive: isActive ?? this.isActive,
    nextDueDate: nextDueDate.present ? nextDueDate.value : this.nextDueDate,
    recurrence: recurrence ?? this.recurrence,
    recurrenceInterval: recurrenceInterval.present
        ? recurrenceInterval.value
        : this.recurrenceInterval,
    isNotificationEnabled: isNotificationEnabled ?? this.isNotificationEnabled,
    createdAt: createdAt ?? this.createdAt,
    emoji: emoji.present ? emoji.value : this.emoji,
  );
  ChoreEntity copyWithCompanion(ChoresCompanion data) {
    return ChoreEntity(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      nextDueDate: data.nextDueDate.present
          ? data.nextDueDate.value
          : this.nextDueDate,
      recurrence: data.recurrence.present
          ? data.recurrence.value
          : this.recurrence,
      recurrenceInterval: data.recurrenceInterval.present
          ? data.recurrenceInterval.value
          : this.recurrenceInterval,
      isNotificationEnabled: data.isNotificationEnabled.present
          ? data.isNotificationEnabled.value
          : this.isNotificationEnabled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChoreEntity(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isActive: $isActive, ')
          ..write('nextDueDate: $nextDueDate, ')
          ..write('recurrence: $recurrence, ')
          ..write('recurrenceInterval: $recurrenceInterval, ')
          ..write('isNotificationEnabled: $isNotificationEnabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('emoji: $emoji')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    isActive,
    nextDueDate,
    recurrence,
    recurrenceInterval,
    isNotificationEnabled,
    createdAt,
    emoji,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChoreEntity &&
          other.id == this.id &&
          other.name == this.name &&
          other.isActive == this.isActive &&
          other.nextDueDate == this.nextDueDate &&
          other.recurrence == this.recurrence &&
          other.recurrenceInterval == this.recurrenceInterval &&
          other.isNotificationEnabled == this.isNotificationEnabled &&
          other.createdAt == this.createdAt &&
          other.emoji == this.emoji);
}

class ChoresCompanion extends UpdateCompanion<ChoreEntity> {
  final Value<int> id;
  final Value<String> name;
  final Value<bool> isActive;
  final Value<DateTime?> nextDueDate;
  final Value<RecurrenceType> recurrence;
  final Value<int?> recurrenceInterval;
  final Value<bool> isNotificationEnabled;
  final Value<DateTime> createdAt;
  final Value<String?> emoji;
  const ChoresCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.isActive = const Value.absent(),
    this.nextDueDate = const Value.absent(),
    this.recurrence = const Value.absent(),
    this.recurrenceInterval = const Value.absent(),
    this.isNotificationEnabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.emoji = const Value.absent(),
  });
  ChoresCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.isActive = const Value.absent(),
    this.nextDueDate = const Value.absent(),
    this.recurrence = const Value.absent(),
    this.recurrenceInterval = const Value.absent(),
    this.isNotificationEnabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.emoji = const Value.absent(),
  }) : name = Value(name);
  static Insertable<ChoreEntity> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<bool>? isActive,
    Expression<DateTime>? nextDueDate,
    Expression<int>? recurrence,
    Expression<int>? recurrenceInterval,
    Expression<bool>? isNotificationEnabled,
    Expression<DateTime>? createdAt,
    Expression<String>? emoji,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (isActive != null) 'is_active': isActive,
      if (nextDueDate != null) 'next_due_date': nextDueDate,
      if (recurrence != null) 'recurrence': recurrence,
      if (recurrenceInterval != null) 'recurrence_interval': recurrenceInterval,
      if (isNotificationEnabled != null)
        'is_notification_enabled': isNotificationEnabled,
      if (createdAt != null) 'created_at': createdAt,
      if (emoji != null) 'emoji': emoji,
    });
  }

  ChoresCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<bool>? isActive,
    Value<DateTime?>? nextDueDate,
    Value<RecurrenceType>? recurrence,
    Value<int?>? recurrenceInterval,
    Value<bool>? isNotificationEnabled,
    Value<DateTime>? createdAt,
    Value<String?>? emoji,
  }) {
    return ChoresCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      recurrence: recurrence ?? this.recurrence,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      isNotificationEnabled:
          isNotificationEnabled ?? this.isNotificationEnabled,
      createdAt: createdAt ?? this.createdAt,
      emoji: emoji ?? this.emoji,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (nextDueDate.present) {
      map['next_due_date'] = Variable<DateTime>(nextDueDate.value);
    }
    if (recurrence.present) {
      map['recurrence'] = Variable<int>(
        $ChoresTable.$converterrecurrence.toSql(recurrence.value),
      );
    }
    if (recurrenceInterval.present) {
      map['recurrence_interval'] = Variable<int>(recurrenceInterval.value);
    }
    if (isNotificationEnabled.present) {
      map['is_notification_enabled'] = Variable<bool>(
        isNotificationEnabled.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChoresCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isActive: $isActive, ')
          ..write('nextDueDate: $nextDueDate, ')
          ..write('recurrence: $recurrence, ')
          ..write('recurrenceInterval: $recurrenceInterval, ')
          ..write('isNotificationEnabled: $isNotificationEnabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('emoji: $emoji')
          ..write(')'))
        .toString();
  }
}

class $CompletionRecordsTable extends CompletionRecords
    with TableInfo<$CompletionRecordsTable, CompletionRecordEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompletionRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _choreIdMeta = const VerificationMeta(
    'choreId',
  );
  @override
  late final GeneratedColumn<int> choreId = GeneratedColumn<int>(
    'chore_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES chores (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [id, choreId, completedAt, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'completion_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<CompletionRecordEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('chore_id')) {
      context.handle(
        _choreIdMeta,
        choreId.isAcceptableOrUnknown(data['chore_id']!, _choreIdMeta),
      );
    } else if (isInserting) {
      context.missing(_choreIdMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CompletionRecordEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CompletionRecordEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      choreId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chore_id'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
    );
  }

  @override
  $CompletionRecordsTable createAlias(String alias) {
    return $CompletionRecordsTable(attachedDatabase, alias);
  }
}

class CompletionRecordEntity extends DataClass
    implements Insertable<CompletionRecordEntity> {
  final int id;
  final int choreId;
  final DateTime completedAt;
  final String note;
  const CompletionRecordEntity({
    required this.id,
    required this.choreId,
    required this.completedAt,
    required this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['chore_id'] = Variable<int>(choreId);
    map['completed_at'] = Variable<DateTime>(completedAt);
    map['note'] = Variable<String>(note);
    return map;
  }

  CompletionRecordsCompanion toCompanion(bool nullToAbsent) {
    return CompletionRecordsCompanion(
      id: Value(id),
      choreId: Value(choreId),
      completedAt: Value(completedAt),
      note: Value(note),
    );
  }

  factory CompletionRecordEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CompletionRecordEntity(
      id: serializer.fromJson<int>(json['id']),
      choreId: serializer.fromJson<int>(json['choreId']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      note: serializer.fromJson<String>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'choreId': serializer.toJson<int>(choreId),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'note': serializer.toJson<String>(note),
    };
  }

  CompletionRecordEntity copyWith({
    int? id,
    int? choreId,
    DateTime? completedAt,
    String? note,
  }) => CompletionRecordEntity(
    id: id ?? this.id,
    choreId: choreId ?? this.choreId,
    completedAt: completedAt ?? this.completedAt,
    note: note ?? this.note,
  );
  CompletionRecordEntity copyWithCompanion(CompletionRecordsCompanion data) {
    return CompletionRecordEntity(
      id: data.id.present ? data.id.value : this.id,
      choreId: data.choreId.present ? data.choreId.value : this.choreId,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CompletionRecordEntity(')
          ..write('id: $id, ')
          ..write('choreId: $choreId, ')
          ..write('completedAt: $completedAt, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, choreId, completedAt, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompletionRecordEntity &&
          other.id == this.id &&
          other.choreId == this.choreId &&
          other.completedAt == this.completedAt &&
          other.note == this.note);
}

class CompletionRecordsCompanion
    extends UpdateCompanion<CompletionRecordEntity> {
  final Value<int> id;
  final Value<int> choreId;
  final Value<DateTime> completedAt;
  final Value<String> note;
  const CompletionRecordsCompanion({
    this.id = const Value.absent(),
    this.choreId = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.note = const Value.absent(),
  });
  CompletionRecordsCompanion.insert({
    this.id = const Value.absent(),
    required int choreId,
    required DateTime completedAt,
    this.note = const Value.absent(),
  }) : choreId = Value(choreId),
       completedAt = Value(completedAt);
  static Insertable<CompletionRecordEntity> custom({
    Expression<int>? id,
    Expression<int>? choreId,
    Expression<DateTime>? completedAt,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (choreId != null) 'chore_id': choreId,
      if (completedAt != null) 'completed_at': completedAt,
      if (note != null) 'note': note,
    });
  }

  CompletionRecordsCompanion copyWith({
    Value<int>? id,
    Value<int>? choreId,
    Value<DateTime>? completedAt,
    Value<String>? note,
  }) {
    return CompletionRecordsCompanion(
      id: id ?? this.id,
      choreId: choreId ?? this.choreId,
      completedAt: completedAt ?? this.completedAt,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (choreId.present) {
      map['chore_id'] = Variable<int>(choreId.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompletionRecordsCompanion(')
          ..write('id: $id, ')
          ..write('choreId: $choreId, ')
          ..write('completedAt: $completedAt, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, TagEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE',
  );
  static const VerificationMeta _colorIndexMeta = const VerificationMeta(
    'colorIndex',
  );
  @override
  late final GeneratedColumn<int> colorIndex = GeneratedColumn<int>(
    'color_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
    'emoji',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, colorIndex, emoji];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<TagEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color_index')) {
      context.handle(
        _colorIndexMeta,
        colorIndex.isAcceptableOrUnknown(data['color_index']!, _colorIndexMeta),
      );
    }
    if (data.containsKey('emoji')) {
      context.handle(
        _emojiMeta,
        emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TagEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TagEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      colorIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_index'],
      )!,
      emoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emoji'],
      ),
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class TagEntity extends DataClass implements Insertable<TagEntity> {
  final int id;
  final String name;
  final int colorIndex;
  final String? emoji;
  const TagEntity({
    required this.id,
    required this.name,
    required this.colorIndex,
    this.emoji,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['color_index'] = Variable<int>(colorIndex);
    if (!nullToAbsent || emoji != null) {
      map['emoji'] = Variable<String>(emoji);
    }
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      name: Value(name),
      colorIndex: Value(colorIndex),
      emoji: emoji == null && nullToAbsent
          ? const Value.absent()
          : Value(emoji),
    );
  }

  factory TagEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TagEntity(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      colorIndex: serializer.fromJson<int>(json['colorIndex']),
      emoji: serializer.fromJson<String?>(json['emoji']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'colorIndex': serializer.toJson<int>(colorIndex),
      'emoji': serializer.toJson<String?>(emoji),
    };
  }

  TagEntity copyWith({
    int? id,
    String? name,
    int? colorIndex,
    Value<String?> emoji = const Value.absent(),
  }) => TagEntity(
    id: id ?? this.id,
    name: name ?? this.name,
    colorIndex: colorIndex ?? this.colorIndex,
    emoji: emoji.present ? emoji.value : this.emoji,
  );
  TagEntity copyWithCompanion(TagsCompanion data) {
    return TagEntity(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      colorIndex: data.colorIndex.present
          ? data.colorIndex.value
          : this.colorIndex,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TagEntity(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorIndex: $colorIndex, ')
          ..write('emoji: $emoji')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, colorIndex, emoji);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TagEntity &&
          other.id == this.id &&
          other.name == this.name &&
          other.colorIndex == this.colorIndex &&
          other.emoji == this.emoji);
}

class TagsCompanion extends UpdateCompanion<TagEntity> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> colorIndex;
  final Value<String?> emoji;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.colorIndex = const Value.absent(),
    this.emoji = const Value.absent(),
  });
  TagsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.colorIndex = const Value.absent(),
    this.emoji = const Value.absent(),
  }) : name = Value(name);
  static Insertable<TagEntity> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? colorIndex,
    Expression<String>? emoji,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (colorIndex != null) 'color_index': colorIndex,
      if (emoji != null) 'emoji': emoji,
    });
  }

  TagsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? colorIndex,
    Value<String?>? emoji,
  }) {
    return TagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      colorIndex: colorIndex ?? this.colorIndex,
      emoji: emoji ?? this.emoji,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colorIndex.present) {
      map['color_index'] = Variable<int>(colorIndex.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorIndex: $colorIndex, ')
          ..write('emoji: $emoji')
          ..write(')'))
        .toString();
  }
}

class $ChoreTagsTable extends ChoreTags
    with TableInfo<$ChoreTagsTable, ChoreTagEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChoreTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _choreIdMeta = const VerificationMeta(
    'choreId',
  );
  @override
  late final GeneratedColumn<int> choreId = GeneratedColumn<int>(
    'chore_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES chores (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<int> tagId = GeneratedColumn<int>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tags (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [choreId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chore_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChoreTagEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('chore_id')) {
      context.handle(
        _choreIdMeta,
        choreId.isAcceptableOrUnknown(data['chore_id']!, _choreIdMeta),
      );
    } else if (isInserting) {
      context.missing(_choreIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {choreId, tagId};
  @override
  ChoreTagEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChoreTagEntity(
      choreId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chore_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tag_id'],
      )!,
    );
  }

  @override
  $ChoreTagsTable createAlias(String alias) {
    return $ChoreTagsTable(attachedDatabase, alias);
  }
}

class ChoreTagEntity extends DataClass implements Insertable<ChoreTagEntity> {
  final int choreId;
  final int tagId;
  const ChoreTagEntity({required this.choreId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['chore_id'] = Variable<int>(choreId);
    map['tag_id'] = Variable<int>(tagId);
    return map;
  }

  ChoreTagsCompanion toCompanion(bool nullToAbsent) {
    return ChoreTagsCompanion(choreId: Value(choreId), tagId: Value(tagId));
  }

  factory ChoreTagEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChoreTagEntity(
      choreId: serializer.fromJson<int>(json['choreId']),
      tagId: serializer.fromJson<int>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'choreId': serializer.toJson<int>(choreId),
      'tagId': serializer.toJson<int>(tagId),
    };
  }

  ChoreTagEntity copyWith({int? choreId, int? tagId}) => ChoreTagEntity(
    choreId: choreId ?? this.choreId,
    tagId: tagId ?? this.tagId,
  );
  ChoreTagEntity copyWithCompanion(ChoreTagsCompanion data) {
    return ChoreTagEntity(
      choreId: data.choreId.present ? data.choreId.value : this.choreId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChoreTagEntity(')
          ..write('choreId: $choreId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(choreId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChoreTagEntity &&
          other.choreId == this.choreId &&
          other.tagId == this.tagId);
}

class ChoreTagsCompanion extends UpdateCompanion<ChoreTagEntity> {
  final Value<int> choreId;
  final Value<int> tagId;
  final Value<int> rowid;
  const ChoreTagsCompanion({
    this.choreId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChoreTagsCompanion.insert({
    required int choreId,
    required int tagId,
    this.rowid = const Value.absent(),
  }) : choreId = Value(choreId),
       tagId = Value(tagId);
  static Insertable<ChoreTagEntity> custom({
    Expression<int>? choreId,
    Expression<int>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (choreId != null) 'chore_id': choreId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChoreTagsCompanion copyWith({
    Value<int>? choreId,
    Value<int>? tagId,
    Value<int>? rowid,
  }) {
    return ChoreTagsCompanion(
      choreId: choreId ?? this.choreId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (choreId.present) {
      map['chore_id'] = Variable<int>(choreId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<int>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChoreTagsCompanion(')
          ..write('choreId: $choreId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ChoresTable chores = $ChoresTable(this);
  late final $CompletionRecordsTable completionRecords =
      $CompletionRecordsTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $ChoreTagsTable choreTags = $ChoreTagsTable(this);
  late final Index idxCompletionRecordsChoreId = Index(
    'idx_completion_records_chore_id',
    'CREATE INDEX idx_completion_records_chore_id ON completion_records (chore_id)',
  );
  late final Index idxChoreTagsTagId = Index(
    'idx_chore_tags_tag_id',
    'CREATE INDEX idx_chore_tags_tag_id ON chore_tags (tag_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    chores,
    completionRecords,
    tags,
    choreTags,
    idxCompletionRecordsChoreId,
    idxChoreTagsTagId,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'chores',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('completion_records', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'chores',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('chore_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tags',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('chore_tags', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ChoresTableCreateCompanionBuilder =
    ChoresCompanion Function({
      Value<int> id,
      required String name,
      Value<bool> isActive,
      Value<DateTime?> nextDueDate,
      Value<RecurrenceType> recurrence,
      Value<int?> recurrenceInterval,
      Value<bool> isNotificationEnabled,
      Value<DateTime> createdAt,
      Value<String?> emoji,
    });
typedef $$ChoresTableUpdateCompanionBuilder =
    ChoresCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<bool> isActive,
      Value<DateTime?> nextDueDate,
      Value<RecurrenceType> recurrence,
      Value<int?> recurrenceInterval,
      Value<bool> isNotificationEnabled,
      Value<DateTime> createdAt,
      Value<String?> emoji,
    });

final class $$ChoresTableReferences
    extends BaseReferences<_$AppDatabase, $ChoresTable, ChoreEntity> {
  $$ChoresTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $CompletionRecordsTable,
    List<CompletionRecordEntity>
  >
  _completionRecordsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.completionRecords,
        aliasName: $_aliasNameGenerator(
          db.chores.id,
          db.completionRecords.choreId,
        ),
      );

  $$CompletionRecordsTableProcessedTableManager get completionRecordsRefs {
    final manager = $$CompletionRecordsTableTableManager(
      $_db,
      $_db.completionRecords,
    ).filter((f) => f.choreId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _completionRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ChoreTagsTable, List<ChoreTagEntity>>
  _choreTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.choreTags,
    aliasName: $_aliasNameGenerator(db.chores.id, db.choreTags.choreId),
  );

  $$ChoreTagsTableProcessedTableManager get choreTagsRefs {
    final manager = $$ChoreTagsTableTableManager(
      $_db,
      $_db.choreTags,
    ).filter((f) => f.choreId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_choreTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ChoresTableFilterComposer
    extends Composer<_$AppDatabase, $ChoresTable> {
  $$ChoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextDueDate => $composableBuilder(
    column: $table.nextDueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RecurrenceType, RecurrenceType, int>
  get recurrence => $composableBuilder(
    column: $table.recurrence,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get recurrenceInterval => $composableBuilder(
    column: $table.recurrenceInterval,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isNotificationEnabled => $composableBuilder(
    column: $table.isNotificationEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> completionRecordsRefs(
    Expression<bool> Function($$CompletionRecordsTableFilterComposer f) f,
  ) {
    final $$CompletionRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.completionRecords,
      getReferencedColumn: (t) => t.choreId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletionRecordsTableFilterComposer(
            $db: $db,
            $table: $db.completionRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> choreTagsRefs(
    Expression<bool> Function($$ChoreTagsTableFilterComposer f) f,
  ) {
    final $$ChoreTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.choreTags,
      getReferencedColumn: (t) => t.choreId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChoreTagsTableFilterComposer(
            $db: $db,
            $table: $db.choreTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChoresTableOrderingComposer
    extends Composer<_$AppDatabase, $ChoresTable> {
  $$ChoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextDueDate => $composableBuilder(
    column: $table.nextDueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recurrence => $composableBuilder(
    column: $table.recurrence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recurrenceInterval => $composableBuilder(
    column: $table.recurrenceInterval,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isNotificationEnabled => $composableBuilder(
    column: $table.isNotificationEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChoresTable> {
  $$ChoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get nextDueDate => $composableBuilder(
    column: $table.nextDueDate,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<RecurrenceType, int> get recurrence =>
      $composableBuilder(
        column: $table.recurrence,
        builder: (column) => column,
      );

  GeneratedColumn<int> get recurrenceInterval => $composableBuilder(
    column: $table.recurrenceInterval,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isNotificationEnabled => $composableBuilder(
    column: $table.isNotificationEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  Expression<T> completionRecordsRefs<T extends Object>(
    Expression<T> Function($$CompletionRecordsTableAnnotationComposer a) f,
  ) {
    final $$CompletionRecordsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.completionRecords,
          getReferencedColumn: (t) => t.choreId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CompletionRecordsTableAnnotationComposer(
                $db: $db,
                $table: $db.completionRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> choreTagsRefs<T extends Object>(
    Expression<T> Function($$ChoreTagsTableAnnotationComposer a) f,
  ) {
    final $$ChoreTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.choreTags,
      getReferencedColumn: (t) => t.choreId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChoreTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.choreTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChoresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChoresTable,
          ChoreEntity,
          $$ChoresTableFilterComposer,
          $$ChoresTableOrderingComposer,
          $$ChoresTableAnnotationComposer,
          $$ChoresTableCreateCompanionBuilder,
          $$ChoresTableUpdateCompanionBuilder,
          (ChoreEntity, $$ChoresTableReferences),
          ChoreEntity,
          PrefetchHooks Function({
            bool completionRecordsRefs,
            bool choreTagsRefs,
          })
        > {
  $$ChoresTableTableManager(_$AppDatabase db, $ChoresTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChoresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime?> nextDueDate = const Value.absent(),
                Value<RecurrenceType> recurrence = const Value.absent(),
                Value<int?> recurrenceInterval = const Value.absent(),
                Value<bool> isNotificationEnabled = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> emoji = const Value.absent(),
              }) => ChoresCompanion(
                id: id,
                name: name,
                isActive: isActive,
                nextDueDate: nextDueDate,
                recurrence: recurrence,
                recurrenceInterval: recurrenceInterval,
                isNotificationEnabled: isNotificationEnabled,
                createdAt: createdAt,
                emoji: emoji,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<bool> isActive = const Value.absent(),
                Value<DateTime?> nextDueDate = const Value.absent(),
                Value<RecurrenceType> recurrence = const Value.absent(),
                Value<int?> recurrenceInterval = const Value.absent(),
                Value<bool> isNotificationEnabled = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> emoji = const Value.absent(),
              }) => ChoresCompanion.insert(
                id: id,
                name: name,
                isActive: isActive,
                nextDueDate: nextDueDate,
                recurrence: recurrence,
                recurrenceInterval: recurrenceInterval,
                isNotificationEnabled: isNotificationEnabled,
                createdAt: createdAt,
                emoji: emoji,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$ChoresTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({completionRecordsRefs = false, choreTagsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (completionRecordsRefs) db.completionRecords,
                    if (choreTagsRefs) db.choreTags,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (completionRecordsRefs)
                        await $_getPrefetchedData<
                          ChoreEntity,
                          $ChoresTable,
                          CompletionRecordEntity
                        >(
                          currentTable: table,
                          referencedTable: $$ChoresTableReferences
                              ._completionRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChoresTableReferences(
                                db,
                                table,
                                p0,
                              ).completionRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.choreId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (choreTagsRefs)
                        await $_getPrefetchedData<
                          ChoreEntity,
                          $ChoresTable,
                          ChoreTagEntity
                        >(
                          currentTable: table,
                          referencedTable: $$ChoresTableReferences
                              ._choreTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChoresTableReferences(
                                db,
                                table,
                                p0,
                              ).choreTagsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.choreId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ChoresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChoresTable,
      ChoreEntity,
      $$ChoresTableFilterComposer,
      $$ChoresTableOrderingComposer,
      $$ChoresTableAnnotationComposer,
      $$ChoresTableCreateCompanionBuilder,
      $$ChoresTableUpdateCompanionBuilder,
      (ChoreEntity, $$ChoresTableReferences),
      ChoreEntity,
      PrefetchHooks Function({bool completionRecordsRefs, bool choreTagsRefs})
    >;
typedef $$CompletionRecordsTableCreateCompanionBuilder =
    CompletionRecordsCompanion Function({
      Value<int> id,
      required int choreId,
      required DateTime completedAt,
      Value<String> note,
    });
typedef $$CompletionRecordsTableUpdateCompanionBuilder =
    CompletionRecordsCompanion Function({
      Value<int> id,
      Value<int> choreId,
      Value<DateTime> completedAt,
      Value<String> note,
    });

final class $$CompletionRecordsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CompletionRecordsTable,
          CompletionRecordEntity
        > {
  $$CompletionRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ChoresTable _choreIdTable(_$AppDatabase db) => db.chores.createAlias(
    $_aliasNameGenerator(db.completionRecords.choreId, db.chores.id),
  );

  $$ChoresTableProcessedTableManager get choreId {
    final $_column = $_itemColumn<int>('chore_id')!;

    final manager = $$ChoresTableTableManager(
      $_db,
      $_db.chores,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_choreIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CompletionRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $CompletionRecordsTable> {
  $$CompletionRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  $$ChoresTableFilterComposer get choreId {
    final $$ChoresTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.choreId,
      referencedTable: $db.chores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChoresTableFilterComposer(
            $db: $db,
            $table: $db.chores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CompletionRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $CompletionRecordsTable> {
  $$CompletionRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  $$ChoresTableOrderingComposer get choreId {
    final $$ChoresTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.choreId,
      referencedTable: $db.chores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChoresTableOrderingComposer(
            $db: $db,
            $table: $db.chores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CompletionRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CompletionRecordsTable> {
  $$CompletionRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$ChoresTableAnnotationComposer get choreId {
    final $$ChoresTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.choreId,
      referencedTable: $db.chores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChoresTableAnnotationComposer(
            $db: $db,
            $table: $db.chores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CompletionRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CompletionRecordsTable,
          CompletionRecordEntity,
          $$CompletionRecordsTableFilterComposer,
          $$CompletionRecordsTableOrderingComposer,
          $$CompletionRecordsTableAnnotationComposer,
          $$CompletionRecordsTableCreateCompanionBuilder,
          $$CompletionRecordsTableUpdateCompanionBuilder,
          (CompletionRecordEntity, $$CompletionRecordsTableReferences),
          CompletionRecordEntity,
          PrefetchHooks Function({bool choreId})
        > {
  $$CompletionRecordsTableTableManager(
    _$AppDatabase db,
    $CompletionRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompletionRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CompletionRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompletionRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> choreId = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<String> note = const Value.absent(),
              }) => CompletionRecordsCompanion(
                id: id,
                choreId: choreId,
                completedAt: completedAt,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int choreId,
                required DateTime completedAt,
                Value<String> note = const Value.absent(),
              }) => CompletionRecordsCompanion.insert(
                id: id,
                choreId: choreId,
                completedAt: completedAt,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CompletionRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({choreId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (choreId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.choreId,
                                referencedTable:
                                    $$CompletionRecordsTableReferences
                                        ._choreIdTable(db),
                                referencedColumn:
                                    $$CompletionRecordsTableReferences
                                        ._choreIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CompletionRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CompletionRecordsTable,
      CompletionRecordEntity,
      $$CompletionRecordsTableFilterComposer,
      $$CompletionRecordsTableOrderingComposer,
      $$CompletionRecordsTableAnnotationComposer,
      $$CompletionRecordsTableCreateCompanionBuilder,
      $$CompletionRecordsTableUpdateCompanionBuilder,
      (CompletionRecordEntity, $$CompletionRecordsTableReferences),
      CompletionRecordEntity,
      PrefetchHooks Function({bool choreId})
    >;
typedef $$TagsTableCreateCompanionBuilder =
    TagsCompanion Function({
      Value<int> id,
      required String name,
      Value<int> colorIndex,
      Value<String?> emoji,
    });
typedef $$TagsTableUpdateCompanionBuilder =
    TagsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> colorIndex,
      Value<String?> emoji,
    });

final class $$TagsTableReferences
    extends BaseReferences<_$AppDatabase, $TagsTable, TagEntity> {
  $$TagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ChoreTagsTable, List<ChoreTagEntity>>
  _choreTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.choreTags,
    aliasName: $_aliasNameGenerator(db.tags.id, db.choreTags.tagId),
  );

  $$ChoreTagsTableProcessedTableManager get choreTagsRefs {
    final manager = $$ChoreTagsTableTableManager(
      $_db,
      $_db.choreTags,
    ).filter((f) => f.tagId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_choreTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorIndex => $composableBuilder(
    column: $table.colorIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> choreTagsRefs(
    Expression<bool> Function($$ChoreTagsTableFilterComposer f) f,
  ) {
    final $$ChoreTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.choreTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChoreTagsTableFilterComposer(
            $db: $db,
            $table: $db.choreTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorIndex => $composableBuilder(
    column: $table.colorIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get colorIndex => $composableBuilder(
    column: $table.colorIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  Expression<T> choreTagsRefs<T extends Object>(
    Expression<T> Function($$ChoreTagsTableAnnotationComposer a) f,
  ) {
    final $$ChoreTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.choreTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChoreTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.choreTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          TagEntity,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (TagEntity, $$TagsTableReferences),
          TagEntity,
          PrefetchHooks Function({bool choreTagsRefs})
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> colorIndex = const Value.absent(),
                Value<String?> emoji = const Value.absent(),
              }) => TagsCompanion(
                id: id,
                name: name,
                colorIndex: colorIndex,
                emoji: emoji,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<int> colorIndex = const Value.absent(),
                Value<String?> emoji = const Value.absent(),
              }) => TagsCompanion.insert(
                id: id,
                name: name,
                colorIndex: colorIndex,
                emoji: emoji,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TagsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({choreTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (choreTagsRefs) db.choreTags],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (choreTagsRefs)
                    await $_getPrefetchedData<
                      TagEntity,
                      $TagsTable,
                      ChoreTagEntity
                    >(
                      currentTable: table,
                      referencedTable: $$TagsTableReferences
                          ._choreTagsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TagsTableReferences(db, table, p0).choreTagsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.tagId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      TagEntity,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (TagEntity, $$TagsTableReferences),
      TagEntity,
      PrefetchHooks Function({bool choreTagsRefs})
    >;
typedef $$ChoreTagsTableCreateCompanionBuilder =
    ChoreTagsCompanion Function({
      required int choreId,
      required int tagId,
      Value<int> rowid,
    });
typedef $$ChoreTagsTableUpdateCompanionBuilder =
    ChoreTagsCompanion Function({
      Value<int> choreId,
      Value<int> tagId,
      Value<int> rowid,
    });

final class $$ChoreTagsTableReferences
    extends BaseReferences<_$AppDatabase, $ChoreTagsTable, ChoreTagEntity> {
  $$ChoreTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ChoresTable _choreIdTable(_$AppDatabase db) => db.chores.createAlias(
    $_aliasNameGenerator(db.choreTags.choreId, db.chores.id),
  );

  $$ChoresTableProcessedTableManager get choreId {
    final $_column = $_itemColumn<int>('chore_id')!;

    final manager = $$ChoresTableTableManager(
      $_db,
      $_db.chores,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_choreIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TagsTable _tagIdTable(_$AppDatabase db) =>
      db.tags.createAlias($_aliasNameGenerator(db.choreTags.tagId, db.tags.id));

  $$TagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<int>('tag_id')!;

    final manager = $$TagsTableTableManager(
      $_db,
      $_db.tags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ChoreTagsTableFilterComposer
    extends Composer<_$AppDatabase, $ChoreTagsTable> {
  $$ChoreTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ChoresTableFilterComposer get choreId {
    final $$ChoresTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.choreId,
      referencedTable: $db.chores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChoresTableFilterComposer(
            $db: $db,
            $table: $db.chores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableFilterComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChoreTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChoreTagsTable> {
  $$ChoreTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ChoresTableOrderingComposer get choreId {
    final $$ChoresTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.choreId,
      referencedTable: $db.chores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChoresTableOrderingComposer(
            $db: $db,
            $table: $db.chores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableOrderingComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChoreTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChoreTagsTable> {
  $$ChoreTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ChoresTableAnnotationComposer get choreId {
    final $$ChoresTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.choreId,
      referencedTable: $db.chores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChoresTableAnnotationComposer(
            $db: $db,
            $table: $db.chores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableAnnotationComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChoreTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChoreTagsTable,
          ChoreTagEntity,
          $$ChoreTagsTableFilterComposer,
          $$ChoreTagsTableOrderingComposer,
          $$ChoreTagsTableAnnotationComposer,
          $$ChoreTagsTableCreateCompanionBuilder,
          $$ChoreTagsTableUpdateCompanionBuilder,
          (ChoreTagEntity, $$ChoreTagsTableReferences),
          ChoreTagEntity,
          PrefetchHooks Function({bool choreId, bool tagId})
        > {
  $$ChoreTagsTableTableManager(_$AppDatabase db, $ChoreTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChoreTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChoreTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChoreTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> choreId = const Value.absent(),
                Value<int> tagId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChoreTagsCompanion(
                choreId: choreId,
                tagId: tagId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int choreId,
                required int tagId,
                Value<int> rowid = const Value.absent(),
              }) => ChoreTagsCompanion.insert(
                choreId: choreId,
                tagId: tagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ChoreTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({choreId = false, tagId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (choreId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.choreId,
                                referencedTable: $$ChoreTagsTableReferences
                                    ._choreIdTable(db),
                                referencedColumn: $$ChoreTagsTableReferences
                                    ._choreIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (tagId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tagId,
                                referencedTable: $$ChoreTagsTableReferences
                                    ._tagIdTable(db),
                                referencedColumn: $$ChoreTagsTableReferences
                                    ._tagIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ChoreTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChoreTagsTable,
      ChoreTagEntity,
      $$ChoreTagsTableFilterComposer,
      $$ChoreTagsTableOrderingComposer,
      $$ChoreTagsTableAnnotationComposer,
      $$ChoreTagsTableCreateCompanionBuilder,
      $$ChoreTagsTableUpdateCompanionBuilder,
      (ChoreTagEntity, $$ChoreTagsTableReferences),
      ChoreTagEntity,
      PrefetchHooks Function({bool choreId, bool tagId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ChoresTableTableManager get chores =>
      $$ChoresTableTableManager(_db, _db.chores);
  $$CompletionRecordsTableTableManager get completionRecords =>
      $$CompletionRecordsTableTableManager(_db, _db.completionRecords);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$ChoreTagsTableTableManager get choreTags =>
      $$ChoreTagsTableTableManager(_db, _db.choreTags);
}
