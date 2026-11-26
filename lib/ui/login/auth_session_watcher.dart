import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';

/// 앱 전체를 감싸서 **로그인 · 서버 · 인터넷 상태**를 지켜보는 위젯. (app.dart의 builder에서 한 번만 쓴다)
///
/// | 언제 | 하는 일 |
/// |---|---|
/// | 로그인 직후 · 앱을 켤 때(자동 로그인) · 앱으로 돌아올 때 | 회원이면 서버의 장부를 받아 기기 사본을 바꾼다 (다른 기기에서 고친 내용 반영) |
/// | 사용자가 하지 않은 로그아웃(만료 · 다른 기기에서 탈퇴 · Apple 연결 해제) | 라우터가 시작 화면으로 보내고, 여기서 "로그인이 만료됐어요" 토스트 |
/// | 회원인데 인터넷이 끊기거나 약함 | "인터넷 연결" 토스트를 **끊길 때마다 1번만**. 다시 연결되면 초기화 |
///
/// 비회원은 인터넷 없이 쓰므로 인터넷 토스트를 띄우지 않는다.
class AuthSessionWatcher extends ConsumerStatefulWidget {
  const AuthSessionWatcher({super.key, required this.child});

  final Widget child;

  static const offlineMessage = '인터넷 연결이 끊겼거나 불안정해요. 연결될 때까지 기록을 저장할 수 없어요';

  @override
  ConsumerState<AuthSessionWatcher> createState() => _AuthSessionWatcherState();
}

class _AuthSessionWatcherState extends ConsumerState<AuthSessionWatcher> {
  late final AppLifecycleListener _lifecycle;

  /// 이번 "끊김" 동안 이미 알렸는지 (1번만 띄우기)
  bool _offlineNotified = false;

  bool get _isMember => ref.read(currentUserIdProvider) != null;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _onResume);
    // 첫 화면을 그린 뒤에 시작 (provider를 build 중에 바꾸지 않도록)
    WidgetsBinding.instance.addPostFrameCallback((_) => _onResume());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  /// 앱으로 돌아올 때 마지막으로 받아 온 시각
  DateTime? _lastResumePull;

  /// 앱으로 돌아올 때 이 시간 안에 이미 받아 왔으면 다시 받지 않는다.
  /// (카톡 보고 돌아오기처럼 잠깐 나갔다 오는 일이 잦아서, 매번 장부 전체를 받으면 서버 전송량이 크게 는다)
  /// 로그인 · 인터넷 재연결 때는 이 시간과 상관없이 바로 받는다.
  static const resumePullInterval = Duration(minutes: 2);

  void _onResume() {
    if (!mounted) return;
    ref.read(authRepositoryProvider).checkProviderConnection();
    final now = DateTime.now();
    final last = _lastResumePull;
    if (last != null && now.difference(last) < resumePullInterval) return;
    _lastResumePull = now;
    _pull();
  }

  void _pull() => ref.read(memberSyncProvider.notifier).pull().catchError((Object e) => debugPrint('[Sync] $e'));

  void _notifyOffline() {
    if (!mounted || !_isMember || _offlineNotified) return;
    _offlineNotified = true;
    context.showToast(AuthSessionWatcher.offlineMessage, type: ToastType.error);
  }

  @override
  Widget build(BuildContext context) {
    // 로그인 만료 → 이유 안내 (화면 이동은 app_router.dart의 redirect가 한다)
    ref.listen(sessionExpiredProvider, (_, next) {
      if (next.hasValue && mounted) context.showToast(AuthFailureType.sessionExpired.message, type: ToastType.info);
    });
    // 로그인한 사람이 바뀌면(로그인 · 자동 로그인) 그 계정의 장부를 받아 온다.
    ref.listen(currentUserIdProvider, (previous, next) {
      // 로그인 · 로그아웃하면 샘플 둘러보기는 끝낸다. (바뀐 계정의 실제 장부를 보여주기 위해)
      if (next != previous) ref.read(sampleModeProvider.notifier).exit();
      if (next != null && next != previous) _pull();
    });
    // 인터넷 끊김 → 1번 알림, 다시 연결 → 초기화 + 최신 장부 받기
    ref.listen(isOnlineProvider, (previous, next) {
      final online = next.value;
      if (online == false) _notifyOffline();
      if (online == true && previous?.value == false) {
        _offlineNotified = false;
        _pull();
      }
    });
    // 연결은 돼 있지만 너무 느려서 서버 작업이 실패함 → 같은 알림 (1번)
    ref.listen(memberSyncProvider, (_, _) => _notifyOffline());
    return widget.child;
  }
}
