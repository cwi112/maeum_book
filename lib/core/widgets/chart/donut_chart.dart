import 'package:fl_chart/fl_chart.dart';
import 'package:maeum_book/core/extensions/extensions.dart';
import 'package:maeum_book/core/theme/app_colors.dart';
import 'package:maeum_book/core/theme/app_dimens.dart';
import 'package:maeum_book/core/theme/app_text_styles.dart';
import 'package:maeum_book/core/widgets/app_text.dart';
import 'package:material_ui/material_ui.dart';

/// 도넛 그래프의 조각 하나.
class ChartSlice {
  const ChartSlice({required this.label, required this.value, required this.color});

  final String label;

  /// 금액 등 크기 값. 0 이하인 조각은 그리지 않는다.
  final int value;
  final Color color;
}

/// 가운데가 빈 원형 그래프 + 아래 범례(이름·금액·비율).
///
/// ```dart
/// DonutChart(
///   slices: [ChartSlice(label: '보낸 마음', value: 150000, color: AppColors.sent), ...],
///   centerLabel: '받은 - 보낸',
///   centerValue: '+50,000원',
/// )
/// ```
///
/// ## 동작
/// - 조각 크기는 전체 합에서 차지하는 비율로 자동 계산된다. (fl_chart의 PieChart)
/// - 조각을 누르면 그 조각이 살짝 커지고, 범례의 해당 줄이 굵게 표시된다.
/// - 값이 0인 조각은 그래프·범례에서 모두 뺀다.
///
/// 그래프 라이브러리(fl_chart)는 이 파일에서만 쓴다. 다른 그래프 라이브러리로 바꾸더라도 이 파일만 고치면 된다.
class DonutChart extends StatefulWidget {
  const DonutChart({super.key, required this.slices, this.centerLabel, this.centerValue, this.size = 200});

  final List<ChartSlice> slices;

  /// 가운데 작은 글씨 / 큰 글씨
  final String? centerLabel;
  final String? centerValue;

  /// 그래프 지름
  final double size;

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart> {
  /// 누른 조각 번호 (없으면 null). 그래프 안에서만 쓰는 화면 상태라 ViewModel이 아닌 여기서 관리한다.
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final slices = widget.slices.where((slice) => slice.value > 0).toList();
    final total = slices.fold<int>(0, (sum, slice) => sum + slice.value);
    final radius = widget.size / 2;

    return Column(
      children: [
        SizedBox.square(
          dimension: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2, // 조각 사이 틈
                  centerSpaceRadius: radius * 0.62, // 가운데 빈 원 크기
                  startDegreeOffset: -90, // 12시 방향부터 시작
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      if (!event.isInterestedForInteractions) return;
                      setState(() => _touchedIndex = response?.touchedSection?.touchedSectionIndex);
                    },
                  ),
                  sections: [
                    for (var i = 0; i < slices.length; i++)
                      PieChartSectionData(
                        value: slices[i].value.toDouble(),
                        color: slices[i].color,
                        radius: radius * (i == _touchedIndex ? 0.42 : 0.36),
                        showTitle: false,
                      ),
                  ],
                ),
              ),
              // 가운데 빈 원 안에 들어가도록 폭을 제한하고, 금액이 크면 글자를 줄인다.
              SizedBox(
                width: radius * 1.15,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.centerLabel != null) AppText.caption(widget.centerLabel!),
                      if (widget.centerValue != null) AppText.amount(widget.centerValue!),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < slices.length; i++)
          _LegendRow(
            slice: slices[i],
            percent: total == 0 ? 0 : slices[i].value * 100 / total,
            highlighted: i == _touchedIndex,
          ),
      ],
    );
  }
}

/// 범례 한 줄: ● 이름 ······ 금액 (비율%)
class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.slice, required this.percent, required this.highlighted});

  final ChartSlice slice;
  final double percent;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final textStyle = highlighted ? AppTextStyles.body.bold : AppTextStyles.body;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: slice.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          // 이름은 길면 "…"로 줄이고, 금액은 자리가 모자랄 때만 글자를 줄여 다 보이게 한다. (금액이 수억 원이어도 넘치지 않게)
          Expanded(flex: 2, child: AppText(slice.label, style: textStyle, maxLines: 1)),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            flex: 3,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: AppText(slice.value.won, style: textStyle),
            ),
          ),
          SizedBox(
            width: 52,
            child: AppText.caption('${percent.round()}%', align: TextAlign.right, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
