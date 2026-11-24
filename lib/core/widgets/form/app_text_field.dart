import 'package:maeum_book/core/define/typedefs.dart';
import 'package:material_ui/material_ui.dart';

/// 앱 공통 글자 입력칸. 모양은 테마(app_theme.dart의 inputDecorationTheme)를 따른다.
///
/// 값은 [onChanged]로 ViewModel에 바로 전달하고, 화면은 ViewModel의 상태만 보여준다. (MVVM)
/// 처음 값은 [initialValue]로 한 번만 넣는다. 이후에는 사용자가 입력한 글자가 그대로 유지된다.
///
/// ```dart
/// AppTextField(hint: '이름', maxLength: 50, onChanged: viewModel.setPersonName, errorText: state.personNameError)
/// ```
class AppTextField extends StatelessWidget {
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
  final int maxLines;

  /// 키보드 완료 버튼의 동작 (다음 칸으로 / 완료)
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      maxLength: maxLength,
      maxLines: maxLines,
      textInputAction: textInputAction,
      decoration: InputDecoration(hintText: hint, errorText: errorText, counterText: ''),
    );
  }
}
