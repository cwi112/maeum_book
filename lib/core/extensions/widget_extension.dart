import 'package:material_ui/material_ui.dart';

/// 위젯을 감싸는 코드를 짧게 쓰기 위한 확장.
///
/// ```dart
/// AppText.title('제목').paddingAll(AppSpacing.md)
/// AppText.body('본문').paddingSymmetric(horizontal: AppSpacing.screen)
/// SummaryCard(...).expanded()
/// ```
extension WidgetX on Widget {
  Widget padding(EdgeInsetsGeometry padding) => Padding(padding: padding, child: this);

  Widget paddingAll(double value) => Padding(padding: EdgeInsets.all(value), child: this);

  Widget paddingSymmetric({double horizontal = 0, double vertical = 0}) => Padding(
    padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
    child: this,
  );

  Widget paddingOnly({double left = 0, double top = 0, double right = 0, double bottom = 0}) => Padding(
    padding: EdgeInsets.only(left: left, top: top, right: right, bottom: bottom),
    child: this,
  );

  Widget center() => Center(child: this);

  Widget expanded({int flex = 1}) => Expanded(flex: flex, child: this);

  Widget onTap(VoidCallback? onTap) => GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: this);
}
