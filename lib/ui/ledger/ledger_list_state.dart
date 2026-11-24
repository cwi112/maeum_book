part of 'ledger_list_view_model.dart';

/// 보내요·받아요 화면의 상태. (ledger_list_view_model.dart의 일부 — part of)
class LedgerListState {
  const LedgerListState({this.entries = const []});

  /// 기록 목록 (최신 날짜순)
  final List<LedgerEntry> entries;

  /// 목록 금액의 합계 (원). 목록이 이미 있으니 DB에 다시 묻지 않고 여기서 더한다.
  int get total => entries.fold(0, (sum, entry) => sum + entry.amount);

  /// 기록 건수
  int get count => entries.length;

  bool get isEmpty => entries.isEmpty;
}
