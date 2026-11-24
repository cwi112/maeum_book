import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';

part 'stats_state.dart';

/// 통계 탭의 ViewModel.
///
/// DB의 "방향 × 종류"별 합계를 구독하다가, 기록이 바뀌면 그래프도 자동으로 다시 그려진다.
/// 합계 계산은 DB에서 `SUM`/`GROUP BY`로 하므로 기록이 많아도 앱이 전체 목록을 들고 있을 필요가 없다.
///
/// ## 화면 선택값을 따로 들고 있는 이유
/// 종류별 그래프의 "보낸/받은" 선택([_typeDirection])은 DB 값이 아니라 화면 선택이다.
/// Stream이 새 합계를 보낼 때마다 상태를 새로 만들기 때문에, 선택값을 필드에 기억해 두었다가 같이 넣어 준다.
/// (그러지 않으면 기록을 추가할 때마다 선택이 "보낸"으로 되돌아간다)
class StatsViewModel extends BaseAsyncViewModel<StatsState> {
  RecordDirection _typeDirection = RecordDirection.sent;

  @override
  Stream<StatsState> watch() => ref
      .watch(ledgerRepositoryProvider)
      .watchTypeSummaries()
      .map((byType) => StatsState(byType: byType, typeDirection: _typeDirection));

  /// 종류별 그래프의 방향을 바꾼다. DB를 다시 읽지 않고 지금 상태에서 선택만 바꾼다.
  void setTypeDirection(RecordDirection direction) {
    _typeDirection = direction;
    final current = state.value;
    if (current != null) state = AsyncData(current.copyWith(typeDirection: direction));
  }
}

final statsViewModelProvider = AsyncNotifierProvider.autoDispose<StatsViewModel, StatsState>(StatsViewModel.new);
