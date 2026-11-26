import 'package:drift/drift.dart';
import 'package:maeum_book/data/database/app_database.dart';
import 'package:maeum_book/data/photos/photo_files.dart';
import 'package:maeum_book/data/photos/photo_processor.dart';
import 'package:maeum_book/data/remote/remote_ledger_store.dart';
import 'package:maeum_book/data/repositories/remote_first_write.dart';

/// 행사에 사진이 너무 많을 때 (행사당 [EventPhotoRepository.maxPerEvent]장)
class PhotoLimitException implements Exception {
  const PhotoLimitException(this.limit);

  final int limit;

  @override
  String toString() => '한 행사에 사진은 $limit장까지 넣을 수 있어요';
}

/// 행사 사진 (화환 · 꽃)을 다루는 Repository. (기획안: docs/EVENT_PHOTO_PLAN.md)
///
/// | 장부 | 사진 정보 | 사진 파일 |
/// |---|---|---|
/// | 비회원 | 기기 DB | 기기 폴더 (원본) |
/// | 회원 | 기기 DB 사본 + 서버 표 | 서버 Storage (원본) + 기기 폴더 (캐시) |
/// | 샘플 | 메모리 DB | 임시 폴더 |
///
/// 회원은 다른 기록처럼 **서버에도 올라가야 저장된다.** 인터넷이 없으면 추가 · 수정 · 삭제가 되지 않고 기기도 그대로다.
class EventPhotoRepository with RemoteFirstWrite {
  EventPhotoRepository(this._dao, {required this.files, this.remote, this.processor = const PhotoProcessor()});

  final EventPhotoDao _dao;
  final PhotoFiles files;
  final PhotoProcessor processor;

  @override
  final RemoteLedgerStore? remote;

  @override
  AppDatabase get db => _dao.attachedDatabase;

  /// 한 행사에 넣을 수 있는 사진 수
  static const maxPerEvent = 30;

  Stream<List<EventPhoto>> watchByEvent(int eventId) => _dao.watchByEvent(eventId);

  /// 행사에 더 넣을 수 있는 사진 수
  Future<int> remaining(int eventId) async => maxPerEvent - await _dao.countByEvent(eventId);

  /// 사진을 줄여서 행사에 추가하고 새 사진 정보를 돌려준다.
  ///
  /// 회원: 파일 → 서버 Storage, 정보 → 서버 표. 하나라도 실패하면 기기 쪽도 되돌린다.
  Future<EventPhoto> add(int eventId, Uint8List raw) async {
    if (await remaining(eventId) <= 0) throw const PhotoLimitException(maxPerEvent);
    final processed = await processor.process(raw);
    final companion = EventPhotosCompanion.insert(id: newIdValue(), eventId: eventId);
    int? savedId;
    try {
      return await write(
        () async {
          final id = await _dao.insertPhoto(companion);
          savedId = id;
          await files.save(id, image: processed.image, thumb: processed.thumb);
          return (await _dao.getById(id))!;
        },
        (photo, server) async {
          await server.uploadPhoto(photo.id, image: processed.image, thumb: processed.thumb);
          await server.upsert(photos: [photo]);
        },
      );
    } catch (_) {
      // DB는 트랜잭션으로 되돌려졌다. 기기에 남은 파일만 지운다.
      final id = savedId;
      if (id != null) await files.delete([id]);
      rethrow;
    }
  }

  /// 보낸 분 · 메모를 고친다. [entryId]: 이 행사의 받은 기록에서 골랐으면 그 기록 (직접 입력이면 null)
  Future<EventPhoto> updateInfo(EventPhoto photo, {String? senderName, int? entryId, String? memo}) {
    final updated = photo.copyWith(
      senderName: Value(_clean(senderName)),
      entryId: Value(entryId),
      memo: Value(_clean(memo)),
    );
    return write(() async {
      await _dao.updatePhoto(updated);
      return updated;
    }, (_, server) => server.upsert(photos: [updated]));
  }

  /// 사진을 지운다. (정보 + 파일, 회원은 서버에서도)
  Future<void> remove(EventPhoto photo) async {
    await write(() => _dao.deletePhoto(photo.id), (_, server) async {
      await server.delete(photoIds: [photo.id]);
      await server.deletePhotoFiles([photo.id]);
    });
    await files.delete([photo.id]);
  }

  /// 사진 파일을 읽는다. 기기에 없으면(회원이 다른 기기에서 올린 사진) 서버에서 받아 기기에 담아 둔다.
  /// 끝내 못 읽으면 null. (인터넷이 없고 받아 둔 적도 없을 때)
  Future<Uint8List?> loadImage(int photoId, {required bool thumb}) async {
    final cached = await files.read(photoId, thumb: thumb);
    if (cached != null) return cached;
    final server = remote;
    if (server == null) return null;
    try {
      final bytes = await server.downloadPhoto(photoId, thumb: thumb);
      await files.saveOne(photoId, bytes, thumb: thumb);
      return bytes;
    } catch (_) {
      return null;
    }
  }

  static String? _clean(String? text) {
    final trimmed = text?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
