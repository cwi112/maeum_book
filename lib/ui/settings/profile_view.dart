import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';
import 'package:maeum_book/ui/login/login_view_model.dart';
import 'package:maeum_book/ui/login/widgets/social_login_buttons.dart';
import 'package:maeum_book/ui/settings/settings_view_model.dart';

/// 내 계정(프로필) 화면. 경로 `/settings/profile` — 설정 맨 위 계정 줄을 누르면 열린다.
///
/// ```
/// ┌ 내 계정 ─────────────────────┐
/// │ (◯) 홍길동                    │
/// │     카카오 계정으로 가입       │
/// │ 로그인 방법                   │
/// │  카카오 로그인        연결됨   │
/// │  Apple 로그인       [연결하기] │
/// │                               │
/// │      로그아웃 · 회원 탈퇴       │  ← 맨 아래 작은 글자
/// └───────────────────────────────┘
/// ```
/// 로그아웃 · 회원 탈퇴는 실수로 누르지 않도록 설정 첫 화면에서 빼고, 이 화면 맨 아래에 작게 둔다.
/// 둘 다 확인 창을 거친다. 끝나면 로그인 상태가 바뀌어 라우터가 시작(로그인) 화면으로 보낸다.
class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  /// 실패 이유에 맞는 문구를 띄운다. (로그인이 만료됐으면 라우터가 시작 화면으로 보낸다)
  static void _showFailure(BuildContext context, AuthFailure failure) {
    if (!context.mounted) return;
    final expired = failure.type == AuthFailureType.sessionExpired;
    context.showToast(failure.message, type: expired ? ToastType.info : ToastType.error);
  }

  /// 로그아웃하면 시작(로그인) 화면으로 간다. 이 기기에 기록한 장부는 그대로 남는다.
  Future<void> _signOut(BuildContext context, SettingsViewModel viewModel) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: '로그아웃할까요?',
      message: '이 기기에 기록한 장부는 그대로 남아요.',
      confirmLabel: '로그아웃',
    );
    if (!confirmed || !context.mounted) return;
    final signedOut = await context.withLoading(
      () => viewModel.signOut(onFailure: (f) => _showFailure(context, f)),
      message: '로그아웃하는 중이에요',
    );
    if (signedOut && context.mounted) {
      context.showToast('로그아웃했어요', type: ToastType.info);
    }
  }

  Future<void> _deleteAccount(BuildContext context, SettingsViewModel viewModel) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: '탈퇴할까요?',
      message: '계정과 서버에 저장된 정보가 지워지고 되돌릴 수 없어요.\n이 기기에 기록한 장부는 그대로 남아요.',
      confirmLabel: '탈퇴하기',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final deleted = await context.withLoading(
      () => viewModel.deleteAccount(onFailure: (f) => _showFailure(context, f)),
      message: '탈퇴하는 중이에요',
    );
    if (deleted && context.mounted) {
      context.showToast('탈퇴했어요. 그동안 고마웠어요', type: ToastType.info);
    }
  }

  Future<void> _link(BuildContext context, SettingsViewModel viewModel, LoginMethod provider) async {
    final linked = await context.withLoading(
      () => viewModel.link(provider, onFailure: (f) => _showFailure(context, f)),
      style: LoadingStyle.button,
    );
    if (linked && context.mounted) {
      context.showToast('${provider.label} 계정을 연결했어요. 이제 어느 쪽으로 로그인해도 같은 계정이에요');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final viewModel = ref.read(settingsViewModelProvider.notifier);
    final linking = ref.watch(settingsViewModelProvider.select((s) => s.linkingProvider));
    return Scaffold(
      appBar: AppBar(title: const Text('내 계정')),
      // 로그아웃 · 탈퇴 직후 잠깐 user가 비는 순간에는 빈 화면 (곧 시작 화면으로 이동)
      body: user == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.screen),
              children: [
                Card(
                  child: ListTile(
                    leading: Icon(Icons.account_circle_outlined, size: 40, color: AppColors.textSecondary),
                    title: AppText.subtitle(user.name ?? '마음장부 사용자'),
                    subtitle: Text('${user.providerLabel} 계정으로 가입'),
                  ),
                ),
                const AppText.caption('로그인 방법').paddingOnly(left: AppSpacing.xs, top: AppSpacing.lg, bottom: AppSpacing.sm),
                // 연결해 두면 카카오 · Apple 어느 쪽으로 로그인해도 같은 계정
                Card(
                  child: Column(
                    children: [
                      for (final (i, provider) in LoginMethod.availableHere.indexed) ...[
                        if (i > 0) const Divider(indent: AppSpacing.screen, endIndent: AppSpacing.screen),
                        _LinkTile(
                          provider: provider,
                          isLinked: user.isLinked(provider.id),
                          isLoading: linking == provider,
                          onLink: linking == null ? () => _link(context, viewModel, provider) : null,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl * 2),
                // 맨 아래 작은 글자: 눈에 띄지 않게, 그래도 찾을 수는 있게
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => _signOut(context, viewModel),
                      child: const AppText.caption('로그아웃'),
                    ).testId(TestIds.settingsSignOut),
                    AppText.caption('·', color: AppColors.textHint),
                    TextButton(
                      onPressed: () => _deleteAccount(context, viewModel),
                      child: AppText.caption('회원 탈퇴', color: AppColors.textHint),
                    ).testId(TestIds.settingsDeleteAccount),
                  ],
                ),
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
          ? AppText.caption('연결됨', color: AppColors.success)
          : isLoading
          ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : TextButton(onPressed: onLink, child: const Text('연결하기')),
    ).testId(provider == LoginMethod.kakao ? TestIds.settingsLinkKakao : TestIds.settingsLinkApple);
  }
}
