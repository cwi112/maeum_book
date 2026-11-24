import 'package:drift/drift.dart';
import 'package:maeum_book/data/database/app_database.dart';
import 'package:maeum_book/data/models/models.dart';

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
class LedgerRepository {
  LedgerRepository(this._dao);

  final LedgerDao _dao;

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

  /// 엑셀 내보내기용 전체 기록 (오래된 날짜순)
  Future<List<LedgerEntry>> fetchAllForExport() => _dao.getAllOrderByDate();

  // ── 저장·수정·삭제 ────────────────────

  /// 새 기록을 저장하고 id를 돌려준다.
  ///
  /// 이름은 앞뒤 공백을 지우고, 메모가 공백뿐이면 비운다(null). 금액이 음수면 [ArgumentError]를 던진다.
  Future<int> add({
    required RecordDirection direction,
    required EventType eventType,
    required String personName,
    required int amount,
    required DateTime date,
    String? memo,
  }) {
    _validate(personName: personName, amount: amount);
    return _dao.insertEntry(
      LedgerEntriesCompanion.insert(
        direction: direction,
        eventType: eventType,
        personName: personName.trim(),
        amount: amount,
        date: date,
        memo: Value(_cleanMemo(memo)),
      ),
    );
  }

  /// 기존 기록을 수정한다. 수정 시각(updatedAt)은 자동으로 지금으로 바뀐다.
  Future<bool> update(LedgerEntry entry) {
    _validate(personName: entry.personName, amount: entry.amount);
    return _dao.updateEntry(
      entry.copyWith(
        personName: entry.personName.trim(),
        memo: Value(_cleanMemo(entry.memo)),
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// 기록을 삭제한다. 실제로 지워졌으면 true.
  Future<bool> remove(int id) async => await _dao.deleteEntry(id) > 0;

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
