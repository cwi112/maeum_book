import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/ui/login/login_view_model.dart';
import 'package:maeum_book/ui/login/widgets/social_login_buttons.dart';

/// 로그인 화면. 경로 `/login` (설정 탭 · 만료 안내 토스트에서 연다)
///
/// ```
///        [편지 아이콘]
///    마음장부에 로그인
///  로그인하면 기록을 서버에 ...
///
///  [💬 카카오 로그인        ]   ← 카카오 디자인 가이드
///  [ Apple로 로그인       ]   ← iOS에서만, 카카오 버튼과 같은 크기
/// ```
/// - App Store 규정(4.8): 카카오 같은 소셜 로그인을 넣으면 Apple 로그인도 있어야 한다. (iOS만 해당)
/// - 로그인은 선택 기능이다. 로그인하지 않아도 앱의 모든 기록 기능을 쓸 수 있다.
class LoginView extends BaseView<LoginViewModel, LoginMethod?> {
  const LoginView({super.key});

  @override
  NotifierProvider<LoginViewModel, LoginMethod?> get provider => loginViewModelProvider;

  static bool get _showApple => defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> _signIn(BuildContext context, LoginViewModel viewModel, LoginMethod method) async {
    final success = await viewModel.signIn(
      method,
      onFailure: (failure) {
        if (context.mounted) context.showToast(failure.message, type: ToastType.error);
      },
    );
    if (success && context.mounted) {
      context.showToast('로그인했어요');
      context.pop();
    }
  }

  @override
  Widget buildView(BuildContext context, WidgetRef ref, LoginMethod? state, LoginViewModel viewModel) {
    final busy = state != null;
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
              KakaoLoginButton(
                isLoading: state == LoginMethod.kakao,
                onPressed: busy ? null : () => _signIn(context, viewModel, LoginMethod.kakao),
              ).testId(TestIds.loginKakao),
              if (_showApple) ...[
                const SizedBox(height: AppSpacing.sm),
                AppleLoginButton(
                  isLoading: state == LoginMethod.apple,
                  onPressed: busy ? null : () => _signIn(context, viewModel, LoginMethod.apple),
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
