import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:maeum_book/data/data.dart';

/// 시간이 지나면 요청을 "실제로" 끊는지, 보통 요청은 그대로 오가는지 진짜 작은 서버로 확인한다.
void main() {
  late HttpServer server;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      request.response
        ..statusCode = 200
        ..write('echo:${request.method}:$body');
      await request.response.close();
    });
  });

  tearDown(() => server.close(force: true));

  Uri url(String path) => Uri.parse('http://127.0.0.1:${server.port}$path');

  test('보통 요청은 내용(본문 · 응답)이 그대로 오간다', () async {
    final client = TimeoutHttpClient(timeoutFor: (_) => const Duration(seconds: 5));
    final response = await client.post(url('/echo'), body: '안녕');
    expect(response.statusCode, 200);
    expect(utf8.decode(response.bodyBytes), 'echo:POST:안녕');
    client.close();
  });

  test('사진 업로드(multipart)도 구분자가 담긴 content-type과 파일 내용이 그대로 간다', () async {
    // Supabase Storage 업로드와 같은 방식. content-type은 finalize() 때 만들어진다.
    final upload = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final received = Completer<(String?, String)>();
    upload.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      received.complete((request.headers.value('content-type'), body));
      request.response.statusCode = 200;
      await request.response.close();
    });

    final client = TimeoutHttpClient(timeoutFor: (_) => const Duration(seconds: 5));
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://127.0.0.1:${upload.port}/storage/v1/object/a/1.jpg'),
    )..files.add(http.MultipartFile.fromBytes('', utf8.encode('사진내용'), filename: '1.jpg'));
    final response = await client.send(request);
    expect(response.statusCode, 200);

    final (contentType, body) = await received.future;
    expect(contentType, startsWith('multipart/form-data; boundary='));
    final boundary = contentType!.split('boundary=').last;
    expect(body, contains('--$boundary'));
    expect(body, contains('사진내용'));
    client.close();
    await upload.close(force: true);
  });

  test('시간이 지나면 요청이 끊기고(RequestAbortedException), 서버 쪽 연결도 닫힌다', () async {
    // 요청을 받고 답하지 않는 서버. 앱이 연결을 끊으면 소켓이 닫혀서(onDone) 바로 알 수 있다.
    final silent = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final closedByApp = Completer<void>();
    silent.listen(
      (socket) => socket.listen((_) {}, onDone: closedByApp.complete, onError: (Object _) => closedByApp.complete()),
    );

    final client = TimeoutHttpClient(timeoutFor: (_) => const Duration(milliseconds: 300));
    final stopwatch = Stopwatch()..start();
    await expectLater(
      client.get(Uri.parse('http://127.0.0.1:${silent.port}/slow')),
      throwsA(isA<http.RequestAbortedException>()),
    );
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 3))); // 끝없이 기다리지 않음
    // 기다리기만 멈춘 게 아니라 연결이 실제로 끊겼다.
    await closedByApp.future.timeout(const Duration(seconds: 3));
    client.close();
    await silent.close();
  });

  test('주소로 시간을 고른다: 사진 파일 40초 · 로그인 20초 · 그 밖 15초', () {
    Duration of(String path) => TimeoutHttpClient.defaultTimeoutFor(Uri.parse('https://x.supabase.co$path'));
    expect(of('/storage/v1/object/event-photos/u/1.jpg'), AppTimeouts.file);
    expect(of('/auth/v1/token'), AppTimeouts.auth);
    expect(of('/rest/v1/ledger_entries'), AppTimeouts.data);
  });
}
