/// 자동화 테스트(Appium, 위젯 테스트)에서 화면 요소를 찾기 위한 고유 이름 모음.
///
/// ## 어떻게 동작하나
/// 위젯에 `.testId(TestIds.xxx)`를 붙이면 `Semantics(identifier: ...)`로 감싸진다. (widget_extension.dart)
/// - Android: 이 값이 **resource-id**로 노출된다 → Appium UiAutomator2에서 `By.id("save_button")`으로 찾는다.
/// - iOS: **accessibilityIdentifier**로 노출된다 → Appium XCUITest에서 `accessibility id`로 찾는다.
/// - 위젯 테스트: `find.bySemanticsIdentifier(TestIds.saveButton)`으로 찾는다.
///
/// 화면 문구는 바뀔 수 있지만 이 이름은 바뀌지 않게 유지한다. (테스트가 깨지지 않도록)
/// 이름 규칙: 소문자_밑줄, `화면_요소` 순서.
abstract final class TestIds {
  // ── 하단 탭 ────────────────────────────
  static const String tabSent = 'tab_sent';
  static const String tabReceived = 'tab_received';
  static const String tabStats = 'tab_stats';
  static const String tabSettings = 'tab_settings';

  // ── 목록 (보내요·받아요) ─────────────────
  /// 기록 추가 버튼. 방향 이름이 붙는다: ledger_add_sent / ledger_add_received
  static String ledgerAdd(Enum direction) => 'ledger_add_${direction.name}';

  /// 합계 카드: ledger_summary_sent / ledger_summary_received
  static String ledgerSummary(Enum direction) => 'ledger_summary_${direction.name}';

  /// 기록 한 줄: entry_tile_12
  static String entryTile(int id) => 'entry_tile_$id';

  /// 밀어서 나오는 버튼: entry_edit_12 / entry_delete_12
  static String entryEdit(int id) => 'entry_edit_$id';
  static String entryDelete(int id) => 'entry_delete_$id';

  // ── 입력 화면 ──────────────────────────
  /// 구분 버튼: form_direction_sent / form_direction_received
  static String formDirection(Enum direction) => 'form_direction_${direction.name}';
  static const String formDate = 'form_date';

  /// 칩 묶음 접두어. 칩마다 뒤에 값 이름이 붙는다: form_event_type_wedding, form_relation_friend
  static const String formEventType = 'form_event_type';
  static const String formRelation = 'form_relation';
  static const String formPersonName = 'form_person_name';
  static const String formAmount = 'form_amount';

  /// 금액 빠른 입력 버튼: form_amount_add_50000
  static String formAmountAdd(int amount) => 'form_amount_add_$amount';
  static const String formMemo = 'form_memo';
  static const String formSave = 'form_save';

  // ── 공통 ───────────────────────────────
  static const String toast = 'toast';
  static const String toastAction = 'toast_action';

  // ── 통계 ───────────────────────────────
  static const String statsBalanceChart = 'stats_balance_chart';
  static const String statsTypeChart = 'stats_type_chart';

  /// 종류별 그래프 방향 선택: stats_type_direction_sent
  static String statsTypeDirection(Enum direction) => 'stats_type_direction_${direction.name}';
}
