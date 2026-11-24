import 'package:maeum_book/core/define/typedefs.dart';
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
  });

  final List<T> values;
  final T? selected;
  final String Function(T value) labelOf;
  final NullableCallback<T> onSelected;
  final bool allowDeselect;

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
          ),
      ],
    );
  }
}
