import 'package:drift/drift.dart';
import 'package:maeum_book/data/database/app_database.dart';
import 'package:maeum_book/data/photos/photo_files.dart';
import 'package:maeum_book/data/remote/remote_ledger_store.dart';
import 'package:maeum_book/data/repositories/remote_first_write.dart';

/// 비로그인 기록 수 (연동 팝업에 보여줄 값)
class LocalRecordCount {
  const LocalRecordCount({required this.entries, required this.events});

  final int entries;
  final int events;

  bool get isEmpty => entries == 0 && events == 0;
}

/// 서버 DB(원본) ↔ 기기 DB(사본) 사이를 옮기는 작업 모음.
///
/// ## 언제 쓰나
/// | 작업 | 언제 |
/// |---|---|
/// | [pull] | 로그인 직후 · 앱을 켤 때 · 앱으로 돌아올 때 (다른 기기에서 고친 내용을 받아 옴) |
/// | [importGuest] | 비로그인으로 쓰다가 로그인할 때 "기록을 계정으로 옮길까요?"에서 [옮기기] |
abstract final class LedgerSync {
  /// 서버의 내 장부 전체를 받아 기기 사본을 **통째로 바꾼다.** (서버가 원본)
  ///
  /// 처음 가입한 계정이라 서버에 경조사 종류가 하나도 없으면, 기기의 기본 종류(1~7)를 서버에 먼저 올린다.
  ///
  /// 받아 오는 동안 이 기기에서 기록을 저장했으면(받은 장부가 이미 옛날 것) 덮어쓰지 않고 다시 받는다. (최대 3번)
  static Future<void> pull(AppDatabase db, RemoteLedgerStore remote) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      final writesBefore = LocalWrites.version;
      var snapshot = await remote.fetchAll();
      if (snapshot.types.isEmpty) {
        final localTypes = await db.select(db.eventTypes).get();
        await remote.upsert(types: localTypes);
        snapshot = await remote.fetchAll();
      }
      if (await replaceLocal(db, snapshot, unlessWrittenSince: writesBefore)) return;
    }
  }

  /// 기기 사본을 [snapshot]으로 바꾼다. 한 트랜잭션이라 화면은 바뀐 결과로 한 번만 다시 그려진다.
  /// [unlessWrittenSince]: 그 뒤로 이 기기에서 저장한 게 있으면 바꾸지 않고 false. (트랜잭션 안에서 확인해 사이에 끼어들 틈이 없다)
  static Future<bool> replaceLocal(AppDatabase db, RemoteSnapshot snapshot, {int? unlessWrittenSince}) =>
      db.transaction(() async {
        if (unlessWrittenSince != null && LocalWrites.version != unlessWrittenSince) return false;
        await _replace(db, snapshot);
        return true;
      });

  static Future<void> _replace(AppDatabase db, RemoteSnapshot snapshot) async {
    await db.delete(db.eventPhotos).go();
    await db.delete(db.ledgerEntries).go();
    await db.delete(db.events).go();
    await db.delete(db.eventTypes).go();
    await db.batch((batch) {
      batch
        ..insertAll(db.eventTypes, snapshot.types)
        ..insertAll(db.events, snapshot.events)
        ..insertAll(db.ledgerEntries, snapshot.entries)
        ..insertAll(db.eventPhotos, snapshot.photos);
    });
  }

  /// 비로그인 기록 수
  static Future<LocalRecordCount> countRecords(AppDatabase db) async {
    final entries = await (db.selectOnly(
      db.ledgerEntries,
    )..addColumns([db.ledgerEntries.id.count()])).map((r) => r.read(db.ledgerEntries.id.count()) ?? 0).getSingle();
    final events = await (db.selectOnly(
      db.events,
    )..addColumns([db.events.id.count()])).map((r) => r.read(db.events.id.count()) ?? 0).getSingle();
    return LocalRecordCount(entries: entries, events: events);
  }

  /// 비로그인 기록(기기 DB [guestDb])을 계정(서버)으로 옮기고, 옮긴 기록 수를 돌려준다.
  ///
  /// - 모든 행에 **새 id**를 붙여 올린다. 다른 기기에서 옮긴 기록과 번호가 겹쳐 덮어쓰는 일이 없다.
  /// - 경조사 종류는 **이름으로 맞춘다.** 계정에 같은 이름이 있으면 그 종류로, 없으면 새로 만든다.
  /// - 다 올린 뒤에 비로그인 기록을 지운다. (계정 기록이 됐으므로. 지우지 않으면 다음 로그인 때 또 옮기게 된다)
  ///   올리는 중에 실패하면 지우지 않는다. 다시 시도하면 새 id로 다시 올리므로, 앞서 일부 올라간 기록이 겹칠 수 있다.
  ///
  /// 행사 사진([guestPhotos] 폴더의 파일)도 새 번호로 서버 Storage에 올리고, 다 옮기면 기기에서 지운다.
  static Future<int> importGuest({
    required AppDatabase guestDb,
    required RemoteLedgerStore remote,
    PhotoFiles? guestPhotos,
  }) async {
    final types = await guestDb.select(guestDb.eventTypes).get();
    final events = await guestDb.select(guestDb.events).get();
    final entries = await guestDb.select(guestDb.ledgerEntries).get();
    final photos = await guestDb.select(guestDb.eventPhotos).get();
    if (events.isEmpty && entries.isEmpty) return 0;

    // 1) 종류: 이름으로 계정 종류와 맞추고, 없는 이름만 새로 만든다.
    final remoteTypes = (await remote.fetchAll()).types;
    final byName = {for (final t in remoteTypes) t.name: t.id};
    var nextOrder = remoteTypes.fold(0, (max, t) => t.sortOrder > max ? t.sortOrder : max) + 1;
    final newTypes = <EventType>[];
    final typeIdMap = <int, int>{};
    for (final type in types) {
      final existing = byName[type.name];
      if (existing != null) {
        typeIdMap[type.id] = existing;
      } else if (remoteTypes.isEmpty && type.id <= 7) {
        // 처음 가입한 계정: 기본 종류는 id 그대로 (pull과 같은 규칙)
        typeIdMap[type.id] = type.id;
        newTypes.add(type);
      } else {
        final id = remote.newId();
        typeIdMap[type.id] = id;
        newTypes.add(type.copyWith(id: id, sortOrder: nextOrder++, isProtected: false));
      }
    }

    // 2) 행사 · 기록: 새 id + 바뀐 종류 · 행사 번호
    final eventIdMap = {for (final e in events) e.id: remote.newId()};
    final newEvents = [
      for (final e in events) e.copyWith(id: eventIdMap[e.id], eventTypeId: typeIdMap[e.eventTypeId] ?? e.eventTypeId),
    ];
    final entryIdMap = {for (final e in entries) e.id: remote.newId()};
    final newEntries = [
      for (final e in entries)
        e.copyWith(
          id: entryIdMap[e.id],
          eventTypeId: typeIdMap[e.eventTypeId] ?? e.eventTypeId,
          eventId: Value(e.eventId == null ? null : eventIdMap[e.eventId]),
        ),
    ];

    await remote.upsert(types: newTypes, events: newEvents, entries: newEntries);

    // 3) 사진: 파일을 새 번호로 먼저 올리고 정보를 올린다. (파일이 없어진 사진은 건너뜀)
    final newPhotos = <EventPhoto>[];
    for (final photo in photos) {
      final image = await guestPhotos?.read(photo.id, thumb: false);
      final thumb = await guestPhotos?.read(photo.id, thumb: true);
      final eventId = eventIdMap[photo.eventId];
      if (image == null || thumb == null || eventId == null) continue;
      final id = remote.newId();
      await remote.uploadPhoto(id, image: image, thumb: thumb);
      newPhotos.add(
        photo.copyWith(
          id: id,
          eventId: eventId,
          entryId: Value(photo.entryId == null ? null : entryIdMap[photo.entryId]),
        ),
      );
    }
    if (newPhotos.isNotEmpty) await remote.upsert(photos: newPhotos);

    // 4) 옮겼으니 비로그인 기록은 지운다. (경조사 종류는 남겨 둔다) 사진 정보는 행사와 함께 지워진다.
    await guestDb.transaction(() async {
      await guestDb.delete(guestDb.eventPhotos).go();
      await guestDb.delete(guestDb.ledgerEntries).go();
      await guestDb.delete(guestDb.events).go();
    });
    await guestPhotos?.clear();
    return entries.length;
  }
}
