import 'package:maeum_book/core/theme/app_colors.dart';
import 'package:material_ui/material_ui.dart';

/// 입력칸 오른쪽의 "전체 지우기"(ⓧ) 버튼. 보통은 [ClearableFieldBuilder]가 알맞을 때만 만들어 준다.
class ClearTextButton extends StatelessWidget {
  const ClearTextButton({super.key, required this.controller, required this.onCleared});

  final TextEditingController controller;
  final VoidCallback onCleared;

  static const String tooltip = '전체 지우기';

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.cancel_rounded, size: 20, color: AppColors.textHint),
      tooltip: tooltip,
      onPressed: () {
        controller.clear();
        onCleared();
      },
    );
  }
}

/// 입력칸을 **누르고 있을 때(포커스) + 글자가 있을 때만** 지우기 버튼을 만들어 [builder]에 넘긴다.
///
/// ```dart
/// ClearableFieldBuilder(
///   controller: _controller,
///   focusNode: _focusNode,
///   onCleared: () => widget.onChanged(''),
///   builder: (context, clearButton, focused) => TextField(
///     controller: _controller,
///     focusNode: _focusNode,
///     decoration: InputDecoration(suffixIcon: clearButton),
///   ),
/// )
/// ```
/// - 버튼이 없을 때는 `null`을 넘기므로 오른쪽 자리를 비워 두지 않는다. → '원' 같은 고정 글자가 오른쪽 끝에 붙어 있다가,
///   버튼이 나오면 그 왼쪽으로 비켜서 서로 겹치지 않는다.
/// - [focused]: 여러 줄 입력칸이 버튼 자리를 미리 비워 둘 때 쓴다. (글자를 칠 때마다 줄바꿈이 바뀌지 않게)
class ClearableFieldBuilder extends StatelessWidget {
  const ClearableFieldBuilder({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onCleared,
    required this.builder,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onCleared;
  final Widget Function(BuildContext context, Widget? clearButton, bool focused) builder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([controller, focusNode]),
      builder: (context, _) {
        final focused = focusNode.hasFocus;
        final show = focused && controller.text.isNotEmpty;
        return builder(context, show ? ClearTextButton(controller: controller, onCleared: onCleared) : null, focused);
      },
    );
  }
}
