import 'package:maeum_book/core/define/app_define.dart';
import 'package:maeum_book/data/database/app_database.dart';

/// 경조사 종류를 다루는 Repository. (설정 → 경조사 종류 관리, 입력 화면의 종류 칩)
class EventTypeRepository {
  EventTypeRepository(this._dao);

  final EventTypeDao _dao;

  /// 모든 종류 (보여주는 순서대로)
  Stream<List<EventType>> watchAll() => _dao.watchAll();

  /// 종류를 추가하고 id를 돌려준다. 이름이 비었거나 너무 길면 [ArgumentError], 같은 이름이 있으면 DB가 막는다.
  Future<int> add(String name) => _dao.insertType(_clean(name));

  /// 이름을 바꾼다. 이 종류를 쓰는 기록은 번호(id)로 연결돼 있어서 따로 고칠 필요가 없다.
  Future<void> rename(int id, String name) => _dao.rename(id, _clean(name));

  /// 이 종류를 쓰는 기록·행사 수
  Future<int> countUsage(int id) => _dao.countUsage(id);

  /// 종류를 지운다. 쓰던 기록·행사는 "기타"로 옮긴다. "기타"(보호된 종류)는 지울 수 없다.
  Future<void> remove(EventType type) {
    if (type.isProtected) throw StateError('"${type.name}" 종류는 지울 수 없어요');
    return _dao.deleteAndMove(type.id, moveToId: DefaultEventTypes.otherId);
  }

  String _clean(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError.value(name, 'name', '이름을 입력해 주세요');
    if (trimmed.length > AppDefine.eventTypeNameMaxLength) {
      throw ArgumentError.value(name, 'name', '${AppDefine.eventTypeNameMaxLength}글자까지 입력할 수 있어요');
    }
    return trimmed;
  }
}
