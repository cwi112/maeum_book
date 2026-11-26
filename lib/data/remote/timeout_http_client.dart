import 'dart:async';

import 'package:http/http.dart' as http;

/// 서버 통신 시간 제한 모음
abstract final class AppTimeouts {
  /// 장부 표 읽기 · 쓰기 (기록 · 행사 · 종류 · 사진 정보)
  static const data = Duration(seconds: 15);

  /// 사진 파일 올리기 · 받기 (장당 약 0.4MB, 느린 데이터 통신 고려)
  static const file = Duration(seconds: 40);

  /// 로그인 · 로그아웃 · 탈퇴
  static const auth = Duration(seconds: 20);

  /// 최신 버전 확인 (실패해도 괜찮은 일이라 짧게)
  static const versionCheck = Duration(seconds: 5);
}

/// 시간이 지나면 **요청을 실제로 끊는** http 연결. Supabase · 버전 확인이 모두 이것을 쓴다.
///
/// Dart의 `future.timeout()`은 "기다리기만 멈추고" 요청은 계속 보낸다. 그러면 앱은 실패라고 했는데
/// 서버에는 늦게 저장되는 일이 생길 수 있다. 이 연결은 시간이 지나면 소켓을 닫아 요청 자체를 취소한다.
/// 끊긴 요청은 [http.RequestAbortedException](ClientException)으로 끝나고, 화면에는 "인터넷 연결" 안내가 뜬다.
///
/// 앱을 강제로 끄면 휴대폰이 모든 연결을 끊으므로 따로 할 일은 없다.
class TimeoutHttpClient extends http.BaseClient {
  TimeoutHttpClient({http.Client? inner, Duration Function(Uri url)? timeoutFor})
    : _inner = inner ?? http.Client(),
      _timeoutFor = timeoutFor ?? defaultTimeoutFor;

  final http.Client _inner;
  final Duration Function(Uri url) _timeoutFor;

  /// 주소로 알맞은 시간을 고른다. (Supabase 주소 규칙: /storage · /auth · 그 밖은 표)
  static Duration defaultTimeoutFor(Uri url) {
    final path = url.path;
    if (path.contains('/storage/')) return AppTimeouts.file;
    if (path.contains('/auth/')) return AppTimeouts.auth;
    return AppTimeouts.data;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final abort = Completer<void>();
    final timer = Timer(_timeoutFor(request.url), () {
      if (!abort.isCompleted) abort.complete();
    });

    // 원래 요청을 "끊을 수 있는 요청"으로 옮겨 담는다. (내용은 그대로 흘려보냄)
    final abortable = http.AbortableStreamedRequest(request.method, request.url, abortTrigger: abort.future)
      ..headers.addAll(request.headers)
      ..contentLength = request.contentLength
      ..followRedirects = request.followRedirects
      ..maxRedirects = request.maxRedirects
      ..persistentConnection = request.persistentConnection;
    // 본문을 다 옮긴 뒤 반드시 닫아야 서버가 "요청 끝"을 안다. (닫지 않으면 서버가 계속 기다린다)
    unawaited(
      abortable.sink
          .addStream(request.finalize())
          .then<void>((_) => abortable.sink.close(), onError: (Object error) => abortable.sink.close()),
    );

    try {
      final response = await _inner.send(abortable);
      // 응답 내용을 다 받을 때까지 시간을 잰다. 다 받으면(또는 실패하면) 타이머를 끈다.
      final body = response.stream.transform(
        StreamTransformer<List<int>, List<int>>.fromHandlers(
          handleDone: (sink) {
            timer.cancel();
            sink.close();
          },
          handleError: (error, stack, sink) {
            timer.cancel();
            sink.addError(error, stack);
          },
        ),
      );
      return http.StreamedResponse(
        body,
        response.statusCode,
        contentLength: response.contentLength,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    } catch (_) {
      timer.cancel();
      rethrow;
    }
  }

  @override
  void close() => _inner.close();
}
