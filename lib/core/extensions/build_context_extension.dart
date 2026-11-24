import 'package:maeum_book/core/widgets/app_toast.dart';
import 'package:material_ui/material_ui.dart';

/// [BuildContext]에서 자주 쓰는 기능을 짧게 부르기 위한 확장.
///
/// ```dart
/// context.textTheme.titleLarge
/// context.screenSize.width
/// context.showToast('기록했어요');
/// context.showToast('저장하지 못했어요', type: ToastType.error);
///
/// 화면 이동은 go_router의 `context.push(AppRoutes...)`, `context.pop()`을 쓴다.
/// ```
extension BuildContextX on BuildContext {
  // ── 테마 ───────────────────────────────
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  // ── 화면 크기 ──────────────────────────
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// 상태바·홈 인디케이터 등이 차지하는 영역
  EdgeInsets get safePadding => MediaQuery.paddingOf(this);

  // ── 알림·키보드 ────────────────────────
  /// 화면 아래에 토스트를 띄운다. 기본은 성공(초록 체크). 자세한 동작은 [AppToast] 참고.
  void showToast(String message, {ToastType type = ToastType.success}) => AppToast.show(this, message, type: type);

  void hideKeyboard() => FocusScope.of(this).unfocus();
}
