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
  const AppText(this.text, {super.key, this._style, this.color, this.align, this.maxLines}) : _kind = _Kind.body;

  const AppText.headline(this.text, {super.key, this.color, this.align, this.maxLines})
    : _style = null,
      _kind = _Kind.headline;

  const AppText.title(this.text, {super.key, this.color, this.align, this.maxLines})
    : _style = null,
      _kind = _Kind.title;

  const AppText.subtitle(this.text, {super.key, this.color, this.align, this.maxLines})
    : _style = null,
      _kind = _Kind.subtitle;

  const AppText.body(this.text, {super.key, this.color, this.align, this.maxLines}) : _style = null, _kind = _Kind.body;

  const AppText.bodySmall(this.text, {super.key, this.color, this.align, this.maxLines})
    : _style = null,
      _kind = _Kind.bodySmall;

  const AppText.caption(this.text, {super.key, this.color, this.align, this.maxLines})
    : _style = null,
      _kind = _Kind.caption;

  const AppText.label(this.text, {super.key, this.color, this.align, this.maxLines})
    : _style = null,
      _kind = _Kind.label;

  const AppText.amountLarge(this.text, {super.key, this.color, this.align, this.maxLines})
    : _style = null,
      _kind = _Kind.amountLarge;

  const AppText.amount(this.text, {super.key, this.color, this.align, this.maxLines})
    : _style = null,
      _kind = _Kind.amount;
  final String text;

  /// 직접 지정한 스타일. 없으면 [_kind]의 스타일을 그릴 때 정한다. (화면 모드에 맞는 글자 색이 나오도록)
  final TextStyle? _style;
  final _Kind _kind;
  final Color? color;
  final TextAlign? align;
  final int? maxLines;

  TextStyle get style =>
      _style ??
      switch (_kind) {
        _Kind.headline => AppTextStyles.headline,
        _Kind.title => AppTextStyles.title,
        _Kind.subtitle => AppTextStyles.subtitle,
        _Kind.body => AppTextStyles.body,
        _Kind.bodySmall => AppTextStyles.bodySmall,
        _Kind.caption => AppTextStyles.caption,
        _Kind.label => AppTextStyles.label,
        _Kind.amountLarge => AppTextStyles.amountLarge,
        _Kind.amount => AppTextStyles.amount,
      };

  @override
  Widget build(BuildContext context) {
    final base = style;
    return Text(
      text,
      style: color == null ? base : base.copyWith(color: color),
      textAlign: align,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}

enum _Kind { headline, title, subtitle, body, bodySmall, caption, label, amountLarge, amount }
