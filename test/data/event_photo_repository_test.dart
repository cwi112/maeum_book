import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maeum_book/data/data.dart';
import 'package:maeum_book/data/database/app_database.dart' show EventPhotosCompanion;

import '../fakes/fake_remote_ledger_store.dart';

/// 행사 사진: 비회원(기기에만) · 회원(서버 + 기기 캐시) · 행사 삭제 · 비회원 → 회원 옮기기 · 사진 줄이기
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late Directory root;
  late PhotoFiles files;
  late FakeRemoteLedgerStore server;

  /// 가로 [width] × 세로 [height] 회색 JPEG
  Uint8List jpeg(int width, int height) =>
      img.encodeJpg(img.Image(width: width, height: height)..clear(img.ColorRgb8(200, 180, 160)));

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    root = Directory.systemTemp.createTempSync('photo_test_');
    files = PhotoFiles(() async => Directory('${root.path}/guest'));
    server = FakeRemoteLedgerStore();
  });

  tearDown(() async {
    await db.close();
    root.deleteSync(recursive: true);
  });

  Future<int> addEvent({RemoteLedgerStore? remote}) =>
      EventRepository(db.eventDao, remote: remote).add(title: '우리 결혼식', eventTypeId: 1, date: DateTime(2026, 5, 10));

  EventPhotoRepository repo({RemoteLedgerStore? remote}) =>
      EventPhotoRepository(db.eventPhotoDao, files: files, remote: remote);

  group('비회원 (기기에만)', () {
    test('사진을 넣으면 정보는 DB에, 원본 · 작은 사진은 기기 폴더에 저장된다', () async {
      final eventId = await addEvent();
      final photo = await repo().add(eventId, jpeg(800, 600));

      expect(await db.eventPhotoDao.getByEvent(eventId), hasLength(1));
      expect(await files.read(photo.id, thumb: false), isNotNull);
      expect(await files.read(photo.id, thumb: true), isNotNull);
      expect(server.photos, isEmpty); // 서버에는 아무것도 안 감
    });

    test('보낸 분 · 메모를 고치고, 지우면 정보와 파일이 모두 사라진다', () async {
      final eventId = await addEvent();
      final repository = repo();
      final photo = await repository.add(eventId, jpeg(400, 400));

      final updated = await repository.updateInfo(photo, senderName: '  김민준 ', memo: '쌀화환 20kg');
      expect(updated.senderName, '김민준'); // 앞뒤 공백 정리
      expect((await db.eventPhotoDao.getById(photo.id))!.memo, '쌀화환 20kg');

      await repository.remove(updated);
      expect(await db.eventPhotoDao.getById(photo.id), isNull);
      expect(await files.read(photo.id, thumb: false), isNull);
    });

    test('행사를 지우면 그 행사 사진 정보와 파일도 지워진다', () async {
      final eventId = await addEvent();
      final photo = await repo().add(eventId, jpeg(400, 400));

      await EventRepository(db.eventDao, photoFiles: files).remove(eventId);
      expect(await db.eventPhotoDao.getAll(), isEmpty);
      expect(await files.read(photo.id, thumb: true), isNull);
    });

    test('한 행사에 30장이 넘으면 더 넣지 않는다', () async {
      final eventId = await addEvent();
      for (var i = 0; i < EventPhotoRepository.maxPerEvent; i++) {
        await db.eventPhotoDao.insertPhoto(EventPhotosCompanion.insert(eventId: eventId));
      }
      expect(() => repo().add(eventId, jpeg(10, 10)), throwsA(isA<PhotoLimitException>()));
    });
  });

  group('회원 (서버가 원본)', () {
    test('사진을 넣으면 파일은 서버 Storage에, 정보는 서버 표에 올라간다', () async {
      final eventId = await addEvent(remote: server);
      final photo = await repo(remote: server).add(eventId, jpeg(400, 300));

      expect(server.photos.keys, [photo.id]);
      expect(server.files.keys, containsAll(['${photo.id}.jpg', '${photo.id}_thumb.jpg']));
    });

    test('인터넷이 없으면 저장되지 않고, 기기에도 사진이 남지 않는다', () async {
      final eventId = await addEvent(remote: server);
      server.offline = true;

      await expectLater(repo(remote: server).add(eventId, jpeg(400, 300)), throwsA(isA<Exception>()));
      expect(await db.eventPhotoDao.getAll(), isEmpty);
      expect(Directory('${root.path}/guest').listSync(), isEmpty);
    });

    test('다른 기기에서 올린 사진은 처음 볼 때 서버에서 받아 기기에 담아 둔다', () async {
      final eventId = await addEvent(remote: server);
      final photo = await repo(remote: server).add(eventId, jpeg(400, 300));
      await files.clear(); // 이 기기에는 없는 상태

      final bytes = await repo(remote: server).loadImage(photo.id, thumb: true);
      expect(bytes, isNotNull);
      expect(await files.read(photo.id, thumb: true), isNotNull); // 캐시됨

      server.offline = true; // 한 번 받은 사진은 인터넷이 없어도 보인다
      expect(await repo(remote: server).loadImage(photo.id, thumb: true), isNotNull);
    });

    test('행사를 지우면 서버의 사진 정보와 파일도 지워진다', () async {
      final eventId = await addEvent(remote: server);
      await repo(remote: server).add(eventId, jpeg(400, 300));

      await EventRepository(db.eventDao, remote: server, photoFiles: files).remove(eventId);
      expect(server.photos, isEmpty);
      expect(server.files, isEmpty);
    });

    test('서버에서 받아 오면(pull) 사진 정보도 기기 사본에 들어온다', () async {
      final eventId = await addEvent(remote: server);
      final photo = await repo(remote: server).add(eventId, jpeg(400, 300));
      await server.upsert(types: await db.select(db.eventTypes).get()); // 실제 서버처럼 기본 종류도 있게
      await MemberSyncNotifier.clearLocalCopy(db);

      await LedgerSync.pull(db, server);
      expect((await db.eventPhotoDao.getAll()).map((p) => p.id), [photo.id]);
    });
  });

  test('비회원 → 회원 옮기기: 사진도 새 번호로 서버에 올라가고, 기기의 비회원 사진은 지워진다', () async {
    final eventId = await addEvent();
    final entryId = await LedgerRepository(db.ledgerDao).add(
      direction: RecordDirection.received,
      eventTypeId: 1,
      eventId: eventId,
      personName: '김민준',
      amount: 100000,
      date: DateTime(2026, 5, 10),
    );
    final repository = repo();
    final photo = await repository.add(eventId, jpeg(400, 300));
    await repository.updateInfo(photo, senderName: '김민준', entryId: entryId);

    await LedgerSync.importGuest(guestDb: db, remote: server, guestPhotos: files);

    final uploaded = server.photos.values.single;
    expect(uploaded.id, isNot(photo.id)); // 새 번호
    expect(uploaded.senderName, '김민준');
    expect(server.events.keys, contains(uploaded.eventId)); // 바뀐 행사 번호로 연결
    expect(server.entries.keys, contains(uploaded.entryId)); // 바뀐 기록 번호로 연결
    expect(server.files.keys, contains('${uploaded.id}.jpg'));
    expect(await db.eventPhotoDao.getAll(), isEmpty);
    expect(await files.read(photo.id, thumb: false), isNull);
  });

  test('사진 줄이기: 긴 변을 1600px(원본) · 400px(작은 사진)로 줄이고, 작은 사진은 그대로 둔다', () async {
    const processor = PhotoProcessor();
    final big = await processor.process(jpeg(4000, 3000));
    expect(img.decodeJpg(big.image)!.width, 1600);
    expect(img.decodeJpg(big.thumb)!.width, 400);
    expect(img.decodeJpg(big.thumb)!.height, 300);

    final portrait = await processor.process(jpeg(900, 2400));
    expect(img.decodeJpg(portrait.image)!.height, 1600);

    final small = await processor.process(jpeg(300, 200));
    expect(img.decodeJpg(small.image)!.width, 300);

    expect(() => processor.process(Uint8List.fromList([1, 2, 3])), throwsA(isA<Exception>()));
  });
}
