// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LedgerEntriesTable extends LedgerEntries with TableInfo<$LedgerEntriesTable, LedgerEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LedgerEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<RecordDirection, String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<RecordDirection>($LedgerEntriesTable.$converterdirection);
  @override
  late final GeneratedColumnWithTypeConverter<EventType, String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<EventType>($LedgerEntriesTable.$convertereventType);
  static const VerificationMeta _personNameMeta = const VerificationMeta('personName');
  @override
  late final GeneratedColumn<String> personName = GeneratedColumn<String>(
    'person_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 50),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    check: () => ComparableExpr(amount).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    direction,
    eventType,
    personName,
    amount,
    date,
    memo,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ledger_entries';
  @override
  VerificationContext validateIntegrity(Insertable<LedgerEntry> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('person_name')) {
      context.handle(_personNameMeta, personName.isAcceptableOrUnknown(data['person_name']!, _personNameMeta));
    } else if (isInserting) {
      context.missing(_personNameMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta, amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('date')) {
      context.handle(_dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('memo')) {
      context.handle(_memoMeta, memo.isAcceptableOrUnknown(data['memo']!, _memoMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LedgerEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LedgerEntry(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      direction: $LedgerEntriesTable.$converterdirection.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}direction'])!,
      ),
      eventType: $LedgerEntriesTable.$convertereventType.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}event_type'])!,
      ),
      personName: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}person_name'])!,
      amount: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}amount'])!,
      date: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      memo: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}memo']),
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $LedgerEntriesTable createAlias(String alias) {
    return $LedgerEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<RecordDirection, String, String> $converterdirection =
      const EnumNameConverter<RecordDirection>(RecordDirection.values);
  static JsonTypeConverter2<EventType, String, String> $convertereventType = const EnumNameConverter<EventType>(
    EventType.values,
  );
}

class LedgerEntry extends DataClass implements Insertable<LedgerEntry> {
  /// 고유 번호. 1부터 자동으로 1씩 증가한다.
  final int id;

  /// 보냄 / 받음. DB에는 'sent' / 'received' 글자로 저장된다.
  final RecordDirection direction;

  /// 경조사 종류 (결혼, 조의 등)
  final EventType eventType;

  /// 상대방 이름. 빈 이름은 저장하지 못하게 1글자 이상, 최대 50글자로 제한한다.
  final String personName;

  /// 금액 (원 단위 정수). 음수는 DB 단계에서 막는다. (SQL의 CHECK 제약 조건)
  ///
  /// 자기 자신(amount)을 참조하는 것은 Drift 공식 문법이라 실제로 재귀 호출되지 않는다. 그래서 경고를 끈다.
  final int amount;

  /// 경조사 날짜 (언제 주고받았는지)
  final DateTime date;

  /// 메모 (선택). 비워 둘 수 있다.
  final String? memo;

  /// 처음 저장한 시각. 값을 안 넣으면 저장 순간의 시각이 자동으로 들어간다.
  final DateTime createdAt;

  /// 마지막으로 수정한 시각. 수정할 때 Repository에서 갱신한다.
  final DateTime updatedAt;
  const LedgerEntry({
    required this.id,
    required this.direction,
    required this.eventType,
    required this.personName,
    required this.amount,
    required this.date,
    this.memo,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['direction'] = Variable<String>($LedgerEntriesTable.$converterdirection.toSql(direction));
    }
    {
      map['event_type'] = Variable<String>($LedgerEntriesTable.$convertereventType.toSql(eventType));
    }
    map['person_name'] = Variable<String>(personName);
    map['amount'] = Variable<int>(amount);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LedgerEntriesCompanion toCompanion(bool nullToAbsent) {
    return LedgerEntriesCompanion(
      id: Value(id),
      direction: Value(direction),
      eventType: Value(eventType),
      personName: Value(personName),
      amount: Value(amount),
      date: Value(date),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LedgerEntry.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LedgerEntry(
      id: serializer.fromJson<int>(json['id']),
      direction: $LedgerEntriesTable.$converterdirection.fromJson(serializer.fromJson<String>(json['direction'])),
      eventType: $LedgerEntriesTable.$convertereventType.fromJson(serializer.fromJson<String>(json['eventType'])),
      personName: serializer.fromJson<String>(json['personName']),
      amount: serializer.fromJson<int>(json['amount']),
      date: serializer.fromJson<DateTime>(json['date']),
      memo: serializer.fromJson<String?>(json['memo']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'direction': serializer.toJson<String>($LedgerEntriesTable.$converterdirection.toJson(direction)),
      'eventType': serializer.toJson<String>($LedgerEntriesTable.$convertereventType.toJson(eventType)),
      'personName': serializer.toJson<String>(personName),
      'amount': serializer.toJson<int>(amount),
      'date': serializer.toJson<DateTime>(date),
      'memo': serializer.toJson<String?>(memo),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LedgerEntry copyWith({
    int? id,
    RecordDirection? direction,
    EventType? eventType,
    String? personName,
    int? amount,
    DateTime? date,
    Value<String?> memo = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LedgerEntry(
    id: id ?? this.id,
    direction: direction ?? this.direction,
    eventType: eventType ?? this.eventType,
    personName: personName ?? this.personName,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    memo: memo.present ? memo.value : this.memo,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LedgerEntry copyWithCompanion(LedgerEntriesCompanion data) {
    return LedgerEntry(
      id: data.id.present ? data.id.value : this.id,
      direction: data.direction.present ? data.direction.value : this.direction,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      personName: data.personName.present ? data.personName.value : this.personName,
      amount: data.amount.present ? data.amount.value : this.amount,
      date: data.date.present ? data.date.value : this.date,
      memo: data.memo.present ? data.memo.value : this.memo,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LedgerEntry(')
          ..write('id: $id, ')
          ..write('direction: $direction, ')
          ..write('eventType: $eventType, ')
          ..write('personName: $personName, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('memo: $memo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, direction, eventType, personName, amount, date, memo, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LedgerEntry &&
          other.id == this.id &&
          other.direction == this.direction &&
          other.eventType == this.eventType &&
          other.personName == this.personName &&
          other.amount == this.amount &&
          other.date == this.date &&
          other.memo == this.memo &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LedgerEntriesCompanion extends UpdateCompanion<LedgerEntry> {
  final Value<int> id;
  final Value<RecordDirection> direction;
  final Value<EventType> eventType;
  final Value<String> personName;
  final Value<int> amount;
  final Value<DateTime> date;
  final Value<String?> memo;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const LedgerEntriesCompanion({
    this.id = const Value.absent(),
    this.direction = const Value.absent(),
    this.eventType = const Value.absent(),
    this.personName = const Value.absent(),
    this.amount = const Value.absent(),
    this.date = const Value.absent(),
    this.memo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LedgerEntriesCompanion.insert({
    this.id = const Value.absent(),
    required RecordDirection direction,
    required EventType eventType,
    required String personName,
    required int amount,
    required DateTime date,
    this.memo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : direction = Value(direction),
       eventType = Value(eventType),
       personName = Value(personName),
       amount = Value(amount),
       date = Value(date);
  static Insertable<LedgerEntry> custom({
    Expression<int>? id,
    Expression<String>? direction,
    Expression<String>? eventType,
    Expression<String>? personName,
    Expression<int>? amount,
    Expression<DateTime>? date,
    Expression<String>? memo,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (direction != null) 'direction': direction,
      if (eventType != null) 'event_type': eventType,
      if (personName != null) 'person_name': personName,
      if (amount != null) 'amount': amount,
      if (date != null) 'date': date,
      if (memo != null) 'memo': memo,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LedgerEntriesCompanion copyWith({
    Value<int>? id,
    Value<RecordDirection>? direction,
    Value<EventType>? eventType,
    Value<String>? personName,
    Value<int>? amount,
    Value<DateTime>? date,
    Value<String?>? memo,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return LedgerEntriesCompanion(
      id: id ?? this.id,
      direction: direction ?? this.direction,
      eventType: eventType ?? this.eventType,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>($LedgerEntriesTable.$converterdirection.toSql(direction.value));
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>($LedgerEntriesTable.$convertereventType.toSql(eventType.value));
    }
    if (personName.present) {
      map['person_name'] = Variable<String>(personName.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LedgerEntriesCompanion(')
          ..write('id: $id, ')
          ..write('direction: $direction, ')
          ..write('eventType: $eventType, ')
          ..write('personName: $personName, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('memo: $memo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LedgerEntriesTable ledgerEntries = $LedgerEntriesTable(this);
  late final Index idxLedgerEntriesDirectionDate = Index(
    'idx_ledger_entries_direction_date',
    'CREATE INDEX idx_ledger_entries_direction_date ON ledger_entries (direction, date)',
  );
  late final LedgerDao ledgerDao = LedgerDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [ledgerEntries, idxLedgerEntriesDirectionDate];
}

typedef $$LedgerEntriesTableCreateCompanionBuilder = LedgerEntriesCompanion Function({
  Value<int> id,
  required RecordDirection direction,
  required EventType eventType,
  required String personName,
  required int amount,
  required DateTime date,
  Value<String?> memo,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$LedgerEntriesTableUpdateCompanionBuilder = LedgerEntriesCompanion Function({
  Value<int> id,
  Value<RecordDirection> direction,
  Value<EventType> eventType,
  Value<String> personName,
  Value<int> amount,
  Value<DateTime> date,
  Value<String?> memo,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$LedgerEntriesTableFilterComposer extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<RecordDirection, RecordDirection, String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<EventType, EventType, String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get personName =>
      $composableBuilder(column: $table.personName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memo => $composableBuilder(column: $table.memo, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$LedgerEntriesTableOrderingComposer extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get personName =>
      $composableBuilder(column: $table.personName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$LedgerEntriesTableAnnotationComposer extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RecordDirection, String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumnWithTypeConverter<EventType, String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<String> get personName => $composableBuilder(column: $table.personName, builder: (column) => column);

  GeneratedColumn<int> get amount => $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get date => $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get memo => $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LedgerEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LedgerEntriesTable,
          LedgerEntry,
          $$LedgerEntriesTableFilterComposer,
          $$LedgerEntriesTableOrderingComposer,
          $$LedgerEntriesTableAnnotationComposer,
          $$LedgerEntriesTableCreateCompanionBuilder,
          $$LedgerEntriesTableUpdateCompanionBuilder,
          (LedgerEntry, BaseReferences<_$AppDatabase, $LedgerEntriesTable, LedgerEntry>),
          LedgerEntry,
          PrefetchHooks Function()
        > {
  $$LedgerEntriesTableTableManager(_$AppDatabase db, $LedgerEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$LedgerEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$LedgerEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$LedgerEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<RecordDirection> direction = const Value.absent(),
                Value<EventType> eventType = const Value.absent(),
                Value<String> personName = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LedgerEntriesCompanion(
                id: id,
                direction: direction,
                eventType: eventType,
                personName: personName,
                amount: amount,
                date: date,
                memo: memo,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required RecordDirection direction,
                required EventType eventType,
                required String personName,
                required int amount,
                required DateTime date,
                Value<String?> memo = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LedgerEntriesCompanion.insert(
                id: id,
                direction: direction,
                eventType: eventType,
                personName: personName,
                amount: amount,
                date: date,
                memo: memo,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LedgerEntriesTable, LedgerEntry>(table),
                  BaseReferences<_$AppDatabase, $LedgerEntriesTable, LedgerEntry>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LedgerEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LedgerEntriesTable,
      LedgerEntry,
      $$LedgerEntriesTableFilterComposer,
      $$LedgerEntriesTableOrderingComposer,
      $$LedgerEntriesTableAnnotationComposer,
      $$LedgerEntriesTableCreateCompanionBuilder,
      $$LedgerEntriesTableUpdateCompanionBuilder,
      (LedgerEntry, BaseReferences<_$AppDatabase, $LedgerEntriesTable, LedgerEntry>),
      LedgerEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LedgerEntriesTableTableManager get ledgerEntries => $$LedgerEntriesTableTableManager(_db, _db.ledgerEntries);
}
