import 'package:material_ui/material_ui.dart';

/// 앱 공통 색상. 컨셉: 손편지·봉투처럼 따뜻한 크림 + 테라코타.
///
/// 화면 코드에서는 `Color(0xFF...)`를 직접 쓰지 말고 항상 여기 정의된 이름을 쓴다.
/// 예) `Text('5만원', style: TextStyle(color: AppColors.received))`
class AppColors {
  AppColors._();

  // ── 브랜드 ─────────────────────────────
  /// 대표 색: 테라코타 (버튼, 선택된 탭, 강조)
  static const Color primary = Color(0xFFC0714A);

  /// 대표 색의 아주 옅은 버전 (선택 배경, 칩, 아이콘 배경)
  static const Color primaryLight = Color(0xFFF6E6DC);

  /// 보조 색: 꿀색 (포인트, 배지)
  static const Color secondary = Color(0xFFE2A55B);

  // ── 배경 ───────────────────────────────
  /// 화면 배경: 크림색 종이
  static const Color background = Color(0xFFFBF7F2);

  /// 카드·시트 배경: 따뜻한 흰색
  static const Color surface = Color(0xFFFFFDFA);

  // ── 글자 ───────────────────────────────
  /// 본문 기본 글자: 진한 고동색 (검정보다 부드러움)
  static const Color textPrimary = Color(0xFF3B2F2A);

  /// 설명·날짜 등 덜 중요한 글자
  static const Color textSecondary = Color(0xFF8C7B70);

  /// 비활성·힌트 글자
  static const Color textHint = Color(0xFFBFB2A7);

  // ── 선·구분 ────────────────────────────
  static const Color divider = Color(0xFFEFE6DD);

  // ── 상태 ───────────────────────────────
  static const Color error = Color(0xFFC9503F);
  static const Color success = Color(0xFF5E9466);

  // ── 마음장부 전용 ──────────────────────
  /// 받은 금액: 차분한 청록
  static const Color received = Color(0xFF3F7F86);

  /// 보낸 금액: 장밋빛 빨강
  static const Color sent = Color(0xFFCB5C5C);
}
