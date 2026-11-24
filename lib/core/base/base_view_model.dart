import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 일반 화면용 ViewModel의 부모 클래스. (Riverpod `Notifier`)
///
/// - [S]: 화면에 보여줄 상태(State)의 타입.
/// - [build]에서 처음 상태를 만들어 돌려준다. (화면이 처음 열릴 때 한 번 실행 = onInit)
/// - `state = 새값`으로 바꾸면 화면이 자동으로 다시 그려진다.
/// - 정리할 것이 있으면 build 안에서 `ref.onDispose(() { ... })`에 등록한다.
///
/// ```dart
/// class CounterViewModel extends BaseViewModel<int> {
///   @override
///   int build() => 0;
///
///   void increment() => state = state + 1;
/// }
///
/// final counterViewModelProvider =
///     NotifierProvider.autoDispose<CounterViewModel, int>(CounterViewModel.new);
/// ```
abstract class BaseViewModel<S> extends Notifier<S> {}

/// 데이터를 불러와야 하는 화면용 ViewModel의 부모 클래스. (Riverpod `AsyncNotifier`)
///
/// - [load]에 데이터를 불러오는 코드를 쓴다. 화면이 열리면 자동으로 실행된다.
/// - 불러오는 동안은 로딩, 실패하면 오류 화면이 [BaseAsyncView]에서 자동으로 표시된다.
/// - 다시 불러오려면 [reload]를 호출한다.
///
/// ```dart
/// class HistoryViewModel extends BaseAsyncViewModel<List<String>> {
///   @override
///   Future<List<String>> load() => repository.fetchAll();
/// }
///
/// final historyViewModelProvider = AsyncNotifierProvider.autoDispose<
///     HistoryViewModel, List<String>>(HistoryViewModel.new);
/// ```
abstract class BaseAsyncViewModel<S> extends AsyncNotifier<S> {
  /// 화면에 필요한 데이터를 불러온다.
  Future<S> load();

  @override
  Future<S> build() => load();

  /// 데이터를 다시 불러온다. 오류가 나면 state가 오류 상태가 된다.
  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(load);
  }

  /// 데이터를 바꾸는 작업(저장·삭제 등)을 실행한다.
  ///
  /// 작업 중에는 로딩, 실패하면 오류 상태가 된다. 성공하면 [task]가 돌려준 값이 새 상태가 된다.
  Future<void> runBusy(Future<S> Function() task) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(task);
  }
}
