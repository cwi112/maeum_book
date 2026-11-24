import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';
import 'package:maeum_book/ui/ledger/ledger.dart';
import 'package:maeum_book/ui/main/main_view_model.dart';
import 'package:maeum_book/ui/settings/settings.dart';
import 'package:maeum_book/ui/stats/stats.dart';

/// 하단 탭(보내요 / 받아요 / 통계 / 설정)을 가진 메인 화면.
class MainView extends BaseView<MainViewModel, int> {
  const MainView({super.key});

  @override
  NotifierProvider<MainViewModel, int> get provider => mainViewModelProvider;

  @override
  Widget buildView(BuildContext context, WidgetRef ref, int state, MainViewModel viewModel) {
    return Scaffold(
      // IndexedStack: 탭을 바꿔도 각 탭 화면의 상태(스크롤 위치 등)가 유지된다.
      body: IndexedStack(
        index: state,
        children: const [
          LedgerListView(direction: RecordDirection.sent),
          LedgerListView(direction: RecordDirection.received),
          StatsView(),
          SettingsView(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: state,
        onDestinationSelected: viewModel.changeTab,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.outbox_outlined), selectedIcon: Icon(Icons.outbox), label: '보내요'),
          NavigationDestination(
            icon: Icon(Icons.move_to_inbox_outlined),
            selectedIcon: Icon(Icons.move_to_inbox),
            label: '받아요',
          ),
          NavigationDestination(
            icon: Icon(Icons.insert_chart_outlined),
            selectedIcon: Icon(Icons.insert_chart),
            label: '통계',
          ),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }
}
