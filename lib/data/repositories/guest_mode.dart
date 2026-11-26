import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 기기에 저장하는 간단한 설정값 저장소. main.dart에서 실제 인스턴스로 바꿔 끼운다. (테스트는 가짜 값)
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('main.dart에서 SharedPreferences를 override 해야 해요'),
);

/// "로그인 없이 시작하기"를 골랐는지. (비회원 모드)
///
/// - true: 비회원으로 앱을 쓰는 중 → 앱을 다시 켜도 시작 화면 없이 바로 기록 화면
/// - false: 아직 고르지 않음 · 로그인함 · 로그아웃함 → 로그인하지 않은 상태면 시작(로그인) 화면을 보여준다
///
/// 앱을 지워도 기록(DB)과 함께 사라진다.
class GuestModeNotifier extends Notifier<bool> {
  static const _key = 'guest_mode';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  bool build() => _prefs.getBool(_key) ?? false;

  /// 비회원으로 시작
  Future<void> enter() async {
    state = true;
    await _prefs.setBool(_key, true);
  }

  /// 비회원 모드 끝 (로그인 · 로그아웃 · 탈퇴할 때)
  Future<void> exit() async {
    state = false;
    await _prefs.remove(_key);
  }
}

final guestModeProvider = NotifierProvider<GuestModeNotifier, bool>(GuestModeNotifier.new);
