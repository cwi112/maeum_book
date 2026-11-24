part of 'ledger_list_view_model.dart';

/// 기간 필터.
enum LedgerPeriod {
  all('전체 기간'),
  thisYear('올해'),
  lastYear('작년'),
  recent3Months('최근 3개월');

  const LedgerPeriod(this.label);

  final String label;

  /// [date]가 이 기간에 들어가는지. [now]는 테스트에서 날짜를 고정하려고 받는다.
  bool contains(DateTime date, DateTime now) => switch (this) {
    LedgerPeriod.all => true,
    LedgerPeriod.thisYear => date.year == now.year,
    LedgerPeriod.lastYear => date.year == now.year - 1,
    LedgerPeriod.recent3Months => !date.isBefore(DateTime(now.year, now.month - 3, now.day)),
  };
}

/// 보내요·받아요 목록의 검색·필터 조건. (ledger_list_view_model.dart의 일부 — part of)
///
/// - [query]: 이름·메모에 이 글자가 들어간 기록만 (대소문자 구분 없음)
/// - [period]: 기간
/// - [eventTypeId]: 경조사 종류 id (null이면 전체)
class LedgerFilter {
  const LedgerFilter({this.query = '', this.period = LedgerPeriod.all, this.eventTypeId});

  final String query;
  final LedgerPeriod period;
  final int? eventTypeId;

  /// 아무 조건도 없는 상태
  static const LedgerFilter none = LedgerFilter();

  /// 검색어를 뺀 조건(기간·종류)이 걸려 있는지. 필터 버튼에 표시(점)를 띄울 때 쓴다.
  bool get hasSheetFilter => period != LedgerPeriod.all || eventTypeId != null;

  /// 검색어 포함, 조건이 하나라도 걸려 있는지
  bool get isActive => query.isNotBlank || hasSheetFilter;

  /// 기록 한 건이 조건에 맞는지
  bool matches(LedgerEntry entry, DateTime now) {
    if (eventTypeId != null && entry.eventTypeId != eventTypeId) return false;
    if (!period.contains(entry.date, now)) return false;
    final keyword = query.trim().toLowerCase();
    if (keyword.isEmpty) return true;
    return entry.personName.toLowerCase().contains(keyword) || (entry.memo?.toLowerCase().contains(keyword) ?? false);
  }

  LedgerFilter copyWith({String? query, LedgerPeriod? period, ValueGetter<int?>? eventTypeId}) => LedgerFilter(
    query: query ?? this.query,
    period: period ?? this.period,
    eventTypeId: eventTypeId != null ? eventTypeId() : this.eventTypeId,
  );
}
