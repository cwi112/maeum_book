import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';

part 'stats_state.dart';

/// 통계 탭의 ViewModel.
///
/// ## 어떻게 갱신되나
/// "방향×종류별 합계" Stream을 **신호**로 쓴다. 기록이 추가·수정·삭제되면 이 Stream이 새 값을 보내고,
/// 그때 `asyncMap`으로 월별·관계별·사람별 합계도 함께 다시 읽어서 하나의 상태로 묶는다.
/// Stream 네 개를 따로 구독하지 않아서, 기록 하나가 바뀔 때 화면이 네 번 깜빡이지 않는다.
///
/// 합계 계산은 모두 DB(SUM·GROUP BY)에서 하므로 기록이 많아도 앱이 전체 목록을 들고 있을 필요가 없다.
///
/// ## 화면 선택값을 따로 들고 있는 이유
/// 종류별·관계별 그래프의 "보낸/받은" 선택([_breakdownDirection])은 DB 값이 아니라 화면 선택이다.
/// 새 합계가 올 때마다 상태를 새로 만들기 때문에, 필드에 기억해 두었다가 같이 넣어 준다.
class StatsViewModel extends BaseAsyncViewModel<StatsState> {
  RecordDirection _breakdownDirection = RecordDirection.sent;

  @override
  Stream<StatsState> watch() {
    final repository = ref.watch(ledgerRepositoryProvider);
    return repository.watchTypeSummaries().asyncMap(
      (byType) async => StatsState(
        byType: byType,
        monthly: await repository.fetchMonthlyTotals(now: DateTime.now()),
        byRelation: await repository.fetchRelationTotals(),
        topPeople: await repository.fetchTopPeople(),
        breakdownDirection: _breakdownDirection,
      ),
    );
  }

  /// 종류별·관계별 그래프의 방향을 바꾼다. DB를 다시 읽지 않고 지금 상태에서 선택만 바꾼다.
  void setBreakdownDirection(RecordDirection direction) {
    _breakdownDirection = direction;
    final current = state.value;
    if (current != null) state = AsyncData(current.copyWith(breakdownDirection: direction));
  }
}

final statsViewModelProvider = AsyncNotifierProvider.autoDispose<StatsViewModel, StatsState>(StatsViewModel.new);
