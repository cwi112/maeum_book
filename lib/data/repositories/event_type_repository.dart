import 'package:maeum_book/core/define/app_define.dart';
import 'package:maeum_book/data/database/app_database.dart';
import 'package:maeum_book/data/remote/remote_ledger_store.dart';
import 'package:maeum_book/data/repositories/remote_first_write.dart';

/// 경조사 종류를 다루는 Repository. (설정 → 경조사 종류 관리, 입력 화면의 종류 칩)
class EventTypeRepository with RemoteFirstWrite {
  /// [remote]: 로그인했으면 서버 창구, 비로그인이면 null
  EventTypeRepository(this._dao, {this.remote});

  final EventTypeDao _dao;

  @override
  final RemoteLedgerStore? remote;

  @override
  AppDatabase get db => _dao.attachedDatabase;

  Future<EventType> _find(int id) => (db.select(db.eventTypes)..where((t) => t.id.equals(id))).getSingle();

  /// 모든 종류 (보여주는 순서대로)
  Stream<List<EventType>> watchAll() => _dao.watchAll();

  /// 종류를 추가하고 id를 돌려준다. 이름이 비었거나 너무 길면 [ArgumentError], 같은 이름이 있으면 DB가 막는다.
  Future<int> add(String name) {
    final cleaned = _clean(name);
    return write(
      () => _dao.insertType(cleaned, id: newIdValue()),
      (id, server) async => server.upsert(types: [await _find(id)]),
    );
  }

  /// 이름을 바꾼다. 이 종류를 쓰는 기록은 번호(id)로 연결돼 있어서 따로 고칠 필요가 없다.
  Future<void> rename(int id, String name) {
    final cleaned = _clean(name);
    return write(() => _dao.rename(id, cleaned), (_, server) async => server.upsert(types: [await _find(id)]));
  }

  /// 이 종류를 쓰는 기록·행사 수
  Future<int> countUsage(int id) => _dao.countUsage(id);

  /// 종류를 지운다. 쓰던 기록·행사는 "기타"로 옮긴다. "기타"(보호된 종류)는 지울 수 없다.
  Future<void> remove(EventType type) {
    if (type.isProtected) throw StateError('"${type.name}" 종류는 지울 수 없어요');
    const moveTo = DefaultEventTypes.otherId;
    // 회원: 서버에서도 쓰던 기록 · 행사를 "기타"로 옮긴 뒤 종류를 지운다. (기록이 지운 종류를 가리키면 서버가 막으므로 순서 중요)
    return write<(List<LedgerEntry>, List<LedgerEvent>)>(
      () async {
        final entries = await (db.select(db.ledgerEntries)..where((t) => t.eventTypeId.equals(type.id))).get();
        final events = await (db.select(db.events)..where((t) => t.eventTypeId.equals(type.id))).get();
        await _dao.deleteAndMove(type.id, moveToId: moveTo);
        return (entries, events);
      },
      (moved, server) async {
        final (entries, events) = moved;
        await server.upsert(
          events: [for (final e in events) e.copyWith(eventTypeId: moveTo)],
          entries: [for (final e in entries) e.copyWith(eventTypeId: moveTo)],
        );
        await server.delete(typeIds: [type.id]);
      },
    );
  }

  String _clean(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError.value(name, 'name', '이름을 입력해 주세요');
    if (trimmed.length > AppDefine.eventTypeNameMaxLength) {
      throw ArgumentError.value(name, 'name', '${AppDefine.eventTypeNameMaxLength}글자까지 입력할 수 있어요');
    }
    return trimmed;
  }
}
