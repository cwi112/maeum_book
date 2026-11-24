import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/ui/stats/stats_view_model.dart';

/// 통계 탭: 보낸·받은 금액 비교, 월별 흐름 등.
class StatsView extends BaseAsyncView<StatsViewModel, StatsState> {
  const StatsView({super.key});

  @override
  AsyncNotifierProvider<StatsViewModel, StatsState> get provider => statsViewModelProvider;

  @override
  Widget buildView(BuildContext context, WidgetRef ref, StatsState data, StatsViewModel viewModel) {
    final hasData = data.sentTotal > 0 || data.receivedTotal > 0;
    return Scaffold(
      appBar: AppBar(title: const Text('통계')),
      body: hasData
          // TODO: 기록이 생기면 보냄/받음 비교, 월별 그래프를 그린다.
          ? const SizedBox.shrink()
          : const EmptyView(
              icon: Icons.insert_chart_outlined,
              title: '아직 통계가 없어요',
              message: '보내고 받은 마음을 기록하면\n한눈에 정리해 드릴게요',
            ),
    );
  }
}
