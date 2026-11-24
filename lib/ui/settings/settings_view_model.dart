import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';

part 'settings_state.dart';

/// 설정 탭의 ViewModel. 상태(state) = [SettingsState].
///
/// 데이터 관리 기능(샘플 넣기·모두 지우기)은 결과 건수만 돌려주고, 목록·통계 화면은 DB Stream으로 자동 갱신된다.
class SettingsViewModel extends BaseViewModel<SettingsState> {
  @override
  SettingsState build() => const SettingsState();

  LedgerRepository get _repository => ref.read(ledgerRepositoryProvider);

  /// 샘플 기록을 넣는다. 성공하면 넣은 건수, 실패하면 null.
  Future<int?> addSamples({ErrorCallback? onError}) => runTask(_repository.addSamples, onError: onError);

  /// 모든 기록을 지운다. 성공하면 지운 건수, 실패하면 null. (화면에서 확인 창을 거친 뒤 호출)
  Future<int?> clearAll({ErrorCallback? onError}) => runTask(_repository.clearAll, onError: onError);
}

final settingsViewModelProvider = NotifierProvider.autoDispose<SettingsViewModel, SettingsState>(SettingsViewModel.new);
