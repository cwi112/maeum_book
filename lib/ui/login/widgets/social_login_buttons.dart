import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:maeum_book/core/core.dart';

/// 소셜 로그인 버튼 공통 크기. 두 버튼 모두 공식 심볼 이미지를 쓴다.
/// Apple 규정: 다른 로그인 버튼보다 작거나 덜 눈에 띄면 안 된다 → 두 버튼 크기를 똑같이 맞춘다.
abstract final class SocialButtonSpec {
  /// 버튼 높이 (Apple 최소 44pt 이상)
  static const double height = 52;

  /// 모서리 둥글기 (카카오 디자인 가이드 12px, Apple 버튼도 같게)
  static const double radius = 12;

  /// OS 기본 서체 이름: iOS는 SF(한글은 Apple SD 산돌고딕 Neo), Android는 Roboto(한글은 본고딕).
  /// 이름을 직접 적어 두면 앱 글꼴(Pretendard)을 물려받지 않고, 스크린샷 생성기에서도 같은 이름으로 대신 그릴 수 있다.
  static String get systemFont => defaultTargetPlatform == TargetPlatform.iOS ? 'CupertinoSystemText' : 'Roboto';
}

/// 카카오 로그인 버튼. [카카오 디자인 가이드](https://developers.kakao.com/docs/ko/kakaologin/design-guide)를 따른다.
///
/// | 항목 | 규격 |
/// |---|---|
/// | 배경 | #FEE500 |
/// | 심볼(말풍선) | 공식 리소스 SVG 그대로 (assets/images/kakao_symbol.svg), 모양 · 비율 · 색 변경 금지 |
/// | 글자 | "카카오 로그인", #000000 85%, **OS 기본 시스템 서체** (앱 글꼴 Pretendard를 쓰지 않음) |
/// | 모서리 | 12px |
/// | 크기 | 버튼을 넓힐 때는 심볼 · 글자는 그대로 두고 좌우로만 늘린다. 글자 높이는 버튼 높이의 1/3 이하 |
class KakaoLoginButton extends StatelessWidget {
  const KakaoLoginButton({super.key, required this.onPressed, this.isLoading = false});

  /// null이면 누를 수 없음 (다른 로그인 진행 중)
  final VoidCallback? onPressed;
  final bool isLoading;

  // 글자 높이 ≤ 버튼 높이의 1/3 (52 / 3 ≈ 17) → 16
  static TextStyle get _labelStyle => TextStyle(
    inherit: false, // 앱 글꼴을 물려받지 않고 OS 기본 서체를 쓴다. (가이드 규정)
    fontFamily: SocialButtonSpec.systemFont,
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
          ? _ButtonSpinner(color: AppColors.kakaoLabel)
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 심볼은 글자와 함께 가운데 정렬 (가이드에서 허용하는 배치)
                SvgPicture.asset('assets/images/kakao_symbol.svg', width: 15, height: 15),
                const SizedBox(width: AppSpacing.sm),
                Text('카카오 로그인', style: _labelStyle),
              ],
            ),
    );
  }
}

/// Apple 로그인 버튼. 로고는 Apple 공식 버튼 이미지 서비스(appleid.cdn-apple.com)에서 받은 이미지를 쓴다.
///
/// | 항목 | 규격 |
/// |---|---|
/// | 스타일 | 검정 배경 + 흰 로고 · 글자 |
/// | 문구 | Apple 한국어 공식 문구 "Apple로 로그인", 시스템 서체 |
/// | 로고 | 공식 이미지 (assets/images/apple_logo.png, 1x · 2x · 3x) |
/// | 크기 | 다른 로그인 버튼보다 작거나 덜 눈에 띄면 안 된다 → 카카오 버튼과 같은 높이 · 너비 · 모서리 |
class AppleLoginButton extends StatelessWidget {
  const AppleLoginButton({super.key, required this.onPressed, this.isLoading = false});

  final VoidCallback? onPressed;
  final bool isLoading;

  static TextStyle get _labelStyle => TextStyle(
    inherit: false, // 시스템 서체 (앱 글꼴을 물려받지 않음)
    fontFamily: SocialButtonSpec.systemFont,
    fontSize: 19,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    textBaseline: TextBaseline.alphabetic,
  );

  @override
  Widget build(BuildContext context) {
    return _SocialButtonFrame(
      color: Colors.black,
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const _ButtonSpinner(color: Colors.white)
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/apple_logo.png', width: 30, height: 30),
                Text('Apple로 로그인', style: _labelStyle),
                const SizedBox(width: 8), // 로고 이미지 안쪽 여백만큼 오른쪽도 비워 가운데를 맞춘다
              ],
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

/// 로그인 방법 공식 심볼 (설정 탭의 "연결된 로그인" 줄 등 작은 자리에 쓴다)
/// - 카카오: 공식 말풍선 심볼 (검정)
/// - Apple: Apple 로고 (Material 아이콘은 쓰지 않고, 밝은 배경에 맞게 검정 원 안에 공식 로고 이미지)
class LoginProviderSymbol extends StatelessWidget {
  const LoginProviderSymbol({super.key, required this.isKakao, this.size = 24});

  final bool isKakao;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (isKakao) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: AppColors.kakao, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: SvgPicture.asset('assets/images/kakao_symbol.svg', width: size * 0.5, height: size * 0.5),
      );
    }
    return ClipOval(
      child: Image.asset('assets/images/apple_logo.png', width: size, height: size, fit: BoxFit.cover),
    );
  }
}
