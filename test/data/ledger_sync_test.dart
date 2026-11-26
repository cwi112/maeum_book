import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maeum_book/core/errors/network_exception.dart';
import 'package:maeum_book/data/data.dart';

import '../fakes/fake_remote_ledger_store.dart';

/// 서버 원본 ↔ 기기 사본, 비로그인 기록 옮기기, 회원 저장(서버 먼저)을 확인한다.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  AppDatabase memoryDb() => AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));

  late AppDatabase guest;
  late AppDatabase member;
  late FakeRemoteLedgerStore server;

  setUp(() {
    guest = memoryDb();
    member = memoryDb();
    server = FakeRemoteLedgerStore();
  });

  tearDown(() async {
    await guest.close();
    await member.close();
  });

  Future<int> addGuestEntry(String name, {int amount = 50000}) => LedgerRepository(
    guest.ledgerDao,
  ).add(direction: RecordDirection.sent, eventTypeId: 1, personName: name, amount: amount, date: DateTime(2026, 11, 1));

  group('pull: 서버 원본으로 기기 사본 바꾸기', () {
    test('새 계정이면 기본 경조사 종류를 서버에 먼저 올린다', () async {
      await LedgerSync.pull(member, server);
      expect(server.types.length, DefaultEventTypes.all.length);
      expect((await member.select(member.eventTypes).get()).length, DefaultEventTypes.all.length);
    });

    test('다른 기기에서 쓴 기록을 받아 오고, 서버에 없는 기기 기록은 지운다', () async {
      await LedgerSync.pull(member, server);
      // 다른 기기가 서버에 쓴 기록
      final other = LedgerRepository(memoryDb().ledgerDao, remote: server);
      await LedgerSync.pull(other.db, server);
      await other.add(
        direction: RecordDirection.sent,
        eventTypeId: 1,
        personName: '다른기기',
        amount: 1,
        date: DateTime(2026),
      );

      await LedgerSync.pull(member, server);
      final names = (await member.select(member.ledgerEntries).get()).map((e) => e.personName);
      expect(names, ['다른기기']);
      await other.db.close();
    });
  });

  group('회원 저장: 서버에 먼저 쓴다', () {
    late LedgerRepository repository;
    setUp(() async {
      await LedgerSync.pull(member, server);
      repository = LedgerRepository(member.ledgerDao, remote: server);
    });

    Future<int> add() => repository.add(
      direction: RecordDirection.received,
      eventTypeId: 1,
      personName: '김철수',
      amount: 100000,
      date: DateTime(2026, 11, 1),
    );

    test('저장 · 수정 · 삭제가 서버에도 반영된다', () async {
      final id = await add();
      expect(server.entries[id]?.personName, '김철수');

      final entry = (await repository.findById(id))!;
      await repository.update(entry.copyWith(amount: 50000));
      expect(server.entries[id]?.amount, 50000);

      await repository.remove(id);
      expect(server.entries, isEmpty);
    });

    test('인터넷이 없으면 NetworkException이고 기기에도 남지 않는다', () async {
      server.offline = true;
      await expectLater(add(), throwsA(isA<NetworkException>()));
      expect(await member.select(member.ledgerEntries).get(), isEmpty);
    });

    test('경조사 종류를 지우면 서버에서도 기록이 "기타"로 옮겨진 뒤 종류가 지워진다', () async {
      final types = EventTypeRepository(member.eventTypeDao, remote: server);
      final typeId = await types.add('환갑');
      final id = await repository.add(
        direction: RecordDirection.sent,
        eventTypeId: typeId,
        personName: '이영희',
        amount: 30000,
        date: DateTime(2026),
      );
      final type = (await member.select(member.eventTypes).get()).firstWhere((t) => t.id == typeId);
      await types.remove(type);
      expect(server.types.containsKey(typeId), isFalse);
      expect(server.entries[id]?.eventTypeId, DefaultEventTypes.otherId);
    });
  });

  group('importGuest: 비로그인 기록을 계정으로 옮기기', () {
    test('새 id로 올리고, 비로그인 기록은 지운다', () async {
      await addGuestEntry('비회원1');
      await addGuestEntry('비회원2');

      final moved = await LedgerSync.importGuest(guestDb: guest, remote: server);
      expect(moved, 2);
      expect(server.entries.values.map((e) => e.personName), containsAll(['비회원1', '비회원2']));
      expect(server.entries.keys.every((id) => id >= 1000000), isTrue); // 새 id
      expect(await guest.select(guest.ledgerEntries).get(), isEmpty);
    });

    test('계정에 기록이 있으면 합친다 (덮어쓰지 않음)', () async {
      await LedgerSync.pull(member, server);
      await LedgerRepository(
        member.ledgerDao,
        remote: server,
      ).add(direction: RecordDirection.sent, eventTypeId: 1, personName: '계정기록', amount: 1, date: DateTime(2026));
      await addGuestEntry('비회원기록');

      await LedgerSync.importGuest(guestDb: guest, remote: server);
      expect(server.entries.values.map((e) => e.personName), containsAll(['계정기록', '비회원기록']));
    });

    test('직접 만든 종류는 이름이 같으면 계정 종류로 맞추고, 없으면 새로 만든다', () async {
      await LedgerSync.pull(member, server);
      final memberTypes = EventTypeRepository(member.eventTypeDao, remote: server);
      final serverHwangap = await memberTypes.add('환갑');

      final guestTypes = EventTypeRepository(guest.eventTypeDao);
      final guestHwangap = await guestTypes.add('환갑');
      final guestGrad = await guestTypes.add('졸업');
      final repo = LedgerRepository(guest.ledgerDao);
      for (final (typeId, name) in [(guestHwangap, '가'), (guestGrad, '나')]) {
        await repo.add(
          direction: RecordDirection.sent,
          eventTypeId: typeId,
          personName: name,
          amount: 1,
          date: DateTime(2026),
        );
      }

      await LedgerSync.importGuest(guestDb: guest, remote: server);
      final byName = {for (final e in server.entries.values) e.personName: e.eventTypeId};
      expect(byName['가'], serverHwangap);
      expect(server.types[byName['나']]?.name, '졸업');
    });

    test('인터넷 문제로 실패하면 비로그인 기록을 지우지 않는다', () async {
      await addGuestEntry('남아야함');
      server.offline = true;
      await expectLater(LedgerSync.importGuest(guestDb: guest, remote: server), throwsA(isA<NetworkException>()));
      expect((await guest.select(guest.ledgerEntries).get()).single.personName, '남아야함');
    });
  });
}
