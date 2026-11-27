import 'package:maeum_book/core/extensions/widget_extension.dart';
import 'package:maeum_book/core/theme/app_colors.dart';
import 'package:maeum_book/core/theme/app_dimens.dart';
import 'package:maeum_book/core/widgets/app_text.dart';
import 'package:material_ui/material_ui.dart';

/// 아래에서 올라오는 "하나 고르기" 창. 고른 값을 돌려준다. (바깥을 누르거나 내리면 null)
///
/// ```dart
/// final mode = await AppChoiceSheet.show<ThemeMode>(
///   context,
///   title: '화면 모드',
///   values: ThemeMode.values,
///   selected: current,
///   labelOf: (mode) => mode.label,
/// );
/// ```
/// ```
/// ┌──────────────────────────────┐
/// │  화면 모드                    │
/// │  ◐ 시스템 설정 따라가기   ✓   │
/// │  ☀ 라이트                     │
/// │  ☾ 다크                       │
/// └──────────────────────────────┘
/// ```
class AppChoiceSheet<T> extends StatelessWidget {
  const AppChoiceSheet({
    super.key,
    required this.title,
    required this.values,
    required this.selected,
    required this.labelOf,
    this.iconOf,
    this.descriptionOf,
    this.testIdOf,
  });

  final String title;
  final List<T> values;
  final T? selected;
  final String Function(T value) labelOf;
  final IconData Function(T value)? iconOf;

  /// 항목 아래 작은 설명 (없으면 생략)
  final String? Function(T value)? descriptionOf;

  /// 자동화 테스트용 이름 (항목마다)
  final String? Function(T value)? testIdOf;

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required List<T> values,
    required T? selected,
    required String Function(T value) labelOf,
    IconData Function(T value)? iconOf,
    String? Function(T value)? descriptionOf,
    String? Function(T value)? testIdOf,
  }) => showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    builder: (_) => AppChoiceSheet<T>(
      title: title,
      values: values,
      selected: selected,
      labelOf: labelOf,
      iconOf: iconOf,
      descriptionOf: descriptionOf,
      testIdOf: testIdOf,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.sm),
              child: AppText.subtitle(title),
            ),
            for (final value in values)
              ListTile(
                leading: iconOf == null
                    ? null
                    : Icon(iconOf!(value), color: value == selected ? AppColors.primary : AppColors.textSecondary),
                title: AppText.body(labelOf(value), color: value == selected ? AppColors.primary : null),
                subtitle: switch (descriptionOf?.call(value)) {
                  final String text => AppText.caption(text),
                  null => null,
                },
                trailing: value == selected ? Icon(Icons.check_rounded, color: AppColors.primary) : null,
                onTap: () => Navigator.of(context).pop(value),
              ).testIdOrSelf(testIdOf?.call(value)),
          ],
        ),
      ),
    );
  }
}
