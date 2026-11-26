import 'package:drift/drift.dart';
import 'package:maeum_book/data/database/app_database.dart';
import 'package:maeum_book/data/database/tables/event_photos_table.dart';

part 'event_photo_dao.g.dart';

/// 행사 사진 정보의 DB 작업. (사진 파일은 PhotoFiles가 따로 다룬다)
@DriftAccessor(tables: [EventPhotos])
class EventPhotoDao extends DatabaseAccessor<AppDatabase> with _$EventPhotoDaoMixin {
  EventPhotoDao(super.attachedDatabase);

  /// 행사의 사진들을 찍은(추가한) 순서대로 구독한다.
  Stream<List<EventPhoto>> watchByEvent(int eventId) =>
      (select(eventPhotos)
            ..where((t) => t.eventId.equals(eventId))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt), (t) => OrderingTerm.asc(t.id)]))
          .watch();

  Future<List<EventPhoto>> getByEvent(int eventId) =>
      (select(eventPhotos)..where((t) => t.eventId.equals(eventId))).get();

  Future<EventPhoto?> getById(int id) => (select(eventPhotos)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<EventPhoto>> getAll() => select(eventPhotos).get();

  Future<int> countByEvent(int eventId) async {
    final count = eventPhotos.id.count();
    final query = selectOnly(eventPhotos)
      ..addColumns([count])
      ..where(eventPhotos.eventId.equals(eventId));
    return await query.map((row) => row.read(count) ?? 0).getSingle();
  }

  Future<int> insertPhoto(EventPhotosCompanion photo) => into(eventPhotos).insert(photo);

  Future<bool> updatePhoto(EventPhoto photo) => update(eventPhotos).replace(photo);

  Future<int> deletePhoto(int id) => (delete(eventPhotos)..where((t) => t.id.equals(id))).go();
}
