import 'package:maeum_book/core/define/test_ids.dart';
import 'package:maeum_book/core/extensions/widget_extension.dart';
import 'package:maeum_book/core/theme/app_colors.dart';
import 'package:maeum_book/core/theme/app_dimens.dart';
import 'package:maeum_book/core/widgets/app_text.dart';
import 'package:material_ui/material_ui.dart';

/// 토스트 종류. 종류에 따라 아이콘과 색이 바뀐다.
enum ToastType {
  success(Icons.check_circle_rounded),
  error(Icons.error_rounded),
  info(Icons.info_rounded);

  const ToastType(this.icon);

  final IconData icon;

  /// 화면 모드(라이트 · 다크)에 맞는 색
  Color get color => switch (this) {
    ToastType.success => AppColors.success,
    ToastType.error => AppColors.error,
    ToastType.info => AppColors.secondary,
  };
}

/// 화면 아래에 잠깐 떴다 사라지는 알림. (Material SnackBar를 앱 디자인에 맞게 꾸민 것)
///
/// 보통은 `context.showToast('기록했어요')` 확장으로 쓴다. (build_context_extension.dart)
///
/// ## 왜 SnackBar인가
/// 앱 전체에 하나뿐인 ScaffoldMessenger가 띄우기 때문에, 토스트를 띄운 직후 화면을 닫아도(pop)
/// 다음 화면 위에 그대로 남아 보인다. 그래서 "저장 → 화면 닫기 → 성공 토스트" 흐름에 알맞다.
///
/// ## 되돌리기 버튼
/// [actionLabel]과 [onAction]을 넘기면 오른쪽에 버튼이 생긴다. (예: 삭제 후 "되돌리기")
/// 버튼이 있을 때는 누를 시간을 주려고 4초 동안 보여준다.
abstract final class AppToast {
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.success,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final hasAction = actionLabel != null && onAction != null;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar() // 연달아 띄우면 앞의 것은 바로 치우고 새 것만 보여준다.
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.textPrimary,
          duration: Duration(seconds: hasAction ? 4 : 2),
          margin: const EdgeInsets.all(AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          action: hasAction
              ? SnackBarAction(label: actionLabel, textColor: AppColors.secondary, onPressed: onAction)
              : null,
          content: Row(
            children: [
              Icon(type.icon, color: type.color, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: AppText.body(message, color: AppColors.surface)),
            ],
          ).testId(TestIds.toast),
        ),
      );
  }
}
