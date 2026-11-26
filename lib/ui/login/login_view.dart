import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/ui/login/login_view_model.dart';
import 'package:maeum_book/ui/login/widgets/social_login_buttons.dart';

/// 로그인 화면. 경로 `/login`
///
/// ```
///        [편지 아이콘]
///    마음장부에 로그인
///  로그인하면 기록을 서버에 ...
///
///  [💬 카카오 로그인        ]   ← 카카오 디자인 가이드, 공식 심볼
///  [ Apple로 로그인       ]   ← iOS에서만, 카카오 버튼과 같은 크기, 공식 로고
///      로그인 없이 시작하기      ← 밑줄 글자 버튼 (시작 화면일 때만)
/// ```
/// 두 가지로 열린다.
/// | 열린 방법 | 뒤로 가기 | 밑줄 버튼 | 로그인 성공 후 |
/// |---|---|---|---|
/// | **시작 화면**: 첫 실행 · 로그아웃 · 탈퇴 · 만료 (라우터가 보냄) | 없음 | 보임 | 앱 첫 화면으로 |
/// | 설정 탭에서 비회원이 [로그인]을 누름 | 있음 | 숨김 (이미 비회원) | 설정으로 돌아감 |
///
/// - App Store 규정(4.8): 카카오 같은 소셜 로그인을 넣으면 Apple 로그인도 있어야 한다. (iOS만 해당)
class LoginView extends BaseView<LoginViewModel, LoginMethod?> {
  const LoginView({super.key});

  @override
  NotifierProvider<LoginViewModel, LoginMethod?> get provider => loginViewModelProvider;

  static bool get _showApple => LoginMethod.availableHere.contains(LoginMethod.apple);

  /// 시작 화면으로 열렸는지 (뒤로 갈 화면이 없으면 시작 화면)
  static bool _isStartScreen(BuildContext context) => !context.canPop();

  /// 시작 화면이면 앱 첫 화면으로, 설정에서 열었으면 닫아서 돌아간다.
  static void _leave(BuildContext context) => _isStartScreen(context) ? context.go(AppRoutes.initial) : context.pop();

  Future<void> _signIn(BuildContext context, LoginViewModel viewModel, LoginMethod method) async {
    final success = await viewModel.signIn(
      method,
      onFailure: (failure) {
        if (context.mounted) context.showToast(failure.message, type: ToastType.error);
      },
    );
    if (success && context.mounted) {
      context.showToast('로그인했어요');
      _leave(context);
    }
  }

  Future<void> _continueAsGuest(BuildContext context, LoginViewModel viewModel) async {
    await viewModel.continueAsGuest();
    if (context.mounted) _leave(context);
  }

  @override
  Widget buildView(BuildContext context, WidgetRef ref, LoginMethod? state, LoginViewModel viewModel) {
    final busy = state != null;
    final isStart = _isStartScreen(context);
    return Scaffold(
      // 시작 화면은 제목 없이, 설정에서 열면 "로그인" 제목 + 뒤로 가기
      appBar: isStart ? null : AppBar(title: const Text('로그인')),
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
              if (isStart)
                TextButton(
                  onPressed: busy ? null : () => _continueAsGuest(context, viewModel),
                  child: Text(
                    '로그인 없이 시작하기',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.textSecondary,
                    ),
                  ),
                ).testId(TestIds.loginGuest)
              else
                const AppText.caption('로그인하지 않아도 모든 기록 기능을 쓸 수 있어요', align: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}
