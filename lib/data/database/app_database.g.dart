// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $EventTypesTable extends EventTypes with TableInfo<$EventTypesTable, EventType> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventTypesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isProtectedMeta = const VerificationMeta('isProtected');
  @override
  late final GeneratedColumn<bool> isProtected = GeneratedColumn<bool>(
    'is_protected',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_protected" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, sortOrder, isProtected];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'event_types';
  @override
  VerificationContext validateIntegrity(Insertable<EventType> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta, sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('is_protected')) {
      context.handle(_isProtectedMeta, isProtected.isAcceptableOrUnknown(data['is_protected']!, _isProtectedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EventType map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventType(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      sortOrder: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      isProtected: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_protected'])!,
    );
  }

  @override
  $EventTypesTable createAlias(String alias) {
    return $EventTypesTable(attachedDatabase, alias);
  }
}

class EventType extends DataClass implements Insertable<EventType> {
  final int id;

  /// 종류 이름. 1~10글자, 같은 이름은 두 번 만들 수 없다(unique).
  final String name;

  /// 보여주는 순서 (작을수록 앞). 새로 추가한 종류는 맨 뒤로 간다.
  final int sortOrder;

  /// 지울 수 없는 종류인지 ("기타")
  final bool isProtected;
  const EventType({required this.id, required this.name, required this.sortOrder, required this.isProtected});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_protected'] = Variable<bool>(isProtected);
    return map;
  }

  EventTypesCompanion toCompanion(bool nullToAbsent) {
    return EventTypesCompanion(
      id: Value(id),
      name: Value(name),
      sortOrder: Value(sortOrder),
      isProtected: Value(isProtected),
    );
  }

  factory EventType.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventType(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isProtected: serializer.fromJson<bool>(json['isProtected']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isProtected': serializer.toJson<bool>(isProtected),
    };
  }

  EventType copyWith({int? id, String? name, int? sortOrder, bool? isProtected}) => EventType(
    id: id ?? this.id,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
    isProtected: isProtected ?? this.isProtected,
  );
  EventType copyWithCompanion(EventTypesCompanion data) {
    return EventType(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isProtected: data.isProtected.present ? data.isProtected.value : this.isProtected,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventType(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isProtected: $isProtected')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, sortOrder, isProtected);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventType &&
          other.id == this.id &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder &&
          other.isProtected == this.isProtected);
}

class EventTypesCompanion extends UpdateCompanion<EventType> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<bool> isProtected;
  const EventTypesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isProtected = const Value.absent(),
  });
  EventTypesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.sortOrder = const Value.absent(),
    this.isProtected = const Value.absent(),
  }) : name = Value(name);
  static Insertable<EventType> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<bool>? isProtected,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isProtected != null) 'is_protected': isProtected,
    });
  }

  EventTypesCompanion copyWith({Value<int>? id, Value<String>? name, Value<int>? sortOrder, Value<bool>? isProtected}) {
    return EventTypesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      isProtected: isProtected ?? this.isProtected,
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
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isProtected.present) {
      map['is_protected'] = Variable<bool>(isProtected.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventTypesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isProtected: $isProtected')
          ..write(')'))
        .toString();
  }
}

class $EventsTable extends Events with TableInfo<$EventsTable, LedgerEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventTypeIdMeta = const VerificationMeta('eventTypeId');
  @override
  late final GeneratedColumn<int> eventTypeId = GeneratedColumn<int>(
    'event_type_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES event_types (id)'),
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
  @override
  List<GeneratedColumn> get $columns => [id, title, eventTypeId, date, memo, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'events';
  @override
  VerificationContext validateIntegrity(Insertable<LedgerEvent> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('event_type_id')) {
      context.handle(_eventTypeIdMeta, eventTypeId.isAcceptableOrUnknown(data['event_type_id']!, _eventTypeIdMeta));
    } else if (isInserting) {
      context.missing(_eventTypeIdMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LedgerEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LedgerEvent(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      eventTypeId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}event_type_id'])!,
      date: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      memo: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}memo']),
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $EventsTable createAlias(String alias) {
    return $EventsTable(attachedDatabase, alias);
  }
}

class LedgerEvent extends DataClass implements Insertable<LedgerEvent> {
  final int id;

  /// 행사 이름 (예: 우리 결혼식, 아버지 칠순)
  final String title;

  /// 경조사 종류. 종류를 지울 때는 Repository에서 먼저 "기타"로 옮기므로 끊어지는 일이 없다.
  final int eventTypeId;

  /// 행사 날짜
  final DateTime date;

  /// 메모 (선택)
  final String? memo;
  final DateTime createdAt;
  const LedgerEvent({
    required this.id,
    required this.title,
    required this.eventTypeId,
    required this.date,
    this.memo,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['event_type_id'] = Variable<int>(eventTypeId);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  EventsCompanion toCompanion(bool nullToAbsent) {
    return EventsCompanion(
      id: Value(id),
      title: Value(title),
      eventTypeId: Value(eventTypeId),
      date: Value(date),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      createdAt: Value(createdAt),
    );
  }

  factory LedgerEvent.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LedgerEvent(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      eventTypeId: serializer.fromJson<int>(json['eventTypeId']),
      date: serializer.fromJson<DateTime>(json['date']),
      memo: serializer.fromJson<String?>(json['memo']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'eventTypeId': serializer.toJson<int>(eventTypeId),
      'date': serializer.toJson<DateTime>(date),
      'memo': serializer.toJson<String?>(memo),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LedgerEvent copyWith({
    int? id,
    String? title,
    int? eventTypeId,
    DateTime? date,
    Value<String?> memo = const Value.absent(),
    DateTime? createdAt,
  }) => LedgerEvent(
    id: id ?? this.id,
    title: title ?? this.title,
    eventTypeId: eventTypeId ?? this.eventTypeId,
    date: date ?? this.date,
    memo: memo.present ? memo.value : this.memo,
    createdAt: createdAt ?? this.createdAt,
  );
  LedgerEvent copyWithCompanion(EventsCompanion data) {
    return LedgerEvent(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      eventTypeId: data.eventTypeId.present ? data.eventTypeId.value : this.eventTypeId,
      date: data.date.present ? data.date.value : this.date,
      memo: data.memo.present ? data.memo.value : this.memo,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LedgerEvent(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('eventTypeId: $eventTypeId, ')
          ..write('date: $date, ')
          ..write('memo: $memo, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, eventTypeId, date, memo, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LedgerEvent &&
          other.id == this.id &&
          other.title == this.title &&
          other.eventTypeId == this.eventTypeId &&
          other.date == this.date &&
          other.memo == this.memo &&
          other.createdAt == this.createdAt);
}

class EventsCompanion extends UpdateCompanion<LedgerEvent> {
  final Value<int> id;
  final Value<String> title;
  final Value<int> eventTypeId;
  final Value<DateTime> date;
  final Value<String?> memo;
  final Value<DateTime> createdAt;
  const EventsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.eventTypeId = const Value.absent(),
    this.date = const Value.absent(),
    this.memo = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  EventsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required int eventTypeId,
    required DateTime date,
    this.memo = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : title = Value(title),
       eventTypeId = Value(eventTypeId),
       date = Value(date);
  static Insertable<LedgerEvent> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<int>? eventTypeId,
    Expression<DateTime>? date,
    Expression<String>? memo,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (eventTypeId != null) 'event_type_id': eventTypeId,
      if (date != null) 'date': date,
      if (memo != null) 'memo': memo,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  EventsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<int>? eventTypeId,
    Value<DateTime>? date,
    Value<String?>? memo,
    Value<DateTime>? createdAt,
  }) {
    return EventsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      eventTypeId: eventTypeId ?? this.eventTypeId,
      date: date ?? this.date,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (eventTypeId.present) {
      map['event_type_id'] = Variable<int>(eventTypeId.value);
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('eventTypeId: $eventTypeId, ')
          ..write('date: $date, ')
          ..write('memo: $memo, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

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
  static const VerificationMeta _eventTypeIdMeta = const VerificationMeta('eventTypeId');
  @override
  late final GeneratedColumn<int> eventTypeId = GeneratedColumn<int>(
    'event_type_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES event_types (id)'),
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta('eventId');
  @override
  late final GeneratedColumn<int> eventId = GeneratedColumn<int>(
    'event_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES events (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _personNameMeta = const VerificationMeta('personName');
  @override
  late final GeneratedColumn<String> personName = GeneratedColumn<String>(
    'person_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
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
  @override
  late final GeneratedColumnWithTypeConverter<Relation?, String> relation = GeneratedColumn<String>(
    'relation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<Relation?>($LedgerEntriesTable.$converterrelationn);
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
    eventTypeId,
    eventId,
    personName,
    amount,
    date,
    relation,
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
    if (data.containsKey('event_type_id')) {
      context.handle(_eventTypeIdMeta, eventTypeId.isAcceptableOrUnknown(data['event_type_id']!, _eventTypeIdMeta));
    } else if (isInserting) {
      context.missing(_eventTypeIdMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(_eventIdMeta, eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta));
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
      eventTypeId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}event_type_id'])!,
      eventId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}event_id']),
      personName: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}person_name'])!,
      amount: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}amount'])!,
      date: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      relation: $LedgerEntriesTable.$converterrelationn.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}relation']),
      ),
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
  static JsonTypeConverter2<Relation, String, String> $converterrelation = const EnumNameConverter<Relation>(
    Relation.values,
  );
  static JsonTypeConverter2<Relation?, String?, String?> $converterrelationn = JsonTypeConverter2.asNullable(
    $converterrelation,
  );
}

class LedgerEntry extends DataClass implements Insertable<LedgerEntry> {
  /// 고유 번호. 1부터 자동으로 1씩 증가한다.
  final int id;

  /// 보냄 / 받음. DB에는 'sent' / 'received' 글자로 저장된다.
  final RecordDirection direction;

  /// 경조사 종류 (event_types 테이블의 id). v3부터 글자 대신 번호로 저장한다.
  final int eventTypeId;

  /// 이 받은 기록이 속한 행사 (받은 기록만, 보낸 기록은 null). v3에서 추가.
  /// 행사를 지우면 안의 기록도 함께 지워진다(cascade).
  final int? eventId;

  /// 상대방 이름. 빈 이름은 저장하지 못하게 1글자 이상, 최대 50글자로 제한한다.
  final String personName;

  /// 금액 (원 단위 정수). 음수는 DB 단계에서 막는다. (SQL의 CHECK 제약 조건)
  ///
  /// 자기 자신(amount)을 참조하는 것은 Drift 공식 문법이라 실제로 재귀 호출되지 않는다. 그래서 경고를 끈다.
  final int amount;

  /// 경조사 날짜 (언제 주고받았는지)
  final DateTime date;

  /// 상대방과의 관계 (선택). 스키마 버전 2에서 추가됐다.
  final Relation? relation;

  /// 메모 (선택). 비워 둘 수 있다.
  final String? memo;

  /// 처음 저장한 시각. 값을 안 넣으면 저장 순간의 시각이 자동으로 들어간다.
  final DateTime createdAt;

  /// 마지막으로 수정한 시각. 수정할 때 Repository에서 갱신한다.
  final DateTime updatedAt;
  const LedgerEntry({
    required this.id,
    required this.direction,
    required this.eventTypeId,
    this.eventId,
    required this.personName,
    required this.amount,
    required this.date,
    this.relation,
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
    map['event_type_id'] = Variable<int>(eventTypeId);
    if (!nullToAbsent || eventId != null) {
      map['event_id'] = Variable<int>(eventId);
    }
    map['person_name'] = Variable<String>(personName);
    map['amount'] = Variable<int>(amount);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || relation != null) {
      map['relation'] = Variable<String>($LedgerEntriesTable.$converterrelationn.toSql(relation));
    }
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
      eventTypeId: Value(eventTypeId),
      eventId: eventId == null && nullToAbsent ? const Value.absent() : Value(eventId),
      personName: Value(personName),
      amount: Value(amount),
      date: Value(date),
      relation: relation == null && nullToAbsent ? const Value.absent() : Value(relation),
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
      eventTypeId: serializer.fromJson<int>(json['eventTypeId']),
      eventId: serializer.fromJson<int?>(json['eventId']),
      personName: serializer.fromJson<String>(json['personName']),
      amount: serializer.fromJson<int>(json['amount']),
      date: serializer.fromJson<DateTime>(json['date']),
      relation: $LedgerEntriesTable.$converterrelationn.fromJson(serializer.fromJson<String?>(json['relation'])),
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
      'eventTypeId': serializer.toJson<int>(eventTypeId),
      'eventId': serializer.toJson<int?>(eventId),
      'personName': serializer.toJson<String>(personName),
      'amount': serializer.toJson<int>(amount),
      'date': serializer.toJson<DateTime>(date),
      'relation': serializer.toJson<String?>($LedgerEntriesTable.$converterrelationn.toJson(relation)),
      'memo': serializer.toJson<String?>(memo),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LedgerEntry copyWith({
    int? id,
    RecordDirection? direction,
    int? eventTypeId,
    Value<int?> eventId = const Value.absent(),
    String? personName,
    int? amount,
    DateTime? date,
    Value<Relation?> relation = const Value.absent(),
    Value<String?> memo = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LedgerEntry(
    id: id ?? this.id,
    direction: direction ?? this.direction,
    eventTypeId: eventTypeId ?? this.eventTypeId,
    eventId: eventId.present ? eventId.value : this.eventId,
    personName: personName ?? this.personName,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    relation: relation.present ? relation.value : this.relation,
    memo: memo.present ? memo.value : this.memo,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LedgerEntry copyWithCompanion(LedgerEntriesCompanion data) {
    return LedgerEntry(
      id: data.id.present ? data.id.value : this.id,
      direction: data.direction.present ? data.direction.value : this.direction,
      eventTypeId: data.eventTypeId.present ? data.eventTypeId.value : this.eventTypeId,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      personName: data.personName.present ? data.personName.value : this.personName,
      amount: data.amount.present ? data.amount.value : this.amount,
      date: data.date.present ? data.date.value : this.date,
      relation: data.relation.present ? data.relation.value : this.relation,
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
          ..write('eventTypeId: $eventTypeId, ')
          ..write('eventId: $eventId, ')
          ..write('personName: $personName, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('relation: $relation, ')
          ..write('memo: $memo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, direction, eventTypeId, eventId, personName, amount, date, relation, memo, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LedgerEntry &&
          other.id == this.id &&
          other.direction == this.direction &&
          other.eventTypeId == this.eventTypeId &&
          other.eventId == this.eventId &&
          other.personName == this.personName &&
          other.amount == this.amount &&
          other.date == this.date &&
          other.relation == this.relation &&
          other.memo == this.memo &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LedgerEntriesCompanion extends UpdateCompanion<LedgerEntry> {
  final Value<int> id;
  final Value<RecordDirection> direction;
  final Value<int> eventTypeId;
  final Value<int?> eventId;
  final Value<String> personName;
  final Value<int> amount;
  final Value<DateTime> date;
  final Value<Relation?> relation;
  final Value<String?> memo;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const LedgerEntriesCompanion({
    this.id = const Value.absent(),
    this.direction = const Value.absent(),
    this.eventTypeId = const Value.absent(),
    this.eventId = const Value.absent(),
    this.personName = const Value.absent(),
    this.amount = const Value.absent(),
    this.date = const Value.absent(),
    this.relation = const Value.absent(),
    this.memo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LedgerEntriesCompanion.insert({
    this.id = const Value.absent(),
    required RecordDirection direction,
    required int eventTypeId,
    this.eventId = const Value.absent(),
    required String personName,
    required int amount,
    required DateTime date,
    this.relation = const Value.absent(),
    this.memo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : direction = Value(direction),
       eventTypeId = Value(eventTypeId),
       personName = Value(personName),
       amount = Value(amount),
       date = Value(date);
  static Insertable<LedgerEntry> custom({
    Expression<int>? id,
    Expression<String>? direction,
    Expression<int>? eventTypeId,
    Expression<int>? eventId,
    Expression<String>? personName,
    Expression<int>? amount,
    Expression<DateTime>? date,
    Expression<String>? relation,
    Expression<String>? memo,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (direction != null) 'direction': direction,
      if (eventTypeId != null) 'event_type_id': eventTypeId,
      if (eventId != null) 'event_id': eventId,
      if (personName != null) 'person_name': personName,
      if (amount != null) 'amount': amount,
      if (date != null) 'date': date,
      if (relation != null) 'relation': relation,
      if (memo != null) 'memo': memo,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LedgerEntriesCompanion copyWith({
    Value<int>? id,
    Value<RecordDirection>? direction,
    Value<int>? eventTypeId,
    Value<int?>? eventId,
    Value<String>? personName,
    Value<int>? amount,
    Value<DateTime>? date,
    Value<Relation?>? relation,
    Value<String?>? memo,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return LedgerEntriesCompanion(
      id: id ?? this.id,
      direction: direction ?? this.direction,
      eventTypeId: eventTypeId ?? this.eventTypeId,
      eventId: eventId ?? this.eventId,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      relation: relation ?? this.relation,
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
    if (eventTypeId.present) {
      map['event_type_id'] = Variable<int>(eventTypeId.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<int>(eventId.value);
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
    if (relation.present) {
      map['relation'] = Variable<String>($LedgerEntriesTable.$converterrelationn.toSql(relation.value));
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
          ..write('eventTypeId: $eventTypeId, ')
          ..write('eventId: $eventId, ')
          ..write('personName: $personName, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('relation: $relation, ')
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
  late final $EventTypesTable eventTypes = $EventTypesTable(this);
  late final $EventsTable events = $EventsTable(this);
  late final $LedgerEntriesTable ledgerEntries = $LedgerEntriesTable(this);
  late final Index idxLedgerEntriesDirectionDate = Index(
    'idx_ledger_entries_direction_date',
    'CREATE INDEX idx_ledger_entries_direction_date ON ledger_entries (direction, date)',
  );
  late final LedgerDao ledgerDao = LedgerDao(this as AppDatabase);
  late final EventTypeDao eventTypeDao = EventTypeDao(this as AppDatabase);
  late final EventDao eventDao = EventDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    eventTypes,
    events,
    ledgerEntries,
    idxLedgerEntriesDirectionDate,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName('events', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('ledger_entries', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$EventTypesTableCreateCompanionBuilder = EventTypesCompanion Function({
  Value<int> id,
  required String name,
  Value<int> sortOrder,
  Value<bool> isProtected,
});
typedef $$EventTypesTableUpdateCompanionBuilder = EventTypesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> sortOrder,
  Value<bool> isProtected,
});

final class $$EventTypesTableReferences extends BaseReferences<_$AppDatabase, $EventTypesTable, EventType> {
  $$EventTypesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$EventsTable, List<LedgerEvent>> _eventsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.events, aliasName: 'event_types__id__events__event_type_id');

  $$EventsTableProcessedTableManager get eventsRefs {
    final manager = $$EventsTableTableManager(
      $_db,
      $_db.events,
    ).filter((f) => f.eventTypeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_eventsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$LedgerEntriesTable, List<LedgerEntry>> _ledgerEntriesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.ledgerEntries, aliasName: 'event_types__id__ledger_entries__event_type_id');

  $$LedgerEntriesTableProcessedTableManager get ledgerEntriesRefs {
    final manager = $$LedgerEntriesTableTableManager(
      $_db,
      $_db.ledgerEntries,
    ).filter((f) => f.eventTypeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_ledgerEntriesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$EventTypesTableFilterComposer extends Composer<_$AppDatabase, $EventTypesTable> {
  $$EventTypesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isProtected =>
      $composableBuilder(column: $table.isProtected, builder: (column) => ColumnFilters(column));

  Expression<bool> eventsRefs(Expression<bool> Function($$EventsTableFilterComposer f) f) {
    final $$EventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.eventTypeId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EventsTableFilterComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ledgerEntriesRefs(Expression<bool> Function($$LedgerEntriesTableFilterComposer f) f) {
    final $$LedgerEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.eventTypeId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LedgerEntriesTableFilterComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EventTypesTableOrderingComposer extends Composer<_$AppDatabase, $EventTypesTable> {
  $$EventTypesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isProtected =>
      $composableBuilder(column: $table.isProtected, builder: (column) => ColumnOrderings(column));
}

class $$EventTypesTableAnnotationComposer extends Composer<_$AppDatabase, $EventTypesTable> {
  $$EventTypesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isProtected => $composableBuilder(column: $table.isProtected, builder: (column) => column);

  Expression<T> eventsRefs<T extends Object>(Expression<T> Function($$EventsTableAnnotationComposer a) f) {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.eventTypeId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EventsTableAnnotationComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> ledgerEntriesRefs<T extends Object>(
    Expression<T> Function($$LedgerEntriesTableAnnotationComposer a) f,
  ) {
    final $$LedgerEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.eventTypeId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LedgerEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EventTypesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventTypesTable,
          EventType,
          $$EventTypesTableFilterComposer,
          $$EventTypesTableOrderingComposer,
          $$EventTypesTableAnnotationComposer,
          $$EventTypesTableCreateCompanionBuilder,
          $$EventTypesTableUpdateCompanionBuilder,
          (EventType, $$EventTypesTableReferences),
          EventType,
          PrefetchHooks Function({bool eventsRefs, bool ledgerEntriesRefs})
        > {
  $$EventTypesTableTableManager(_$AppDatabase db, $EventTypesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$EventTypesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$EventTypesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$EventTypesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<bool> isProtected = const Value.absent(),
          }) => EventTypesCompanion(id: id, name: name, sortOrder: sortOrder, isProtected: isProtected),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<int> sortOrder = const Value.absent(),
            Value<bool> isProtected = const Value.absent(),
          }) => EventTypesCompanion.insert(id: id, name: name, sortOrder: sortOrder, isProtected: isProtected),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$EventTypesTable, EventType>(table), $$EventTypesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({eventsRefs = false, ledgerEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (eventsRefs) db.events, if (ledgerEntriesRefs) db.ledgerEntries],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (eventsRefs)
                    await $_getPrefetchedDataByColumns<EventType, $EventTypesTable, LedgerEvent, $EventsTable>(
                      currentTable: table,
                      referencedTable: $$EventTypesTableReferences._eventsRefsTable(db),
                      managerFromTypedResult: (p0) => $$EventTypesTableReferences(db, table, p0).eventsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'event_type_id',
                      typedResults: items,
                    ),
                  if (ledgerEntriesRefs)
                    await $_getPrefetchedDataByColumns<EventType, $EventTypesTable, LedgerEntry, $LedgerEntriesTable>(
                      currentTable: table,
                      referencedTable: $$EventTypesTableReferences._ledgerEntriesRefsTable(db),
                      managerFromTypedResult: (p0) => $$EventTypesTableReferences(db, table, p0).ledgerEntriesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'event_type_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$EventTypesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventTypesTable,
      EventType,
      $$EventTypesTableFilterComposer,
      $$EventTypesTableOrderingComposer,
      $$EventTypesTableAnnotationComposer,
      $$EventTypesTableCreateCompanionBuilder,
      $$EventTypesTableUpdateCompanionBuilder,
      (EventType, $$EventTypesTableReferences),
      EventType,
      PrefetchHooks Function({bool eventsRefs, bool ledgerEntriesRefs})
    >;
typedef $$EventsTableCreateCompanionBuilder = EventsCompanion Function({
  Value<int> id,
  required String title,
  required int eventTypeId,
  required DateTime date,
  Value<String?> memo,
  Value<DateTime> createdAt,
});
typedef $$EventsTableUpdateCompanionBuilder = EventsCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<int> eventTypeId,
  Value<DateTime> date,
  Value<String?> memo,
  Value<DateTime> createdAt,
});

final class $$EventsTableReferences extends BaseReferences<_$AppDatabase, $EventsTable, LedgerEvent> {
  $$EventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EventTypesTable _eventTypeIdTable(_$AppDatabase db) =>
      db.eventTypes.createAlias('events__event_type_id__event_types__id');

  $$EventTypesTableProcessedTableManager get eventTypeId {
    final $_column = $_itemColumn<int>('event_type_id')!;

    final manager = $$EventTypesTableTableManager($_db, $_db.eventTypes).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventTypeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$LedgerEntriesTable, List<LedgerEntry>> _ledgerEntriesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.ledgerEntries, aliasName: 'events__id__ledger_entries__event_id');

  $$LedgerEntriesTableProcessedTableManager get ledgerEntriesRefs {
    final manager = $$LedgerEntriesTableTableManager(
      $_db,
      $_db.ledgerEntries,
    ).filter((f) => f.eventId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_ledgerEntriesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$EventsTableFilterComposer extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memo => $composableBuilder(column: $table.memo, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$EventTypesTableFilterComposer get eventTypeId {
    final $$EventTypesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventTypeId,
      referencedTable: $db.eventTypes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EventTypesTableFilterComposer(
            $db: $db,
            $table: $db.eventTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> ledgerEntriesRefs(Expression<bool> Function($$LedgerEntriesTableFilterComposer f) f) {
    final $$LedgerEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.eventId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LedgerEntriesTableFilterComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EventsTableOrderingComposer extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$EventTypesTableOrderingComposer get eventTypeId {
    final $$EventTypesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventTypeId,
      referencedTable: $db.eventTypes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EventTypesTableOrderingComposer(
            $db: $db,
            $table: $db.eventTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EventsTableAnnotationComposer extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get date => $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get memo => $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$EventTypesTableAnnotationComposer get eventTypeId {
    final $$EventTypesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventTypeId,
      referencedTable: $db.eventTypes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EventTypesTableAnnotationComposer(
            $db: $db,
            $table: $db.eventTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> ledgerEntriesRefs<T extends Object>(
    Expression<T> Function($$LedgerEntriesTableAnnotationComposer a) f,
  ) {
    final $$LedgerEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.eventId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LedgerEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventsTable,
          LedgerEvent,
          $$EventsTableFilterComposer,
          $$EventsTableOrderingComposer,
          $$EventsTableAnnotationComposer,
          $$EventsTableCreateCompanionBuilder,
          $$EventsTableUpdateCompanionBuilder,
          (LedgerEvent, $$EventsTableReferences),
          LedgerEvent,
          PrefetchHooks Function({bool eventTypeId, bool ledgerEntriesRefs})
        > {
  $$EventsTableTableManager(_$AppDatabase db, $EventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$EventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$EventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$EventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> eventTypeId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => EventsCompanion(
                id: id,
                title: title,
                eventTypeId: eventTypeId,
                date: date,
                memo: memo,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required int eventTypeId,
                required DateTime date,
                Value<String?> memo = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => EventsCompanion.insert(
                id: id,
                title: title,
                eventTypeId: eventTypeId,
                date: date,
                memo: memo,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$EventsTable, LedgerEvent>(table), $$EventsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({eventTypeId = false, ledgerEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (ledgerEntriesRefs) db.ledgerEntries],
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
                    if (eventTypeId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.eventTypeId,
                        referencedTable: $$EventsTableReferences._eventTypeIdTable(db),
                        referencedColumn: $$EventsTableReferences._eventTypeIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (ledgerEntriesRefs)
                    await $_getPrefetchedDataByColumns<LedgerEvent, $EventsTable, LedgerEntry, $LedgerEntriesTable>(
                      currentTable: table,
                      referencedTable: $$EventsTableReferences._ledgerEntriesRefsTable(db),
                      managerFromTypedResult: (p0) => $$EventsTableReferences(db, table, p0).ledgerEntriesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'event_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$EventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventsTable,
      LedgerEvent,
      $$EventsTableFilterComposer,
      $$EventsTableOrderingComposer,
      $$EventsTableAnnotationComposer,
      $$EventsTableCreateCompanionBuilder,
      $$EventsTableUpdateCompanionBuilder,
      (LedgerEvent, $$EventsTableReferences),
      LedgerEvent,
      PrefetchHooks Function({bool eventTypeId, bool ledgerEntriesRefs})
    >;
typedef $$LedgerEntriesTableCreateCompanionBuilder = LedgerEntriesCompanion Function({
  Value<int> id,
  required RecordDirection direction,
  required int eventTypeId,
  Value<int?> eventId,
  required String personName,
  required int amount,
  required DateTime date,
  Value<Relation?> relation,
  Value<String?> memo,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$LedgerEntriesTableUpdateCompanionBuilder = LedgerEntriesCompanion Function({
  Value<int> id,
  Value<RecordDirection> direction,
  Value<int> eventTypeId,
  Value<int?> eventId,
  Value<String> personName,
  Value<int> amount,
  Value<DateTime> date,
  Value<Relation?> relation,
  Value<String?> memo,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$LedgerEntriesTableReferences extends BaseReferences<_$AppDatabase, $LedgerEntriesTable, LedgerEntry> {
  $$LedgerEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EventTypesTable _eventTypeIdTable(_$AppDatabase db) =>
      db.eventTypes.createAlias('ledger_entries__event_type_id__event_types__id');

  $$EventTypesTableProcessedTableManager get eventTypeId {
    final $_column = $_itemColumn<int>('event_type_id')!;

    final manager = $$EventTypesTableTableManager($_db, $_db.eventTypes).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventTypeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $EventsTable _eventIdTable(_$AppDatabase db) => db.events.createAlias('ledger_entries__event_id__events__id');

  $$EventsTableProcessedTableManager? get eventId {
    final $_column = $_itemColumn<int>('event_id');
    if ($_column == null) return null;
    final manager = $$EventsTableTableManager($_db, $_db.events).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

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

  ColumnFilters<String> get personName =>
      $composableBuilder(column: $table.personName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Relation?, Relation, String> get relation =>
      $composableBuilder(column: $table.relation, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get memo => $composableBuilder(column: $table.memo, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$EventTypesTableFilterComposer get eventTypeId {
    final $$EventTypesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventTypeId,
      referencedTable: $db.eventTypes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EventTypesTableFilterComposer(
            $db: $db,
            $table: $db.eventTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventsTableFilterComposer get eventId {
    final $$EventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EventsTableFilterComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  ColumnOrderings<String> get personName =>
      $composableBuilder(column: $table.personName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get relation =>
      $composableBuilder(column: $table.relation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$EventTypesTableOrderingComposer get eventTypeId {
    final $$EventTypesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventTypeId,
      referencedTable: $db.eventTypes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EventTypesTableOrderingComposer(
            $db: $db,
            $table: $db.eventTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventsTableOrderingComposer get eventId {
    final $$EventsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EventsTableOrderingComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  GeneratedColumn<String> get personName => $composableBuilder(column: $table.personName, builder: (column) => column);

  GeneratedColumn<int> get amount => $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get date => $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Relation?, String> get relation =>
      $composableBuilder(column: $table.relation, builder: (column) => column);

  GeneratedColumn<String> get memo => $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$EventTypesTableAnnotationComposer get eventTypeId {
    final $$EventTypesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventTypeId,
      referencedTable: $db.eventTypes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EventTypesTableAnnotationComposer(
            $db: $db,
            $table: $db.eventTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventsTableAnnotationComposer get eventId {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EventsTableAnnotationComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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
          (LedgerEntry, $$LedgerEntriesTableReferences),
          LedgerEntry,
          PrefetchHooks Function({bool eventTypeId, bool eventId})
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
                Value<int> eventTypeId = const Value.absent(),
                Value<int?> eventId = const Value.absent(),
                Value<String> personName = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<Relation?> relation = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LedgerEntriesCompanion(
                id: id,
                direction: direction,
                eventTypeId: eventTypeId,
                eventId: eventId,
                personName: personName,
                amount: amount,
                date: date,
                relation: relation,
                memo: memo,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required RecordDirection direction,
                required int eventTypeId,
                Value<int?> eventId = const Value.absent(),
                required String personName,
                required int amount,
                required DateTime date,
                Value<Relation?> relation = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LedgerEntriesCompanion.insert(
                id: id,
                direction: direction,
                eventTypeId: eventTypeId,
                eventId: eventId,
                personName: personName,
                amount: amount,
                date: date,
                relation: relation,
                memo: memo,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LedgerEntriesTable, LedgerEntry>(table),
                  $$LedgerEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({eventTypeId = false, eventId = false}) {
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
                    if (eventTypeId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.eventTypeId,
                        referencedTable: $$LedgerEntriesTableReferences._eventTypeIdTable(db),
                        referencedColumn: $$LedgerEntriesTableReferences._eventTypeIdTable(db).id,
                      ) as T;
                    }
                    if (eventId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.eventId,
                        referencedTable: $$LedgerEntriesTableReferences._eventIdTable(db),
                        referencedColumn: $$LedgerEntriesTableReferences._eventIdTable(db).id,
                      ) as T;
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
      (LedgerEntry, $$LedgerEntriesTableReferences),
      LedgerEntry,
      PrefetchHooks Function({bool eventTypeId, bool eventId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$EventTypesTableTableManager get eventTypes => $$EventTypesTableTableManager(_db, _db.eventTypes);
  $$EventsTableTableManager get events => $$EventsTableTableManager(_db, _db.events);
  $$LedgerEntriesTableTableManager get ledgerEntries => $$LedgerEntriesTableTableManager(_db, _db.ledgerEntries);
}
