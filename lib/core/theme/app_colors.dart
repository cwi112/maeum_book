import 'package:material_ui/material_ui.dart';

/// 앱 공통 색상. 컨셉: 손편지·봉투처럼 따뜻한 크림 + 테라코타. (다크 모드: 밤의 찻집처럼 따뜻한 고동색)
///
/// 화면 코드에서는 `Color(0xFF...)`를 직접 쓰지 말고 항상 여기 정의된 이름을 쓴다.
/// 예) `Text('5만원', style: TextStyle(color: AppColors.received))`
///
/// 값은 지금 화면 모드(라이트 · 다크)에 맞는 [AppPalette]에서 나온다. 화면 모드가 바뀌면 앱 맨 위의
/// [AppPaletteSync]가 팔레트를 바꾸고 모든 화면을 다시 그린다. 그래서 `const`로는 쓸 수 없다.
class AppColors {
  AppColors._();

  static AppPalette _palette = AppPalette.light;

  /// 지금 쓰는 팔레트 (라이트 · 다크)
  static AppPalette get palette => _palette;

  /// 팔레트를 바꾼다. 바꿨으면 true. (보통 [AppPaletteSync]만 부른다)
  static bool use(AppPalette palette) {
    if (identical(_palette, palette)) return false;
    _palette = palette;
    return true;
  }

  static Color get primary => _palette.primary;
  static Color get primaryLight => _palette.primaryLight;
  static Color get secondary => _palette.secondary;
  static Color get background => _palette.background;
  static Color get surface => _palette.surface;
  static Color get textPrimary => _palette.textPrimary;
  static Color get textSecondary => _palette.textSecondary;
  static Color get textHint => _palette.textHint;
  static Color get divider => _palette.divider;
  static Color get shadow => _palette.shadow;
  static Color get error => _palette.error;
  static Color get success => _palette.success;
  static Color get received => _palette.received;
  static Color get sent => _palette.sent;
  static Color get kakao => _palette.kakao;
  static Color get kakaoLabel => _palette.kakaoLabel;
  static Color get deleteAction => _palette.deleteAction;
  static Color get deleteActionPressed => _palette.deleteActionPressed;
  static Color get editAction => _palette.editAction;
  static Color get editActionPressed => _palette.editActionPressed;
  static Color get pressedOverlay => _palette.pressedOverlay;
  static Color get loadingDim => _palette.loadingDim;
  static Color get loadingDimSubtext => _palette.loadingDimSubtext;
  static List<Color> get chartPalette => _palette.chartPalette;
}

/// 화면 모드 하나의 색 묶음. [AppPalette.light] · [AppPalette.dark]
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.primary,
    required this.primaryLight,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.divider,
    required this.shadow,
    required this.error,
    required this.success,
    required this.received,
    required this.sent,
    required this.deleteAction,
    required this.deleteActionPressed,
    required this.editAction,
    required this.editActionPressed,
    required this.pressedOverlay,
    required this.loadingDim,
    required this.chartPalette,
  });

  final Brightness brightness;

  // ── 브랜드 ─────────────────────────────
  /// 대표 색: 테라코타 (버튼, 선택된 탭, 강조)
  final Color primary;

  /// 대표 색의 옅은 버전 (선택 배경, 칩, 아이콘 배경). 다크에서는 어두운 테라코타
  final Color primaryLight;

  /// 보조 색: 꿀색 (포인트, 배지)
  final Color secondary;

  // ── 배경 ───────────────────────────────
  /// 화면 배경: 크림색 종이 (다크: 짙은 고동)
  final Color background;

  /// 카드·시트 배경 (배경보다 한 단계 밝게)
  final Color surface;

  // ── 글자 ───────────────────────────────
  /// 본문 기본 글자
  final Color textPrimary;

  /// 설명·날짜 등 덜 중요한 글자
  final Color textSecondary;

  /// 비활성·힌트 글자
  final Color textHint;

  // ── 선·구분 ────────────────────────────
  final Color divider;

  /// 그림자 색: 검정 대신 고동색을 아주 옅게 써서 따뜻한 톤을 유지한다.
  final Color shadow;

  // ── 상태 ───────────────────────────────
  final Color error;
  final Color success;

  // ── 마음장부 전용 ──────────────────────
  /// 받은 금액: 차분한 청록
  final Color received;

  /// 보낸 금액: 장밋빛 빨강
  final Color sent;

  // ── 외부 서비스 (각 회사 디자인 가이드 색 → 화면 모드와 상관없이 같다) ──
  /// 카카오 로그인 버튼 배경 (카카오 노랑)
  Color get kakao => const Color(0xFFFEE500);

  /// 카카오 로그인 버튼 글자 (검정 85%)
  Color get kakaoLabel => const Color(0xD9000000);

  // ── 밀어서 나오는 버튼 (스와이프 액션) ──
  /// 삭제 버튼 / 눌렀을 때 (조금 더 진하게 가라앉는 느낌)
  final Color deleteAction;
  final Color deleteActionPressed;

  /// 수정 버튼 / 눌렀을 때
  final Color editAction;
  final Color editActionPressed;

  /// 목록 줄을 눌렀을 때 퍼지는 색 (아주 옅은 테라코타)
  final Color pressedOverlay;

  /// 로딩 중 화면을 덮는 어두운 막 과 그 위의 작은 안내 글자 (흰색 80%)
  final Color loadingDim;
  Color get loadingDimSubtext => const Color(0xCCFFFFFF);

  // ── 차트 ───────────────────────────────
  /// 그래프 조각 색. 따뜻한 톤 안에서 서로 잘 구분되도록 고른 순서다. (경조사 종류 순서대로 사용)
  final List<Color> chartPalette;

  bool get isDark => brightness == Brightness.dark;

  static const light = AppPalette(
    brightness: Brightness.light,
    primary: Color(0xFFC0714A),
    primaryLight: Color(0xFFF6E6DC),
    secondary: Color(0xFFE2A55B),
    background: Color(0xFFFBF7F2),
    surface: Color(0xFFFFFDFA),
    textPrimary: Color(0xFF3B2F2A),
    textSecondary: Color(0xFF8C7B70),
    textHint: Color(0xFFBFB2A7),
    divider: Color(0xFFEFE6DD),
    shadow: Color(0x2E3B2F2A),
    error: Color(0xFFC9503F),
    success: Color(0xFF5E9466),
    received: Color(0xFF3F7F86),
    sent: Color(0xFFCB5C5C),
    deleteAction: Color(0xFFD9655A),
    deleteActionPressed: Color(0xFFB04A40),
    editAction: Color(0xFFE2A55B),
    editActionPressed: Color(0xFFC4863D),
    pressedOverlay: Color(0x33C0714A),
    loadingDim: Color(0x993B2F2A),
    chartPalette: [
      Color(0xFFC0714A), // 테라코타
      Color(0xFF6B8F9C), // 회청
      Color(0xFFE2A55B), // 꿀색
      Color(0xFFCB5C5C), // 장밋빛
      Color(0xFF7FA37A), // 세이지
      Color(0xFF9A7BA8), // 라벤더
      Color(0xFFB7A99A), // 모래
    ],
  );

  /// 다크: 새까만 검정 대신 따뜻한 고동색 바탕. 강조색은 어두운 바탕에서 잘 읽히게 한 톤 밝게.
  static const dark = AppPalette(
    brightness: Brightness.dark,
    primary: Color(0xFFDB8B63),
    primaryLight: Color(0xFF4A3026),
    secondary: Color(0xFFE8B370),
    background: Color(0xFF1B1613),
    surface: Color(0xFF26201C),
    textPrimary: Color(0xFFF2E8E0),
    textSecondary: Color(0xFFB5A498),
    textHint: Color(0xFF7D6E63),
    divider: Color(0xFF3B312B),
    shadow: Color(0x66000000),
    error: Color(0xFFE5776A),
    success: Color(0xFF86B98D),
    received: Color(0xFF72B6BD),
    sent: Color(0xFFE68282),
    deleteAction: Color(0xFFC65A50),
    deleteActionPressed: Color(0xFFA2463D),
    editAction: Color(0xFFC99247),
    editActionPressed: Color(0xFFA97832),
    pressedOverlay: Color(0x33DB8B63),
    loadingDim: Color(0xB3000000),
    chartPalette: [
      Color(0xFFDB8B63), // 테라코타
      Color(0xFF86AAB7), // 회청
      Color(0xFFE8B370), // 꿀색
      Color(0xFFE07A7A), // 장밋빛
      Color(0xFF94BA8F), // 세이지
      Color(0xFFB396C1), // 라벤더
      Color(0xFFA89A8B), // 모래
    ],
  );
}

/// 앱 맨 위(MaterialApp.builder)에서 지금 테마의 밝기에 맞게 [AppColors] 팔레트를 바꾸고,
/// 바뀌었으면 아래 모든 화면을 다시 그린다. (화면 상태 · 입력값 · 스크롤 위치는 그대로)
class AppPaletteSync extends StatelessWidget {
  const AppPaletteSync({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
    if (AppColors.use(palette)) {
      // AppColors는 위젯이 의존 관계로 알 수 없는 값이라, 아래 위젯들을 직접 "다시 그려야 함"으로 표시한다.
      void rebuild(Element element) {
        element.markNeedsBuild();
        element.visitChildren(rebuild);
      }

      (context as Element).visitChildren(rebuild);
    }
    return child;
  }
}
