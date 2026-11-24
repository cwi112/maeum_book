import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:maeum_book/data/database/daos/ledger_dao.dart';
import 'package:maeum_book/data/database/tables/ledger_entries_table.dart';
import 'package:maeum_book/data/models/models.dart';

export 'package:maeum_book/data/database/daos/ledger_dao.dart';

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
@DriftDatabase(tables: [LedgerEntries], daos: [LedgerDao])
class AppDatabase extends _$AppDatabase {
  /// [executor]를 넘기지 않으면 휴대폰 저장소의 DB 파일을 연다.
  /// 테스트에서는 `NativeDatabase.memory()`를 넘겨 메모리에만 있는 임시 DB로 실행한다.
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// DB 구조(스키마) 버전.
  ///
  /// 출시 후에 테이블·컬럼을 바꾸면 이 숫자를 1 올리고 [migration]의 `onUpgrade`에 변경 방법을 적어야 한다.
  /// 그래야 이미 앱을 쓰던 사람의 기존 데이터가 지워지지 않고 새 구조로 옮겨진다.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    // 앱을 처음 설치해서 DB 파일이 없을 때: 모든 테이블·인덱스를 만든다.
    onCreate: (m) => m.createAll(),
    // TODO: schemaVersion을 올릴 때 여기에 단계별 변경을 추가한다. 예) if (from < 2) await m.addColumn(...);
    onUpgrade: (m, from, to) async {},
  );

  /// 기기별로 알맞은 SQLite 연결을 연다.
  /// Android·iOS에서는 앱 문서 폴더에 `maeum_book.sqlite` 파일을 만든다.
  static QueryExecutor _openConnection() => driftDatabase(name: 'maeum_book');
}
