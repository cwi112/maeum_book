import 'dart:math';

import 'package:drift/drift.dart';
import 'package:maeum_book/data/database/app_database.dart';
import 'package:maeum_book/data/models/models.dart';

/// 화면·통계·검색을 확인해 보기 위한 샘플 기록을 만든다. (설정 → 샘플 데이터 넣기)
///
/// ## 무엇을 만드나
/// - **보낸 기록 [sentCount]건**: 남의 경조사에 보낸 마음. 종류·금액·관계·메모를 섞는다.
/// - **경조사 종류 [extraTypeNames] 추가**: 환갑·백일·졸업 등. 종류 칩이 3줄을 넘어 가로 스크롤되는 모습을 볼 수 있다.
/// - **내 행사 [eventCount]개 + 받은 기록**: 결혼식·돌잔치·장례·칠순 등. 행사마다 3~12명이 마음을 준다.
///   행사가 많아서 받은 기록 입력의 행사 칩도 3줄을 넘는다.
///
/// ## 어떻게 만드나
/// - 실제처럼 보이도록 종류별로 흔한 금액대를 정해 두고 그 안에서 고른다. (가족·친척은 금액 2배)
/// - 날짜는 [now] 기준 최근 2년 안. 그래야 "올해/작년/최근 3개월" 필터와 월별 통계가 모두 의미 있게 나온다.
/// - [Random]에 고정 seed를 넣어서 **항상 같은 데이터**가 만들어진다. (테스트·스크린샷이 매번 같도록)
/// - 이름은 가상 인물이며, 일부는 보냄·받음 양쪽에 등장해 사람별 합계도 확인할 수 있다.
/// - 보낸 기록은 기본 종류(id 1~7)만 쓴다. 없는 종류는 "기타"로 넣는다. 행사는 종류 이름으로 찾는다.
/// - 샘플은 메모리 임시 DB에만 넣으므로 추가한 종류도 둘러보기를 끝내면 사라진다.
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

  /// 받은 기록 메모 예시 (보낸 기록 메모와 말투가 다르다)
  static const List<String> _receivedMemos = ['화환도 보내 주심', '직접 와 주심', '계좌로 보내 주심', '멀리서 와 주심', '', '', ''];

  /// 보낸 기록의 종류 비율 (결혼·조의가 많도록 여러 번 넣음)
  static const List<int> _sentTypeWeights = [1, 1, 1, 1, 2, 2, 2, 3, 3, 4, 5, 6, 7];

  /// 샘플에서만 더하는 경조사 종류 (기본 7개 뒤에 붙는다)
  static const List<String> extraTypeNames = ['환갑', '칠순', '백일', '졸업', '입학', '퇴임', '승진', '출산', '결혼기념일', '팔순'];

  static int get eventCount => _myEvents.length;

  /// 내 행사: (이름, 종류 이름, 며칠 전, 준 사람 수)
  static const List<(String, String, int, int)> _myEvents = [
    ('우리 결혼식', '결혼', 620, 12),
    ('첫째 돌잔치', '돌잔치', 250, 8),
    ('새집 집들이', '집들이', 120, 6),
    ('할머니 장례', '조의', 60, 10),
    ('아버지 칠순', '칠순', 20, 9),
    ('둘째 백일', '백일', 700, 5),
    ('어머니 환갑', '환갑', 680, 8),
    ('가게 개업', '개업', 540, 6),
    ('첫째 초등학교 입학', '입학', 400, 4),
    ('대학원 졸업', '졸업', 380, 4),
    ('아버지 정년 퇴임', '퇴임', 330, 5),
    ('팀장 승진', '승진', 300, 3),
    ('둘째 출산', '출산', 280, 6),
    ('결혼 5주년', '결혼기념일', 210, 3),
    ('할아버지 팔순', '팔순', 180, 7),
    ('내 생일 파티', '생일', 150, 4),
    ('이사 집들이', '집들이', 90, 4),
    ('외할머니 장례', '조의', 45, 8),
    ('장인어른 환갑', '환갑', 30, 6),
    ('동생 결혼식 (혼주)', '결혼', 10, 7),
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
    // 샘플 전용 종류를 기본 종류 뒤에 더한다. (이미 같은 이름이 있으면 그대로 둔다)
    final types = await db.select(db.eventTypes).get();
    var order = types.fold(0, (max, t) => t.sortOrder > max ? t.sortOrder : max);
    for (final name in extraTypeNames) {
      if (types.any((t) => t.name == name)) continue;
      await db.into(db.eventTypes).insert(EventTypesCompanion.insert(name: name, sortOrder: Value(++order)));
    }
    final typeIdByName = {for (final t in await db.select(db.eventTypes).get()) t.name: t.id};
    final existingTypeIds = typeIdByName.values.toSet();
    int typeOrOther(int id) => existingTypeIds.contains(id) ? id : DefaultEventTypes.otherId;
    int typeIdOf(String name) => typeIdByName[name] ?? DefaultEventTypes.otherId;

    LedgerEntriesCompanion entry({
      required RecordDirection direction,
      required int typeId,
      required DateTime date,
      int? eventId,
      String? name,
    }) {
      final (amounts, memos) = _patterns[typeId] ?? _patterns[DefaultEventTypes.otherId]!;
      final relation = random.nextInt(5) == 0 ? null : pick(Relation.values);
      final isFamily = relation == Relation.family || relation == Relation.relative;
      final memo = direction == RecordDirection.received ? pick(_receivedMemos) : pick(memos);
      return LedgerEntriesCompanion.insert(
        id: id(),
        direction: direction,
        eventTypeId: eventId == null ? typeOrOther(typeId) : typeId,
        eventId: Value(eventId),
        personName: name ?? pick(_people),
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
      for (final (title, typeName, daysAgo, givers) in _myEvents) {
        final typeId = typeIdOf(typeName);
        final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysAgo));
        final eventId = await db.eventDao.insertEvent(
          EventsCompanion.insert(id: id(), title: title, eventTypeId: typeId, date: date),
        );
        // 한 행사 안에서는 같은 이름이 두 번 나오지 않게 섞은 명단에서 차례로 뽑는다.
        final names = [..._people]..shuffle(random);
        final received = [
          for (var i = 0; i < givers; i++)
            entry(direction: RecordDirection.received, typeId: typeId, date: date, eventId: eventId, name: names[i]),
        ];
        await db.ledgerDao.insertAll(received);
        count += received.length;
      }
      return count;
    });
  }
}
