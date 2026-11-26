import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:maeum_book/data/data.dart';

/// 테스트용 카메라 · 앨범: 실제 화면을 띄우지 않고 미리 정한 사진을 돌려준다.
class FakePhotoPicker implements PhotoPickerService {
  /// 다음에 돌려줄 사진 수 (0이면 취소한 것처럼)
  int nextCount = 1;

  /// 작은 진짜 JPEG (화면에서 그림으로 풀 수 있게)
  static final Uint8List sample = img.encodeJpg(img.Image(width: 8, height: 8)..clear(img.ColorRgb8(200, 120, 90)));

  @override
  Future<Uint8List?> takePhoto() async => nextCount > 0 ? sample : null;

  @override
  Future<List<Uint8List>> pickFromAlbum({required int limit}) async => List.filled(nextCount.clamp(0, limit), sample);
}

/// 테스트용 사진 줄이기: 다른 일꾼(Isolate) 없이 그대로 돌려준다. (위젯 테스트의 가짜 시계에서도 바로 끝나게)
class FakePhotoProcessor implements PhotoProcessor {
  const FakePhotoProcessor();

  @override
  Future<ProcessedPhoto> process(Uint8List raw) async => ProcessedPhoto(image: raw, thumb: raw);
}
