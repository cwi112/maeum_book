part of 'settings_view_model.dart';

/// 설정 탭의 상태. (settings_view_model.dart의 일부 — part of)
class SettingsState {
  const SettingsState({this.appVersion = AppDefine.appVersion});

  /// 앱 버전 표시용
  final String appVersion;

  // TODO: 알림 사용 여부 등 설정 항목을 여기에 추가한다.

  SettingsState copyWith({String? appVersion}) => SettingsState(appVersion: appVersion ?? this.appVersion);
}
