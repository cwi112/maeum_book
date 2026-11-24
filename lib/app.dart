import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/router/app_router.dart';

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
    );
  }
}
