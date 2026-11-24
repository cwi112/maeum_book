import 'package:maeum_book/core/core.dart';

part 'settings_state.dart';

/// 설정 탭의 ViewModel. 상태(state) = [SettingsState].
class SettingsViewModel extends BaseViewModel<SettingsState> {
  @override
  SettingsState build() => const SettingsState();
}

final settingsViewModelProvider = NotifierProvider.autoDispose<SettingsViewModel, SettingsState>(SettingsViewModel.new);
