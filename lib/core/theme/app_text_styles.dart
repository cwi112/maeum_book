import 'package:maeum_book/core/theme/app_colors.dart';
import 'package:material_ui/material_ui.dart';

/// 앱 공통 글자 스타일.
///
/// - 제목·금액: 고운바탕 (손편지 같은 따뜻한 느낌)
/// - 본문·설명: Pretendard (깔끔하고 잘 읽힘)
///
/// 보통은 [AppText] 위젯으로 쓰고, 직접 스타일이 필요할 때만 여기 값을 쓴다.
/// ```dart
/// AppText.title('이번 달 보낸 마음')              // 위젯으로 (가장 간단)
/// Text('5만원', style: AppTextStyles.amount)    // 스타일만
/// AppTextStyles.body.bold.withColor(AppColors.sent)  // 조금 바꿔 쓰기
/// ```
/// 글자 색은 지금 화면 모드(라이트 · 다크)의 [AppColors]를 따른다. 그래서 `const`로는 쓸 수 없다.
class AppTextStyles {
  AppTextStyles._();

  static const String bodyFont = 'Pretendard';
  static const String titleFont = 'GowunBatang';

  // ── 제목 (고운바탕) ────────────────────
  /// 화면 상단 큰 제목 (26)
  static TextStyle get headline => _headline.copyWith(color: AppColors.textPrimary);

  /// 카드·섹션 제목 (20)
  static TextStyle get title => _title.copyWith(color: AppColors.textPrimary);

  // ── 본문 (Pretendard) ─────────────────
  /// 작은 제목, 목록 항목 이름 (16, 굵게)
  static TextStyle get subtitle => _subtitle.copyWith(color: AppColors.textPrimary);

  /// 기본 본문 (15)
  static TextStyle get body => _body.copyWith(color: AppColors.textPrimary);

  /// 작은 본문 (13)
  static TextStyle get bodySmall => _bodySmall.copyWith(color: AppColors.textPrimary);

  /// 날짜·보조 설명 (12, 회색)
  static TextStyle get caption => _caption.copyWith(color: AppColors.textSecondary);

  /// 버튼·탭 글자 (15, 굵게)
  static TextStyle get label => _label.copyWith(color: AppColors.textPrimary);

  // ── 금액 (고운바탕) ────────────────────
  /// 합계 등 큰 금액 (30)
  static TextStyle get amountLarge => _amountLarge.copyWith(color: AppColors.textPrimary);

  /// 목록 안의 금액 (17)
  static TextStyle get amount => _amount.copyWith(color: AppColors.textPrimary);

  // ── 모양 (색 없음) ─────────────────────
  static const TextStyle _headline = TextStyle(
    fontFamily: titleFont,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );
  static const TextStyle _title = TextStyle(
    fontFamily: titleFont,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );
  static const TextStyle _subtitle = TextStyle(
    fontFamily: bodyFont,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  static const TextStyle _body = TextStyle(
    fontFamily: bodyFont,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  static const TextStyle _bodySmall = TextStyle(
    fontFamily: bodyFont,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  static const TextStyle _caption = TextStyle(
    fontFamily: bodyFont,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
  static const TextStyle _label = TextStyle(
    fontFamily: bodyFont,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
  static const TextStyle _amountLarge = TextStyle(
    fontFamily: titleFont,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  static const TextStyle _amount = TextStyle(
    fontFamily: titleFont,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  /// 작은 본문(13) 모양 — 색 없이. 테마의 칩 글자처럼 색을 따로 정할 때 쓴다.
  static const TextStyle bodySmallBase = _bodySmall;

  /// 버튼·탭 글자(15, 굵게) 모양 — 색 없이.
  static const TextStyle labelBase = _label;

  /// Material 기본 위젯(AppBar, ListTile, 버튼 등)이 쓰는 글자 스타일. 화면 모드의 색 [p]로 만든다.
  /// 위 스타일과 연결해 두어서, 기본 위젯도 같은 글꼴로 나온다.
  static TextTheme textThemeFor(AppPalette p) {
    TextStyle c(TextStyle base, [Color? color]) => base.copyWith(color: color ?? p.textPrimary);
    return TextTheme(
      headlineMedium: c(_headline),
      headlineSmall: c(_headline),
      titleLarge: c(_title),
      titleMedium: c(_subtitle),
      titleSmall: c(_label),
      bodyLarge: c(_body),
      bodyMedium: c(_body),
      bodySmall: c(_caption, p.textSecondary),
      labelLarge: c(_label),
      labelMedium: c(const TextStyle(fontFamily: bodyFont, fontSize: 12, fontWeight: FontWeight.w500)),
      labelSmall: c(const TextStyle(fontFamily: bodyFont, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }
}
