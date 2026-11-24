import 'package:maeum_book/core/theme/app_colors.dart';
import 'package:maeum_book/core/theme/app_dimens.dart';
import 'package:maeum_book/core/widgets/app_text.dart';
import 'package:material_ui/material_ui.dart';

/// 입력 폼의 항목 하나. "제목 + 필수/선택 표시 + 입력 위젯 + 오류 문구" 묶음이다.
///
/// ```dart
/// FormSection(label: '금액', isRequired: true, child: AmountField(...))
/// FormSection(label: '메모', child: AppTextField(...))   // isRequired 기본값 false = 선택
/// ```
/// [errorText]는 칩처럼 자체 오류 표시가 없는 입력 위젯 아래에 문구를 띄울 때 쓴다.
class FormSection extends StatelessWidget {
  const FormSection({super.key, required this.label, required this.child, this.isRequired = false, this.errorText});

  final String label;
  final Widget child;

  /// 필수 입력이면 true (제목 옆에 "필수" 배지)
  final bool isRequired;

  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppText.label(label),
            const SizedBox(width: AppSpacing.xs + 2),
            _RequiredBadge(isRequired: isRequired),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.xs + 2),
          AppText.caption(errorText!, color: AppColors.error),
        ],
      ],
    );
  }
}

/// "필수"(테라코타) / "선택"(회색) 작은 배지
class _RequiredBadge extends StatelessWidget {
  const _RequiredBadge({required this.isRequired});

  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isRequired ? AppColors.primaryLight : AppColors.divider,
        borderRadius: BorderRadius.circular(6),
      ),
      child: AppText.caption(isRequired ? '필수' : '선택', color: isRequired ? AppColors.primary : AppColors.textSecondary),
    );
  }
}
