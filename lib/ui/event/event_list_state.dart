part of 'event_list_view_model.dart';

/// 받아요 탭의 상태. (event_list_view_model.dart의 일부 — part of)
class EventListState {
  const EventListState({this.allEvents = const [], this.query = ''});

  /// 모든 행사 (최신순, 행사별 합계 포함)
  final List<EventSummary> allEvents;

  /// 검색어. 행사 이름이나 그 행사에 마음을 준 사람 이름에 들어 있으면 보여준다.
  final String query;

  bool get isSearching => query.isNotBlank;

  /// 검색 결과 (검색어가 없으면 전체)
  List<EventSummary> get events {
    final keyword = query.trim().toLowerCase();
    if (keyword.isEmpty) return allEvents;
    return allEvents
        .where(
          (summary) =>
              summary.event.title.toLowerCase().contains(keyword) ||
              summary.giverNames.any((name) => name.toLowerCase().contains(keyword)),
        )
        .toList();
  }

  /// 보이는 행사들의 받은 금액 합계 / 받은 건수
  int get total => events.fold(0, (sum, e) => sum + e.total);
  int get count => events.fold(0, (sum, e) => sum + e.count);

  EventListState copyWith({String? query}) => EventListState(allEvents: allEvents, query: query ?? this.query);
}
