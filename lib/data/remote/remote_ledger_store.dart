import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show SocketException;
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:maeum_book/core/errors/network_exception.dart';
import 'package:maeum_book/data/database/app_database.dart';
import 'package:maeum_book/data/models/models.dart';
import 'package:maeum_book/data/remote/timeout_http_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 서버에 있는 한 사람의 장부 전체
class RemoteSnapshot {
  const RemoteSnapshot({required this.types, required this.events, required this.entries, this.photos = const []});

  final List<EventType> types;
  final List<LedgerEvent> events;
  final List<LedgerEntry> entries;

  /// 행사 사진 정보 (사진 파일은 Storage에 따로 있다)
  final List<EventPhoto> photos;

  bool get isEmpty => types.isEmpty && events.isEmpty && entries.isEmpty;
}

/// 회원 장부의 원본이 있는 서버 창구.
///
/// - 표(DB): event_types · events · ledger_entries · event_photos
/// - 파일(Storage): 비공개 버킷 `event-photos`의 `<사용자 id>/<사진 id>.jpg` · `<사진 id>_thumb.jpg`
/// - 모든 작업은 로그인한 본인 행 · 본인 폴더에만 닿는다. (서버의 RLS 규칙)
/// - 인터넷이 없거나 응답이 늦으면 [NetworkException]을 던진다.
/// - 테스트에서는 메모리에 저장하는 가짜 구현으로 바꿔 끼운다.
abstract interface class RemoteLedgerStore {
  /// 새 행의 id. 여러 기기에서 동시에 만들어도 겹치지 않도록 큰 임의의 수를 쓴다.
  int newId();

  /// 내 장부 전체를 읽는다.
  Future<RemoteSnapshot> fetchAll();

  /// 행을 넣거나 고친다. (같은 id면 덮어씀) 종류 → 행사 → 기록 → 사진 순서로 보낸다. (서로 참조하므로)
  Future<void> upsert({
    List<EventType> types = const [],
    List<LedgerEvent> events = const [],
    List<LedgerEntry> entries = const [],
    List<EventPhoto> photos = const [],
  });

  /// 행을 지운다. 사진 → 기록 → 행사 → 종류 순서로 지운다. (행사를 지우면 안의 기록 · 사진 정보는 서버가 같이 지움)
  /// 사진 **파일**은 지우지 않는다. → [deletePhotoFiles]
  Future<void> delete({
    List<int> typeIds = const [],
    List<int> eventIds = const [],
    List<int> entryIds = const [],
    List<int> photoIds = const [],
  });

  /// 기록 · 행사 · 사진을 모두 지운다. (경조사 종류는 남김) 사진 파일도 지운다.
  Future<void> clearRecords();

  /// 사진 파일(원본 + 작은 사진)을 올린다. 같은 id면 덮어쓴다.
  Future<void> uploadPhoto(int photoId, {required Uint8List image, required Uint8List thumb});

  /// 사진 파일을 받는다. [thumb]이면 목록용 작은 사진.
  Future<Uint8List> downloadPhoto(int photoId, {required bool thumb});

  /// 사진 파일들을 지운다.
  Future<void> deletePhotoFiles(List<int> photoIds);

  /// 내 사진 파일을 모두 지운다. (모든 기록 지우기 · 회원 탈퇴 전에)
  Future<void> deleteAllPhotoFiles();

  /// 사진 정보가 없는 파일(주인 없는 파일)을 지우고 지운 수를 돌려준다. [keep]: 남길 사진 번호
  ///
  /// 사진 파일을 올린 직후 정보를 올리기 전에 앱이 꺼지면 파일만 남아 저장 공간을 차지한다.
  /// 다른 기기에서 지금 막 올리는 중인 사진을 지우지 않도록, 만든 지 [minAge]가 지난 파일만 지운다.
  Future<int> deleteOrphanPhotoFiles(Set<int> keep, {Duration minAge = const Duration(hours: 1)});
}

/// Supabase로 만든 실제 구현
class SupabaseRemoteLedgerStore implements RemoteLedgerStore {
  SupabaseRemoteLedgerStore(this._client, {Random? random}) : _random = random ?? Random.secure();

  final SupabaseClient _client;
  final Random _random;

  /// 요청 자체는 TimeoutHttpClient가 시간이 되면 끊는다. 여기 시간은 그보다 조금 긴 "마지막 안전장치"다.
  static final _timeout = AppTimeouts.data + const Duration(seconds: 5);

  /// 사진 파일은 크기가 있어서 더 기다린다. (원본 · 작은 사진 두 번 보내므로 두 배)
  static final _fileTimeout = AppTimeouts.file * 2 + const Duration(seconds: 5);

  static const photoBucket = 'event-photos';

  StorageFileApi get _bucket => _client.storage.from(photoBucket);

  /// 내 폴더 = 사용자 id. (Storage 권한이 "폴더 첫 칸이 내 id"일 때만 허락한다)
  String get _folder => _client.auth.currentUser?.id ?? (throw StateError('로그인이 필요해요'));

  String _path(int photoId, {required bool thumb}) => '$_folder/$photoId${thumb ? '_thumb' : ''}.jpg';

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
      photos: await _fetchPhotos(),
    );
  });

  /// 사진 정보. 서버에 사진 표를 아직 안 만들었으면(SQL 적용 전) 빈 목록으로 본다. (장부 받기는 막지 않게)
  Future<List<EventPhoto>> _fetchPhotos() async {
    try {
      final rows = await _client.from('event_photos').select();
      return rows.map(LedgerJson.photoFrom).toList();
    } on PostgrestException catch (e) {
      developer.log('event_photos 표를 읽지 못했어요: ${e.message}', name: 'RemoteLedgerStore');
      return const [];
    }
  }

  @override
  Future<void> upsert({
    List<EventType> types = const [],
    List<LedgerEvent> events = const [],
    List<LedgerEntry> entries = const [],
    List<EventPhoto> photos = const [],
  }) => _run(() async {
    if (types.isNotEmpty) await _client.from('event_types').upsert(types.map(LedgerJson.typeTo).toList());
    if (events.isNotEmpty) await _client.from('events').upsert(events.map(LedgerJson.eventTo).toList());
    if (entries.isNotEmpty) await _client.from('ledger_entries').upsert(entries.map(LedgerJson.entryTo).toList());
    if (photos.isNotEmpty) await _client.from('event_photos').upsert(photos.map(LedgerJson.photoTo).toList());
  });

  @override
  Future<void> delete({
    List<int> typeIds = const [],
    List<int> eventIds = const [],
    List<int> entryIds = const [],
    List<int> photoIds = const [],
  }) => _run(() async {
    if (photoIds.isNotEmpty) await _client.from('event_photos').delete().inFilter('id', photoIds);
    if (entryIds.isNotEmpty) await _client.from('ledger_entries').delete().inFilter('id', entryIds);
    if (eventIds.isNotEmpty) await _client.from('events').delete().inFilter('id', eventIds);
    if (typeIds.isNotEmpty) await _client.from('event_types').delete().inFilter('id', typeIds);
  });

  @override
  Future<void> clearRecords() async {
    await deleteAllPhotoFiles();
    await _run(() async {
      // 지우기 요청에는 조건이 꼭 있어야 해서 "id가 0 이상"(=전부)을 붙인다. 본인 행만 지워지는 건 RLS가 보장한다.
      // 사진 정보는 행사를 지우면 서버가 같이 지운다. (on delete cascade)
      await _client.from('ledger_entries').delete().gte('id', 0);
      await _client.from('events').delete().gte('id', 0);
    });
  }

  @override
  Future<void> uploadPhoto(int photoId, {required Uint8List image, required Uint8List thumb}) => _run(() async {
    const options = FileOptions(contentType: 'image/jpeg', upsert: true);
    await _bucket.uploadBinary(_path(photoId, thumb: false), image, fileOptions: options);
    await _bucket.uploadBinary(_path(photoId, thumb: true), thumb, fileOptions: options);
  }, timeout: _fileTimeout);

  @override
  Future<Uint8List> downloadPhoto(int photoId, {required bool thumb}) =>
      _run(() => _bucket.download(_path(photoId, thumb: thumb)), timeout: _fileTimeout);

  @override
  Future<void> deletePhotoFiles(List<int> photoIds) => _run(() async {
    final paths = [
      for (final id in photoIds) ...[_path(id, thumb: false), _path(id, thumb: true)],
    ];
    // 한 번에 1000개까지 지울 수 있다.
    for (var i = 0; i < paths.length; i += 1000) {
      await _bucket.remove(paths.sublist(i, min(i + 1000, paths.length)));
    }
  }, timeout: _fileTimeout);

  @override
  Future<void> deleteAllPhotoFiles() => _run(() async {
    final folder = _folder;
    // 폴더 목록을 1000개씩 읽어 지운다. 지운 만큼 목록이 줄어들어서 매번 처음부터 다시 읽는다.
    while (true) {
      final files = await _bucket.list(path: folder, searchOptions: const SearchOptions(limit: 1000));
      if (files.isEmpty) return;
      await _bucket.remove([for (final file in files) '$folder/${file.name}']);
      if (files.length < 1000) return;
    }
  }, timeout: _fileTimeout);

  @override
  Future<int> deleteOrphanPhotoFiles(Set<int> keep, {Duration minAge = const Duration(hours: 1)}) => _run(() async {
    final folder = _folder;
    final now = DateTime.now().toUtc();
    final orphans = <String>[];
    var offset = 0;
    while (true) {
      final files = await _bucket.list(
        path: folder,
        searchOptions: SearchOptions(limit: 1000, offset: offset),
      );
      for (final file in files) {
        final id = int.tryParse(file.name.split(RegExp(r'[_.]')).first);
        final created = DateTime.tryParse(file.createdAt ?? '');
        final oldEnough = created == null || now.difference(created) >= minAge;
        if (id != null && !keep.contains(id) && oldEnough) orphans.add('$folder/${file.name}');
      }
      if (files.length < 1000) break;
      offset += files.length;
    }
    for (var i = 0; i < orphans.length; i += 1000) {
      await _bucket.remove(orphans.sublist(i, min(i + 1000, orphans.length)));
    }
    return orphans.length;
  }, timeout: _fileTimeout * 2);

  /// 인터넷 문제는 [NetworkException]으로 바꿔서 화면이 알맞은 안내를 띄우게 한다.
  Future<T> _run<T>(Future<T> Function() action, {Duration? timeout}) async {
    try {
      return await action().timeout(timeout ?? _timeout);
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
  static int? _intOrNull(Object? v) => v == null ? null : _int(v);

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
    eventId: _intOrNull(j['event_id']),
    personName: j['person_name'] as String,
    amount: _int(j['amount']),
    date: _parse(j['date']),
    relation: j['relation'] == null ? null : Relation.values.byName(j['relation'] as String),
    memo: j['memo'] as String?,
    createdAt: _parse(j['created_at']),
    updatedAt: _parse(j['updated_at']),
  );

  static Map<String, Object?> photoTo(EventPhoto p) => {
    'id': p.id,
    'event_id': p.eventId,
    'entry_id': p.entryId,
    'sender_name': p.senderName,
    'memo': p.memo,
    'created_at': _date(p.createdAt),
  };

  static EventPhoto photoFrom(Map<String, dynamic> j) => EventPhoto(
    id: _int(j['id']),
    eventId: _int(j['event_id']),
    entryId: _intOrNull(j['entry_id']),
    senderName: j['sender_name'] as String?,
    memo: j['memo'] as String?,
    createdAt: _parse(j['created_at']),
  );
}
