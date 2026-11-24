import 'package:material_ui/material_ui.dart';

/// 앱 공통 색상.
///
/// 화면 코드에서는 `Color(0xFF...)`를 직접 쓰지 말고 항상 여기 정의된 이름을 쓴다.
/// 예) `Text('5만원', style: TextStyle(color: AppColors.received))`
class AppColors {
  AppColors._();

  // ── 브랜드 ─────────────────────────────
  /// 앱 대표 색 (버튼, 선택된 탭 등)
  static const Color primary = Color(0xFF2E7D6B);

  /// 보조 강조 색
  static const Color secondary = Color(0xFFE8A87C);

  // ── 배경 ───────────────────────────────
  static const Color background = Color(0xFFF7F8F6);
  static const Color surface = Color(0xFFFFFFFF);

  // ── 글자 ───────────────────────────────
  /// 본문 기본 글자
  static const Color textPrimary = Color(0xFF1F2421);

  /// 설명·날짜 등 덜 중요한 글자
  static const Color textSecondary = Color(0xFF6B7370);

  /// 비활성·힌트 글자
  static const Color textHint = Color(0xFFA9B0AD);

  // ── 선·구분 ────────────────────────────
  static const Color divider = Color(0xFFE3E6E4);

  // ── 상태 ───────────────────────────────
  static const Color error = Color(0xFFD64545);
  static const Color success = Color(0xFF3A9D5D);

  // ── 마음장부 전용 ──────────────────────
  /// 받은 금액
  static const Color received = Color(0xFF2F6FD6);

  /// 보낸 금액
  static const Color sent = Color(0xFFD6573A);
}
