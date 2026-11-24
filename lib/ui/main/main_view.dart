import 'package:maeum_book/core/core.dart';

/// 하단 탭(보내요 / 받아요 / 통계 / 설정)을 가진 메인 틀.
///
/// 어떤 탭이 선택됐는지는 go_router의 [StatefulNavigationShell]이 관리한다.
/// 그래서 이 화면에는 상태가 없고 ViewModel도 필요 없다. (탭 상태 = 현재 URL)
/// - [navigationShell]: 현재 탭의 화면. 탭마다 화면 상태(스크롤 위치 등)가 따로 유지된다.
class MainView extends StatelessWidget {
  const MainView({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// 탭을 누르면 해당 탭으로 이동한다. 이미 선택된 탭을 다시 누르면 그 탭의 첫 화면으로 돌아간다.
  void _onTap(int index) => navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.outbox_outlined),
            selectedIcon: Icon(Icons.outbox),
            label: '보내요',
          ).testId(TestIds.tabSent),
          const NavigationDestination(
            icon: Icon(Icons.move_to_inbox_outlined),
            selectedIcon: Icon(Icons.move_to_inbox),
            label: '받아요',
          ).testId(TestIds.tabReceived),
          const NavigationDestination(
            icon: Icon(Icons.insert_chart_outlined),
            selectedIcon: Icon(Icons.insert_chart),
            label: '통계',
          ).testId(TestIds.tabStats),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '설정',
          ).testId(TestIds.tabSettings),
        ],
      ),
    );
  }
}
