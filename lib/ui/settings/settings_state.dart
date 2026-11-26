part of 'settings_view_model.dart';

/// 설정 탭의 상태. (settings_view_model.dart의 일부 — part of)
class SettingsState {
  const SettingsState({this.appVersion, this.isCheckingUpdate = false});

  /// 지금 설치된 앱 버전. 기기에서 읽는 동안은 null.
  final String? appVersion;

  /// 최신 버전 확인 중이면 true (앱 정보를 연달아 눌러도 한 번만 확인)
  final bool isCheckingUpdate;

  // TODO: 알림 사용 여부 등 설정 항목을 여기에 추가한다.

  SettingsState copyWith({String? appVersion, bool? isCheckingUpdate}) => SettingsState(
    appVersion: appVersion ?? this.appVersion,
    isCheckingUpdate: isCheckingUpdate ?? this.isCheckingUpdate,
  );
}
