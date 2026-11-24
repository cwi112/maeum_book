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

  String? _testIdOf(T value) {
    if (testIdPrefix == null) return null;
    final key = testKeyOf?.call(value) ?? (value is Enum ? value.name : '$value');
    return '${testIdPrefix}_$key';
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final value in values)
          ChoiceChip(
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
          ).testIdOrSelf(_testIdOf(value)),
      ],
    );
  }
}
