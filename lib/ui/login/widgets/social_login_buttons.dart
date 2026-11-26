import 'package:maeum_book/core/core.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// 소셜 로그인 버튼 공통 크기. Apple 규정: 다른 로그인 버튼보다 작거나 덜 눈에 띄면 안 된다 → 두 버튼 크기를 똑같이 맞춘다.
abstract final class SocialButtonSpec {
  /// 버튼 높이 (Apple 최소 44pt 이상)
  static const double height = 52;

  /// 모서리 둥글기 (카카오 디자인 가이드 12px, Apple 버튼도 같게)
  static const double radius = 12;
}

/// 카카오 로그인 버튼. [카카오 디자인 가이드](https://developers.kakao.com/docs/ko/kakaologin/design-guide)를 따른다.
///
/// | 항목 | 규격 |
/// |---|---|
/// | 배경 | #FEE500 |
/// | 심볼(말풍선) | #000000, 모양 · 비율 · 색 변경 금지, 심볼 없는 버튼 금지 |
/// | 글자 | "카카오 로그인", #000000 85%, **OS 기본 시스템 서체** (앱 글꼴 Pretendard를 쓰지 않음) |
/// | 모서리 | 12px |
/// | 크기 | 버튼을 넓힐 때는 심볼 · 글자는 그대로 두고 좌우로만 늘린다. 글자 높이는 버튼 높이의 1/3 이하 |
class KakaoLoginButton extends StatelessWidget {
  const KakaoLoginButton({super.key, required this.onPressed, this.isLoading = false});

  /// null이면 누를 수 없음 (다른 로그인 진행 중)
  final VoidCallback? onPressed;
  final bool isLoading;

  // 글자 높이 ≤ 버튼 높이의 1/3 (52 / 3 ≈ 17) → 16
  static const _labelStyle = TextStyle(
    inherit: false, // 앱 글꼴을 물려받지 않고 OS 기본 서체를 쓴다. (가이드 규정)
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.kakaoLabel,
    textBaseline: TextBaseline.alphabetic,
  );

  @override
  Widget build(BuildContext context) {
    return _SocialButtonFrame(
      color: AppColors.kakao,
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const _ButtonSpinner(color: AppColors.kakaoLabel)
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 심볼은 글자와 함께 가운데 정렬 (가이드에서 허용하는 배치)
                SizedBox.square(dimension: 18, child: CustomPaint(painter: _KakaoSymbolPainter())),
                SizedBox(width: AppSpacing.sm),
                Text('카카오 로그인', style: _labelStyle),
              ],
            ),
    );
  }
}

/// Apple 로그인 버튼. Apple이 정한 모양(로고 · 서체 · 검정 스타일)을 그려 주는 sign_in_with_apple 패키지 버튼을 쓴다.
/// 문구는 Apple의 한국어 공식 문구 "Apple로 로그인". 크기 · 모서리는 카카오 버튼과 같게 맞춘다.
class AppleLoginButton extends StatelessWidget {
  const AppleLoginButton({super.key, required this.onPressed, this.isLoading = false});

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _SocialButtonFrame(
        color: Colors.black,
        child: _ButtonSpinner(color: Colors.white),
      );
    }
    // 다른 로그인 진행 중이면 흐리게 + 누를 수 없게
    return Opacity(
      opacity: onPressed == null ? 0.6 : 1,
      child: IgnorePointer(
        ignoring: onPressed == null,
        child: SignInWithAppleButton(
          onPressed: onPressed ?? () {},
          text: 'Apple로 로그인',
          height: SocialButtonSpec.height,
          borderRadius: const BorderRadius.all(Radius.circular(SocialButtonSpec.radius)),
        ),
      ),
    );
  }
}

/// 두 버튼이 같이 쓰는 틀: 같은 높이 · 모서리 · 꽉 찬 너비
class _SocialButtonFrame extends StatelessWidget {
  const _SocialButtonFrame({required this.color, required this.child, this.onPressed});

  final Color color;
  final Widget child;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: SocialButtonSpec.height,
      child: Material(
        // 누를 수 없을 때도 회사 색은 유지하고 살짝만 흐리게 (가이드: 색 변경 금지)
        color: onPressed == null ? color.withValues(alpha: 0.6) : color,
        borderRadius: BorderRadius.circular(SocialButtonSpec.radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) =>
      SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2, color: color));
}

/// 카카오 말풍선 심볼 (검정). 둥근 말풍선 + 왼쪽 아래 꼬리.
/// 공식 리소스(developers.kakao.com → 도구 → 리소스 다운로드 → 카카오 로그인)의 심볼 이미지로 바꿀 수 있다.
class _KakaoSymbolPainter extends CustomPainter {
  const _KakaoSymbolPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..color = Colors.black;
    // 말풍선 몸통: 가로로 조금 긴 타원
    canvas.drawOval(Rect.fromLTWH(0, h * 0.04, w, h * 0.78), paint);
    // 꼬리: 몸통 왼쪽 아래에서 아래로 짧게
    final tail = Path()
      ..moveTo(w * 0.22, h * 0.66)
      ..lineTo(w * 0.17, h * 0.98)
      ..lineTo(w * 0.44, h * 0.76)
      ..close();
    canvas.drawPath(tail, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
