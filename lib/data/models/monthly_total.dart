/// 한 달 동안 보낸·받은 합계. (통계의 월별 막대그래프 한 칸)
class MonthlyTotal {
  const MonthlyTotal({required this.month, required this.sent, required this.received});

  /// 그 달의 1일
  final DateTime month;

  /// 보낸 합계 / 받은 합계 (원)
  final int sent;
  final int received;
}
