/// 앱 전체에서 쓰는 고정값 모음.
///
/// 여러 파일에 같은 숫자·문자열을 직접 쓰면 바꿀 때 하나를 빠뜨리기 쉽다.
/// 그래서 "의미 있는 고정값"은 여기 한곳에 이름을 붙여 두고 가져다 쓴다.
///
/// ```dart
/// Text(AppDefine.appName)
/// TextField(maxLength: AppDefine.personNameMaxLength)
/// ```
abstract final class AppDefine {
  // ── 앱 정보 ────────────────────────────
  static const String appName = '마음장부';

  /// 화면에 보여줄 버전. pubspec.yaml의 version과 맞춘다.
  static const String appVersion = '1.0.0';

  // ── 데이터베이스 ───────────────────────
  /// 기기에 저장되는 DB 파일 이름 (실제 파일: maeum_book.sqlite)
  static const String databaseName = 'maeum_book';

  // ── 입력 제한 ──────────────────────────
  /// 상대방 이름 최대 글자 수 (DB 컬럼 제한과 같아야 한다)
  static const int personNameMaxLength = 50;

  /// 메모 최대 글자 수
  static const int memoMaxLength = 200;

  /// 경조사 종류 이름 최대 글자 수
  static const int eventTypeNameMaxLength = 10;

  /// 행사 이름 최대 글자 수
  static const int eventTitleMaxLength = 30;

  /// 한 번에 입력할 수 있는 최대 금액 (1억 원)
  static const int amountMax = 100000000;

  // ── 메시지 ─────────────────────────────
  static const String comingSoonMessage = '곧 추가될 기능이에요';
}
