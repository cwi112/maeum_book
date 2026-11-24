import 'package:maeum_book/core/theme/app_colors.dart';
import 'package:maeum_book/core/theme/app_dimens.dart';
import 'package:maeum_book/core/widgets/app_text.dart';
import 'package:material_ui/material_ui.dart';

/// 합계 금액을 보여주는 카드. (보내요·받아요 화면 상단)
///
/// ```dart
/// SummaryCard(label: '지금까지 보낸 마음', amount: 50000.won, count: 3, color: AppColors.sent)
/// ```
class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.label, required this.amount, required this.count, required this.color});

  final String label;
  final String amount;
  final int count;

  /// 금액 색 (보냄: AppColors.sent, 받음: AppColors.received)
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.caption(label),
                  const SizedBox(height: AppSpacing.xs),
                  AppText.amountLarge(amount, color: color),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(AppRadius.sm)),
              child: AppText.label('$count건', color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
