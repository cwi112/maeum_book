import 'dart:math';

import 'package:drift/drift.dart';
import 'package:maeum_book/data/database/app_database.dart';
import 'package:maeum_book/data/models/models.dart';

/// 화면·통계·검색을 확인해 보기 위한 샘플 기록을 만든다. (설정 → 샘플 데이터 넣기)
///
/// ## 무엇을 만드나
/// - **보낸 기록 [sentCount]건**: 남의 경조사에 보낸 마음. 종류·금액·관계·메모를 섞는다.
/// - **내 행사 5개 + 받은 기록**: 결혼식·돌잔치·집들이·장례·칠순. 행사마다 6~12명이 마음을 준다.
///
/// ## 어떻게 만드나
/// - 실제처럼 보이도록 종류별로 흔한 금액대를 정해 두고 그 안에서 고른다. (가족·친척은 금액 2배)
/// - 날짜는 [now] 기준 최근 2년 안. 그래야 "올해/작년/최근 3개월" 필터와 월별 통계가 모두 의미 있게 나온다.
/// - [Random]에 고정 seed를 넣어서 **항상 같은 데이터**가 만들어진다. (테스트·스크린샷이 매번 같도록)
/// - 이름은 가상 인물이며, 일부는 보냄·받음 양쪽에 등장해 사람별 합계도 확인할 수 있다.
/// - 기본 경조사 종류(id 1~7)만 쓴다. 사용자가 종류를 지웠어도 깨지지 않게, 없는 종류는 "기타"로 넣는다.
abstract final class SampleData {
  static const int sentCount = 40;

  /// 샘플을 넣으면 생기는 기록 수 (보낸 + 행사별 받은)
  static int get totalCount => sentCount + _myEvents.fold(0, (sum, e) => sum + e.$4);

  static const List<String> _people = [
    '김민준', '이서연', '박지훈', '최수아', '정예준', '강하은', '조도윤', '윤지우', '장서준', '임하린', //
    '한지민', '오세훈', '서유진', '신동현', '권나연', '황태민', '안소희', '송민재', '전다은', '홍준서',
  ];

  /// 종류 id별 [흔한 금액들, 메모 예시들]
  static const Map<int, (List<int>, List<String>)> _patterns = {
    1: ([50000, 50000, 100000, 100000, 100000, 200000], ['대학 동기 결혼식', '회사 동료 결혼식', '화환도 보냄', '']),
    2: ([50000, 100000, 100000, 200000], ['부친상', '모친상', '조화 보냄', '']),
    3: ([30000, 50000, 50000, 100000], ['돌반지 대신 현금', '']),
    4: ([30000, 50000, 100000], ['생일 선물 대신', '']),
    5: ([30000, 50000, 100000], ['휴지 세트도 같이', '']),
    6: ([50000, 100000, 200000], ['개업 화분', '']),
    7: ([20000, 30000, 50000], ['승진 축하', '출산 축하', '']),
  };

  /// 보낸 기록의 종류 비율 (결혼·조의가 많도록 여러 번 넣음)
  static const List<int> _sentTypeWeights = [1, 1, 1, 1, 2, 2, 2, 3, 3, 4, 5, 6, 7];

  /// 내 행사: (이름, 종류 id, 며칠 전, 준 사람 수)
  static const List<(String, int, int, int)> _myEvents = [
    ('우리 결혼식', 1, 620, 12),
    ('첫째 돌잔치', 3, 250, 8),
    ('새집 집들이', 5, 120, 6),
    ('할머니 장례', 2, 60, 10),
    ('아버지 칠순', 7, 20, 9),
  ];

  /// DB에 샘플을 넣고 넣은 기록 수를 돌려준다. 행사와 기록을 **한 트랜잭션**으로 넣어서,
  /// 중간에 실패하면 전부 취소되고 화면 갱신도 마지막에 한 번만 일어난다.
  /// [newId]: 회원이면 서버와 겹치지 않는 번호를 만드는 함수 (비로그인은 null → 자동 번호)
  static Future<int> insertInto(
    AppDatabase db, {
    required DateTime now,
    int seed = 20261124,
    int Function()? newId,
  }) async {
    Value<int> id() => newId == null ? const Value.absent() : Value(newId());
    final random = Random(seed);
    T pick<T>(List<T> list) => list[random.nextInt(list.length)];
    final existingTypeIds = (await db.select(db.eventTypes).get()).map((t) => t.id).toSet();
    int typeOrOther(int id) => existingTypeIds.contains(id) ? id : DefaultEventTypes.otherId;

    LedgerEntriesCompanion entry({
      required RecordDirection direction,
      required int typeId,
      required DateTime date,
      int? eventId,
    }) {
      final (amounts, memos) = _patterns[typeId]!;
      final relation = random.nextInt(5) == 0 ? null : pick(Relation.values);
      final isFamily = relation == Relation.family || relation == Relation.relative;
      final memo = pick(memos);
      return LedgerEntriesCompanion.insert(
        id: id(),
        direction: direction,
        eventTypeId: typeOrOther(typeId),
        eventId: Value(eventId),
        personName: pick(_people),
        amount: pick(amounts) * (isFamily ? 2 : 1),
        date: date,
        relation: Value(relation),
        memo: Value(memo.isEmpty ? null : memo),
      );
    }

    return db.transaction(() async {
      var count = 0;
      // 1) 보낸 기록
      final sent = [
        for (var i = 0; i < sentCount; i++)
          entry(
            direction: RecordDirection.sent,
            typeId: pick(_sentTypeWeights),
            date: now.subtract(Duration(days: random.nextInt(730))),
          ),
      ];
      await db.ledgerDao.insertAll(sent);
      count += sent.length;

      // 2) 내 행사 + 받은 기록 (같은 행사 안에서는 같은 날짜·종류)
      for (final (title, typeId, daysAgo, givers) in _myEvents) {
        final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysAgo));
        final eventId = await db.eventDao.insertEvent(
          EventsCompanion.insert(id: id(), title: title, eventTypeId: typeOrOther(typeId), date: date),
        );
        final received = [
          for (var i = 0; i < givers; i++)
            entry(direction: RecordDirection.received, typeId: typeId, date: date, eventId: eventId),
        ];
        await db.ledgerDao.insertAll(received);
        count += received.length;
      }
      return count;
    });
  }
}
