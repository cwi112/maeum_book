import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';

part 'settings_state.dart';

/// 설정 탭의 ViewModel. 상태(state) = [SettingsState].
///
/// 데이터 관리 기능(샘플 넣기·모두 지우기)은 결과 건수만 돌려주고, 목록·통계 화면은 DB Stream으로 자동 갱신된다.
class SettingsViewModel extends BaseViewModel<SettingsState> {
  @override
  SettingsState build() {
    _loadVersion();
    return const SettingsState();
  }

  LedgerRepository get _repository => ref.read(ledgerRepositoryProvider);
  AppUpdateRepository get _updateRepository => ref.read(appUpdateRepositoryProvider);

  /// 설치된 앱 버전을 기기에서 읽어 화면에 보여준다. (앱을 업데이트하면 자동으로 새 버전이 보인다)
  Future<void> _loadVersion() async {
    final version = await runTask(_updateRepository.currentVersion);
    if (version != null && ref.mounted) state = state.copyWith(appVersion: version);
  }

  /// 샘플 기록을 넣는다. 성공하면 넣은 건수, 실패하면 null.
  Future<int?> addSamples({ErrorCallback? onError}) => runTask(_repository.addSamples, onError: onError);

  /// 모든 기록을 지운다. 성공하면 지운 건수, 실패하면 null. (화면에서 확인 창을 거친 뒤 호출)
  Future<int?> clearAll({ErrorCallback? onError}) => runTask(_repository.clearAll, onError: onError);

  AuthRepository get _authRepository => ref.read(authRepositoryProvider);

  /// 로그아웃. 성공하면 true. (인터넷이 없어도 기기에서는 로그아웃된다)
  Future<bool> signOut({void Function(AuthFailure failure)? onFailure}) =>
      _runAuth(_authRepository.signOut, onFailure: onFailure);

  /// 회원 탈퇴 (서버 계정 삭제). 기기 안의 기록은 그대로 둔다. 성공하면 true.
  Future<bool> deleteAccount({void Function(AuthFailure failure)? onFailure}) =>
      _runAuth(_authRepository.deleteAccount, onFailure: onFailure);

  /// 계정 작업을 실행하고, 실패하면 이유([AuthFailure])를 알린다.
  Future<bool> _runAuth(Future<void> Function() action, {void Function(AuthFailure failure)? onFailure}) async {
    try {
      await action();
      return true;
    } on AuthFailure catch (failure) {
      if (!failure.isCanceled) onFailure?.call(failure);
      return false;
    } catch (error) {
      onFailure?.call(AuthFailure(AuthFailureType.unknown, error));
      return false;
    }
  }

  /// 최신 버전인지 확인한다. 이미 확인 중이면 null.
  Future<AppUpdateResult?> checkUpdate() async {
    if (state.isCheckingUpdate) return null;
    state = state.copyWith(isCheckingUpdate: true);
    final result = await _updateRepository.check();
    if (ref.mounted) state = state.copyWith(isCheckingUpdate: false);
    return result;
  }
}

final settingsViewModelProvider = NotifierProvider.autoDispose<SettingsViewModel, SettingsState>(SettingsViewModel.new);
