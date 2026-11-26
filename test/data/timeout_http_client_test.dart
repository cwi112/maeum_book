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
