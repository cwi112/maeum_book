import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';
import 'package:maeum_book/ui/entry/entry.dart';
import 'package:maeum_book/ui/ledger/ledger.dart';
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
  final router = GoRouter(
    initialLocation: AppRoutes.initial,
    routes: [
      // 하단 탭 4개. indexedStack: 탭을 바꿔도 각 탭 화면이 사라지지 않고 상태가 유지된다.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainView(navigationShell: navigationShell),
        branches: [
          _tab(AppRoutes.sent, const LedgerListView(direction: RecordDirection.sent)),
          _tab(AppRoutes.received, const LedgerListView(direction: RecordDirection.received)),
          _tab(AppRoutes.stats, const StatsView()),
          _tab(AppRoutes.settings, const SettingsView()),
        ],
      ),

      // 기록 입력: 경로의 :direction 값('sent'/'received')을 enum으로 바꿔 화면에 넘긴다.
      GoRoute(
        path: AppRoutes.entryNewPattern,
        builder: (context, state) =>
            EntryFormView.create(direction: RecordDirection.values.byName(state.pathParameters['direction']!)),
      ),

      // 기록 수정: 경로의 :id를 숫자로 바꿔 넘긴다. 숫자가 아니면 -1(없는 기록) → "기록을 찾을 수 없어요" 화면.
      GoRoute(
        path: AppRoutes.entryEditPattern,
        builder: (context, state) => EntryFormView.edit(entryId: int.tryParse(state.pathParameters['id']!) ?? -1),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// 탭 하나(branch)를 만드는 도우미. 탭마다 같은 모양이라 반복을 줄였다.
StatefulShellBranch _tab(String path, Widget screen) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: (_, _) => screen)],
);
