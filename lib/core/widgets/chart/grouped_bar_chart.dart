import 'package:fl_chart/fl_chart.dart';
import 'package:maeum_book/core/extensions/extensions.dart';
import 'package:maeum_book/core/theme/app_colors.dart';
import 'package:maeum_book/core/theme/app_dimens.dart';
import 'package:maeum_book/core/theme/app_text_styles.dart';
import 'package:maeum_book/core/widgets/app_text.dart';
import 'package:material_ui/material_ui.dart';

/// 막대 묶음 하나 (예: 11월의 보냄·받음)
class BarGroup {
  const BarGroup({required this.label, required this.values});

  /// 아래 축 글자 (예: '11월')
  final String label;

  /// 막대 값들. 순서는 [GroupedBarChart.series]와 같다.
  final List<int> values;
}

/// 막대 종류 하나 (예: 보냄 - 장밋빛)
class BarSeries {
  const BarSeries({required this.label, required this.color});

  final String label;
  final Color color;
}

/// 여러 막대를 나란히 세우는 막대그래프. (통계의 월별 보냄·받음)
///
/// ```dart
/// GroupedBarChart(
///   series: [BarSeries(label: '보냄', color: AppColors.sent), BarSeries(label: '받음', color: AppColors.received)],
///   groups: [BarGroup(label: '11월', values: [150000, 50000]), ...],
/// )
/// ```
///
/// ## 동작
/// - 세로 눈금은 가장 큰 값에 맞춰 자동으로 정하고, '10만'처럼 만 원 단위로 짧게 표시한다.
/// - 막대를 누르면 그 달의 금액이 말풍선으로 뜬다.
/// - 그래프 라이브러리(fl_chart)는 차트 파일에서만 쓴다. (DonutChart와 같은 원칙)
class GroupedBarChart extends StatelessWidget {
  const GroupedBarChart({super.key, required this.series, required this.groups, this.height = 220});

  final List<BarSeries> series;
  final List<BarGroup> groups;
  final double height;

  /// 세로축 숫자를 짧게: 150000 → '15만', 0 → '0'
  static String _short(double value) => value == 0 ? '0' : '${(value / 10000).round()}만';

  @override
  Widget build(BuildContext context) {
    final maxValue = groups.expand((g) => g.values).fold(0, (max, v) => v > max ? v : max);
    // 눈금 4칸이 10만 원 단위로 깔끔하게 떨어지도록 한 칸 크기(step)를 먼저 정하고, 맨 위 = step × 4로 한다.
    // 예) 최댓값 47만 → 한 칸 20만 → 맨 위 80만 (0·20만·40만·60만·80만). 기록이 없으면 한 칸 10만.
    final step = maxValue == 0 ? 100000.0 : ((maxValue / 4 / 100000).ceil() * 100000).toDouble();
    final top = step * 4;

    return Column(
      children: [
        SizedBox(
          height: height,
          child: BarChart(
            BarChartData(
              maxY: top,
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: step,
                getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.divider, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: step,
                    getTitlesWidget: (value, meta) => AppText.caption(_short(value)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      // 12개월이 다 들어가면 글자가 겹쳐서, 짝수 번째 달만 글자를 보여준다.
                      if (index < 0 || index >= groups.length || (groups.length > 6 && index.isOdd)) {
                        return const SizedBox.shrink();
                      }
                      return AppText.caption(groups[index].label).paddingOnly(top: AppSpacing.xs);
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.textPrimary,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                    '${groups[groupIndex].label} ${series[rodIndex].label}\n${rod.toY.toInt().won}',
                    AppTextStyles.caption.copyWith(color: AppColors.surface),
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < groups.length; i++)
                  BarChartGroupData(
                    x: i,
                    barsSpace: 2,
                    barRods: [
                      for (var s = 0; s < series.length; s++)
                        BarChartRodData(
                          toY: groups[i].values[s].toDouble(),
                          color: series[s].color,
                          width: 7,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // 범례
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final s in series) ...[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: AppSpacing.xs),
              AppText.caption(s.label),
              const SizedBox(width: AppSpacing.md),
            ],
          ],
        ),
      ],
    );
  }
}
