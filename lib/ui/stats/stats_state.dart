part of 'stats_view_model.dart';

/// 통계 탭의 상태. (stats_view_model.dart의 일부 — part of)
class StatsState {
  const StatsState({this.sentTotal = 0, this.receivedTotal = 0});

  /// 보낸 금액 합계 (원)
  final int sentTotal;

  /// 받은 금액 합계 (원)
  final int receivedTotal;

  /// 받은 금액 - 보낸 금액 (양수면 더 많이 받음)
  int get balance => receivedTotal - sentTotal;

  StatsState copyWith({int? sentTotal, int? receivedTotal}) =>
      StatsState(sentTotal: sentTotal ?? this.sentTotal, receivedTotal: receivedTotal ?? this.receivedTotal);
}
