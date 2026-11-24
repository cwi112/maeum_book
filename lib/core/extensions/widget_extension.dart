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

/// 자동화 테스트용 이름표를 붙이는 확장. 이름 목록은 `TestIds`(test_ids.dart) 참고.
///
/// ```dart
/// FilledButton(...).testId(TestIds.formSave)
/// ```
/// `Semantics.identifier`는 화면 낭독(TalkBack·VoiceOver)에는 읽히지 않고,
/// 테스트 도구에만 resource-id / accessibilityIdentifier로 보인다. 그래서 사용자에게는 영향이 없다.
extension TestIdX on Widget {
  Widget testId(String id) => Semantics(identifier: id, child: this);

  /// [id]가 있을 때만 이름표를 붙인다. 컴포넌트에서 testId를 선택 파라미터로 받을 때 쓴다.
  Widget testIdOrSelf(String? id) => id == null ? this : testId(id);
}
