import 'dart:convert';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:http/http.dart' as http;
import 'package:maeum_book/data/models/app_update_info.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 앱 버전 확인 Repository.
///
/// - 지금 설치된 버전: 기기에서 읽는다. (pubspec.yaml의 version이 빌드할 때 앱에 들어간다)
/// - 최신 버전: [versionUrl]의 JSON을 읽는다. 릴리스 스크립트(scripts/release.ps1)가 배포할 때 이 파일도 함께 올린다.
class AppUpdateRepository {
  AppUpdateRepository({required this.versionUrl, http.Client? client}) : _client = client ?? http.Client();

  final String versionUrl;
  final http.Client _client;

  /// 지금 설치된 앱 버전 (예: 1.0.1)
  Future<String> currentVersion() async => (await PackageInfo.fromPlatform()).version;

  /// 서버의 최신 버전 정보를 읽는다. 5초 안에 응답이 없거나 실패하면 예외.
  Future<AppUpdateInfo> fetchLatest() async {
    final response = await _client.get(Uri.parse(versionUrl)).timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) throw Exception('버전 정보를 읽지 못했어요 (${response.statusCode})');
    return AppUpdateInfo.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
  }

  /// 지금 버전과 최신 버전을 비교한다. 실패해도 예외를 던지지 않고 [AppUpdateCheckFailed]를 돌려준다.
  Future<AppUpdateResult> check() async {
    try {
      final current = await currentVersion();
      final latest = await fetchLatest();
      if (!isNewer(latest.latestVersion, current)) return const AppUpToDate();
      final url = defaultTargetPlatform == TargetPlatform.iOS ? latest.iosUrl : latest.androidUrl;
      return AppUpdateAvailable(latestVersion: latest.latestVersion, url: url);
    } catch (_) {
      return const AppUpdateCheckFailed();
    }
  }

  /// [latest]가 [current]보다 높은 버전이면 true. 점으로 나눈 숫자를 앞자리부터 비교한다.
  ///
  /// ```dart
  /// isNewer('1.0.10', '1.0.9')  // true  (글자가 아니라 숫자로 비교)
  /// isNewer('1.0.1', '1.0.1')   // false
  /// isNewer('1.1', '1.0.5')     // true  (빈 자리는 0)
  /// ```
  static bool isNewer(String latest, String current) {
    List<int> parse(String v) => v.split('+').first.split('.').map((p) => int.tryParse(p.trim()) ?? 0).toList();
    final a = parse(latest);
    final b = parse(current);
    for (var i = 0; i < (a.length > b.length ? a.length : b.length); i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }
}
