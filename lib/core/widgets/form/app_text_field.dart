import 'package:maeum_book/core/define/typedefs.dart';
import 'package:maeum_book/core/theme/app_dimens.dart';
import 'package:maeum_book/core/widgets/form/clear_text_button.dart';
import 'package:material_ui/material_ui.dart';

/// 앱 공통 글자 입력칸. 모양은 테마(app_theme.dart의 inputDecorationTheme)를 따른다.
///
/// 값은 [onChanged]로 ViewModel에 바로 전달하고, 화면은 ViewModel의 상태만 보여준다. (MVVM)
/// 처음 값은 [initialValue]로 한 번만 넣는다. 이후에는 사용자가 입력한 글자가 그대로 유지된다.
/// 입력칸을 눌러 쓰는 중이고 글자가 있으면 오른쪽에 전체 지우기(ⓧ) 버튼이 나온다. ([ClearableFieldBuilder])
///
/// ```dart
/// AppTextField(hint: '이름', maxLength: 50, onChanged: viewModel.setPersonName, errorText: state.personNameError)
/// ```
///
/// ## 여러 줄 입력칸의 지우기 버튼
/// 보통은 입력칸 세로 가운데에 놓이는데, 메모처럼 여러 줄이면 줄이 늘수록 버튼이 가운데로 내려가 글자와 겹쳐 보인다.
/// 그래서 여러 줄([maxLines] ≠ 1)일 때는 **첫 줄 높이의 오른쪽 위**에 고정한다.
/// 입력칸을 누르면 버튼 자리만큼 오른쪽을 비워 둬서, 글자가 버튼 밑으로 들어가지 않는다.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.onChanged,
    this.initialValue,
    this.hint,
    this.errorText,
    this.maxLength,
    this.maxLines = 1,
    this.textInputAction = TextInputAction.next,
  });

  final StringCallback onChanged;
  final String? initialValue;
  final String? hint;
  final String? errorText;

  /// 최대 글자 수. 넘으면 더 입력되지 않는다. (입력칸 아래 글자 수 표시는 숨김)
  final int? maxLength;
  final int? maxLines;

  /// 키보드 완료 버튼의 동작 (다음 칸으로 / 완료)
  final TextInputAction textInputAction;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialValue);
  final FocusNode _focusNode = FocusNode();

  /// 여러 줄 입력칸에서 지우기 버튼 자리 (버튼 48 - 겹쳐도 되는 여백)
  static const double _clearButtonSpace = 44;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final multiline = widget.maxLines != 1;
    return ClearableFieldBuilder(
      controller: _controller,
      focusNode: _focusNode,
      onCleared: () => widget.onChanged(''),
      builder: (context, clearButton, focused) {
        final field = TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: widget.onChanged,
          maxLength: widget.maxLength,
          maxLines: widget.maxLines,
          textInputAction: widget.textInputAction,
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: widget.errorText,
            counterText: '',
            suffixIcon: multiline ? null : clearButton,
            // 여러 줄: 쓰는 중에는 버튼 자리만큼 오른쪽을 비워 둔다. (글자가 버튼 밑으로 들어가지 않게)
            contentPadding: multiline && focused
                ? const EdgeInsets.fromLTRB(AppSpacing.md, 14, _clearButtonSpace, 14)
                : null,
          ),
        );
        if (!multiline) return field;
        // 첫 줄 가운데(위 여백 14 + 줄 높이의 절반)와 버튼(48) 가운데를 맞춘다.
        return Stack(
          children: [
            field,
            if (clearButton != null) Positioned(top: 1, right: 0, child: clearButton),
          ],
        );
      },
    );
  }
}
