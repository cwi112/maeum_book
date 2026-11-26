import 'package:go_router/go_router.dart';
import 'package:maeum_book/core/errors/network_exception.dart';
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
/// 화면 이동은 [pushOnce](연타해도 한 번만), go_router의 `context.go` · `context.pop()`을 쓴다.
/// ```
extension BuildContextX on BuildContext {
  // ── 화면 이동 ──────────────────────────
  /// 마지막으로 쌓은 화면 (라우터마다 따로 기억한다. 테스트마다 새 라우터라 서로 섞이지 않게)
  static final _lastPush = Expando<(String, DateTime)>();

  /// 연타 방지 간격: 이 시간 안에 다시 누르면 화면을 또 쌓지 않는다.
  static const pushGuard = Duration(milliseconds: 600);

  /// 화면 위에 새 화면을 쌓는다. (go_router의 push) 같은 버튼을 빠르게 두 번 눌러도 **한 번만** 쌓인다.
  /// 막힌 두 번째 누름은 null을 돌려준다.
  Future<T?> pushOnce<T extends Object?>(String location) {
    final now = DateTime.now();
    final router = GoRouter.of(this);
    final last = _lastPush[router];
    if (last != null && last.$1 == location && now.difference(last.$2) < pushGuard) return Future.value();
    _lastPush[router] = (location, now);
    return push<T>(location);
  }

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
  /// [actionLabel]·[onAction]을 넣으면 "되돌리기" 같은 버튼이 붙는다.
  void showToast(String message, {ToastType type = ToastType.success, String? actionLabel, VoidCallback? onAction}) =>
      AppToast.show(this, message, type: type, actionLabel: actionLabel, onAction: onAction);

  /// 실패 토스트. 인터넷 문제([NetworkException])면 연결 안내를, 아니면 [fallback] 문구를 띄운다.
  ///
  /// ```dart
  /// onError: (e) => context.showErrorToast(e, '저장하지 못했어요. 잠시 후 다시 시도해 주세요'),
  /// ```
  void showErrorToast(Object error, String fallback) =>
      showToast(error is NetworkException ? NetworkException.message : fallback, type: ToastType.error);

  void hideKeyboard() => FocusScope.of(this).unfocus();
}
