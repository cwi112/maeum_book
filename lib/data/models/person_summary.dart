/// 한 사람과 주고받은 마음의 합계. (사람별 정리 화면용)
///
/// DB에서 이름(person_name)별로 묶어(GROUP BY) 계산한 결과를 담는다. (LedgerDao.watchPersonSummaries)
class PersonSummary {
  const PersonSummary({required this.name, required this.sentTotal, required this.receivedTotal, required this.count});

  /// 상대방 이름
  final String name;

  /// 내가 이 사람에게 보낸 총액 (원)
  final int sentTotal;

  /// 내가 이 사람에게 받은 총액 (원)
  final int receivedTotal;

  /// 주고받은 기록 건수 (보냄 + 받음)
  final int count;

  /// 받은 총액 - 보낸 총액. 양수면 받은 게 더 많다는 뜻.
  int get balance => receivedTotal - sentTotal;
}
