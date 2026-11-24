import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maeum_book/data/data.dart';

/// v2(예전 구조) DB를 직접 만들어 두고, 앱을 열었을 때 v3로 데이터가 제대로 옮겨지는지 검사한다.
/// 실제 사용자 휴대폰에 있는 예전 데이터가 업데이트 후에도 살아남는지 확인하는 테스트다.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  // 2026-05-10, 2026-08-01 (초 단위 유닉스 시간: Drift 기본 날짜 저장 방식)
  final may10 = DateTime(2026, 5, 10).millisecondsSinceEpoch ~/ 1000;
  final aug1 = DateTime(2026, 8, 1).millisecondsSinceEpoch ~/ 1000;

  AppDatabase openV2Database() => AppDatabase(
    NativeDatabase.memory(
      setup: (raw) {
        raw.execute('''
          CREATE TABLE ledger_entries (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            direction TEXT NOT NULL,
            event_type TEXT NOT NULL,
            person_name TEXT NOT NULL,
            amount INTEGER NOT NULL CHECK (amount >= 0),
            date INTEGER NOT NULL,
            relation TEXT NULL,
            memo TEXT NULL,
            created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
            updated_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
          )''');
        raw.execute('CREATE INDEX idx_ledger_entries_direction_date ON ledger_entries (direction, date)');
        void insert(String direction, String type, String name, int amount, int date) => raw.execute(
          'INSERT INTO ledger_entries (direction, event_type, person_name, amount, date) VALUES (?, ?, ?, ?, ?)',
          [direction, type, name, amount, date],
        );
        insert('sent', 'funeral', '김철수', 100000, aug1);
        insert('received', 'wedding', '이영희', 50000, may10);
        insert('received', 'wedding', '박민수', 100000, may10); // 같은 날 같은 종류 → 같은 행사
        insert('received', 'opening', '최수아', 30000, aug1); // 다른 행사
        raw.execute('PRAGMA user_version = 2');
      },
    ),
  );

  test('v2 → v3: 기존 기록이 모두 남고, 종류 글자가 번호로 바뀐다', () async {
    final db = openV2Database();
    addTearDown(db.close);

    final entries = await LedgerRepository(db.ledgerDao).fetchAllForExport();
    expect(entries.length, 4);
    expect(entries.firstWhere((e) => e.personName == '김철수').eventTypeId, 2); // funeral → 조의(2)
    expect(entries.firstWhere((e) => e.personName == '최수아').eventTypeId, 6); // opening → 개업(6)

    final types = await EventTypeRepository(db.eventTypeDao).watchAll().first;
    expect(types.map((t) => t.name), ['결혼', '조의', '돌잔치', '생일', '집들이', '개업', '기타']);
  });

  test('v2 → v3: 받은 기록은 같은 날짜·종류끼리 행사로 묶이고, 보낸 기록은 행사가 없다', () async {
    final db = openV2Database();
    addTearDown(db.close);

    final events = await EventRepository(db.eventDao).watchSummaries().first;
    expect(events.length, 2);
    final wedding = events.firstWhere((e) => e.event.title == '결혼');
    expect(wedding.count, 2);
    expect(wedding.total, 150000);
    expect(wedding.giverNames.toSet(), {'이영희', '박민수'});

    final sent = (await LedgerRepository(db.ledgerDao).fetchAllForExport()).firstWhere((e) => e.personName == '김철수');
    expect(sent.eventId, isNull);
  });
}
