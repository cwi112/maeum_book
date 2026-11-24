import 'package:maeum_book/core/theme/app_text_styles.dart';
import 'package:material_ui/material_ui.dart';

/// 앱 공통 글자 위젯. 스타일 이름만 골라 쓰면 된다.
///
/// ```dart
/// AppText.headline('마음장부')
/// AppText.title('이번 달 보낸 마음')
/// AppText.body('본문 내용')
/// AppText.caption('2026.11.24', color: AppColors.textHint)
/// AppText.amount('50,000원', color: AppColors.sent)
/// AppText('직접 스타일 지정', style: AppTextStyles.body.bold)
/// ```
///
/// - [color]: 색만 바꿀 때
/// - [align]: 정렬 (가운데 등)
/// - [maxLines]: 줄 수 제한. 넘치면 "…"으로 줄인다.
class AppText extends StatelessWidget {
  const AppText(this.text, {super.key, this.style = AppTextStyles.body, this.color, this.align, this.maxLines});

  const AppText.headline(this.text, {super.key, this.color, this.align, this.maxLines})
    : style = AppTextStyles.headline;

  const AppText.title(this.text, {super.key, this.color, this.align, this.maxLines}) : style = AppTextStyles.title;

  const AppText.subtitle(this.text, {super.key, this.color, this.align, this.maxLines})
    : style = AppTextStyles.subtitle;

  const AppText.body(this.text, {super.key, this.color, this.align, this.maxLines}) : style = AppTextStyles.body;

  const AppText.bodySmall(this.text, {super.key, this.color, this.align, this.maxLines})
    : style = AppTextStyles.bodySmall;

  const AppText.caption(this.text, {super.key, this.color, this.align, this.maxLines}) : style = AppTextStyles.caption;

  const AppText.label(this.text, {super.key, this.color, this.align, this.maxLines}) : style = AppTextStyles.label;

  const AppText.amountLarge(this.text, {super.key, this.color, this.align, this.maxLines})
    : style = AppTextStyles.amountLarge;

  const AppText.amount(this.text, {super.key, this.color, this.align, this.maxLines}) : style = AppTextStyles.amount;

  final String text;
  final TextStyle style;
  final Color? color;
  final TextAlign? align;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: color == null ? style : style.copyWith(color: color),
      textAlign: align,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}
