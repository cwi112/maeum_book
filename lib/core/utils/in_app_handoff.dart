/// 앱이 **스스로** 다른 화면(앨범 · 카메라 · 공유 창 · 저장 창 · 브라우저)을 열었다가 돌아오는 중인지 기억한다.
///
/// 앱으로 돌아오면(resume) 회원 장부를 서버에서 새로 받는데, 이건 "다른 기기에서 고친 내용"을 반영하려는 것이다.
/// 사진을 고르러 앨범에 다녀온 것처럼 앱이 직접 연 화면에서 돌아올 때는 다른 기기의 변화가 있을 리 없고,
/// 오히려 그 직후 저장(사진 추가)과 겹쳐 서버 전송만 늘어난다. 그래서 이때는 받아 오지 않는다.
///
/// ```dart
/// final photo = await InAppHandoff.run(() => picker.pickImage(...));
/// ```
abstract final class InAppHandoff {
  static int _active = 0;
  static DateTime? _endedAt;

  /// 돌아온 뒤 이 시간 안의 resume은 "앱이 연 화면에서 돌아온 것"으로 본다.
  /// (시스템 화면이 닫히는 것과 앱의 resume 알림 순서가 기기마다 조금씩 달라서 여유를 둔다)
  static const grace = Duration(seconds: 3);

  /// [action]이 진행되는 동안 · 끝난 직후의 resume에서는 서버에서 받아 오지 않는다.
  static Future<T> run<T>(Future<T> Function() action) async {
    _active++;
    try {
      return await action();
    } finally {
      _active--;
      _endedAt = DateTime.now();
    }
  }

  /// 지금 resume이 앱이 연 화면에서 돌아온 것인지
  static bool get isReturning {
    if (_active > 0) return true;
    final ended = _endedAt;
    return ended != null && DateTime.now().difference(ended) < grace;
  }
}
