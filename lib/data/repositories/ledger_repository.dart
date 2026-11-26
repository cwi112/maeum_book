import 'package:drift/drift.dart';
import 'package:maeum_book/data/database/app_database.dart';
import 'package:maeum_book/data/models/models.dart';
import 'package:maeum_book/data/remote/remote_ledger_store.dart';
import 'package:maeum_book/data/repositories/remote_first_write.dart';
import 'package:maeum_book/data/seed/sample_data.dart';

/// 경조사 기록을 다루는 Repository(저장소).
///
/// ## 역할
/// ViewModel은 이 클래스만 사용한다. DB가 Drift인지, 나중에 클라우드로 바뀌는지 ViewModel은 몰라도 된다.
/// 저장소를 바꾸더라도 이 클래스의 내부만 고치면 화면 코드는 그대로 둘 수 있다.
///
/// ## 여기서 하는 일
/// - DAO 결과를 화면에서 쓰기 좋은 형태로 바꾼다. (예: 기록이 없는 방향의 합계를 0으로 채움)
/// - 저장 전에 입력값을 정리·검사한다. (이름 앞뒤 공백 제거, 음수 금액 차단)
/// - 수정 시각(updatedAt)처럼 매번 챙겨야 하는 값을 자동으로 넣는다.
class LedgerRepository with RemoteFirstWrite {
  /// [remote]: 로그인했으면 서버 창구, 비로그인이면 null (기기 DB에만 저장)
  LedgerRepository(this._dao, {this.remote});

  final LedgerDao _dao;

  @override
  final RemoteLedgerStore? remote;

  @override
  AppDatabase get db => _dao.attachedDatabase;

  // ── 조회 (Stream: DB가 바뀌면 자동으로 새 값이 온다) ─────────────

  /// 보냄 또는 받음 기록 목록 (최신순)
  Stream<List<LedgerEntry>> watchEntries(RecordDirection direction) => _dao.watchByDirection(direction);

  /// 보냄·받음 합계. 기록이 없는 방향도 빠짐없이 [LedgerSummary.empty]로 채워서 돌려준다.
  Stream<Map<RecordDirection, LedgerSummary>> watchSummaries() => _dao.watchSummaries().map(
    (summaries) => {
      for (final direction in RecordDirection.values) direction: summaries[direction] ?? LedgerSummary.empty,
    },
  );

  /// 한 방향의 합계만 필요할 때 (보내요·받아요 화면 상단 카드)
  Stream<LedgerSummary> watchSummary(RecordDirection direction) =>
      watchSummaries().map((summaries) => summaries[direction]!);

  /// 사람별 주고받은 합계
  Stream<List<PersonSummary>> watchPersonSummaries() => _dao.watchPersonSummaries();

  /// 많이 주고받은 사람 [limit]명
  Future<List<PersonSummary>> fetchTopPeople({int limit = 5}) => _dao.getTopPeople(limit: limit);

  /// 최근 [months]개월(이번 달 포함)의 월별 보냄·받음 합계. 기록이 없는 달도 0으로 채워 **항상 [months]개**를 돌려준다.
  /// (그래프 막대 개수가 매번 같아야 보기 편하므로)
  Future<List<MonthlyTotal>> fetchMonthlyTotals({required DateTime now, int months = 12}) async {
    final first = DateTime(now.year, now.month - (months - 1));
    final totals = await _dao.getMonthlyTotals(from: first);
    return [
      for (var i = 0; i < months; i++)
        () {
          final month = DateTime(first.year, first.month + i);
          final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
          return MonthlyTotal(
            month: month,
            sent: totals[key]?[RecordDirection.sent] ?? 0,
            received: totals[key]?[RecordDirection.received] ?? 0,
          );
        }(),
    ];
  }

  /// 방향·관계별 합계 (관계 미입력은 null)
  Future<Map<RecordDirection, Map<Relation?, int>>> fetchRelationTotals() => _dao.getRelationTotals();

  /// 엑셀 내보내기용 전체 기록 (오래된 날짜순)
  Future<List<LedgerEntry>> fetchAllForExport() => _dao.getAllOrderByDate();

  /// 방향·종류별 합계 (통계 그래프용). 기록이 없는 방향도 빈 Map으로 채워서 돌려준다.
  Stream<Map<RecordDirection, Map<int, LedgerSummary>>> watchTypeSummaries() => _dao.watchTypeSummaries().map(
    (summaries) => {for (final direction in RecordDirection.values) direction: summaries[direction] ?? const {}},
  );

  /// id로 기록 한 건 찾기. 없으면 null (이미 지워진 경우 등)
  Future<LedgerEntry?> findById(int id) => _dao.getById(id);

  // ── 저장·수정·삭제 ────────────────────

  /// 새 기록을 저장하고 id를 돌려준다.
  ///
  /// 관계·메모는 선택 입력이다. 이름은 앞뒤 공백을 지우고, 메모가 공백뿐이면 비운다(null). 금액이 음수면 [ArgumentError]를 던진다.
  Future<int> add({
    required RecordDirection direction,
    required int eventTypeId,
    required String personName,
    required int amount,
    required DateTime date,
    int? eventId,
    Relation? relation,
    String? memo,
  }) {
    _validate(personName: personName, amount: amount);
    // 함수로 감싸서, 회원일 때는 write의 트랜잭션 안에서 실행되게 한다.
    Future<int> insert() => _dao.insertEntry(
      LedgerEntriesCompanion.insert(
        id: newIdValue(),
        direction: direction,
        eventTypeId: eventTypeId,
        eventId: Value(eventId),
        personName: personName.trim(),
        amount: amount,
        date: date,
        relation: Value(relation),
        memo: Value(_cleanMemo(memo)),
      ),
    );
    return write(insert, (id, server) async => server.upsert(entries: [(await _dao.getById(id))!]));
  }

  /// 기존 기록을 수정한다. 수정 시각(updatedAt)은 자동으로 지금으로 바뀐다.
  Future<bool> update(LedgerEntry entry) {
    _validate(personName: entry.personName, amount: entry.amount);
    final cleaned = entry.copyWith(
      personName: entry.personName.trim(),
      memo: Value(_cleanMemo(entry.memo)),
      updatedAt: DateTime.now(),
    );
    return write(() => _dao.updateEntry(cleaned), (_, server) => server.upsert(entries: [cleaned]));
  }

  /// 원래 기록([original])의 값을 입력 화면에서 바꾼 값으로 고쳐 저장한다. id·작성 시각은 그대로 유지된다.
  ///
  /// 관계·메모처럼 "비우기"가 가능한 값은 null을 넣으면 비워진다.
  /// (DB 라이브러리의 Value 타입을 화면 쪽에서 몰라도 되도록 여기서 감싼다)
  Future<bool> edit(
    LedgerEntry original, {
    required RecordDirection direction,
    required int eventTypeId,
    required String personName,
    required int amount,
    required DateTime date,
    int? eventId,
    Relation? relation,
    String? memo,
  }) => update(
    original.copyWith(
      direction: direction,
      eventTypeId: eventTypeId,
      eventId: Value(eventId),
      personName: personName,
      amount: amount,
      date: date,
      relation: Value(relation),
      memo: Value(memo),
    ),
  );

  /// 기록을 삭제한다. 실제로 지워졌으면 true.
  Future<bool> remove(int id) async =>
      await write(() => _dao.deleteEntry(id), (_, server) => server.delete(entryIds: [id])) > 0;

  /// 삭제한 기록을 되돌린다. id·작성 시각까지 그대로라 목록의 원래 자리로 돌아간다.
  Future<void> restore(LedgerEntry entry) =>
      write(() => _dao.restoreEntry(entry), (_, server) => server.upsert(entries: [entry]));

  /// 샘플 기록을 넣고 넣은 건수를 돌려준다. (설정 → 샘플 데이터 넣기)
  /// 회원이면 넣은 행사 · 기록을 서버에도 올린다.
  Future<int> addSamples({DateTime? now}) => write(
    () => SampleData.insertInto(db, now: now ?? DateTime.now(), newId: remote?.newId),
    (_, server) async =>
        server.upsert(events: await db.select(db.events).get(), entries: await db.select(db.ledgerEntries).get()),
  );

  /// 모든 기록과 행사를 지우고 지운 기록 수를 돌려준다. 되돌릴 수 없으므로 화면에서 꼭 확인을 받은 뒤 부른다.
  /// (경조사 종류는 사용자 설정이라 남겨 둔다)
  Future<int> clearAll() => write(
    () => db.transaction(() async {
      final count = await _dao.deleteAll();
      await db.delete(db.events).go();
      return count;
    }),
    (_, server) => server.clearRecords(),
  );

  // ── 내부 도우미 ───────────────────────

  void _validate({required String personName, required int amount}) {
    if (personName.trim().isEmpty) throw ArgumentError.value(personName, 'personName', '이름을 입력해 주세요');
    if (amount < 0) throw ArgumentError.value(amount, 'amount', '금액은 0원 이상이어야 해요');
  }

  String? _cleanMemo(String? memo) {
    final trimmed = memo?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
