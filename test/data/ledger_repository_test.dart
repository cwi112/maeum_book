import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maeum_book/data/data.dart';

/// Repository + DAO + 실제 SQLite 쿼리를 함께 검사한다.
/// 파일 대신 메모리에만 있는 DB(NativeDatabase.memory)를 써서, 테스트마다 빈 DB로 시작한다.
void main() {
  late AppDatabase database;
  late LedgerRepository repository;

  // 테스트마다 DB를 새로 만들기 때문에 "DB를 여러 개 만들었다"는 Drift 경고를 끈다.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = LedgerRepository(database.ledgerDao);
  });

  tearDown(() => database.close());

  Future<int> add(RecordDirection direction, String name, int amount, {DateTime? date, String? memo}) => repository.add(
    direction: direction,
    eventType: EventType.wedding,
    personName: name,
    amount: amount,
    date: date ?? DateTime(2026, 11, 24),
    memo: memo,
  );

  test('저장한 기록이 방향별로 최신 날짜순으로 조회된다', () async {
    await add(RecordDirection.sent, '김철수', 50000, date: DateTime(2026, 1, 1));
    await add(RecordDirection.sent, '이영희', 100000, date: DateTime(2026, 5, 1));
    await add(RecordDirection.received, '박민수', 30000);

    final sent = await repository.watchEntries(RecordDirection.sent).first;
    expect(sent.map((e) => e.personName), ['이영희', '김철수']);
  });

  test('보냄·받음 합계를 계산하고, 기록이 없는 방향은 0으로 채운다', () async {
    var summaries = await repository.watchSummaries().first;
    expect(summaries[RecordDirection.sent]!.total, 0);

    await add(RecordDirection.sent, '김철수', 50000);
    await add(RecordDirection.sent, '이영희', 70000);

    summaries = await repository.watchSummaries().first;
    expect(summaries[RecordDirection.sent]!.total, 120000);
    expect(summaries[RecordDirection.sent]!.count, 2);
    expect(summaries[RecordDirection.received]!.total, 0);
  });

  test('사람별로 보낸 총액과 받은 총액을 묶어서 계산한다', () async {
    await add(RecordDirection.sent, '김철수', 50000);
    await add(RecordDirection.received, '김철수', 100000);
    await add(RecordDirection.sent, '이영희', 30000);

    final people = await repository.watchPersonSummaries().first;
    final chulsoo = people.firstWhere((p) => p.name == '김철수');
    expect(chulsoo.sentTotal, 50000);
    expect(chulsoo.receivedTotal, 100000);
    expect(chulsoo.balance, 50000);
    expect(people.first.name, '김철수'); // 주고받은 금액이 큰 사람이 먼저
  });

  test('DB가 바뀌면 Stream이 새 목록을 다시 보내준다', () async {
    final stream = repository.watchEntries(RecordDirection.sent);
    final counts = <int>[];
    final subscription = stream.listen((entries) => counts.add(entries.length));

    await pumpEventQueue();
    final id = await add(RecordDirection.sent, '김철수', 50000);
    await pumpEventQueue();
    await repository.remove(id);
    await pumpEventQueue();
    await subscription.cancel();

    expect(counts, [0, 1, 0]);
  });

  test('이름 공백을 정리하고, 공백뿐인 메모는 비운다', () async {
    await add(RecordDirection.sent, '  김철수  ', 50000, memo: '   ');
    final entry = (await repository.fetchAllForExport()).single;
    expect(entry.personName, '김철수');
    expect(entry.memo, isNull);
  });

  test('빈 이름이나 음수 금액은 저장하지 않는다', () {
    expect(() => add(RecordDirection.sent, '   ', 50000), throwsArgumentError);
    expect(() => add(RecordDirection.sent, '김철수', -1), throwsArgumentError);
  });

  test('수정하면 내용과 수정 시각이 바뀐다', () async {
    final id = await add(RecordDirection.sent, '김철수', 50000);
    final before = (await repository.fetchAllForExport()).single;

    await repository.update(before.copyWith(amount: 70000));
    final after = (await repository.fetchAllForExport()).single;

    expect(after.id, id);
    expect(after.amount, 70000);
    expect(after.updatedAt.isBefore(before.updatedAt), isFalse);
  });

  test('엑셀용 전체 조회는 오래된 날짜순이다', () async {
    await add(RecordDirection.sent, '나중', 1, date: DateTime(2026, 12, 1));
    await add(RecordDirection.received, '먼저', 1, date: DateTime(2025, 1, 1));
    final all = await repository.fetchAllForExport();
    expect(all.map((e) => e.personName), ['먼저', '나중']);
  });

  test('id로 기록을 찾고, 없으면 null을 돌려준다', () async {
    final id = await add(RecordDirection.sent, '김철수', 50000);
    expect((await repository.findById(id))?.personName, '김철수');
    expect(await repository.findById(9999), isNull);
  });

  test('삭제한 기록을 되돌리면 id까지 그대로 돌아온다', () async {
    final id = await add(RecordDirection.sent, '김철수', 50000);
    final entry = (await repository.findById(id))!;

    await repository.remove(id);
    expect(await repository.findById(id), isNull);

    await repository.restore(entry);
    final restored = await repository.findById(id);
    expect(restored?.personName, '김철수');
    expect(restored?.createdAt, entry.createdAt);
  });

  test('edit은 바꾼 값을 저장하고, 관계·메모를 비울 수 있다', () async {
    final id = await repository.add(
      direction: RecordDirection.sent,
      eventType: EventType.wedding,
      personName: '김철수',
      amount: 50000,
      date: DateTime(2026, 11, 24),
      relation: Relation.friend,
      memo: '메모',
    );
    final original = (await repository.findById(id))!;

    await repository.edit(
      original,
      direction: RecordDirection.received,
      eventType: EventType.funeral,
      personName: '김철수',
      amount: 100000,
      date: DateTime(2026, 12, 1),
    );
    final edited = (await repository.findById(id))!;

    expect(edited.direction, RecordDirection.received);
    expect(edited.eventType, EventType.funeral);
    expect(edited.amount, 100000);
    expect(edited.relation, isNull);
    expect(edited.memo, isNull);
    expect(edited.createdAt, original.createdAt);
  });

  test('방향·종류별 합계를 묶어서 계산한다', () async {
    await add(RecordDirection.sent, '김철수', 50000);
    await add(RecordDirection.sent, '이영희', 30000);
    await repository.add(
      direction: RecordDirection.sent,
      eventType: EventType.funeral,
      personName: '박민수',
      amount: 100000,
      date: DateTime(2026, 11, 24),
    );

    final byType = await repository.watchTypeSummaries().first;
    expect(byType[RecordDirection.sent]![EventType.wedding]!.total, 80000);
    expect(byType[RecordDirection.sent]![EventType.wedding]!.count, 2);
    expect(byType[RecordDirection.sent]![EventType.funeral]!.total, 100000);
    expect(byType[RecordDirection.received], isEmpty);
  });
}
