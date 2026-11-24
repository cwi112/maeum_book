part of 'stats_view_model.dart';

/// 통계 탭의 상태. (stats_view_model.dart의 일부 — part of)
class StatsState {
  const StatsState({this.sent = LedgerSummary.empty, this.received = LedgerSummary.empty});

  /// 보낸 마음 합계·건수
  final LedgerSummary sent;

  /// 받은 마음 합계·건수
  final LedgerSummary received;

  /// 받은 금액 - 보낸 금액 (양수면 더 많이 받음)
  int get balance => received.total - sent.total;

  /// 기록이 하나라도 있는지
  bool get hasData => sent.count > 0 || received.count > 0;
}
