import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';

/// 앱 전체를 감싸서 **로그인 만료**를 지켜보는 위젯. (app.dart의 builder에서 한 번만 쓴다)
///
/// - 사용자가 직접 하지 않은 로그아웃(토큰 갱신 거절 · 다른 기기에서 탈퇴 · Apple 연결 해제)이 일어나면
///   라우터가 시작(로그인) 화면으로 보내고, 여기서는 "로그인이 만료됐어요" 토스트로 이유를 알린다.
/// - 앱을 켤 때와 다시 열 때(백그라운드 → 화면) 로그인 방법 쪽 연결이 살아 있는지 확인한다. (Apple)
/// - 시작 화면에서 다시 로그인하거나 "로그인 없이 시작하기"를 고를 수 있다.
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
    // 화면 이동은 라우터가 한다: 로그인이 풀리면 시작(로그인) 화면으로 자동으로 간다. (app_router.dart의 redirect)
    // 여기서는 왜 로그인 화면이 나왔는지만 알려 준다.
    context.showToast(AuthFailureType.sessionExpired.message, type: ToastType.info);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sessionExpiredProvider, (_, next) {
      if (next.hasValue) _onExpired();
    });
    return widget.child;
  }
}
