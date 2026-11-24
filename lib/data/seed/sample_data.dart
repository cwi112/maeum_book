import 'dart:math';

import 'package:drift/drift.dart';
import 'package:maeum_book/data/database/app_database.dart';
import 'package:maeum_book/data/models/models.dart';

/// 화면·통계·검색을 확인해 보기 위한 샘플 기록을 만든다. (설정 → 샘플 데이터 넣기)
///
/// ## 어떻게 만드나
/// - 실제 경조사처럼 보이도록 종류별로 흔한 금액대·관계·메모를 정해 두고, 그 안에서 고른다.
///   (예: 결혼은 5만·10만이 많고, 돌잔치는 3만·5만, 가족 결혼은 금액이 큼)
/// - 날짜는 [now] 기준 최근 2년 안에서 퍼뜨린다. 그래야 "올해/작년/최근 3개월" 필터가 모두 의미 있게 걸린다.
/// - [Random]에 고정 seed를 넣어서 **항상 같은 데이터**가 만들어진다. (테스트·스크린샷이 매번 같도록)
/// - 이름은 흔한 성 + 이름 조합의 가상 인물이며, 일부는 보냄·받음 양쪽에 등장하게 해 사람별 합계도 확인할 수 있다.
abstract final class SampleData {
  static const int defaultCount = 60;

  static const List<String> _people = [
    '김민준', '이서연', '박지훈', '최수아', '정예준', '강하은', '조도윤', '윤지우', '장서준', '임하린', //
    '한지민', '오세훈', '서유진', '신동현', '권나연', '황태민', '안소희', '송민재', '전다은', '홍준서',
  ];

  /// 종류별 [흔한 금액들, 메모 예시들]
  static const Map<EventType, (List<int>, List<String>)> _patterns = {
    EventType.wedding: (
      [50000, 50000, 100000, 100000, 100000, 200000, 300000],
      ['대학 동기 결혼식', '회사 동료 결혼식', '화환도 보냄', '축가 부탁받음', ''],
    ),
    EventType.funeral: ([50000, 100000, 100000, 200000], ['부친상', '모친상', '조부상', '조화 보냄', '']),
    EventType.firstBirthday: ([30000, 50000, 50000, 100000], ['돌반지 대신 현금', '돌잔치 참석', '']),
    EventType.birthday: ([30000, 50000, 100000], ['생일 선물 대신', '깜짝 파티', '']),
    EventType.housewarming: ([30000, 50000, 100000], ['휴지 세트도 같이', '집들이 초대', '']),
    EventType.opening: ([50000, 100000, 200000], ['개업 화분', '카페 개업', '']),
    EventType.other: ([20000, 30000, 50000], ['승진 축하', '출산 축하', '']),
  };

  /// 종류가 나오는 비율 (결혼·조의가 가장 많도록 여러 번 넣음)
  static const List<EventType> _typeWeights = [
    EventType.wedding, EventType.wedding, EventType.wedding, EventType.wedding, //
    EventType.funeral, EventType.funeral, EventType.funeral,
    EventType.firstBirthday, EventType.firstBirthday,
    EventType.birthday, EventType.housewarming, EventType.opening, EventType.other,
  ];

  static List<LedgerEntriesCompanion> generate({required DateTime now, int count = defaultCount, int seed = 20261124}) {
    final random = Random(seed);
    T pick<T>(List<T> list) => list[random.nextInt(list.length)];

    return List.generate(count, (i) {
      final type = pick(_typeWeights);
      final (amounts, memos) = _patterns[type]!;
      // 받은 기록은 40% 정도. 내가 보내는 경우가 더 흔하므로.
      final direction = random.nextInt(10) < 6 ? RecordDirection.sent : RecordDirection.received;
      // 가족·친척이면 금액을 2배로 (실제로도 더 크게 하는 편)
      final relation = random.nextInt(5) == 0 ? null : pick(Relation.values);
      final isFamily = relation == Relation.family || relation == Relation.relative;
      final memo = pick(memos);

      return LedgerEntriesCompanion.insert(
        direction: direction,
        eventType: type,
        personName: pick(_people),
        amount: pick(amounts) * (isFamily ? 2 : 1),
        date: now.subtract(Duration(days: random.nextInt(730))),
        relation: Value(relation),
        memo: Value(memo.isEmpty ? null : memo),
      );
    });
  }
}
