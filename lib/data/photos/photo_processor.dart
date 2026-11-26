import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// 줄인 사진 한 장: 원본(긴 변 1600px) + 목록용 작은 사진(긴 변 400px). 둘 다 JPEG.
class ProcessedPhoto {
  const ProcessedPhoto({required this.image, required this.thumb});

  final Uint8List image;
  final Uint8List thumb;
}

/// 고른 사진을 저장하기 좋게 줄인다.
///
/// 휴대폰 사진은 장당 3 ~ 5MB라 그대로 두면 기기 공간 · 서버 비용이 10배 든다.
/// 장부 기록용으로는 긴 변 1600px · 품질 80(장당 약 0.3 ~ 0.4MB)이면 리본 글씨까지 충분히 보인다. (docs/EVENT_PHOTO_PLAN.md)
///
/// 사진을 푸는 · 다시 압축하는 일은 무거워서 다른 일꾼(Isolate)에게 맡긴다. 그동안 화면이 멈추지 않는다.
class PhotoProcessor {
  const PhotoProcessor();

  static const maxSide = 1600;
  static const thumbSide = 400;

  /// 읽을 수 없는 사진이면(HEIC 등) [FormatException].
  Future<ProcessedPhoto> process(Uint8List raw) => Isolate.run(() => _process(raw));

  static ProcessedPhoto _process(Uint8List raw) {
    final decoded = img.decodeImage(raw);
    if (decoded == null) throw const FormatException('사진을 읽지 못했어요');
    // 휴대폰이 "돌려서 보라"고 적어 둔 방향(EXIF)대로 실제로 돌려 둔다. (안 하면 옆으로 누운 사진이 됨)
    final upright = img.bakeOrientation(decoded);
    return ProcessedPhoto(
      image: img.encodeJpg(_fit(upright, maxSide), quality: 80),
      thumb: img.encodeJpg(_fit(upright, thumbSide), quality: 75),
    );
  }

  /// 긴 변이 [side]를 넘으면 비율을 지켜 줄인다. (작은 사진은 그대로)
  static img.Image _fit(img.Image image, int side) {
    if (image.width <= side && image.height <= side) return image;
    return image.width >= image.height
        ? img.copyResize(image, width: side, interpolation: img.Interpolation.average)
        : img.copyResize(image, height: side, interpolation: img.Interpolation.average);
  }
}
