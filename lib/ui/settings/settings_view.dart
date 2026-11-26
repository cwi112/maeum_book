import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';
import 'package:maeum_book/ui/login/login_view_model.dart';
import 'package:maeum_book/ui/login/widgets/social_login_buttons.dart';
import 'package:maeum_book/ui/settings/settings_view_model.dart';
import 'package:url_launcher/url_launcher.dart';

/// 설정 탭.
///
/// - 데이터: 샘플 데이터로 둘러보기(메모리 전용, 앱을 끄면 사라짐), 모든 기록 지우기(확인 창 필수, 되돌릴 수 없음)
/// - 준비 중: 알림, 백업, 화면 모드(라이트 · 다크 · 시스템) (누르면 "곧 추가될 기능" 토스트)
/// - 앱 정보: 설치된 버전 표시, 누르면 최신 버전 확인 → 업데이트 안내
class SettingsView extends BaseView<SettingsViewModel, SettingsState> {
  const SettingsView({super.key});

  @override
  NotifierProvider<SettingsViewModel, SettingsState> get provider => settingsViewModelProvider;

  static void _showError(BuildContext context, Object error) => context.showErrorToast(error, '처리하지 못했어요. 다시 시도해 주세요');

  Future<void> _startSampleTour(BuildContext context, SettingsViewModel viewModel) async {
    final count = await viewModel.startSampleTour(onError: (e) => _showError(context, e));
    if (count != null && context.mounted) {
      context.showToast('샘플 기록 $count개로 둘러보는 중이에요. 앱을 끄면 사라져요', type: ToastType.info);
    }
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
    final count = await viewModel.clearAll(onError: (e) => _showError(context, e));
    if (count != null && context.mounted) context.showToast('기록 $count개를 지웠어요', type: ToastType.info);
  }

  static void _showComingSoon(BuildContext context) =>
      context.showToast(AppDefine.comingSoonMessage, type: ToastType.info);

  /// 앱 정보를 누르면: 최신 버전인지 확인하고, 아니면 업데이트할 곳(지금은 TestFlight)으로 보낸다.
  Future<void> _checkUpdate(BuildContext context, SettingsViewModel viewModel) async {
    final result = await viewModel.checkUpdate();
    if (result == null || !context.mounted) return;
    switch (result) {
      case AppUpToDate():
        context.showToast('최신 버전을 쓰고 있어요');
      case AppUpdateCheckFailed():
        context.showToast('버전을 확인하지 못했어요. 인터넷 연결을 확인해 주세요', type: ToastType.error);
      case AppUpdateAvailable(:final latestVersion, :final url):
        if (url == null) {
          context.showToast('새 버전 $latestVersion이 나왔어요', type: ToastType.info);
          return;
        }
        final confirmed = await AppDialog.confirm(
          context,
          title: '새 버전이 나왔어요',
          message: '버전 $latestVersion으로 업데이트할 수 있어요.\n업데이트하러 갈까요?',
          confirmLabel: '업데이트',
          cancelLabel: '나중에',
        );
        if (!confirmed) return;
        final opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        if (!opened && context.mounted) {
          context.showToast('업데이트 화면을 열지 못했어요', type: ToastType.error);
        }
    }
  }

  @override
  Widget buildView(BuildContext context, WidgetRef ref, SettingsState state, SettingsViewModel viewModel) {
    final sampleMode = ref.watch(sampleModeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: [
          const _SectionLabel('계정'),
          _AccountCard(viewModel: viewModel),
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
                // 샘플은 메모리에만 둔다: 기기 DB · 서버에 쓰지 않고, 끝내거나 앱을 끄면 사라진다.
                if (sampleMode)
                  ListTile(
                    leading: const Icon(Icons.close_rounded),
                    title: const Text('샘플 둘러보기 끝내기'),
                    subtitle: const Text('샘플을 지우고 내 기록으로 돌아가요'),
                    onTap: viewModel.endSampleTour,
                  ).testId(TestIds.settingsSeed)
                else ...[
                  ListTile(
                    leading: const Icon(Icons.auto_awesome_outlined),
                    title: const Text('샘플 데이터로 둘러보기'),
                    subtitle: const Text('내 기록과 섞이지 않고, 앱을 끄면 사라져요'),
                    onTap: () => _startSampleTour(context, viewModel),
                  ).testId(TestIds.settingsSeed),
                  const Divider(indent: AppSpacing.screen, endIndent: AppSpacing.screen),
                  // 샘플 중에는 숨긴다. (샘플만 지우는데 "모든 기록"이 지워지는 줄 알고 놀라지 않게)
                  ListTile(
                    leading: const Icon(Icons.delete_sweep_outlined, color: AppColors.error),
                    title: const AppText.body('모든 기록 지우기', color: AppColors.error),
                    onTap: () => _clearAll(context, viewModel),
                  ).testId(TestIds.settingsClear),
                ],
              ],
            ),
          ),
          const _SectionLabel('준비 중'),
          // TODO: 기능이 생기면 onTap을 실제 화면으로 바꾼다. 지금은 눌러도 "준비 중" 안내만 띄운다.
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_none),
                  title: const Text('알림'),
                  subtitle: const Text('준비 중'),
                  onTap: () => _showComingSoon(context),
                ),
                const Divider(indent: AppSpacing.screen, endIndent: AppSpacing.screen),
                ListTile(
                  leading: const Icon(Icons.cloud_outlined),
                  title: const Text('백업'),
                  subtitle: const Text('준비 중'),
                  onTap: () => _showComingSoon(context),
                ),
                const Divider(indent: AppSpacing.screen, endIndent: AppSpacing.screen),
                // TODO: 라이트 · 다크 · 시스템(기기 설정 따라가기) 중 고르는 화면. 고른 값은 기기에 저장해 MaterialApp.themeMode로.
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: const Text('화면 모드'),
                  subtitle: const Text('라이트 · 다크 · 시스템 (준비 중)'),
                  onTap: () => _showComingSoon(context),
                ).testId(TestIds.settingsThemeMode),
              ],
            ),
          ),
          const _SectionLabel('정보'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('앱 정보'),
              subtitle: Text(state.appVersion == null ? '버전 확인 중' : '버전 ${state.appVersion}'),
              trailing: state.isCheckingUpdate
                  ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
              onTap: () => _checkUpdate(context, viewModel),
            ).testId(TestIds.settingsAppInfo),
          ),
        ],
      ),
    );
  }
}

/// 계정 카드. 로그인 상태(currentUserProvider)가 바뀌면 자동으로 다시 그려진다.
///
/// - 로그인 전: [로그인] → 로그인 화면
/// - 로그인 후: 이름 · 로그인 방법, [로그아웃], [회원 탈퇴]
class _AccountCard extends ConsumerWidget {
  const _AccountCard({required this.viewModel});

  final SettingsViewModel viewModel;

  /// 실패 이유에 맞는 문구를 띄운다. (로그인이 만료됐으면 라우터가 시작 화면으로 보낸다)
  static void _showFailure(BuildContext context, AuthFailure failure) {
    if (!context.mounted) return;
    final expired = failure.type == AuthFailureType.sessionExpired;
    context.showToast(failure.message, type: expired ? ToastType.info : ToastType.error);
  }

  /// 로그아웃하면 시작(로그인) 화면으로 간다. 이 기기에 기록한 장부는 그대로 남는다.
  Future<void> _signOut(BuildContext context) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: '로그아웃할까요?',
      message: '이 기기에 기록한 장부는 그대로 남아요.',
      confirmLabel: '로그아웃',
    );
    if (!confirmed || !context.mounted) return;
    if (await viewModel.signOut(onFailure: (f) => _showFailure(context, f)) && context.mounted) {
      context.showToast('로그아웃했어요', type: ToastType.info);
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: '탈퇴할까요?',
      message: '계정과 서버에 저장된 정보가 지워지고 되돌릴 수 없어요.\n이 기기에 기록한 장부는 그대로 남아요.',
      confirmLabel: '탈퇴하기',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    if (await viewModel.deleteAccount(onFailure: (f) => _showFailure(context, f)) && context.mounted) {
      context.showToast('탈퇴했어요. 그동안 고마웠어요', type: ToastType.info);
    }
  }

  Future<void> _link(BuildContext context, LoginMethod provider) async {
    final linked = await viewModel.link(provider, onFailure: (f) => _showFailure(context, f));
    if (linked && context.mounted) {
      context.showToast('${provider.label} 계정을 연결했어요. 이제 어느 쪽으로 로그인해도 같은 계정이에요');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.person_outline),
          title: const Text('로그인'),
          subtitle: const Text('비회원으로 쓰는 중이에요. 로그인해도 기록은 그대로예요'),
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
          onTap: () => context.push(AppRoutes.login),
        ).testId(TestIds.settingsAccount),
      );
    }
    final linking = ref.watch(settingsViewModelProvider.select((s) => s.linkingProvider));
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: Text(user.name ?? '마음장부 사용자'),
            subtitle: Text('${user.providerLabel} 계정으로 가입'),
          ).testId(TestIds.settingsAccount),
          const Divider(indent: AppSpacing.screen, endIndent: AppSpacing.screen),
          // 연결된 로그인 방법: 연결해 두면 카카오 · Apple 어느 쪽으로 로그인해도 같은 계정
          for (final provider in LoginMethod.availableHere)
            _LinkTile(
              provider: provider,
              isLinked: user.isLinked(provider.id),
              isLoading: linking == provider,
              onLink: linking == null ? () => _link(context, provider) : null,
            ),
          const Divider(indent: AppSpacing.screen, endIndent: AppSpacing.screen),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('로그아웃'),
            onTap: () => _signOut(context),
          ).testId(TestIds.settingsSignOut),
          const Divider(indent: AppSpacing.screen, endIndent: AppSpacing.screen),
          ListTile(
            leading: const Icon(Icons.person_remove_outlined, color: AppColors.textSecondary),
            title: const AppText.body('회원 탈퇴', color: AppColors.textSecondary),
            onTap: () => _deleteAccount(context),
          ).testId(TestIds.settingsDeleteAccount),
        ],
      ),
    );
  }
}

/// 로그인 방법 한 줄: [카카오 · 연결됨] 또는 [Apple · 연결하기]
class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.provider, required this.isLinked, required this.isLoading, required this.onLink});

  final LoginMethod provider;
  final bool isLinked;
  final bool isLoading;
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: LoginProviderSymbol(isKakao: provider == LoginMethod.kakao),
      title: Text('${provider.label} 로그인'),
      trailing: isLinked
          ? const AppText.caption('연결됨', color: AppColors.success)
          : isLoading
          ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : TextButton(onPressed: onLink, child: const Text('연결하기')),
    ).testId(provider == LoginMethod.kakao ? TestIds.settingsLinkKakao : TestIds.settingsLinkApple);
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
