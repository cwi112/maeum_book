import 'package:drift/drift.dart';
import 'package:maeum_book/data/database/app_database.dart';
import 'package:maeum_book/data/database/tables/event_types_table.dart';
import 'package:maeum_book/data/database/tables/events_table.dart';
import 'package:maeum_book/data/database/tables/ledger_entries_table.dart';

part 'event_type_dao.g.dart';

/// 경조사 종류 테이블의 DB 작업.
@DriftAccessor(tables: [EventTypes, Events, LedgerEntries])
class EventTypeDao extends DatabaseAccessor<AppDatabase> with _$EventTypeDaoMixin {
  EventTypeDao(super.attachedDatabase);

  /// 모든 종류를 보여주는 순서대로 구독한다. 종류를 추가·수정·삭제하면 화면의 칩 목록이 바로 바뀐다.
  Stream<List<EventType>> watchAll() =>
      (select(eventTypes)..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.id)])).watch();

  /// 새 종류를 맨 뒤에 추가하고 id를 돌려준다.
  ///
  /// SQL로 쓰면: `INSERT INTO event_types (name, sort_order) VALUES (?, (SELECT MAX(sort_order) + 1 ...))`
  Future<int> insertType(String name) async {
    final maxOrder = eventTypes.sortOrder.max();
    final last = await (selectOnly(eventTypes)..addColumns([maxOrder])).map((row) => row.read(maxOrder)).getSingle();
    return into(eventTypes).insert(EventTypesCompanion.insert(name: name, sortOrder: Value((last ?? 0) + 1)));
  }

  /// 이름을 바꾼다.
  Future<int> rename(int id, String name) =>
      (update(eventTypes)..where((t) => t.id.equals(id))).write(EventTypesCompanion(name: Value(name)));

  /// 이 종류를 쓰는 기록·행사 수 (삭제 전에 "몇 건이 옮겨져요" 안내용)
  Future<int> countUsage(int id) async {
    final entries = ledgerEntries.id.count(filter: ledgerEntries.eventTypeId.equals(id));
    final events = this.events.id.count(filter: this.events.eventTypeId.equals(id));
    final entryCount = await (selectOnly(ledgerEntries)..addColumns([entries])).map((r) => r.read(entries)).getSingle();
    final eventCount = await (selectOnly(this.events)..addColumns([events])).map((r) => r.read(events)).getSingle();
    return (entryCount ?? 0) + (eventCount ?? 0);
  }

  /// 종류를 지운다. 이 종류를 쓰던 기록·행사는 먼저 [moveToId] 종류로 옮긴다.
  ///
  /// transaction: 옮기기·지우기가 **모두 성공하거나 모두 취소**된다. 중간에 실패해서 기록이 갈 곳을 잃는 일이 없다.
  Future<void> deleteAndMove(int id, {required int moveToId}) => transaction(() async {
    await (update(
      ledgerEntries,
    )..where((t) => t.eventTypeId.equals(id))).write(LedgerEntriesCompanion(eventTypeId: Value(moveToId)));
    await (update(events)..where((t) => t.eventTypeId.equals(id))).write(EventsCompanion(eventTypeId: Value(moveToId)));
    await (delete(eventTypes)..where((t) => t.id.equals(id))).go();
  });
}
