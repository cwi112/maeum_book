import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maeum_book/data/data.dart';

/// 행사·경조사 종류 Repository와 실제 SQLite 쿼리를 함께 검사한다. (메모리 DB)
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late EventRepository events;
  late EventTypeRepository types;
  late LedgerRepository ledger;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    events = EventRepository(db.eventDao);
    types = EventTypeRepository(db.eventTypeDao);
    ledger = LedgerRepository(db.ledgerDao);
  });
  tearDown(() => db.close());

  Future<int> give(int eventId, String name, int amount) => ledger.add(
    direction: RecordDirection.received,
    eventTypeId: 1,
    eventId: eventId,
    personName: name,
    amount: amount,
    date: DateTime(2026, 5, 10),
  );

  test('새 DB에는 기본 경조사 종류 7개가 있고 "기타"는 보호된다', () async {
    final all = await types.watchAll().first;
    expect(all.length, 7);
    expect(all.last.name, '기타');
    expect(all.last.isProtected, isTrue);
  });

  test('행사 목록에 행사별 합계·인원·준 사람 이름이 함께 나온다 (받은 기록이 없는 행사도 0으로)', () async {
    final wedding = await events.add(title: '우리 결혼식', eventTypeId: 1, date: DateTime(2026, 5, 10));
    await events.add(title: '집들이', eventTypeId: 5, date: DateTime(2026, 8, 1));
    await give(wedding, '김철수', 50000);
    await give(wedding, '이영희', 100000);

    final summaries = await events.watchSummaries().first;
    expect(summaries.first.event.title, '집들이'); // 최신 날짜순
    expect(summaries.first.total, 0);
    expect(summaries.last.total, 150000);
    expect(summaries.last.count, 2);
    expect(summaries.last.giverNames.toSet(), {'김철수', '이영희'});
  });

  test('행사의 날짜·종류를 고치면 안의 받은 기록도 같이 바뀐다', () async {
    final id = await events.add(title: '결혼식', eventTypeId: 1, date: DateTime(2026, 5, 10));
    final entryId = await give(id, '김철수', 50000);

    await events.edit((await events.findById(id))!, title: '결혼식', eventTypeId: 2, date: DateTime(2026, 6, 1));
    final entry = (await ledger.findById(entryId))!;
    expect(entry.eventTypeId, 2);
    expect(entry.date, DateTime(2026, 6, 1));
  });

  test('행사를 지우면 안의 받은 기록도 함께 지워진다 (외래 키 cascade)', () async {
    final id = await events.add(title: '결혼식', eventTypeId: 1, date: DateTime(2026, 5, 10));
    final entryId = await give(id, '김철수', 50000);

    await events.remove(id);
    expect(await ledger.findById(entryId), isNull);
  });

  test('종류를 추가·이름 변경하고, 같은 이름과 빈 이름은 막는다', () async {
    final id = await types.add('  환갑 ');
    expect((await types.watchAll().first).last.name, '환갑'); // 공백 정리 + 맨 뒤
    await types.rename(id, '칠순');
    expect((await types.watchAll().first).any((t) => t.name == '칠순'), isTrue);
    await expectLater(types.add('결혼'), throwsA(anything)); // 같은 이름 (unique)
    expect(() => types.add('   '), throwsArgumentError);
  });

  test('쓰고 있는 종류를 지우면 그 기록·행사는 "기타"로 옮겨지고, "기타"는 지울 수 없다', () async {
    final custom = await types.add('환갑');
    final eventId = await events.add(title: '아버지 환갑', eventTypeId: custom, date: DateTime(2026, 5, 10));
    final entryId = await ledger.add(
      direction: RecordDirection.sent,
      eventTypeId: custom,
      personName: '김철수',
      amount: 50000,
      date: DateTime(2026, 5, 10),
    );
    expect(await types.countUsage(custom), 2);

    final all = await types.watchAll().first;
    await types.remove(all.firstWhere((t) => t.id == custom));
    expect((await ledger.findById(entryId))!.eventTypeId, DefaultEventTypes.otherId);
    expect((await events.findById(eventId))!.eventTypeId, DefaultEventTypes.otherId);

    expect(() => types.remove(all.firstWhere((t) => t.isProtected)), throwsStateError);
  });
}
