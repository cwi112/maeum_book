import 'package:maeum_book/core/theme/app_colors.dart';
import 'package:maeum_book/core/theme/app_dimens.dart';
import 'package:maeum_book/core/widgets/app_text.dart';
import 'package:material_ui/material_ui.dart';

/// 토스트 종류. 종류에 따라 아이콘과 색이 바뀐다.
enum ToastType {
  success(Icons.check_circle_rounded, AppColors.success),
  error(Icons.error_rounded, AppColors.error),
  info(Icons.info_rounded, AppColors.secondary);

  const ToastType(this.icon, this.color);

  final IconData icon;
  final Color color;
}

/// 화면 아래에 잠깐 떴다 사라지는 알림. (Material SnackBar를 앱 디자인에 맞게 꾸민 것)
///
/// 보통은 `context.showToast('기록했어요')` 확장으로 쓴다. (build_context_extension.dart)
///
/// ## 왜 SnackBar인가
/// 앱 전체에 하나뿐인 ScaffoldMessenger가 띄우기 때문에, 토스트를 띄운 직후 화면을 닫아도(pop)
/// 다음 화면 위에 그대로 남아 보인다. 그래서 "저장 → 화면 닫기 → 성공 토스트" 흐름에 알맞다.
abstract final class AppToast {
  static void show(BuildContext context, String message, {ToastType type = ToastType.success}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar() // 연달아 띄우면 앞의 것은 바로 치우고 새 것만 보여준다.
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.textPrimary,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          content: Row(
            children: [
              Icon(type.icon, color: type.color, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: AppText.body(message, color: AppColors.surface)),
            ],
          ),
        ),
      );
  }
}
