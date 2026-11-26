import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';
import 'package:maeum_book/ui/stats/stats_view_model.dart';

/// 통계 탭.
///
/// 1. 보낸 마음과 받은 마음: 도넛, 가운데에 차액(받은 - 보낸)
/// 2. 월별 흐름: 최근 12개월 보냄·받음 막대그래프
/// 3. 보낸/받은 선택 → 종류별 도넛, 관계별 도넛
/// 4. 사람별 TOP 5: 많이 주고받은 사람과 차액
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
    final typeNames = ref.watch(eventTypeNamesProvider);
    // 종류 색은 종류 목록 순서로 정한다. (보낸/받은을 바꿔도 같은 종류는 같은 색)
    final typeOrder = typeNames.keys.toList();
    Color typeColor(int id) =>
        AppColors.chartPalette[typeOrder.indexOf(id).clamp(0, 999) % AppColors.chartPalette.length];
    Color relationColor(Relation? relation) =>
        relation == null ? AppColors.textHint : AppColors.chartPalette[relation.index % AppColors.chartPalette.length];
    final direction = data.breakdownDirection;

    return Scaffold(
      appBar: AppBar(title: const Text('통계')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: [
          // 1. 보낸 vs 받은
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

          // 2. 월별 흐름
          _StatsCard(
            title: '월별 흐름',
            subtitle: '최근 12개월',
            child: GroupedBarChart(
              series: const [
                BarSeries(label: '보낸 마음', color: AppColors.sent),
                BarSeries(label: '받은 마음', color: AppColors.received),
              ],
              groups: [
                for (final month in data.monthly)
                  BarGroup(label: '${month.month.month}월', values: [month.sent, month.received]),
              ],
            ).testId(TestIds.statsMonthlyChart),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 3. 보낸/받은 선택 → 종류별·관계별
          Row(
            children: [
              const AppText.title('나눠 보기').expanded(),
              SegmentedButton<RecordDirection>(
                segments: [
                  for (final value in RecordDirection.values)
                    ButtonSegment(value: value, label: Text(value.label).testId(TestIds.statsTypeDirection(value))),
                ],
                selected: {direction},
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                onSelectionChanged: (values) => viewModel.setBreakdownDirection(values.first),
              ),
            ],
          ).paddingSymmetric(horizontal: AppSpacing.xs),
          const SizedBox(height: AppSpacing.md),
          _StatsCard(
            title: '종류별',
            child: data.typeRanking.isEmpty
                ? _NoData(direction: direction)
                : DonutChart(
                    slices: [
                      for (final item in data.typeRanking)
                        ChartSlice(
                          label: typeNames[item.key] ?? '',
                          value: item.value.total,
                          color: typeColor(item.key),
                        ),
                    ],
                    centerLabel: '${direction.label} 합계',
                    centerValue: data.summaryOf(direction).total.won,
                  ).testId(TestIds.statsTypeChart),
          ),
          const SizedBox(height: AppSpacing.md),
          _StatsCard(
            title: '관계별',
            child: data.relationRanking.isEmpty
                ? _NoData(direction: direction)
                : DonutChart(
                    slices: [
                      for (final item in data.relationRanking)
                        ChartSlice(label: item.key?.label ?? '미입력', value: item.value, color: relationColor(item.key)),
                    ],
                    centerLabel: '${direction.label} 합계',
                    centerValue: data.summaryOf(direction).total.won,
                  ).testId(TestIds.statsRelationChart),
          ),
          const SizedBox(height: AppSpacing.md),

          // 4. 사람별 TOP 5
          _StatsCard(
            title: '많이 주고받은 사람',
            subtitle: 'TOP ${data.topPeople.length}',
            child: Column(
              children: [
                for (final (index, person) in data.topPeople.indexed) _PersonRankRow(rank: index + 1, person: person),
              ],
            ).testId(TestIds.statsTopPeople),
          ),
        ],
      ),
    );
  }
}

/// 통계 카드: 제목(+작은 설명) + 내용
class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 좁은 화면 · 큰 글씨에서 제목 + 설명이 한 줄을 넘지 않게 둘 다 줄어들 수 있게 한다.
                Flexible(child: AppText.title(title, maxLines: 1)),
                if (subtitle != null)
                  Flexible(child: AppText.caption(subtitle!, maxLines: 1).paddingOnly(left: AppSpacing.sm, bottom: 3)),
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

/// 고른 방향에 기록이 없을 때
class _NoData extends StatelessWidget {
  const _NoData({required this.direction});

  final RecordDirection direction;

  @override
  Widget build(BuildContext context) => AppText.body(
    '아직 ${direction.label} 기록이 없어요',
    color: AppColors.textSecondary,
  ).paddingSymmetric(vertical: AppSpacing.xl).center();
}

/// 사람별 순위 한 줄:  1  김민준   보냄 30만원 · 받음 20만원    -10만원
class _PersonRankRow extends StatelessWidget {
  const _PersonRankRow({required this.rank, required this.person});

  final int rank;
  final PersonSummary person;

  @override
  Widget build(BuildContext context) {
    final balance = person.balance;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(width: 24, child: AppText.label('$rank', color: rank <= 3 ? AppColors.primary : AppColors.textHint)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 이름 옆에 관계를 붙여 동명이인을 구분한다. (예: 김민준 · 친구)
              AppText.subtitle(
                person.relation == null ? person.name : '${person.name} · ${person.relation!.label}',
                maxLines: 1,
              ),
              AppText.caption('보냄 ${person.sentTotal.manWon} · 받음 ${person.receivedTotal.manWon}'),
            ],
          ).expanded(),
          AppText.label(
            balance == 0 ? '같음' : '${balance > 0 ? '+' : '-'}${balance.abs().manWon}',
            color: balance > 0 ? AppColors.received : (balance < 0 ? AppColors.sent : AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
