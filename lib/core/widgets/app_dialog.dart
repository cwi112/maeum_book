import 'package:maeum_book/core/define/test_ids.dart';
import 'package:maeum_book/core/extensions/widget_extension.dart';
import 'package:maeum_book/core/theme/app_colors.dart';
import 'package:maeum_book/core/theme/app_dimens.dart';
import 'package:maeum_book/core/widgets/app_text.dart';
import 'package:material_ui/material_ui.dart';

/// 앱 공통 확인 창.
abstract final class AppDialog {
  /// "정말 할까요?" 확인 창을 띄우고, 확인을 누르면 true를 돌려준다. (취소·바깥 누름은 false)
  ///
  /// ```dart
  /// if (await AppDialog.confirm(context, title: '모두 지울까요?', confirmLabel: '지우기', isDestructive: true)) { ... }
  /// ```
  /// [isDestructive]: 되돌릴 수 없는 작업이면 true. 확인 버튼이 빨간색이 된다.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    String? message,
    String confirmLabel = '확인',
    String cancelLabel = '취소',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: AppText.title(title),
        content: message == null ? null : AppText.body(message, color: AppColors.textSecondary),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            child: Text(cancelLabel),
          ).testId(TestIds.dialogCancel),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: isDestructive ? FilledButton.styleFrom(backgroundColor: AppColors.error) : null,
            child: Text(confirmLabel),
          ).testId(TestIds.dialogConfirm),
        ],
      ),
    );
    return result ?? false;
  }
}
