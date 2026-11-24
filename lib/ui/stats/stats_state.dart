part of 'stats_view_model.dart';

/// 통계 탭의 상태. (stats_view_model.dart의 일부 — part of)
///
/// DB에서 "방향 × 경조사 종류"별 합계를 한 번에 받아서(watchTypeSummaries), 방향별 총합도 여기서 더해 쓴다.
/// 쿼리를 하나로 합쳐서, 기록이 바뀔 때 DB를 두 번 읽지 않게 했다.
class StatsState {
  const StatsState({this.byType = const {}, this.typeDirection = RecordDirection.sent});

  /// 방향별 → 종류별 합계
  final Map<RecordDirection, Map<EventType, LedgerSummary>> byType;

  /// 종류별 그래프에서 지금 보고 있는 방향 (보낸 / 받은)
  final RecordDirection typeDirection;

  /// 한 방향의 총합·건수
  LedgerSummary summaryOf(RecordDirection direction) {
    final types = byType[direction]?.values ?? const <LedgerSummary>[];
    return LedgerSummary(
      total: types.fold(0, (sum, s) => sum + s.total),
      count: types.fold(0, (sum, s) => sum + s.count),
    );
  }

  LedgerSummary get sent => summaryOf(RecordDirection.sent);
  LedgerSummary get received => summaryOf(RecordDirection.received);

  /// 받은 금액 - 보낸 금액 (양수면 더 많이 받음)
  int get balance => received.total - sent.total;

  /// 기록이 하나라도 있는지
  bool get hasData => sent.count > 0 || received.count > 0;

  /// 종류별 그래프에 쓸 합계 (금액 큰 순서)
  List<MapEntry<EventType, LedgerSummary>> get typeRanking =>
      (byType[typeDirection]?.entries.toList() ?? [])..sort((a, b) => b.value.total.compareTo(a.value.total));

  StatsState copyWith({Map<RecordDirection, Map<EventType, LedgerSummary>>? byType, RecordDirection? typeDirection}) =>
      StatsState(byType: byType ?? this.byType, typeDirection: typeDirection ?? this.typeDirection);
}
