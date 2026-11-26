import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:maeum_book/core/errors/network_exception.dart';
import 'package:maeum_book/data/data.dart';

/// 테스트용 가짜 서버 DB. 실제 Supabase 대신 메모리에 한 사람의 장부를 저장한다.
class FakeRemoteLedgerStore implements RemoteLedgerStore {
  final Map<int, EventType> types = {};
  final Map<int, LedgerEvent> events = {};
  final Map<int, LedgerEntry> entries = {};
  final Map<int, EventPhoto> photos = {};

  /// 가짜 Storage: 파일 경로(`<id>.jpg`, `<id>_thumb.jpg`) → 내용
  final Map<String, Uint8List> files = {};

  /// true면 다음 작업들이 인터넷 문제로 실패한다. (다시 false로 바꿀 때까지)
  bool offline = false;

  var _next = 1000000;

  void _check() {
    if (offline) throw const NetworkException('offline');
  }

  static String _path(int id, {required bool thumb}) => '$id${thumb ? '_thumb' : ''}.jpg';

  @override
  int newId() => _next++;

  @override
  Future<RemoteSnapshot> fetchAll() async {
    _check();
    return RemoteSnapshot(
      types: types.values.toList(),
      events: events.values.toList(),
      entries: entries.values.toList(),
      photos: photos.values.toList(),
    );
  }

  @override
  Future<void> upsert({
    List<EventType> types = const [],
    List<LedgerEvent> events = const [],
    List<LedgerEntry> entries = const [],
    List<EventPhoto> photos = const [],
  }) async {
    _check();
    for (final t in types) {
      this.types[t.id] = t;
    }
    for (final e in events) {
      this.events[e.id] = e;
    }
    for (final e in entries) {
      this.entries[e.id] = e;
    }
    for (final p in photos) {
      this.photos[p.id] = p;
    }
  }

  @override
  Future<void> delete({
    List<int> typeIds = const [],
    List<int> eventIds = const [],
    List<int> entryIds = const [],
    List<int> photoIds = const [],
  }) async {
    _check();
    photoIds.forEach(photos.remove);
    for (final id in entryIds) {
      entries.remove(id);
      photos.updateAll((_, p) => p.entryId == id ? p.copyWith(entryId: const Value(null)) : p); // 서버의 set null
    }
    for (final id in eventIds) {
      events.remove(id);
      entries.removeWhere((_, e) => e.eventId == id); // 서버의 cascade
      photos.removeWhere((_, p) => p.eventId == id);
    }
    typeIds.forEach(types.remove);
  }

  @override
  Future<void> clearRecords() async {
    _check();
    files.clear();
    photos.clear();
    entries.clear();
    events.clear();
  }

  @override
  Future<void> uploadPhoto(int photoId, {required Uint8List image, required Uint8List thumb}) async {
    _check();
    files[_path(photoId, thumb: false)] = image;
    files[_path(photoId, thumb: true)] = thumb;
  }

  @override
  Future<Uint8List> downloadPhoto(int photoId, {required bool thumb}) async {
    _check();
    return files[_path(photoId, thumb: thumb)] ?? (throw StateError('없는 파일'));
  }

  @override
  Future<void> deletePhotoFiles(List<int> photoIds) async {
    _check();
    for (final id in photoIds) {
      files
        ..remove(_path(id, thumb: false))
        ..remove(_path(id, thumb: true));
    }
  }

  @override
  Future<void> deleteAllPhotoFiles() async {
    _check();
    files.clear();
  }

  @override
  Future<int> deleteOrphanPhotoFiles(Set<int> keep, {Duration minAge = const Duration(hours: 1)}) async {
    _check();
    final orphans = files.keys
        .where((path) => !keep.contains(int.tryParse(path.split(RegExp(r'[_.]')).first)))
        .toList();
    orphans.forEach(files.remove);
    return orphans.length;
  }
}
