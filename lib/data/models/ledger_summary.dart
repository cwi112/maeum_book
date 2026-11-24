/// 한 방향(보냄 또는 받음)의 합계 정보.
///
/// DB에서 `SUM(amount)`, `COUNT(id)`로 계산한 결과를 담는다. (LedgerDao.watchSummaries)
class LedgerSummary {
  const LedgerSummary({this.total = 0, this.count = 0});

  /// 기록이 하나도 없을 때 쓰는 빈 합계
  static const LedgerSummary empty = LedgerSummary();

  /// 금액 합계 (원)
  final int total;

  /// 기록 건수
  final int count;
}
