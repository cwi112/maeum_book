import 'package:maeum_book/data/models/relation.dart';

/// 한 사람과 주고받은 마음의 합계. (통계의 사람별 TOP 5)
///
/// DB에서 **이름 + 관계**로 묶어(GROUP BY) 계산한 결과를 담는다. (LedgerDao.watchPersonSummaries)
///
/// ## 동명이인
/// 앱은 "같은 사람"을 알 방법이 이름뿐이라, 이름만으로 묶으면 다른 두 사람의 금액이 합쳐진다.
/// 그래서 관계까지 같아야 한 사람으로 본다. (엑셀 사람별 시트와 같은 규칙)
/// - 친구 김민준 / 직장 김민준 → 두 사람
/// - 관계까지 같은 동명이인은 구분할 수 없다. 이럴 땐 이름에 표시를 붙여 쓰도록 안내한다. (예: 김민준(회사))
class PersonSummary {
  const PersonSummary({
    required this.name,
    required this.sentTotal,
    required this.receivedTotal,
    required this.count,
    this.relation,
  });

  /// 상대방 이름
  final String name;

  /// 관계 (고르지 않았으면 null)
  final Relation? relation;

  /// 내가 이 사람에게 보낸 총액 (원)
  final int sentTotal;

  /// 내가 이 사람에게 받은 총액 (원)
  final int receivedTotal;

  /// 주고받은 기록 건수 (보냄 + 받음)
  final int count;

  /// 받은 총액 - 보낸 총액. 양수면 받은 게 더 많다는 뜻.
  int get balance => receivedTotal - sentTotal;
}
