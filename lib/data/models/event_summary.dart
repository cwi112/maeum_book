import 'package:maeum_book/data/database/app_database.dart';

/// 행사 하나와 그 행사에서 받은 마음의 합계. (받아요 탭 행사 목록용)
class EventSummary {
  const EventSummary({required this.event, required this.total, required this.count, required this.giverNames});

  final LedgerEvent event;

  /// 받은 금액 합계 (원)
  final int total;

  /// 마음을 준 사람 수(기록 건수)
  final int count;

  /// 준 사람 이름들. 행사 목록에서 "사람 이름으로 검색"할 때 쓴다.
  final List<String> giverNames;
}
