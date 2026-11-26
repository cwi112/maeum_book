import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maeum_book/data/data.dart';

void main() {
  group('isNewer: 버전 비교', () {
    test('숫자로 비교한다 (1.0.10 > 1.0.9)', () => expect(AppUpdateRepository.isNewer('1.0.10', '1.0.9'), isTrue));
    test('같으면 false', () => expect(AppUpdateRepository.isNewer('1.0.1', '1.0.1'), isFalse));
    test('더 낮으면 false', () => expect(AppUpdateRepository.isNewer('1.0.0', '1.0.1'), isFalse));
    test('빈 자리는 0으로 본다', () => expect(AppUpdateRepository.isNewer('1.1', '1.0.5'), isTrue));
    test('빌드 번호(+3)는 무시한다', () => expect(AppUpdateRepository.isNewer('1.0.1+5', '1.0.1'), isFalse));
  });

  test('fetchLatest: JSON을 읽는다', () async {
    final client = MockClient(
      (_) async => http.Response('{"latestVersion":"1.0.2","iosUrl":"itms-beta://","androidUrl":"https://a"}', 200),
    );
    final info = await AppUpdateRepository(versionUrl: 'https://x/app_version.json', client: client).fetchLatest();
    expect(info.latestVersion, '1.0.2');
    expect(info.iosUrl, 'itms-beta://');
  });

  test('fetchLatest: 서버 오류면 예외', () async {
    final client = MockClient((_) async => http.Response('not found', 404));
    expect(AppUpdateRepository(versionUrl: 'https://x', client: client).fetchLatest(), throwsException);
  });
}
