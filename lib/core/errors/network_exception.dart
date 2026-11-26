/// 인터넷이 없거나 약해서 서버 작업을 못 했을 때 던지는 예외.
///
/// 회원은 서버 DB가 원본이라 인터넷이 있어야 저장할 수 있다. 저장 · 수정 · 삭제가 이 예외로 실패하면
/// 화면은 `context.showErrorToast(error, ...)`로 "인터넷 연결을 확인해 주세요"를 띄운다.
class NetworkException implements Exception {
  const NetworkException([this.cause]);

  final Object? cause;

  static const String message = '인터넷 연결을 확인해 주세요. 회원은 인터넷이 연결돼야 저장할 수 있어요';

  @override
  String toString() => 'NetworkException($cause)';
}
