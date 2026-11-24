import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/ui/settings/settings_view_model.dart';

/// 설정 탭.
///
/// - 데이터: 샘플 데이터 넣기, 모든 기록 지우기(확인 창 필수, 되돌릴 수 없음)
/// - 준비 중: 알림, 백업
/// - 앱 정보
class SettingsView extends BaseView<SettingsViewModel, SettingsState> {
  const SettingsView({super.key});

  @override
  NotifierProvider<SettingsViewModel, SettingsState> get provider => settingsViewModelProvider;

  static void _showError(BuildContext context) => context.showToast('처리하지 못했어요. 다시 시도해 주세요', type: ToastType.error);

  Future<void> _addSamples(BuildContext context, SettingsViewModel viewModel) async {
    final count = await viewModel.addSamples(onError: (_) => _showError(context));
    if (count != null && context.mounted) context.showToast('샘플 기록 $count개를 넣었어요');
  }

  Future<void> _clearAll(BuildContext context, SettingsViewModel viewModel) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: '모든 기록을 지울까요?',
      message: '보낸 마음과 받은 마음이 모두 지워지고, 되돌릴 수 없어요.',
      confirmLabel: '모두 지우기',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final count = await viewModel.clearAll(onError: (_) => _showError(context));
    if (count != null && context.mounted) context.showToast('기록 $count개를 지웠어요', type: ToastType.info);
  }

  @override
  Widget buildView(BuildContext context, WidgetRef ref, SettingsState state, SettingsViewModel viewModel) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: [
          const _SectionLabel('기록 설정'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.category_outlined),
              title: const Text('경조사 종류 관리'),
              subtitle: const Text('환갑·졸업처럼 필요한 종류를 추가하거나 지워요'),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
              onTap: () => context.push(AppRoutes.eventTypes),
            ).testId(TestIds.settingsEventTypes),
          ),
          const _SectionLabel('데이터'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.auto_awesome_outlined),
                  title: const Text('샘플 데이터 넣기'),
                  subtitle: const Text('화면과 통계를 미리 보고 싶을 때'),
                  onTap: () => _addSamples(context, viewModel),
                ).testId(TestIds.settingsSeed),
                const Divider(indent: AppSpacing.screen, endIndent: AppSpacing.screen),
                ListTile(
                  leading: const Icon(Icons.delete_sweep_outlined, color: AppColors.error),
                  title: const AppText.body('모든 기록 지우기', color: AppColors.error),
                  onTap: () => _clearAll(context, viewModel),
                ).testId(TestIds.settingsClear),
              ],
            ),
          ),
          const _SectionLabel('준비 중'),
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
          const _SectionLabel('정보'),
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

/// 카드 묶음 위의 작은 제목
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      AppText.caption(text).paddingOnly(left: AppSpacing.xs, top: AppSpacing.md, bottom: AppSpacing.sm);
}
