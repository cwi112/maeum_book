import 'dart:async';
import 'dart:io' show SocketException;
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:maeum_book/core/errors/network_exception.dart';
import 'package:maeum_book/data/database/app_database.dart';
import 'package:maeum_book/data/models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 서버에 있는 한 사람의 장부 전체
class RemoteSnapshot {
  const RemoteSnapshot({required this.types, required this.events, required this.entries});

  final List<EventType> types;
  final List<LedgerEvent> events;
  final List<LedgerEntry> entries;

  bool get isEmpty => types.isEmpty && events.isEmpty && entries.isEmpty;
}

/// 회원 장부의 원본이 있는 서버 DB 창구. (Supabase 표: event_types · events · ledger_entries)
///
/// - 모든 작업은 로그인한 본인 행에만 닿는다. (서버의 RLS 규칙)
/// - 인터넷이 없거나 응답이 늦으면 [NetworkException]을 던진다.
/// - 테스트에서는 메모리에 저장하는 가짜 구현으로 바꿔 끼운다.
abstract interface class RemoteLedgerStore {
  /// 새 행의 id. 여러 기기에서 동시에 만들어도 겹치지 않도록 큰 임의의 수를 쓴다.
  int newId();

  /// 내 장부 전체를 읽는다.
  Future<RemoteSnapshot> fetchAll();

  /// 행을 넣거나 고친다. (같은 id면 덮어씀) 종류 → 행사 → 기록 순서로 보낸다. (서로 참조하므로)
  Future<void> upsert({
    List<EventType> types = const [],
    List<LedgerEvent> events = const [],
    List<LedgerEntry> entries = const [],
  });

  /// 행을 지운다. 기록 → 행사 → 종류 순서로 지운다. (행사를 지우면 안의 기록은 서버가 같이 지움)
  Future<void> delete({List<int> typeIds = const [], List<int> eventIds = const [], List<int> entryIds = const []});

  /// 기록과 행사를 모두 지운다. (경조사 종류는 남김)
  Future<void> clearRecords();
}

/// Supabase로 만든 실제 구현
class SupabaseRemoteLedgerStore implements RemoteLedgerStore {
  SupabaseRemoteLedgerStore(this._client, {Random? random}) : _random = random ?? Random.secure();

  final SupabaseClient _client;
  final Random _random;

  static const _timeout = Duration(seconds: 15);

  /// 기본 종류 id(1~7)와 겹치지 않고, Dart · SQLite · Postgres 모두 정확히 다루는 범위(2^53 미만)의 수
  @override
  int newId() => 1000000 + _random.nextInt(1 << 32) * (1 << 20) + _random.nextInt(1 << 20);

  @override
  Future<RemoteSnapshot> fetchAll() => _run(() async {
    final results = await Future.wait([
      _client.from('event_types').select(),
      _client.from('events').select(),
      _client.from('ledger_entries').select(),
    ]);
    return RemoteSnapshot(
      types: results[0].map(LedgerJson.typeFrom).toList(),
      events: results[1].map(LedgerJson.eventFrom).toList(),
      entries: results[2].map(LedgerJson.entryFrom).toList(),
    );
  });

  @override
  Future<void> upsert({
    List<EventType> types = const [],
    List<LedgerEvent> events = const [],
    List<LedgerEntry> entries = const [],
  }) => _run(() async {
    if (types.isNotEmpty) await _client.from('event_types').upsert(types.map(LedgerJson.typeTo).toList());
    if (events.isNotEmpty) await _client.from('events').upsert(events.map(LedgerJson.eventTo).toList());
    if (entries.isNotEmpty) await _client.from('ledger_entries').upsert(entries.map(LedgerJson.entryTo).toList());
  });

  @override
  Future<void> delete({List<int> typeIds = const [], List<int> eventIds = const [], List<int> entryIds = const []}) =>
      _run(() async {
        if (entryIds.isNotEmpty) await _client.from('ledger_entries').delete().inFilter('id', entryIds);
        if (eventIds.isNotEmpty) await _client.from('events').delete().inFilter('id', eventIds);
        if (typeIds.isNotEmpty) await _client.from('event_types').delete().inFilter('id', typeIds);
      });

  @override
  Future<void> clearRecords() => _run(() async {
    // 지우기 요청에는 조건이 꼭 있어야 해서 "id가 0 이상"(=전부)을 붙인다. 본인 행만 지워지는 건 RLS가 보장한다.
    await _client.from('ledger_entries').delete().gte('id', 0);
    await _client.from('events').delete().gte('id', 0);
  });

  /// 인터넷 문제는 [NetworkException]으로 바꿔서 화면이 알맞은 안내를 띄우게 한다.
  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action().timeout(_timeout);
    } on SocketException catch (e) {
      throw NetworkException(e);
    } on TimeoutException catch (e) {
      throw NetworkException(e);
    } on http.ClientException catch (e) {
      throw NetworkException(e);
    } on AuthRetryableFetchException catch (e) {
      throw NetworkException(e);
    }
  }
}

/// 로컬 DB 행 ↔ 서버 JSON 변환. 서버 열 이름은 snake_case, 날짜는 UTC ISO 문자열.
abstract final class LedgerJson {
  static String _date(DateTime d) => d.toUtc().toIso8601String();
  static DateTime _parse(Object? v) => DateTime.parse(v! as String).toLocal();
  static int _int(Object? v) => (v! as num).toInt();

  static Map<String, Object?> typeTo(EventType t) => {
    'id': t.id,
    'name': t.name,
    'sort_order': t.sortOrder,
    'is_protected': t.isProtected,
  };

  static EventType typeFrom(Map<String, dynamic> j) => EventType(
    id: _int(j['id']),
    name: j['name'] as String,
    sortOrder: _int(j['sort_order']),
    isProtected: j['is_protected'] as bool,
  );

  static Map<String, Object?> eventTo(LedgerEvent e) => {
    'id': e.id,
    'title': e.title,
    'event_type_id': e.eventTypeId,
    'date': _date(e.date),
    'memo': e.memo,
    'created_at': _date(e.createdAt),
  };

  static LedgerEvent eventFrom(Map<String, dynamic> j) => LedgerEvent(
    id: _int(j['id']),
    title: j['title'] as String,
    eventTypeId: _int(j['event_type_id']),
    date: _parse(j['date']),
    memo: j['memo'] as String?,
    createdAt: _parse(j['created_at']),
  );

  static Map<String, Object?> entryTo(LedgerEntry e) => {
    'id': e.id,
    'direction': e.direction.name,
    'event_type_id': e.eventTypeId,
    'event_id': e.eventId,
    'person_name': e.personName,
    'amount': e.amount,
    'date': _date(e.date),
    'relation': e.relation?.name,
    'memo': e.memo,
    'created_at': _date(e.createdAt),
    'updated_at': _date(e.updatedAt),
  };

  static LedgerEntry entryFrom(Map<String, dynamic> j) => LedgerEntry(
    id: _int(j['id']),
    direction: RecordDirection.values.byName(j['direction'] as String),
    eventTypeId: _int(j['event_type_id']),
    eventId: j['event_id'] == null ? null : _int(j['event_id']),
    personName: j['person_name'] as String,
    amount: _int(j['amount']),
    date: _parse(j['date']),
    relation: j['relation'] == null ? null : Relation.values.byName(j['relation'] as String),
    memo: j['memo'] as String?,
    createdAt: _parse(j['created_at']),
    updatedAt: _parse(j['updated_at']),
  );
}
