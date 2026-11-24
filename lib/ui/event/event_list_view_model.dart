import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';

part 'event_list_state.dart';

/// 받아요 탭(행사 목록)의 ViewModel.
///
/// - DB의 행사 목록(행사별 합계·인원 포함)을 구독한다. 받은 기록이 추가·삭제되면 합계가 자동으로 바뀐다.
/// - 검색어는 보내요 탭과 같은 방식으로, DB를 다시 읽지 않고 들고 있는 목록에서 거른다.
///   다른 탭에 갔다 와도 유지되고(하단 탭은 IndexedStack이라 ViewModel이 살아 있음), 앱을 다시 켜면 초기화된다.
class EventListViewModel extends BaseAsyncViewModel<EventListState> {
  String _query = '';

  @override
  Stream<EventListState> watch() => ref
      .watch(eventRepositoryProvider)
      .watchSummaries()
      .map((events) => EventListState(allEvents: events, query: _query));

  /// 검색어를 바꾼다. (행사 이름 또는 준 사람 이름)
  void setQuery(String query) {
    _query = query;
    final current = state.value;
    if (current != null) state = AsyncData(current.copyWith(query: query));
  }
}

final eventListViewModelProvider = AsyncNotifierProvider.autoDispose<EventListViewModel, EventListState>(
  EventListViewModel.new,
);
