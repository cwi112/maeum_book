/// 앱 공통 간격·모서리 크기.
///
/// 여백이나 둥근 정도를 숫자로 직접 쓰지 말고 여기 이름을 쓴다.
/// 예) `Padding(padding: EdgeInsets.all(AppSpacing.md))`
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  /// 화면 좌우 기본 여백
  static const double screen = 20;
}

class AppRadius {
  AppRadius._();

  /// 칩·작은 버튼
  static const double sm = 10;

  /// 버튼·입력창
  static const double md = 14;

  /// 카드
  static const double lg = 20;

  /// 바텀시트 위쪽
  static const double xl = 28;
}
