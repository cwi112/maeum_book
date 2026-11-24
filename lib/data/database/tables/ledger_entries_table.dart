import 'package:drift/drift.dart';
import 'package:maeum_book/core/define/app_define.dart';
import 'package:maeum_book/data/database/tables/event_types_table.dart';
import 'package:maeum_book/data/database/tables/events_table.dart';
import 'package:maeum_book/data/models/models.dart';

/// 경조사 기록 테이블. 보낸 것과 받은 것을 **한 테이블**에 담고 [direction]으로 구분한다.
///
/// ## 왜 한 테이블인가
/// - 통계(보낸 합계 vs 받은 합계), 사람별 정리, 엑셀 내보내기 모두 "전체 기록"을 한 번에 다룬다.
/// - 테이블을 나누면 같은 쿼리를 두 번 쓰고 합쳐야 해서 번거롭다.
///
/// ## 엑셀 열과의 대응
/// | 엑셀 열 | 컬럼 |
/// |---|---|
/// | 날짜 | [date] |
/// | 종류 | [eventTypeId] → event_types.name |
/// | 상대방 | [personName] |
/// | 금액 | [amount] |
/// | 보냄/받음 | [direction] |
/// | 관계 | [relation] |
/// | 메모 | [memo] |
///
/// ## 동작 방식
/// 이 클래스는 "설계도"일 뿐이다. `dart run build_runner build`를 실행하면 Drift가 이 설계도를 읽고
/// - 실제 SQLite 테이블(`ledger_entries`)을 만드는 SQL과
/// - 한 행을 담는 데이터 클래스 [LedgerEntry]
/// 를 `app_database.g.dart`에 자동으로 생성한다.
///
/// `@DataClassName`을 쓴 이유: 기본 이름(`LedgerEntrie`)이 어색하고,
/// Dart에 이미 `Record`라는 타입이 있어서 이름이 겹치지 않게 직접 지정했다.
///
/// `@TableIndex`: "보냄/받음별로 날짜순 목록"을 가장 자주 조회하므로, 그 두 컬럼에 인덱스(책의 색인 같은 것)를
/// 만들어 기록이 많아져도 빠르게 찾을 수 있게 했다.
@DataClassName('LedgerEntry')
@TableIndex(name: 'idx_ledger_entries_direction_date', columns: {#direction, #date})
class LedgerEntries extends Table {
  /// 고유 번호. 1부터 자동으로 1씩 증가한다.
  IntColumn get id => integer().autoIncrement()();

  /// 보냄 / 받음. DB에는 'sent' / 'received' 글자로 저장된다.
  TextColumn get direction => textEnum<RecordDirection>()();

  /// 경조사 종류 (event_types 테이블의 id). v3부터 글자 대신 번호로 저장한다.
  IntColumn get eventTypeId => integer().references(EventTypes, #id)();

  /// 이 받은 기록이 속한 행사 (받은 기록만, 보낸 기록은 null). v3에서 추가.
  /// 행사를 지우면 안의 기록도 함께 지워진다(cascade).
  IntColumn get eventId => integer().nullable().references(Events, #id, onDelete: KeyAction.cascade)();

  /// 상대방 이름. 빈 이름은 저장하지 못하게 1글자 이상, 최대 50글자로 제한한다.
  TextColumn get personName => text().withLength(min: 1, max: AppDefine.personNameMaxLength)();

  /// 금액 (원 단위 정수). 음수는 DB 단계에서 막는다. (SQL의 CHECK 제약 조건)
  ///
  /// 자기 자신(amount)을 참조하는 것은 Drift 공식 문법이라 실제로 재귀 호출되지 않는다. 그래서 경고를 끈다.
  // ignore: recursive_getters
  IntColumn get amount => integer().check(amount.isBiggerOrEqualValue(0))();

  /// 경조사 날짜 (언제 주고받았는지)
  DateTimeColumn get date => dateTime()();

  /// 상대방과의 관계 (선택). 스키마 버전 2에서 추가됐다.
  TextColumn get relation => textEnum<Relation>().nullable()();

  /// 메모 (선택). 비워 둘 수 있다.
  TextColumn get memo => text().nullable()();

  /// 처음 저장한 시각. 값을 안 넣으면 저장 순간의 시각이 자동으로 들어간다.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 마지막으로 수정한 시각. 수정할 때 Repository에서 갱신한다.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
