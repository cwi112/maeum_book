import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/base/base_view.dart';
import '../history/history_view.dart';
import '../people/people_view.dart';
import '../settings/settings_view.dart';
import 'main_view_model.dart';

/// 하단 탭(내역 / 사람 / 설정)을 가진 메인 화면.
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
        children: const [HistoryView(), PeopleView(), SettingsView()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: state,
        onDestinationSelected: viewModel.changeTab,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: '내역'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: '사람'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }
}
