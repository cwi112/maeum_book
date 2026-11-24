import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';

part 'stats_state.dart';

/// 통계 탭의 ViewModel.
///
/// DB의 보냄·받음 합계를 구독하다가, 기록이 바뀌면 통계도 자동으로 다시 계산되어 화면에 반영된다.
/// 합계 계산은 DB에서 `SUM`/`COUNT`로 하므로 기록이 많아도 앱이 전체 목록을 들고 있을 필요가 없다.
class StatsViewModel extends BaseAsyncViewModel<StatsState> {
  @override
  Stream<StatsState> watch() => ref
      .watch(ledgerRepositoryProvider)
      .watchSummaries()
      .map(
        (summaries) =>
            StatsState(sent: summaries[RecordDirection.sent]!, received: summaries[RecordDirection.received]!),
      );

  // TODO: 월별·종류별 통계, 사람별 합계(watchPersonSummaries)를 추가한다.
}

final statsViewModelProvider = AsyncNotifierProvider.autoDispose<StatsViewModel, StatsState>(StatsViewModel.new);
