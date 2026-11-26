import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';
import 'package:maeum_book/router/app_router.dart';

/// 앱 전체를 감싸서 **로그인 만료**를 지켜보는 위젯. (app.dart의 builder에서 한 번만 쓴다)
///
/// - 사용자가 직접 하지 않은 로그아웃(토큰 갱신 거절 · 다른 기기에서 탈퇴 · Apple 연결 해제)이 일어나면
///   어느 화면에 있든 "로그인이 만료됐어요" 토스트와 [다시 로그인] 버튼을 띄운다.
/// - 앱을 켤 때와 다시 열 때(백그라운드 → 화면) 로그인 방법 쪽 연결이 살아 있는지 확인한다. (Apple)
/// - 로그인하지 않아도 앱은 그대로 쓸 수 있으므로, 강제로 로그인 화면으로 보내지는 않는다.
class AuthSessionWatcher extends ConsumerStatefulWidget {
  const AuthSessionWatcher({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AuthSessionWatcher> createState() => _AuthSessionWatcherState();
}

class _AuthSessionWatcherState extends ConsumerState<AuthSessionWatcher> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _checkConnection);
    _checkConnection();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _checkConnection() => ref.read(authRepositoryProvider).checkProviderConnection();

  void _onExpired() {
    if (!mounted) return;
    context.showToast(
      AuthFailureType.sessionExpired.message,
      type: ToastType.info,
      actionLabel: '다시 로그인',
      // 이 위젯은 Navigator 바깥(앱 맨 위)에 있어서 context.push 대신 라우터를 직접 쓴다.
      onAction: () => ref.read(appRouterProvider).push(AppRoutes.login),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sessionExpiredProvider, (_, next) {
      if (next.hasValue) _onExpired();
    });
    return widget.child;
  }
}
