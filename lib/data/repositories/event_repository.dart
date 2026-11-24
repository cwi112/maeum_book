import 'package:drift/drift.dart';
import 'package:maeum_book/data/database/app_database.dart';
import 'package:maeum_book/data/models/models.dart';

/// 행사(내가 연 경조사)를 다루는 Repository. (받아요 탭)
class EventRepository {
  EventRepository(this._dao);

  final EventDao _dao;

  /// 행사 목록 + 행사별 받은 합계 (최신순)
  Stream<List<EventSummary>> watchSummaries() => _dao.watchSummaries();

  /// 행사 하나 (지워지면 null)
  Stream<LedgerEvent?> watchEvent(int id) => _dao.watchById(id);

  Future<LedgerEvent?> findById(int id) => _dao.getById(id);

  /// 행사의 받은 기록 (금액 큰 순)
  Stream<List<LedgerEntry>> watchEntries(int eventId) => _dao.watchEntries(eventId);

  /// 입력 화면의 "어느 행사에서 받았나요?" 선택 목록
  Future<List<LedgerEvent>> fetchAll() => _dao.getAll();

  /// 행사를 만들고 id를 돌려준다.
  Future<int> add({required String title, required int eventTypeId, required DateTime date, String? memo}) =>
      _dao.insertEvent(
        EventsCompanion.insert(
          title: _cleanTitle(title),
          eventTypeId: eventTypeId,
          date: date,
          memo: Value(_cleanMemo(memo)),
        ),
      );

  /// 행사를 고친다. 안의 받은 기록의 날짜·종류도 같이 바뀐다.
  Future<void> edit(
    LedgerEvent original, {
    required String title,
    required int eventTypeId,
    required DateTime date,
    String? memo,
  }) => _dao.updateEvent(
    original.copyWith(title: _cleanTitle(title), eventTypeId: eventTypeId, date: date, memo: Value(_cleanMemo(memo))),
  );

  /// 행사를 지운다. **안의 받은 기록도 모두 지워진다.** 화면에서 꼭 확인을 받은 뒤 부른다.
  Future<bool> remove(int id) async => await _dao.deleteEvent(id) > 0;

  String _cleanTitle(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) throw ArgumentError.value(title, 'title', '행사 이름을 입력해 주세요');
    return trimmed;
  }

  String? _cleanMemo(String? memo) {
    final trimmed = memo?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
