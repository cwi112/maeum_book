import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maeum_book/core/utils/app_monitor.dart';
import 'package:maeum_book/data/repositories/guest_mode.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 화면 모드: 라이트 · 다크 · 시스템(기기 설정 따라가기). 기본값은 시스템.
///
/// 기기에 저장하므로 앱을 다시 켜도 그대로다. (로그인 · 계정과 상관없음)
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  ThemeMode build() {
    final saved = _prefs.getString(_key);
    return ThemeMode.values.firstWhere((mode) => mode.name == saved, orElse: () => ThemeMode.system);
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    AppMonitor.logEvent(AppEvents.themeMode, {'mode': mode.name});
    await _prefs.setString(_key, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// 설정 화면에 보여 줄 이름
extension ThemeModeLabel on ThemeMode {
  String get label => switch (this) {
    ThemeMode.system => '시스템 설정 따라가기',
    ThemeMode.light => '라이트',
    ThemeMode.dark => '다크',
  };
}
