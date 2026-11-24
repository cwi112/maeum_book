import 'package:maeum_book/core/theme/app_colors.dart';
import 'package:maeum_book/core/theme/app_dimens.dart';
import 'package:maeum_book/core/widgets/app_text.dart';
import 'package:material_ui/material_ui.dart';

/// 목록이 비어 있을 때 보여주는 공통 화면.
///
/// ```dart
/// EmptyView(icon: Icons.outbox_outlined, title: '아직 보낸 마음이 없어요', message: '첫 마음을 기록해 보세요')
/// ```
class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.icon, required this.title, this.message});

  final IconData icon;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppText.title(title, align: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              AppText.body(message!, color: AppColors.textSecondary, align: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}
