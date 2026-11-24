import 'package:material_ui/material_ui.dart';

import 'core/theme/app_theme.dart';
import 'ui/main/main_view.dart';

/// 앱의 최상위 위젯: 제목, 테마, 첫 화면을 정한다.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '마음장부',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const MainView(),
    );
  }
}
