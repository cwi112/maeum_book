import 'package:flutter/services.dart';
import 'package:maeum_book/core/define/typedefs.dart';
import 'package:maeum_book/core/extensions/extensions.dart';
import 'package:maeum_book/core/theme/app_dimens.dart';
import 'package:maeum_book/core/widgets/form/clear_text_button.dart';
import 'package:material_ui/material_ui.dart';

/// 금액 입력칸. 입력하면 세 자리마다 쉼표가 자동으로 찍히고, 아래 버튼(+1만 · +5만 · +10만 · +50만 · +100만)으로
/// 금액을 빠르게 더할 수 있다. 오른쪽 ⓧ로 전체 지우기.
///
/// ```dart
/// AmountField(value: state.amount, onChanged: viewModel.setAmount, errorText: state.amountError)
/// ```
///
/// ## 왜 StatefulWidget인가
/// "+5만" 버튼처럼 **바깥에서 값이 바뀌면** 입력칸 글자도 바뀌어야 한다.
/// 그러려면 입력칸 글자를 직접 고칠 수 있는 [TextEditingController]가 필요하고,
/// 컨트롤러는 화면이 살아 있는 동안 유지했다가 정리(dispose)해야 해서 State가 있는 위젯으로 만들었다.
class AmountField extends StatefulWidget {
  const AmountField({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.maxAmount,
    this.quickAmounts = const [10000, 50000, 100000, 500000, 1000000],
    this.testId,
  });

  /// 현재 금액 (원). 0이면 입력칸을 비워 둔다.
  final int value;
  final IntCallback onChanged;
  final String? errorText;

  /// 입력 가능한 최대 금액. 넘는 입력은 무시된다.
  final int? maxAmount;

  /// 빠른 입력 버튼 금액들. 누르면 현재 금액에 더한다.
  final List<int> quickAmounts;

  /// 자동화 테스트용 이름. 입력칸은 그대로, 빠른 입력 버튼은 `이름_add_금액`이 붙는다. (예: form_amount_add_50000)
  final String? testId;

  @override
  State<AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<AmountField> {
  late final TextEditingController _controller = TextEditingController(text: _format(widget.value));

  static String _format(int value) => value == 0 ? '' : value.comma;

  /// 부모가 넘긴 value가 입력칸 글자와 다르면(예: 빠른 입력 버튼) 글자를 맞춘다.
  /// 사용자가 직접 입력한 경우는 이미 같으므로 건드리지 않는다. (커서가 튀지 않게)
  @override
  void didUpdateWidget(AmountField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((_controller.text.toAmount ?? 0) != widget.value) {
      final text = _format(widget.value);
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add(int amount) {
    final next = widget.value + amount;
    if (widget.maxAmount != null && next > widget.maxAmount!) return;
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          inputFormatters: [_ThousandsFormatter(widget.maxAmount)],
          onChanged: (text) => widget.onChanged(text.toAmount ?? 0),
          decoration: InputDecoration(
            hintText: '0',
            suffixText: '원',
            errorText: widget.errorText,
            suffixIcon: ClearTextButton(controller: _controller, onCleared: () => widget.onChanged(0)),
          ),
        ).testIdOrSelf(widget.testId),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            // 10000 → '+1만', 50000 → '+5만'
            for (final amount in widget.quickAmounts)
              ActionChip(
                label: Text('+${amount ~/ 10000}만'),
                onPressed: () => _add(amount),
              ).testIdOrSelf(widget.testId == null ? null : '${widget.testId}_add_$amount'),
          ],
        ),
      ],
    );
  }
}

/// 입력할 때마다 숫자만 남기고 쉼표를 다시 찍는다. 최대 금액을 넘는 입력은 받지 않는다.
class _ThousandsFormatter extends TextInputFormatter {
  _ThousandsFormatter(this.maxAmount);

  final int? maxAmount;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final amount = newValue.text.toAmount;
    if (amount == null) return TextEditingValue.empty;
    if (maxAmount != null && amount > maxAmount!) return oldValue;
    final text = amount.comma;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
