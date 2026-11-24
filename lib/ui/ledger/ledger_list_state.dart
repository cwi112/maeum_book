part of 'ledger_list_view_model.dart';

/// 보내요·받아요 화면의 상태. (ledger_list_view_model.dart의 일부 — part of)
///
/// DB에서 받은 **전체 목록**([allEntries])과 **검색·필터 조건**([filter])을 같이 들고 있고,
/// 화면에 보여줄 목록([entries])은 둘을 조합해 그때그때 계산한다.
/// 그래서 검색어를 바꿔도 DB를 다시 읽지 않고, 결과가 깜빡임 없이 바로 바뀐다.
class LedgerListState {
  const LedgerListState({this.allEntries = const [], this.filter = LedgerFilter.none, required this.now});

  /// 이 방향의 전체 기록 (최신 날짜순)
  final List<LedgerEntry> allEntries;

  final LedgerFilter filter;

  /// 기간 필터 기준 시각 (상태를 만든 시점)
  final DateTime now;

  /// 조건에 맞는 기록만 (조건이 없으면 전체)
  List<LedgerEntry> get entries =>
      filter.isActive ? allEntries.where((entry) => filter.matches(entry, now)).toList() : allEntries;

  /// 보이는 목록 금액의 합계 (원). 필터가 걸려 있으면 필터 결과의 합계다.
  int get total => entries.fold(0, (sum, entry) => sum + entry.amount);

  /// 보이는 기록 건수
  int get count => entries.length;

  /// 기록이 하나도 없는지 (필터와 상관없이)
  bool get hasNoRecords => allEntries.isEmpty;

  LedgerListState copyWith({List<LedgerEntry>? allEntries, LedgerFilter? filter}) =>
      LedgerListState(allEntries: allEntries ?? this.allEntries, filter: filter ?? this.filter, now: now);
}
