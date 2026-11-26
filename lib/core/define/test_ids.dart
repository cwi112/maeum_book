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

  /// 받은 기록의 행사 칩: form_event_3 / 새 행사 만들기 버튼
  static const String formEvent = 'form_event';
  static const String formEventCreate = 'form_event_create';

  // ── 행사 (받아요) ───────────────────────
  static const String eventAdd = 'event_add';
  static const String eventSearch = 'event_search';

  /// 행사 카드: event_card_3
  static String eventCard(int id) => 'event_card_$id';
  static const String eventAddEntry = 'event_add_entry';
  static const String eventEditButton = 'event_edit';
  static const String eventDeleteButton = 'event_delete';

  // 행사 사진: 추가 칸 / 사진 한 장(event_photo_12) / 찍기 · 앨범 / 전체 화면의 정보 수정 · 삭제 / 정보 창
  static const String eventPhotoAdd = 'event_photo_add';
  static String eventPhoto(int id) => 'event_photo_$id';
  static const String photoCamera = 'photo_camera';
  static const String photoAlbum = 'photo_album';
  static const String photoEdit = 'photo_edit';
  static const String photoDelete = 'photo_delete';
  static const String photoSenderField = 'photo_sender_field';
  static const String photoMemoField = 'photo_memo_field';
  static const String photoInfoSave = 'photo_info_save';
  static const String eventFormTitle = 'event_form_title';
  static const String eventFormType = 'event_form_type';
  static const String eventFormDate = 'event_form_date';
  static const String eventFormMemo = 'event_form_memo';
  static const String eventFormSave = 'event_form_save';

  // ── 경조사 종류 관리 ─────────────────────
  static const String settingsEventTypes = 'settings_event_types';
  static const String eventTypeAdd = 'event_type_add';
  static const String eventTypeNameField = 'event_type_name_field';

  /// 종류 한 줄 / 이름 변경 / 삭제 버튼: event_type_3, event_type_delete_3
  static String eventTypeTile(int id) => 'event_type_$id';
  static String eventTypeDelete(int id) => 'event_type_delete_$id';

  // ── 공통 ───────────────────────────────
  static const String toast = 'toast';
  static const String toastAction = 'toast_action';
  static const String dialogConfirm = 'dialog_confirm';
  static const String dialogCancel = 'dialog_cancel';
  static const String dialogInput = 'dialog_input';

  // ── 검색·필터 ──────────────────────────
  /// 검색창·필터 버튼: ledger_search_sent / ledger_filter_sent
  static String ledgerSearch(Enum direction) => 'ledger_search_${direction.name}';
  static String ledgerFilter(Enum direction) => 'ledger_filter_${direction.name}';
  static const String filterApply = 'filter_apply';
  static const String filterReset = 'filter_reset';

  /// 필터 시트 칩 접두어. 값 이름이 붙는다: filter_period_thisYear, filter_event_type_wedding
  static const String filterPeriod = 'filter_period';
  static const String filterEventType = 'filter_event_type';

  // ── 설정 ───────────────────────────────
  static const String settingsSeed = 'settings_seed';
  static const String settingsClear = 'settings_clear';
  static const String sampleTourEnd = 'sample_tour_end';
  static const String settingsAppInfo = 'settings_app_info';
  static const String settingsThemeMode = 'settings_theme_mode';
  static const String settingsExcelExport = 'settings_excel_export';
  static const String excelShare = 'excel_share'; // 엑셀 내보내기 창: 공유하기
  static const String excelSave = 'excel_save'; // 엑셀 내보내기 창: 내 휴대폰에 저장
  static const String settingsAccount = 'settings_account';
  static const String settingsSignOut = 'settings_sign_out';
  static const String settingsDeleteAccount = 'settings_delete_account';

  // ── 로그인 ─────────────────────────────
  static const String loginKakao = 'login_kakao';
  static const String loginApple = 'login_apple';
  static const String loginGuest = 'login_guest';
  static const String settingsLinkKakao = 'settings_link_kakao';
  static const String settingsLinkApple = 'settings_link_apple';

  // ── 통계 ───────────────────────────────
  static const String statsBalanceChart = 'stats_balance_chart';
  static const String statsTypeChart = 'stats_type_chart';
  static const String statsMonthlyChart = 'stats_monthly_chart';
  static const String statsRelationChart = 'stats_relation_chart';
  static const String statsTopPeople = 'stats_top_people';

  /// 종류별 그래프 방향 선택: stats_type_direction_sent
  static String statsTypeDirection(Enum direction) => 'stats_type_direction_${direction.name}';
}
