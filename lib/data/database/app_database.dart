import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:maeum_book/core/define/app_define.dart';
import 'package:maeum_book/data/database/daos/event_dao.dart';
import 'package:maeum_book/data/database/daos/event_photo_dao.dart';
import 'package:maeum_book/data/database/daos/event_type_dao.dart';
import 'package:maeum_book/data/database/daos/ledger_dao.dart';
import 'package:maeum_book/data/database/tables/event_photos_table.dart';
import 'package:maeum_book/data/database/tables/event_types_table.dart';
import 'package:maeum_book/data/database/tables/events_table.dart';
import 'package:maeum_book/data/database/tables/ledger_entries_table.dart';
import 'package:maeum_book/data/models/models.dart';

export 'package:maeum_book/data/database/daos/event_dao.dart';
export 'package:maeum_book/data/database/daos/event_photo_dao.dart';
export 'package:maeum_book/data/database/daos/event_type_dao.dart';
export 'package:maeum_book/data/database/daos/ledger_dao.dart';
export 'package:maeum_book/data/database/tables/event_types_table.dart' show DefaultEventTypes;

part 'app_database.g.dart';

/// 앱의 로컬 데이터베이스 (SQLite + Drift).
///
/// ## 어떻게 동작하나
/// 1. `@DriftDatabase`에 어떤 테이블과 DAO를 쓰는지 적는다.
/// 2. `dart run build_runner build`를 실행하면 `app_database.g.dart`에 실제 코드(`_$AppDatabase`)가 생성된다.
///    테이블·DAO를 고쳤다면 이 명령을 **다시 실행**해야 한다.
/// 3. 앱이 처음 DB를 쓰는 순간 휴대폰 안에 `maeum_book.sqlite` 파일이 만들어지고, 이후로는 그 파일을 계속 쓴다.
///    (앱을 지우기 전까지 데이터가 유지된다. 인터넷·서버 필요 없음)
///
/// ## 앱 전체에서 하나만 쓴다
/// DB 연결을 여러 개 만들면 데이터가 꼬일 수 있어서, [appDatabaseProvider]를 통해 **하나만** 만들어 공유한다.
@DriftDatabase(
  tables: [LedgerEntries, EventTypes, Events, EventPhotos],
  daos: [LedgerDao, EventTypeDao, EventDao, EventPhotoDao],
)
class AppDatabase extends _$AppDatabase {
  /// [executor]를 넘기지 않으면 휴대폰 저장소의 DB 파일을 연다.
  /// 테스트에서는 `NativeDatabase.memory()`를 넘겨 메모리에만 있는 임시 DB로 실행한다.
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// 이름이 다른 DB 파일을 연다. (회원 계정별 사본: `maeum_book_<사용자 id>.sqlite`)
  AppDatabase.named(String name) : super(driftDatabase(name: name));

  /// DB 구조(스키마) 버전.
  /// - v1: 최초 (기록 테이블)
  /// - v2: 관계(relation) 컬럼 추가
  /// - v3: 경조사 종류를 테이블로(event_types), 행사 테이블(events) 추가, 받은 기록을 행사에 연결
  /// - v4: 행사 사진 테이블(event_photos) 추가
  ///
  /// 출시 후에 테이블·컬럼을 바꾸면 이 숫자를 1 올리고 [migration]의 `onUpgrade`에 변경 방법을 적어야 한다.
  /// 그래야 이미 앱을 쓰던 사람의 기존 데이터가 지워지지 않고 새 구조로 옮겨진다.
  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    // 앱을 처음 설치해서 DB 파일이 없을 때: 모든 테이블·인덱스를 만들고 기본 경조사 종류를 넣는다.
    onCreate: (m) async {
      await m.createAll();
      await _insertDefaultEventTypes();
    },
    // 이미 설치된 앱이 새 버전으로 업데이트될 때: 버전 차이만큼 단계별로 구조를 바꾼다.
    // 단계를 if로 나눠 두면 1→3처럼 여러 버전을 건너뛰어 업데이트해도 순서대로 모두 적용된다.
    onUpgrade: (m, from, to) async {
      // v2: 관계(relation) 컬럼 추가. 기존 기록의 관계는 비어 있음(null)으로 남는다.
      if (from < 2) await m.addColumn(ledgerEntries, ledgerEntries.relation);

      // v3: 경조사 종류를 글자(enum) → 테이블 번호로, 행사 테이블 추가
      if (from < 3) {
        await m.createTable(eventTypes);
        await _insertDefaultEventTypes();
        await m.createTable(events);

        // 기록 테이블을 새 구조로 다시 만들면서 데이터를 옮긴다. (SQLite는 컬럼 타입 변경을 직접 지원하지 않음)
        // - 예전 event_type 글자('wedding')를 기본 종류 번호(1)로 바꿔 event_type_id에 넣는다.
        // - event_id(행사)는 일단 비워 두고 아래에서 채운다.
        final caseWhen = DefaultEventTypes.all.map((t) => "WHEN '${t.$3}' THEN ${t.$1}").join(' ');
        await m.alterTable(
          TableMigration(
            ledgerEntries,
            columnTransformer: {
              ledgerEntries.eventTypeId: CustomExpression<int>(
                'CASE event_type $caseWhen ELSE ${DefaultEventTypes.otherId} END',
              ),
            },
            newColumns: [ledgerEntries.eventTypeId, ledgerEntries.eventId],
          ),
        );

        // 예전 받은 기록을 "같은 종류 + 같은 날짜"끼리 행사 하나로 묶는다. 행사 이름은 종류 이름으로 시작한다.
        await customStatement('''
          INSERT INTO events (title, event_type_id, date, created_at)
          SELECT t.name, e.event_type_id, e.date, MIN(e.created_at)
          FROM ledger_entries e JOIN event_types t ON t.id = e.event_type_id
          WHERE e.direction = 'received'
          GROUP BY e.event_type_id, e.date
        ''');
        await customStatement('''
          UPDATE ledger_entries SET event_id = (
            SELECT ev.id FROM events ev
            WHERE ev.event_type_id = ledger_entries.event_type_id AND ev.date = ledger_entries.date
          )
          WHERE direction = 'received'
        ''');
      }

      // v4: 행사 사진 테이블 추가 (기존 데이터는 그대로)
      if (from < 4) await m.createTable(eventPhotos);
    },
    // DB를 열 때마다: 외래 키(행사 삭제 시 안의 기록도 삭제 등) 규칙을 켠다.
    // 마이그레이션이 끝난 뒤에 실행되므로, 표를 다시 만드는 도중에 규칙 때문에 실패하지 않는다.
    beforeOpen: (details) => customStatement('PRAGMA foreign_keys = ON'),
  );

  /// 기본 경조사 종류 7개를 고정 id로 넣는다. ("기타"는 지울 수 없게 표시)
  Future<void> _insertDefaultEventTypes() => batch(
    (batch) => batch.insertAll(eventTypes, [
      for (final (index, type) in DefaultEventTypes.all.indexed)
        EventTypesCompanion.insert(
          id: Value(type.$1),
          name: type.$2,
          sortOrder: Value(index),
          isProtected: Value(type.$1 == DefaultEventTypes.otherId),
        ),
    ]),
  );

  /// 기기별로 알맞은 SQLite 연결을 연다.
  /// Android·iOS에서는 앱 문서 폴더에 `maeum_book.sqlite` 파일을 만든다.
  static QueryExecutor _openConnection() => driftDatabase(name: AppDefine.databaseName);
}
