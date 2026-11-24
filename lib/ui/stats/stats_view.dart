import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/ui/stats/stats_view_model.dart';

/// 통계 탭: 보낸·받은 합계와 그 차이를 보여준다.
class StatsView extends BaseAsyncView<StatsViewModel, StatsState> {
  const StatsView({super.key});

  @override
  AsyncNotifierProvider<StatsViewModel, StatsState> get provider => statsViewModelProvider;

  @override
  Widget buildView(BuildContext context, WidgetRef ref, StatsState data, StatsViewModel viewModel) {
    return Scaffold(
      appBar: AppBar(title: const Text('통계')),
      body: data.hasData
          ? ListView(
              padding: const EdgeInsets.all(AppSpacing.screen),
              children: [
                SummaryCard(label: '보낸 마음', amount: data.sent.total.won, count: data.sent.count, color: AppColors.sent),
                const SizedBox(height: AppSpacing.md),
                SummaryCard(
                  label: '받은 마음',
                  amount: data.received.total.won,
                  count: data.received.count,
                  color: AppColors.received,
                ),
                const SizedBox(height: AppSpacing.lg),
                // 받은 게 더 많으면 +, 보낸 게 더 많으면 - 로 표시
                const AppText.caption('받은 마음 - 보낸 마음').paddingOnly(left: AppSpacing.xs),
                AppText.amountLarge(
                  '${data.balance >= 0 ? '+' : ''}${data.balance.won}',
                  color: data.balance >= 0 ? AppColors.received : AppColors.sent,
                ).paddingOnly(left: AppSpacing.xs, top: AppSpacing.xs),
                // TODO: 월별 그래프, 종류별 비율, 사람별 순위
              ],
            )
          : const EmptyView(
              icon: Icons.insert_chart_outlined,
              title: '아직 통계가 없어요',
              message: '보내고 받은 마음을 기록하면\n한눈에 정리해 드릴게요',
            ),
    );
  }
}
