part of 'entry_form_view_model.dart';

/// 기록 입력·수정 화면의 상태. (entry_form_view_model.dart의 일부 — part of)
///
/// ## 입력 항목
/// | 항목 | 필수 | 기본값 |
/// |---|:---:|---|
/// | 보냄/받음 [direction] | 필수 | 들어온 탭에 따라 |
/// | 날짜 [date] | 필수 | 오늘 |
/// | 경조사 종류 [eventType] | 필수 | 없음 (직접 골라야 함) |
/// | 상대방 이름 [personName] | 필수 | 빈칸 |
/// | 금액 [amount] | 필수 | 0 |
/// | 관계 [relation] | 선택 | 없음 |
/// | 메모 [memo] | 선택 | 빈칸 |
///
/// 종류는 일부러 기본값을 두지 않았다. "결혼"이 미리 골라져 있으면 장례인데도 그대로 저장되는 실수가 생기기 쉽다.
///
/// ## 오류 문구 표시 시점
/// 화면을 열자마자 빨간 글씨가 보이면 불편하므로, **저장 버튼을 한 번 누른 뒤([showErrors])부터** 오류를 보여준다.
class EntryFormState {
  const EntryFormState({
    required this.direction,
    required this.date,
    this.eventType,
    this.personName = '',
    this.amount = 0,
    this.relation,
    this.memo = '',
    this.showErrors = false,
    this.isSaving = false,
    this.original,
  });

  /// 수정할 기록으로 모든 칸을 채운 상태를 만든다.
  factory EntryFormState.fromEntry(LedgerEntry entry) => EntryFormState(
    direction: entry.direction,
    date: entry.date,
    eventType: entry.eventType,
    personName: entry.personName,
    amount: entry.amount,
    relation: entry.relation,
    memo: entry.memo ?? '',
    original: entry,
  );

  final RecordDirection direction;
  final DateTime date;
  final EventType? eventType;
  final String personName;
  final int amount;
  final Relation? relation;
  final String memo;

  /// 저장을 한 번이라도 눌렀는지 (오류 문구 표시 여부)
  final bool showErrors;

  /// 저장 중인지. 저장 중에는 버튼을 막아 같은 기록이 두 번 저장되지 않게 한다.
  final bool isSaving;

  /// 수정 중인 원래 기록. 새 기록이면 null.
  final LedgerEntry? original;

  /// 수정 화면인지 (화면 제목·완료 문구가 달라진다)
  bool get isEditing => original != null;

  // ── 항목별 오류 (없으면 null) ──────────────
  String? get eventTypeError => showErrors && eventType == null ? '경조사 종류를 골라 주세요' : null;

  String? get personNameError => showErrors && personName.isBlank ? '이름을 입력해 주세요' : null;

  String? get amountError {
    if (!showErrors) return null;
    if (amount <= 0) return '금액을 입력해 주세요';
    if (amount > AppDefine.amountMax) return '${AppDefine.amountMax.manWon}까지 입력할 수 있어요';
    return null;
  }

  /// 필수 항목이 모두 올바르게 채워졌는지
  bool get isValid => eventType != null && personName.isNotBlank && amount > 0 && amount <= AppDefine.amountMax;

  /// 일부 값만 바꾼 새 상태를 만든다.
  ///
  /// 비울 수 있는 값(종류·관계)은 `null`을 넣어 "지우기"를 할 수 있어야 해서 함수로 받는다.
  /// 예) `copyWith(relation: () => null)` → 관계 선택 해제
  EntryFormState copyWith({
    RecordDirection? direction,
    DateTime? date,
    ValueGetter<EventType?>? eventType,
    String? personName,
    int? amount,
    ValueGetter<Relation?>? relation,
    String? memo,
    bool? showErrors,
    bool? isSaving,
  }) => EntryFormState(
    direction: direction ?? this.direction,
    date: date ?? this.date,
    eventType: eventType != null ? eventType() : this.eventType,
    personName: personName ?? this.personName,
    amount: amount ?? this.amount,
    relation: relation != null ? relation() : this.relation,
    memo: memo ?? this.memo,
    showErrors: showErrors ?? this.showErrors,
    isSaving: isSaving ?? this.isSaving,
    original: original,
  );
}
