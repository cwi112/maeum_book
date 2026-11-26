/// 서버(저장소의 `app_version.json`)에 올려 둔 최신 버전 정보.
///
/// ```json
/// {
///   "latestVersion": "1.0.2",
///   "iosUrl": "itms-beta://",
///   "androidUrl": "https://github.com/cwi112/maeum_book/releases/latest"
/// }
/// ```
/// 지금 iOS는 TestFlight 앱(`itms-beta://`)으로 보낸다.
/// App Store에 출시하면 `iosUrl`만 App Store 주소로 바꾸면 되고, 앱을 다시 배포할 필요는 없다.
class AppUpdateInfo {
  const AppUpdateInfo({required this.latestVersion, this.iosUrl, this.androidUrl});

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) => AppUpdateInfo(
    latestVersion: json['latestVersion'] as String,
    iosUrl: json['iosUrl'] as String?,
    androidUrl: json['androidUrl'] as String?,
  );

  /// 최신 버전 (예: 1.0.2)
  final String latestVersion;

  /// iOS에서 업데이트하러 갈 주소
  final String? iosUrl;

  /// Android에서 업데이트하러 갈 주소
  final String? androidUrl;
}

/// 업데이트 확인 결과.
sealed class AppUpdateResult {
  const AppUpdateResult();
}

/// 이미 최신 버전
final class AppUpToDate extends AppUpdateResult {
  const AppUpToDate();
}

/// 새 버전이 있음. [url]이 null이면 이 기기에서 업데이트하러 갈 곳이 없다.
final class AppUpdateAvailable extends AppUpdateResult {
  const AppUpdateAvailable({required this.latestVersion, this.url});

  final String latestVersion;
  final String? url;
}

/// 확인하지 못함 (인터넷 연결 없음 등)
final class AppUpdateCheckFailed extends AppUpdateResult {
  const AppUpdateCheckFailed();
}
