import 'package:maeum_book/core/define/typedefs.dart';
import 'package:maeum_book/core/extensions/widget_extension.dart';
import 'package:maeum_book/core/theme/app_dimens.dart';
import 'package:material_ui/material_ui.dart';

/// 여러 값 중 하나를 고르는 칩 묶음. enum 선택에 쓴다.
///
/// ```dart
/// ChoiceChipGroup<EventType>(
///   values: EventType.values,
///   selected: state.eventType,
///   labelOf: (type) => type.label,
///   onSelected: viewModel.setEventType,
/// )
/// ```
/// - [allowDeselect]: true면 선택된 칩을 다시 눌러 선택을 해제할 수 있다(null 전달). 선택 입력 항목에 쓴다.
/// - [maxLines]: 칩이 많아 이 줄 수를 넘으면, 칩을 [maxLines]줄로 고르게 나눠 **가로로 넘겨 보게** 한다.
///   (경조사 종류를 많이 추가해도 화면을 아래로 길게 차지하지 않게. 순서는 그대로 왼쪽 위부터)
class ChoiceChipGroup<T> extends StatelessWidget {
  const ChoiceChipGroup({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.allowDeselect = false,
    this.testIdPrefix,
    this.testKeyOf,
    this.maxLines = 3,
  });

  final List<T> values;
  final T? selected;
  final String Function(T value) labelOf;
  final NullableCallback<T> onSelected;
  final bool allowDeselect;

  /// 자동화 테스트용 이름 접두어. 칩마다 `접두어_값이름`이 붙는다. (예: form_event_type_wedding)
  final String? testIdPrefix;

  /// 칩 이름표에 붙일 값. enum이면 이름(wedding), 아니면 이 함수로 정한다. (예: 종류 id)
  final String Function(T value)? testKeyOf;

  /// 이 줄 수를 넘으면 가로 스크롤로 바꾼다. null이면 줄 수 제한 없이 아래로 이어진다.
  final int? maxLines;

  static const double _spacing = AppSpacing.sm;

  /// 칩 글자 바깥 여백 (글자 여백 8 × 2 + 칩 여백 4 × 2 + 테두리) — 줄 수를 미리 계산할 때만 쓴다.
  static const double _chipChrome = 28;

  String? _testIdOf(T value) {
    if (testIdPrefix == null) return null;
    final key = testKeyOf?.call(value) ?? (value is Enum ? value.name : '$value');
    return '${testIdPrefix}_$key';
  }

  Widget _chip(T value) => ChoiceChip(
    label: Text(labelOf(value)),
    selected: value == selected,
    showCheckmark: false,
    onSelected: (isOn) {
      if (isOn) {
        onSelected(value);
      } else if (allowDeselect) {
        onSelected(null);
      }
    },
  ).testIdOrSelf(_testIdOf(value));

  /// 칩 하나의 대략적인 너비. 선택된 칩은 글자가 굵어지므로 굵은 글씨 기준으로 넉넉하게 잰다.
  double _estimateWidth(BuildContext context, T value) {
    final base = ChipTheme.of(context).labelStyle ?? Theme.of(context).textTheme.labelLarge ?? const TextStyle();
    final painter = TextPainter(
      text: TextSpan(
        text: labelOf(value),
        style: base.copyWith(fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    return painter.width + _chipChrome;
  }

  /// 칩을 차례대로 [lines]줄에 나눈다. 줄마다 너비 합이 비슷해지게 (순서는 유지)
  static List<List<int>> _splitIntoLines(List<double> widths, int lines) {
    final total = widths.fold<double>(0, (sum, w) => sum + w + _spacing);
    final target = total / lines;
    final result = <List<int>>[[]];
    var current = 0.0;
    for (var i = 0; i < widths.length; i++) {
      final remainingLines = lines - result.length;
      if (current >= target && remainingLines > 0) {
        result.add([]);
        current = 0;
      }
      result.last.add(i);
      current += widths[i] + _spacing;
    }
    return result;
  }

  /// 일반 줄바꿈(Wrap)으로 놓았을 때 몇 줄이 되는지
  static int _wrapLineCount(List<double> widths, double maxWidth) {
    var lines = 1;
    var current = 0.0;
    for (final w in widths) {
      final needed = current == 0 ? w : current + _spacing + w;
      if (needed > maxWidth && current > 0) {
        lines++;
        current = w;
      } else {
        current = needed;
      }
    }
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final limit = maxLines;
    Widget wrap() =>
        Wrap(spacing: _spacing, runSpacing: _spacing, children: [for (final value in values) _chip(value)]);
    if (limit == null || values.isEmpty) return wrap();

    return LayoutBuilder(
      builder: (context, constraints) {
        final widths = [for (final value in values) _estimateWidth(context, value)];
        if (!constraints.hasBoundedWidth || _wrapLineCount(widths, constraints.maxWidth) <= limit) return wrap();

        // 줄 수가 넘치면: [limit]줄로 나눠 가로로 넘겨 본다.
        final lines = _splitIntoLines(widths, limit);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (lineIndex, line) in lines.indexed) ...[
                if (lineIndex > 0) const SizedBox(height: _spacing),
                Row(
                  children: [
                    for (final (i, index) in line.indexed) ...[
                      if (i > 0) const SizedBox(width: _spacing),
                      _chip(values[index]),
                    ],
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
