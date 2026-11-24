import 'package:material_ui/material_ui.dart';

/// 글자 스타일을 조금씩 바꿔 쓰기 위한 확장.
///
/// ```dart
/// AppTextStyles.body.bold
/// AppTextStyles.caption.withColor(AppColors.primary)
/// AppTextStyles.amount.size(22)
/// ```
extension TextStyleX on TextStyle {
  TextStyle get regular => copyWith(fontWeight: FontWeight.w400);
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);
  TextStyle get bold => copyWith(fontWeight: FontWeight.w700);
  TextStyle withColor(Color color) => copyWith(color: color);
  TextStyle size(double fontSize) => copyWith(fontSize: fontSize);
  TextStyle lineHeight(double height) => copyWith(height: height);
}
