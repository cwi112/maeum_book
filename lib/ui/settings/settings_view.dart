import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/base/base_view.dart';
import '../../core/theme/app_colors.dart';
import 'settings_view_model.dart';

/// 설정 탭.
class SettingsView extends BaseView<SettingsViewModel, SettingsState> {
  const SettingsView({super.key});

  @override
  NotifierProvider<SettingsViewModel, SettingsState> get provider => settingsViewModelProvider;

  @override
  Widget buildView(BuildContext context, WidgetRef ref, SettingsState state, SettingsViewModel viewModel) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: const Center(
        child: Text('설정 화면', style: TextStyle(color: AppColors.textSecondary)),
      ),
    );
  }
}
