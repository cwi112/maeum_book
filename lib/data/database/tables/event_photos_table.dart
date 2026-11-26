import 'package:drift/drift.dart';
import 'package:maeum_book/core/define/app_define.dart';
import 'package:maeum_book/data/database/tables/events_table.dart';
import 'package:maeum_book/data/database/tables/ledger_entries_table.dart';

/// 행사 사진 (화환 · 꽃 · 쌀화환 …). 사진 파일은 DB가 아니라 기기 폴더(회원은 서버 Storage)에 두고, 여기에는 정보만 둔다.
///
/// | 열 | 내용 |
/// |---|---|
/// | id | 사진 번호. 파일 이름도 이 번호로 정한다 (`<id>.jpg`, `<id>_thumb.jpg`) |
/// | eventId | 어느 행사 사진인지. 행사를 지우면 사진 정보도 지워진다 |
/// | senderName | 보낸 분 (선택). 리본에 적힌 이름 등 |
/// | entryId | 보낸 분을 이 행사의 받은 기록에서 골랐으면 그 기록. 기록을 지우면 비워진다 |
/// | memo | 메모 (선택). 예) 쌀화환 20kg |
@DataClassName('EventPhoto')
class EventPhotos extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get eventId => integer().references(Events, #id, onDelete: KeyAction.cascade)();

  TextColumn get senderName => text().withLength(max: AppDefine.personNameMaxLength).nullable()();

  IntColumn get entryId => integer().nullable().references(LedgerEntries, #id, onDelete: KeyAction.setNull)();

  TextColumn get memo => text().withLength(max: AppDefine.memoMaxLength).nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
