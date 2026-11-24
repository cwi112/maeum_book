import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';
import 'package:maeum_book/ui/stats/stats_view_model.dart';

/// 통계 탭.
///
/// 1. 보낸 마음 vs 받은 마음: 도넛 그래프, 가운데에 차액(받은 - 보낸)
/// 2. 종류별: 보낸/받은을 골라서 경조사 종류별 비율을 도넛 그래프로
class StatsView extends BaseAsyncView<StatsViewModel, StatsState> {
  const StatsView({super.key});

  @override
  AsyncNotifierProvider<StatsViewModel, StatsState> get provider => statsViewModelProvider;

  @override
  Widget buildView(BuildContext context, WidgetRef ref, StatsState data, StatsViewModel viewModel) {
    if (!data.hasData) {
      return Scaffold(
        appBar: AppBar(title: const Text('통계')),
        body: const EmptyView(
          icon: Icons.insert_chart_outlined,
          title: '아직 통계가 없어요',
          message: '보내고 받은 마음을 기록하면\n한눈에 정리해 드릴게요',
        ),
      );
    }

    final balance = data.balance;
    final ranking = data.typeRanking;
    return Scaffold(
      appBar: AppBar(title: const Text('통계')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: [
          _StatsCard(
            title: '보낸 마음과 받은 마음',
            child: DonutChart(
              slices: [
                ChartSlice(label: '보낸 마음', value: data.sent.total, color: AppColors.sent),
                ChartSlice(label: '받은 마음', value: data.received.total, color: AppColors.received),
              ],
              centerLabel: '받은 - 보낸',
              centerValue: '${balance > 0 ? '+' : ''}${balance.won}',
            ).testId(TestIds.statsBalanceChart),
          ),
          const SizedBox(height: AppSpacing.md),
          _StatsCard(
            title: '종류별',
            trailing: SegmentedButton<RecordDirection>(
              segments: [
                for (final direction in RecordDirection.values)
                  ButtonSegment(
                    value: direction,
                    label: Text(direction.label).testId(TestIds.statsTypeDirection(direction)),
                  ),
              ],
              selected: {data.typeDirection},
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              onSelectionChanged: (values) => viewModel.setTypeDirection(values.first),
            ),
            child: ranking.isEmpty
                ? AppText.body(
                    '아직 ${data.typeDirection.label} 기록이 없어요',
                    color: AppColors.textSecondary,
                  ).paddingSymmetric(vertical: AppSpacing.xl).center()
                : DonutChart(
                    slices: [
                      for (final item in ranking)
                        ChartSlice(
                          label: item.key.label,
                          value: item.value.total,
                          // 종류마다 색을 고정해서, 보낸/받은을 바꿔도 같은 종류는 같은 색으로 보이게 한다.
                          color: AppColors.chartPalette[item.key.index % AppColors.chartPalette.length],
                        ),
                    ],
                    centerLabel: '${data.typeDirection.label} 합계',
                    centerValue: data.summaryOf(data.typeDirection).total.won,
                  ).testId(TestIds.statsTypeChart),
          ),
        ],
      ),
    );
  }
}

/// 통계 카드: 제목(+오른쪽 위젯) + 내용
class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: AppText.title(title)),
                ?trailing,
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            child,
          ],
        ),
      ),
    );
  }
}
