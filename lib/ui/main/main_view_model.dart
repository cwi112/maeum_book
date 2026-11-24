import 'package:maeum_book/core/core.dart';

/// 하단 탭 상태를 관리한다. 상태(state) = 현재 선택된 탭 번호.
class MainViewModel extends BaseViewModel<int> {
  @override
  int build() => 0;

  void changeTab(int index) => state = index;
}

final mainViewModelProvider = NotifierProvider.autoDispose<MainViewModel, int>(MainViewModel.new);
