import 'package:drift/drift.dart';
import 'package:maeum_book/core/define/app_define.dart';
import 'package:maeum_book/data/database/tables/event_types_table.dart';

/// 행사 테이블: **내가 연** 경조사. (스키마 v3에서 추가)
///
/// 예) "우리 결혼식" (결혼, 2025-05-10) — 이 행사에 마음을 준 사람들이 받은 기록으로 묶인다.
///
/// 받아요 탭은 이 행사들을 먼저 보여주고, 행사를 누르면 그 안의 받은 기록(준 사람들)을 보여준다.
/// 받은 기록의 날짜·종류는 행사 값을 그대로 따른다. (행사를 고치면 안의 기록도 같이 바뀜)
@DataClassName('LedgerEvent')
class Events extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 행사 이름 (예: 우리 결혼식, 아버지 칠순)
  TextColumn get title => text().withLength(min: 1, max: AppDefine.eventTitleMaxLength)();

  /// 경조사 종류. 종류를 지울 때는 Repository에서 먼저 "기타"로 옮기므로 끊어지는 일이 없다.
  IntColumn get eventTypeId => integer().references(EventTypes, #id)();

  /// 행사 날짜
  DateTimeColumn get date => dateTime()();

  /// 메모 (선택)
  TextColumn get memo => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
