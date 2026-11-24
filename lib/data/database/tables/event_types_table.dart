import 'package:drift/drift.dart';
import 'package:maeum_book/core/define/app_define.dart';

/// 경조사 종류 테이블. (스키마 v3에서 추가)
///
/// 예전에는 종류가 코드에 고정된 enum이었지만, 사용자마다 필요한 종류가 달라서(예: 환갑, 칠순, 졸업)
/// 직접 추가·이름 변경·삭제할 수 있도록 테이블로 옮겼다.
///
/// - 기본 종류 7개는 DB를 처음 만들 때 넣는다. ([DefaultEventTypes])
/// - "기타"는 [isProtected]가 true라 지울 수 없다. 다른 종류를 지울 때 그 종류의 기록이 "기타"로 옮겨 가기 때문이다.
@DataClassName('EventType')
class EventTypes extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 종류 이름. 1~10글자, 같은 이름은 두 번 만들 수 없다(unique).
  TextColumn get name => text().withLength(min: 1, max: AppDefine.eventTypeNameMaxLength).unique()();

  /// 보여주는 순서 (작을수록 앞). 새로 추가한 종류는 맨 뒤로 간다.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// 지울 수 없는 종류인지 ("기타")
  BoolColumn get isProtected => boolean().withDefault(const Constant(false))();
}

/// 처음 설치할 때 넣는 기본 종류.
///
/// id를 고정해 두는 이유: v2 → v3 업데이트 때 예전 글자 값('wedding' 등)을 이 id로 바꿔 넣기 때문이다.
abstract final class DefaultEventTypes {
  static const int otherId = 7;

  /// (id, 이름, 예전 enum 이름)
  static const List<(int, String, String)> all = [
    (1, '결혼', 'wedding'),
    (2, '조의', 'funeral'),
    (3, '돌잔치', 'firstBirthday'),
    (4, '생일', 'birthday'),
    (5, '집들이', 'housewarming'),
    (6, '개업', 'opening'),
    (otherId, '기타', 'other'),
  ];
}
