import 'package:maeum_book/core/errors/network_exception.dart';
import 'package:maeum_book/data/data.dart';

/// 테스트용 가짜 서버 DB. 실제 Supabase 대신 메모리에 한 사람의 장부를 저장한다.
class FakeRemoteLedgerStore implements RemoteLedgerStore {
  final Map<int, EventType> types = {};
  final Map<int, LedgerEvent> events = {};
  final Map<int, LedgerEntry> entries = {};

  /// true면 다음 작업들이 인터넷 문제로 실패한다. (다시 false로 바꿀 때까지)
  bool offline = false;

  var _next = 1000000;

  void _check() {
    if (offline) throw const NetworkException('offline');
  }

  @override
  int newId() => _next++;

  @override
  Future<RemoteSnapshot> fetchAll() async {
    _check();
    return RemoteSnapshot(
      types: types.values.toList(),
      events: events.values.toList(),
      entries: entries.values.toList(),
    );
  }

  @override
  Future<void> upsert({
    List<EventType> types = const [],
    List<LedgerEvent> events = const [],
    List<LedgerEntry> entries = const [],
  }) async {
    _check();
    for (final t in types) {
      this.types[t.id] = t;
    }
    for (final e in events) {
      this.events[e.id] = e;
    }
    for (final e in entries) {
      this.entries[e.id] = e;
    }
  }

  @override
  Future<void> delete({
    List<int> typeIds = const [],
    List<int> eventIds = const [],
    List<int> entryIds = const [],
  }) async {
    _check();
    entryIds.forEach(entries.remove);
    for (final id in eventIds) {
      events.remove(id);
      entries.removeWhere((_, e) => e.eventId == id); // 서버의 cascade
    }
    typeIds.forEach(types.remove);
  }

  @override
  Future<void> clearRecords() async {
    _check();
    entries.clear();
    events.clear();
  }
}
