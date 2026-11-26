import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:maeum_book/core/utils/in_app_handoff.dart';

/// 카메라로 찍기 · 앨범에서 고르기. (테스트에서는 가짜로 바꿔 끼운다)
///
/// 고르는 단계에서 이미 긴 변 1600px · 품질 85로 줄여 받는다. 아이폰 HEIC 사진도 이때 JPEG로 바뀐다.
/// 권한: 아이폰은 Info.plist의 카메라 · 사진 문구가 필요하다. 안드로이드는 카메라 앱 · 사진 선택기를 빌려 써서 권한 요청이 없다.
class PhotoPickerService {
  PhotoPickerService([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const _maxSide = 1600.0;
  static const _quality = 85;

  /// 카메라로 한 장 찍는다. 취소하면 null.
  ///
  /// 카메라 · 앨범은 앱 밖 화면이라 다녀오면 앱이 "다시 열린 것"처럼 알림을 받는다.
  /// [InAppHandoff]로 감싸서, 이때는 서버에서 장부를 새로 받지 않게 한다. (막 고른 사진 저장과 겹치지 않게)
  Future<Uint8List?> takePhoto() async {
    final file = await InAppHandoff.run(
      () => _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: _maxSide,
        maxHeight: _maxSide,
        imageQuality: _quality,
      ),
    );
    return file?.readAsBytes();
  }

  /// 앨범에서 여러 장 고른다. 최대 [limit]장. 취소하면 빈 목록.
  Future<List<Uint8List>> pickFromAlbum({required int limit}) async {
    if (limit <= 0) return const [];
    final files = await InAppHandoff.run(() async {
      if (limit == 1) {
        final one = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: _maxSide,
          maxHeight: _maxSide,
          imageQuality: _quality,
        );
        return [?one];
      }
      return _picker.pickMultiImage(maxWidth: _maxSide, maxHeight: _maxSide, imageQuality: _quality, limit: limit);
    });
    return [for (final file in files.take(limit)) await file.readAsBytes()];
  }
}
