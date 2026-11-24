import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/ui/settings/settings_view_model.dart';

/// 설정 탭.
class SettingsView extends BaseView<SettingsViewModel, SettingsState> {
  const SettingsView({super.key});

  @override
  NotifierProvider<SettingsViewModel, SettingsState> get provider => settingsViewModelProvider;

  @override
  Widget buildView(BuildContext context, WidgetRef ref, SettingsState state, SettingsViewModel viewModel) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: [
          // TODO: 기능이 생기면 onTap을 연결한다.
          const Card(
            child: Column(
              children: [
                ListTile(leading: Icon(Icons.notifications_none), title: Text('알림'), subtitle: Text('준비 중')),
                Divider(indent: AppSpacing.screen, endIndent: AppSpacing.screen),
                ListTile(leading: Icon(Icons.cloud_outlined), title: Text('백업'), subtitle: Text('준비 중')),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('앱 정보'),
              subtitle: Text('버전 ${state.appVersion}'),
            ),
          ),
        ],
      ),
    );
  }
}
