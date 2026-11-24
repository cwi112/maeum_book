import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/base/base_view_model.dart';

/// 설정 탭의 상태.
class SettingsState {
  const SettingsState();
  // TODO: 알림 사용 여부 등 설정 항목을 여기에 추가한다.
}

/// 설정 탭의 ViewModel.
class SettingsViewModel extends BaseViewModel<SettingsState> {
  @override
  SettingsState build() => const SettingsState();
}

final settingsViewModelProvider =
    NotifierProvider.autoDispose<SettingsViewModel, SettingsState>(SettingsViewModel.new);
