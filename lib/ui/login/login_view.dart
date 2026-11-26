import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/ui/login/login_view_model.dart';

/// 로그인 화면. 경로 `/login` (설정 탭에서 연다)
///
/// ```
///        [편지 아이콘]
///    마음장부에 로그인
///  로그인하면 기록을 서버에 ...
///
///  [💬 카카오 로그인        ]   ← 카카오 노랑
///  [ Apple로 로그인       ]   ← iOS에서만
/// ```
/// - App Store 규정: 카카오 같은 소셜 로그인을 넣으면 Apple 로그인도 있어야 한다. (iOS만 해당)
/// - 로그인은 선택 기능이다. 로그인하지 않아도 앱의 모든 기록 기능을 쓸 수 있다.
class LoginView extends BaseView<LoginViewModel, LoginMethod?> {
  const LoginView({super.key});

  @override
  NotifierProvider<LoginViewModel, LoginMethod?> get provider => loginViewModelProvider;

  static bool get _showApple => defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> _signIn(BuildContext context, LoginViewModel viewModel, LoginMethod method) async {
    final success = await viewModel.signIn(
      method,
      onError: (_) => context.showToast('로그인하지 못했어요. 잠시 후 다시 시도해 주세요', type: ToastType.error),
    );
    if (success && context.mounted) {
      context.showToast('로그인했어요');
      context.pop();
    }
  }

  @override
  Widget buildView(BuildContext context, WidgetRef ref, LoginMethod? state, LoginViewModel viewModel) {
    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            children: [
              const Spacer(),
              Image.asset('assets/icon/app_icon_foreground.png', width: 140, height: 140),
              const AppText.headline('마음장부에 로그인'),
              const SizedBox(height: AppSpacing.sm),
              const AppText.body(
                '로그인해 두면 곧 추가될 백업 기능으로\n기록을 안전하게 보관할 수 있어요',
                color: AppColors.textSecondary,
                align: TextAlign.center,
              ),
              const Spacer(),
              _LoginButton(
                label: '카카오 로그인',
                icon: Icons.chat_bubble,
                background: AppColors.kakao,
                foreground: AppColors.kakaoLabel,
                isLoading: state == LoginMethod.kakao,
                onPressed: state == null ? () => _signIn(context, viewModel, LoginMethod.kakao) : null,
              ).testId(TestIds.loginKakao),
              if (_showApple) ...[
                const SizedBox(height: AppSpacing.sm),
                _LoginButton(
                  label: 'Apple로 로그인',
                  icon: Icons.apple,
                  background: Colors.black,
                  foreground: Colors.white,
                  isLoading: state == LoginMethod.apple,
                  onPressed: state == null ? () => _signIn(context, viewModel, LoginMethod.apple) : null,
                ).testId(TestIds.loginApple),
              ],
              const SizedBox(height: AppSpacing.md),
              const AppText.caption('로그인하지 않아도 모든 기록 기능을 쓸 수 있어요', align: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

/// 로그인 버튼 (회사별 색만 다르고 모양은 같다). 누르는 중이면 글자 대신 로딩 표시.
class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          // 다른 버튼 로그인 중일 때도 회사 색을 유지하고 살짝만 흐리게 한다.
          disabledBackgroundColor: background.withValues(alpha: 0.6),
          disabledForegroundColor: foreground.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
        child: isLoading
            ? SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2, color: foreground))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(label, style: AppTextStyles.label.withColor(foreground)),
                ],
              ),
      ),
    );
  }
}
