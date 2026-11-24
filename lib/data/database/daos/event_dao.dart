import 'package:drift/drift.dart';
import 'package:maeum_book/data/database/app_database.dart';
import 'package:maeum_book/data/database/tables/event_types_table.dart';
import 'package:maeum_book/data/database/tables/events_table.dart';
import 'package:maeum_book/data/database/tables/ledger_entries_table.dart';
import 'package:maeum_book/data/models/models.dart';

part 'event_dao.g.dart';

/// 행사(내가 연 경조사) 테이블의 DB 작업.
@DriftAccessor(tables: [Events, EventTypes, LedgerEntries])
class EventDao extends DatabaseAccessor<AppDatabase> with _$EventDaoMixin {
  EventDao(super.attachedDatabase);

  /// 행사 목록을 최신 날짜순으로, 행사마다 받은 합계·인원·준 사람 이름과 함께 구독한다.
  ///
  /// 행사 표와 기록 표를 LEFT JOIN으로 붙이고 행사별로 묶는다(GROUP BY).
  /// LEFT JOIN이라 아직 받은 기록이 없는 행사도 합계 0으로 나온다.
  /// `GROUP_CONCAT`으로 이름들을 한 줄로 이어 받아서, 검색할 때 따로 DB를 읽지 않아도 되게 했다.
  Stream<List<EventSummary>> watchSummaries() {
    final total = ledgerEntries.amount.sum();
    final count = ledgerEntries.id.count();
    // 이름에 쉼표가 들어갈 수 있어서, 거의 쓰이지 않는 문자(\u001F, 단위 구분자)로 잇는다.
    final names = ledgerEntries.personName.groupConcat(separator: '\u001F');
    final query = select(events).join([leftOuterJoin(ledgerEntries, ledgerEntries.eventId.equalsExp(events.id))])
      ..addColumns([total, count, names])
      ..groupBy([events.id])
      ..orderBy([OrderingTerm.desc(events.date), OrderingTerm.desc(events.id)]);

    return query.watch().map(
      (rows) => [
        for (final row in rows)
          EventSummary(
            event: row.readTable(events),
            total: row.read(total) ?? 0,
            count: row.read(count) ?? 0,
            giverNames: row.read(names)?.split('\u001F') ?? const [],
          ),
      ],
    );
  }

  /// 행사 하나를 구독한다. (행사 상세 화면 위쪽 정보) 지워지면 null이 온다.
  Stream<LedgerEvent?> watchById(int id) => (select(events)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<LedgerEvent?> getById(int id) => (select(events)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// 행사의 받은 기록(준 사람들)을 금액 큰 순으로 구독한다.
  Stream<List<LedgerEntry>> watchEntries(int eventId) =>
      (select(ledgerEntries)
            ..where((t) => t.eventId.equals(eventId))
            ..orderBy([(t) => OrderingTerm.desc(t.amount), (t) => OrderingTerm.asc(t.personName)]))
          .watch();

  /// 모든 행사를 최신순으로 한 번 읽는다. (입력 화면의 행사 선택 목록)
  Future<List<LedgerEvent>> getAll() =>
      (select(events)..orderBy([(t) => OrderingTerm.desc(t.date), (t) => OrderingTerm.desc(t.id)])).get();

  Future<int> insertEvent(EventsCompanion event) => into(events).insert(event);

  /// 행사를 고친다. 안의 받은 기록도 날짜·종류를 행사에 맞춰 같이 바꾼다. (한 트랜잭션)
  Future<void> updateEvent(LedgerEvent event) => transaction(() async {
    await update(events).replace(event);
    await (update(ledgerEntries)..where((t) => t.eventId.equals(event.id))).write(
      LedgerEntriesCompanion(date: Value(event.date), eventTypeId: Value(event.eventTypeId)),
    );
  });

  /// 행사를 지운다. 안의 받은 기록은 외래 키의 cascade 설정으로 DB가 함께 지운다.
  Future<int> deleteEvent(int id) => (delete(events)..where((t) => t.id.equals(id))).go();
}
