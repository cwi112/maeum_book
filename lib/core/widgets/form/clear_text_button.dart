import 'package:maeum_book/core/theme/app_colors.dart';
import 'package:material_ui/material_ui.dart';

/// 입력칸 오른쪽의 "전체 지우기"(ⓧ) 버튼. 글자가 있을 때만 보인다.
///
/// ```dart
/// TextField(
///   controller: _controller,
///   decoration: InputDecoration(suffixIcon: ClearTextButton(controller: _controller, onCleared: () => onChanged(''))),
/// )
/// ```
/// 누르면 [controller]를 비우고 [onCleared]를 부른다. (ViewModel 값도 같이 비우도록)
/// 여러 줄 입력칸은 [AppTextField]가 이 버튼을 첫 줄 높이(오른쪽 위)에 따로 놓는다.
class ClearTextButton extends StatelessWidget {
  const ClearTextButton({super.key, required this.controller, required this.onCleared});

  final TextEditingController controller;
  final VoidCallback onCleared;

  static const String tooltip = '전체 지우기';

  @override
  Widget build(BuildContext context) {
    // 글자가 바뀔 때마다 이 버튼만 다시 그린다.
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => controller.text.isEmpty
          ? const SizedBox.shrink()
          : IconButton(
              icon: Icon(Icons.cancel_rounded, size: 20, color: AppColors.textHint),
              tooltip: tooltip,
              onPressed: () {
                controller.clear();
                onCleared();
              },
            ),
    );
  }
}
