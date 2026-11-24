import 'package:maeum_book/core/core.dart';

part 'stats_state.dart';

/// 통계 탭의 ViewModel. 상태(state) = [StatsState].
class StatsViewModel extends BaseAsyncViewModel<StatsState> {
  // TODO: 저장소에서 내역을 불러와 합계·월별 통계를 계산한다.
  @override
  Future<StatsState> load() async => const StatsState();
}

final statsViewModelProvider = AsyncNotifierProvider.autoDispose<StatsViewModel, StatsState>(StatsViewModel.new);
