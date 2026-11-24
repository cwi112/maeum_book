part of 'stats_view_model.dart';

/// 통계 탭의 상태. (stats_view_model.dart의 일부 — part of)
///
/// | 값 | 쓰는 곳 |
/// |---|---|
/// | [byType] 방향×종류별 합계 | 보낸·받은 비율(합쳐서), 종류별 그래프 |
/// | [monthly] 최근 12개월 | 월별 막대그래프 |
/// | [byRelation] 방향×관계별 합계 | 관계별 그래프 |
/// | [topPeople] 많이 주고받은 5명 | 사람별 TOP 5 |
/// | [breakdownDirection] | 종류별·관계별 그래프가 보낸/받은 중 무엇을 볼지 (화면 선택값) |
class StatsState {
  const StatsState({
    this.byType = const {},
    this.monthly = const [],
    this.byRelation = const {},
    this.topPeople = const [],
    this.breakdownDirection = RecordDirection.sent,
  });

  final Map<RecordDirection, Map<int, LedgerSummary>> byType;
  final List<MonthlyTotal> monthly;
  final Map<RecordDirection, Map<Relation?, int>> byRelation;
  final List<PersonSummary> topPeople;
  final RecordDirection breakdownDirection;

  /// 한 방향의 총합·건수 (종류별 합계를 모두 더함)
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

  /// 선택한 방향의 종류별 합계 (금액 큰 순)
  List<MapEntry<int, LedgerSummary>> get typeRanking =>
      (byType[breakdownDirection]?.entries.toList() ?? [])..sort((a, b) => b.value.total.compareTo(a.value.total));

  /// 선택한 방향의 관계별 합계 (금액 큰 순, 관계 미입력은 null)
  List<MapEntry<Relation?, int>> get relationRanking =>
      (byRelation[breakdownDirection]?.entries.toList() ?? [])..sort((a, b) => b.value.compareTo(a.value));

  StatsState copyWith({RecordDirection? breakdownDirection}) => StatsState(
    byType: byType,
    monthly: monthly,
    byRelation: byRelation,
    topPeople: topPeople,
    breakdownDirection: breakdownDirection ?? this.breakdownDirection,
  );
}
