import 'package:drift/drift.dart';
import 'package:maeum_book/data/database/app_database.dart';
import 'package:maeum_book/data/database/tables/ledger_entries_table.dart';
import 'package:maeum_book/data/models/models.dart';

part 'ledger_dao.g.dart';

/// 경조사 기록 테이블에 대한 **DB 작업(쿼리)만** 모아 둔 클래스. (DAO = Data Access Object)
///
/// ## 역할 나누기
/// - DAO: "어떤 SQL을 실행할지"만 안다. (조회·저장·수정·삭제)
/// - Repository: DAO를 사용해 앱에서 쓰기 편한 형태로 바꾸고, 입력값 검사 같은 규칙을 적용한다.
/// - ViewModel: Repository만 알고, DB나 SQL은 전혀 모른다.
///
/// ## watch와 get의 차이
/// - `watch...()`는 `Stream`을 돌려준다. 테이블 내용이 바뀌면(저장·수정·삭제) **새 결과를 자동으로 다시 보내준다.**
///   그래서 화면이 이걸 구독하고 있으면 따로 새로고침하지 않아도 목록과 합계가 바로 갱신된다.
/// - `get...()`은 `Future`로 **지금 시점의 결과 한 번**만 돌려준다. (엑셀 내보내기처럼 한 번 읽으면 되는 경우)
///
/// `ledger_dao.g.dart`는 build_runner가 자동으로 만드는 파일이며, [ledgerEntries] 같은 테이블 접근자가 들어 있다.
@DriftAccessor(tables: [LedgerEntries])
class LedgerDao extends DatabaseAccessor<AppDatabase> with _$LedgerDaoMixin {
  LedgerDao(super.attachedDatabase);

  // ── 조회 ──────────────────────────────

  /// 보냄 또는 받음 기록 목록을 **최신 날짜순**으로 구독한다.
  ///
  /// SQL로 쓰면: `SELECT * FROM ledger_entries WHERE direction = ? ORDER BY date DESC, id DESC`
  /// 같은 날짜면 나중에 저장한 기록(id가 큰 것)이 위로 온다.
  Stream<List<LedgerEntry>> watchByDirection(RecordDirection direction) {
    final query = select(ledgerEntries)
      ..where((t) => t.direction.equalsValue(direction))
      ..orderBy([(t) => OrderingTerm.desc(t.date), (t) => OrderingTerm.desc(t.id)]);
    return query.watch();
  }

  /// 보냄·받음 각각의 합계와 건수를 구독한다.
  ///
  /// SQL로 쓰면: `SELECT direction, SUM(amount), COUNT(id) FROM ledger_entries GROUP BY direction`
  /// 결과는 `{보냄: 합계, 받음: 합계}` 형태의 Map이다. 기록이 없는 방향은 Map에 들어 있지 않다.
  Stream<Map<RecordDirection, LedgerSummary>> watchSummaries() {
    final total = ledgerEntries.amount.sum();
    final count = ledgerEntries.id.count();
    final query = selectOnly(ledgerEntries)
      ..addColumns([ledgerEntries.direction, total, count])
      ..groupBy([ledgerEntries.direction]);

    return query.watch().map(
      (rows) => {
        for (final row in rows)
          row.readWithConverter<RecordDirection?, String>(ledgerEntries.direction)!: LedgerSummary(
            total: row.read(total) ?? 0,
            count: row.read(count) ?? 0,
          ),
      },
    );
  }

  /// 사람별로 보낸 총액·받은 총액을 구독한다. 주고받은 금액이 큰 사람부터 정렬한다.
  ///
  /// 조건부 합계(`CASE WHEN`)는 SQL로 직접 쓰는 편이 읽기 쉬워서 [customSelect]를 사용했다.
  /// `readsFrom`에 테이블을 알려 줘야 그 테이블이 바뀔 때 Stream이 다시 실행된다.
  Stream<List<PersonSummary>> watchPersonSummaries() {
    return customSelect(
      '''
      SELECT
        person_name,
        SUM(CASE WHEN direction = 'sent' THEN amount ELSE 0 END)     AS sent_total,
        SUM(CASE WHEN direction = 'received' THEN amount ELSE 0 END) AS received_total,
        COUNT(*)                                                     AS entry_count
      FROM ledger_entries
      GROUP BY person_name
      ORDER BY (sent_total + received_total) DESC, person_name ASC
      ''',
      readsFrom: {ledgerEntries},
    ).watch().map(
      (rows) => [
        for (final row in rows)
          PersonSummary(
            name: row.read<String>('person_name'),
            sentTotal: row.read<int>('sent_total'),
            receivedTotal: row.read<int>('received_total'),
            count: row.read<int>('entry_count'),
          ),
      ],
    );
  }

  /// 방향·경조사 종류별 합계와 건수를 구독한다. (통계 화면의 그래프용)
  ///
  /// SQL로 쓰면: `SELECT direction, event_type, SUM(amount), COUNT(id) FROM ledger_entries GROUP BY direction, event_type`
  /// 결과는 `{보냄: {결혼: 합계, ...}, 받음: {...}}` 형태다. 기록이 없는 조합은 들어 있지 않다.
  Stream<Map<RecordDirection, Map<EventType, LedgerSummary>>> watchTypeSummaries() {
    final total = ledgerEntries.amount.sum();
    final count = ledgerEntries.id.count();
    final query = selectOnly(ledgerEntries)
      ..addColumns([ledgerEntries.direction, ledgerEntries.eventType, total, count])
      ..groupBy([ledgerEntries.direction, ledgerEntries.eventType]);

    return query.watch().map((rows) {
      final result = <RecordDirection, Map<EventType, LedgerSummary>>{};
      for (final row in rows) {
        final direction = row.readWithConverter<RecordDirection?, String>(ledgerEntries.direction)!;
        final type = row.readWithConverter<EventType?, String>(ledgerEntries.eventType)!;
        (result[direction] ??= {})[type] = LedgerSummary(total: row.read(total) ?? 0, count: row.read(count) ?? 0);
      }
      return result;
    });
  }

  /// id로 기록 한 건을 읽는다. 없으면 null. (수정 화면에서 기존 값을 채울 때 사용)
  Future<LedgerEntry?> getById(int id) => (select(ledgerEntries)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// 전체 기록을 **오래된 날짜순**으로 한 번 읽는다. 엑셀 내보내기에 쓴다.
  Future<List<LedgerEntry>> getAllOrderByDate() {
    final query = select(ledgerEntries)..orderBy([(t) => OrderingTerm.asc(t.date), (t) => OrderingTerm.asc(t.id)]);
    return query.get();
  }

  // ── 저장·수정·삭제 ────────────────────

  /// 새 기록을 저장하고, 새로 매겨진 id를 돌려준다.
  ///
  /// [LedgerEntriesCompanion]은 "일부 값만 채운 행"이다. id·createdAt처럼 DB가 채워 주는 값은 비워 둔다.
  Future<int> insertEntry(LedgerEntriesCompanion entry) => into(ledgerEntries).insert(entry);

  /// 지웠던 기록을 **원래 id·작성 시각 그대로** 다시 넣는다. (삭제 후 "되돌리기")
  Future<int> restoreEntry(LedgerEntry entry) => into(ledgerEntries).insert(entry);

  /// 기록 한 건을 통째로 덮어쓴다. id가 같은 행을 찾아 바꾸며, 바뀐 행이 있으면 true.
  Future<bool> updateEntry(LedgerEntry entry) => update(ledgerEntries).replace(entry);

  /// id로 기록을 지우고, 지워진 행 수를 돌려준다. (0이면 해당 id가 없었다는 뜻)
  Future<int> deleteEntry(int id) => (delete(ledgerEntries)..where((t) => t.id.equals(id))).go();

  /// 여러 기록을 한 번에 넣는다. batch는 하나의 트랜잭션으로 처리되어,
  /// 60건을 넣어도 Stream 갱신이 한 번만 일어나고 중간에 실패하면 전부 취소된다.
  Future<void> insertAll(List<LedgerEntriesCompanion> entries) =>
      batch((batch) => batch.insertAll(ledgerEntries, entries));

  /// 모든 기록을 지우고, 지운 행 수를 돌려준다.
  Future<int> deleteAll() => delete(ledgerEntries).go();
}
