import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/router/app_router.dart';
import 'package:maeum_book/ui/login/auth_session_watcher.dart';

/// 앱의 최상위 위젯: 제목, 테마, 화면 이동(라우터)을 정한다.
///
/// `MaterialApp.router`: 화면 이동을 go_router에 맡기는 방식. 어떤 화면을 보여줄지는 [appRouterProvider]가 정한다.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppDefine.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: ref.watch(appRouterProvider),
      // 한국어 고정: 날짜 선택 달력, 복사·붙여넣기 메뉴 등 기본 위젯 문구가 한국어로 나온다.
      locale: const Locale('ko'),
      supportedLocales: const [Locale('ko')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // 모든 화면(다이얼로그 포함)을 감싸서, 빈 공간을 터치하면 키보드를 닫는다.
      // 입력칸·버튼을 누르면 그 위젯이 터치를 먼저 가져가므로 키보드는 그대로 둔다.
      // AuthSessionWatcher: 로그인이 만료되면 어느 화면에서든 다시 로그인을 안내한다.
      // AppLoading: 서버 작업 중에는 앱 전체(다이얼로그 · 아래 창 포함)의 터치와 뒤로 가기를 막는다.
      builder: (context, child) => AppLoading(
        child: AuthSessionWatcher(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: child,
          ),
        ),
      ),
    );
  }
}
