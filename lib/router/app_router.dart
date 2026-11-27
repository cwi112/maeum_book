import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/core/utils/app_monitor.dart';
import 'package:maeum_book/data/data.dart';
import 'package:maeum_book/ui/entry/entry.dart';
import 'package:maeum_book/ui/event/event.dart';
import 'package:maeum_book/ui/event_type/event_type.dart';
import 'package:maeum_book/ui/ledger/ledger.dart';
import 'package:maeum_book/ui/login/login.dart';
import 'package:maeum_book/ui/main/main.dart';
import 'package:maeum_book/ui/settings/settings.dart';
import 'package:maeum_book/ui/stats/stats.dart';

/// 앱의 화면 이동 지도. "어떤 경로(URL)면 어떤 화면을 보여줄지"를 정한다.
///
/// ## 구조
/// ```
/// /                       → /sent 로 이동
/// ┌ 하단 탭 (StatefulShellRoute) ─────────────┐
/// │ /sent  /received  /stats  /settings       │  탭 전환: context.go(...)
/// └───────────────────────────────────────────┘
/// /entry/new/:direction   → 탭 위에 전체 화면으로 쌓임   context.push(...)
/// ```
///
/// ## go와 push의 차이
/// - `context.go(경로)`: 그 화면으로 **바꾼다**. 뒤로 가기 기록이 쌓이지 않는다. (탭 전환에 사용)
/// - `context.push(경로)`: 지금 화면 위에 **쌓는다**. 뒤로 가기로 돌아올 수 있다. (상세·입력 화면에 사용)
///
/// Provider로 만든 이유: 테스트마다 새 ProviderScope를 쓰면 라우터도 새로 만들어져
/// 이전 테스트의 화면 위치가 남지 않는다.
final appRouterProvider = Provider<GoRouter>((ref) {
  // ── 시작 화면 문지기 ──
  // 로그인했거나 "로그인 없이 시작하기"를 골랐으면 앱으로, 아니면 로그인(시작) 화면으로 보낸다.
  // 로그인 · 로그아웃 · 탈퇴 · 만료 · 비회원 선택이 바뀔 때마다 redirect를 다시 계산한다.
  bool canEnterApp() => ref.read(authRepositoryProvider).currentUser != null || ref.read(guestModeProvider);

  // ValueNotifier는 값이 "바뀔 때만" 알린다. 그래서 비회원 → 회원처럼 들어갈 수 있는 상태가 그대로면
  // 라우터를 다시 계산하지 않는다. (설정에서 연 로그인 화면이 스스로 닫히는 것과 겹치지 않게)
  final refresh = ValueNotifier<bool>(canEnterApp());
  void update() => refresh.value = canEnterApp();
  ref.listen(currentUserProvider, (_, _) => update());
  ref.listen(guestModeProvider, (_, _) => update());
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.initial,
    refreshListenable: refresh,
    redirect: (context, state) {
      final atLogin = state.matchedLocation == AppRoutes.login;
      if (!canEnterApp()) return atLogin ? null : AppRoutes.login;
      // 시작 화면(뒤로 갈 곳 없는 로그인 화면)에서 로그인 · 비회원 선택이 끝나면 앱 첫 화면으로.
      // 설정에서 쌓아 연 로그인 화면은 화면이 스스로 닫는다.
      return null;
    },
    routes: [
      // 하단 탭 4개. indexedStack: 탭을 바꿔도 각 탭 화면이 사라지지 않고 상태가 유지된다.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainView(navigationShell: navigationShell),
        branches: [
          _tab(AppRoutes.sent, const LedgerListView(direction: RecordDirection.sent)),
          // 받아요는 기록 목록이 아니라 "내 행사" 목록이다. 행사를 누르면 준 사람들이 나온다.
          _tab(AppRoutes.received, const EventListView()),
          _tab(AppRoutes.stats, const StatsView()),
          _tab(AppRoutes.settings, const SettingsView()),
        ],
      ),

      // 기록 입력: 경로의 :direction 값('sent'/'received')을 enum으로 바꿔 화면에 넘긴다.
      // 행사 화면에서 오면 ?eventId=3 이 붙어서 그 행사가 미리 골라진다.
      GoRoute(
        path: AppRoutes.entryNewPattern,
        builder: (context, state) => EntryFormView.create(
          direction: RecordDirection.values.byName(state.pathParameters['direction']!),
          eventId: int.tryParse(state.uri.queryParameters['eventId'] ?? ''),
        ),
      ),

      // 행사. 주의: '/event/new'가 '/event/:id'보다 먼저 있어야 "new"를 id로 읽지 않는다.
      GoRoute(path: AppRoutes.eventNew, builder: (_, _) => const EventFormView()),
      GoRoute(
        path: AppRoutes.eventDetailPattern,
        builder: (context, state) => EventDetailView(eventId: int.tryParse(state.pathParameters['id']!) ?? -1),
      ),
      // 행사 사진 전체 화면: ?index=2 → 세 번째 사진부터
      GoRoute(
        path: AppRoutes.eventPhotosPattern,
        builder: (context, state) => EventPhotoView(
          eventId: int.tryParse(state.pathParameters['id']!) ?? -1,
          initialIndex: int.tryParse(state.uri.queryParameters['index'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: AppRoutes.eventEditPattern,
        builder: (context, state) => EventFormView(eventId: int.tryParse(state.pathParameters['id']!) ?? -1),
      ),

      // 설정 → 경조사 종류 관리
      GoRoute(path: AppRoutes.eventTypes, builder: (_, _) => const EventTypeView()),

      // 설정 → 개인정보 처리방침 (앱 안에 들어 있는 글)
      GoRoute(path: AppRoutes.privacyPolicy, builder: (_, _) => const PrivacyPolicyView()),
      GoRoute(path: AppRoutes.profile, builder: (_, _) => const ProfileView()),

      // 설정 → 로그인
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginView()),

      // 기록 수정: 경로의 :id를 숫자로 바꿔 넘긴다. 숫자가 아니면 -1(없는 기록) → "기록을 찾을 수 없어요" 화면.
      GoRoute(
        path: AppRoutes.entryEditPattern,
        builder: (context, state) => EntryFormView.edit(entryId: int.tryParse(state.pathParameters['id']!) ?? -1),
      ),
    ],
  );
  // 사용 분석: 화면이 바뀔 때마다 주소 모양(예: /events/:eventId)을 남긴다. 실제 번호 · 내용은 들어가지 않는다.
  String? lastScreen;
  void logScreen() {
    final screen = router.routerDelegate.currentConfiguration.fullPath;
    if (screen.isEmpty || screen == lastScreen) return;
    lastScreen = screen;
    AppMonitor.logScreen(screen);
  }

  router.routerDelegate.addListener(logScreen);
  ref.onDispose(() => router.routerDelegate.removeListener(logScreen));
  ref.onDispose(router.dispose);
  return router;
});

/// 탭 하나(branch)를 만드는 도우미. 탭마다 같은 모양이라 반복을 줄였다.
StatefulShellBranch _tab(String path, Widget screen) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: (_, _) => screen)],
);
