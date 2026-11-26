import 'dart:io';
import 'dart:typed_data';

/// 행사 사진 파일을 기기 폴더에 저장 · 읽기 · 지우기.
///
/// 장부마다 폴더가 따로다. (DB 파일이 따로인 것과 같은 규칙)
/// | 장부 | 폴더 | 역할 |
/// |---|---|---|
/// | 비회원 | `<앱 문서 폴더>/photos/guest` | **원본** (앱을 지우면 사라짐) |
/// | 회원 | `<앱 문서 폴더>/photos/<사용자 id>` | 서버에서 받은 사진을 담아 두는 **캐시** (끊겨도 보이게) |
/// | 샘플 | `<임시 폴더>/photos/sample` | 둘러보기용, 시작할 때마다 비움 |
///
/// 파일 이름: `<사진 id>.jpg`(원본) · `<사진 id>_thumb.jpg`(목록용 작은 사진)
class PhotoFiles {
  /// [root]: 폴더 위치를 알려 주는 함수. (앱 문서 폴더를 찾는 일이 비동기라 처음 쓸 때 한 번만 부른다)
  PhotoFiles(Future<Directory> Function() root) : _root = root;

  final Future<Directory> Function() _root;
  Future<Directory>? _dir;

  Future<Directory> get _directory => _dir ??= _root().then((dir) async {
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  });

  Future<File> _file(int photoId, {required bool thumb}) async =>
      File('${(await _directory).path}/$photoId${thumb ? '_thumb' : ''}.jpg');

  Future<void> save(int photoId, {required Uint8List image, required Uint8List thumb}) async {
    await (await _file(photoId, thumb: false)).writeAsBytes(image, flush: true);
    await (await _file(photoId, thumb: true)).writeAsBytes(thumb, flush: true);
  }

  /// 한쪽만 저장한다. (회원이 서버에서 받은 사진을 캐시에 담을 때)
  Future<void> saveOne(int photoId, Uint8List bytes, {required bool thumb}) async =>
      (await _file(photoId, thumb: thumb)).writeAsBytes(bytes, flush: true);

  /// 저장된 사진. 없으면 null.
  Future<Uint8List?> read(int photoId, {required bool thumb}) async {
    final file = await _file(photoId, thumb: thumb);
    return file.existsSync() ? file.readAsBytes() : null;
  }

  Future<void> delete(Iterable<int> photoIds) async {
    for (final id in photoIds) {
      for (final thumb in [false, true]) {
        final file = await _file(id, thumb: thumb);
        if (file.existsSync()) await file.delete();
      }
    }
  }

  /// [photoIds]에 없는 사진 파일을 지운다. (다른 기기에서 지운 사진의 캐시 정리)
  Future<void> retainOnly(Set<int> photoIds) async {
    final dir = await _directory;
    for (final entity in dir.listSync()) {
      final name = entity.uri.pathSegments.last;
      final id = int.tryParse(name.split(RegExp(r'[_.]')).first);
      if (entity is File && (id == null || !photoIds.contains(id))) await entity.delete();
    }
  }

  /// 폴더의 사진을 모두 지운다.
  Future<void> clear() => retainOnly(const {});
}
