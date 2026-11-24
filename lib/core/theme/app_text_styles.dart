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
class AppTextStyles {
  AppTextStyles._();

  static const String bodyFont = 'Pretendard';
  static const String titleFont = 'GowunBatang';

  // ── 제목 (고운바탕) ────────────────────
  /// 화면 상단 큰 제목 (26)
  static const TextStyle headline = TextStyle(
    fontFamily: titleFont,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  /// 카드·섹션 제목 (20)
  static const TextStyle title = TextStyle(
    fontFamily: titleFont,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  // ── 본문 (Pretendard) ─────────────────
  /// 작은 제목, 목록 항목 이름 (16, 굵게)
  static const TextStyle subtitle = TextStyle(
    fontFamily: bodyFont,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  /// 기본 본문 (15)
  static const TextStyle body = TextStyle(
    fontFamily: bodyFont,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// 작은 본문 (13)
  static const TextStyle bodySmall = TextStyle(
    fontFamily: bodyFont,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// 날짜·보조 설명 (12, 회색)
  static const TextStyle caption = TextStyle(
    fontFamily: bodyFont,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  /// 버튼·탭 글자 (15, 굵게)
  static const TextStyle label = TextStyle(
    fontFamily: bodyFont,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  // ── 금액 (고운바탕) ────────────────────
  /// 합계 등 큰 금액 (30)
  static const TextStyle amountLarge = TextStyle(
    fontFamily: titleFont,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  /// 목록 안의 금액 (17)
  static const TextStyle amount = TextStyle(
    fontFamily: titleFont,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  /// Material 기본 위젯(AppBar, ListTile, 버튼 등)이 쓰는 글자 스타일.
  /// 위 스타일과 연결해 두어서, 기본 위젯도 같은 글꼴로 나온다.
  static const TextTheme textTheme = TextTheme(
    headlineMedium: headline,
    headlineSmall: headline,
    titleLarge: title,
    titleMedium: subtitle,
    titleSmall: label,
    bodyLarge: body,
    bodyMedium: body,
    bodySmall: caption,
    labelLarge: label,
    labelMedium: TextStyle(
      fontFamily: bodyFont,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
    ),
    labelSmall: TextStyle(
      fontFamily: bodyFont,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
    ),
  );
}
