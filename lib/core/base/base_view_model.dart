import 'dart:async';

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
/// 데이터를 가져오는 방법에 따라 둘 중 **하나만** 구현한다.
///
/// | 구현할 메서드 | 언제 | 동작 |
/// |---|---|---|
/// | [load] | 한 번 읽으면 되는 데이터 | 화면이 열릴 때 한 번 실행 |
/// | [watch] | DB처럼 바뀔 수 있는 데이터 | Stream을 구독하다가 **새 값이 올 때마다 화면 자동 갱신** |
///
/// 불러오는 동안은 로딩, 실패하면 오류 화면이 [BaseAsyncView]에서 자동으로 표시된다.
///
/// ```dart
/// // 1) 한 번만 읽기
/// class NoticeViewModel extends BaseAsyncViewModel<List<Notice>> {
///   @override
///   Future<List<Notice>> load() => ref.read(noticeRepositoryProvider).fetchAll();
/// }
///
/// // 2) DB 변경을 계속 구독하기
/// class SentViewModel extends BaseAsyncViewModel<List<LedgerEntry>> {
///   @override
///   Stream<List<LedgerEntry>> watch() => ref.watch(ledgerRepositoryProvider).watchEntries(RecordDirection.sent);
/// }
/// ```
abstract class BaseAsyncViewModel<S> extends AsyncNotifier<S> {
  /// 데이터를 한 번 불러온다. [watch]를 구현했다면 Stream의 첫 값을 돌려준다.
  Future<S> load() {
    final stream = watch();
    if (stream == null) throw UnimplementedError('$runtimeType: load() 또는 watch() 중 하나를 구현해야 해요');
    return stream.first;
  }

  /// 데이터 변경을 계속 받아 올 Stream. 구현하지 않으면 null이고, 그때는 [load]를 쓴다.
  Stream<S>? watch() => null;

  /// 화면이 처음 열릴 때 Riverpod이 호출한다.
  ///
  /// - [watch]가 없으면: [load] 결과를 그대로 첫 상태로 쓴다.
  /// - [watch]가 있으면: Stream을 구독한다.
  ///   첫 값은 build의 결과(첫 화면)가 되고, 그 뒤에 오는 값은 `state`에 넣어 화면을 다시 그리게 한다.
  ///   화면이 사라지면(autoDispose) `ref.onDispose`에서 구독을 끊어 메모리 누수를 막는다.
  @override
  Future<S> build() {
    final stream = watch();
    if (stream == null) return load();

    final firstValue = Completer<S>();
    final subscription = stream.listen(
      (data) {
        if (firstValue.isCompleted) {
          state = AsyncData(data);
        } else {
          firstValue.complete(data);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (firstValue.isCompleted) {
          state = AsyncError(error, stackTrace);
        } else {
          firstValue.completeError(error, stackTrace);
        }
      },
    );
    ref.onDispose(subscription.cancel);
    return firstValue.future;
  }

  /// 처음부터 다시 불러온다. (오류 화면의 "다시 시도" 버튼이 호출)
  ///
  /// `invalidateSelf`는 이 ViewModel의 [build]를 새로 실행시킨다. 기존 Stream 구독은 자동으로 정리된다.
  void reload() => ref.invalidateSelf();

  /// 저장·삭제처럼 시간이 걸리는 작업을 실행하고, 실패하면 오류를 [onError]로 알려 준다.
  ///
  /// [watch]를 쓰는 화면은 DB가 바뀌면 목록이 알아서 갱신되므로, 여기서는 작업만 실행하면 된다.
  /// 작업이 끝날 때까지 화면 전체를 로딩으로 바꾸지 않아서, 목록이 깜빡이지 않는다.
  Future<bool> runTask(Future<void> Function() task, {void Function(Object error)? onError}) async {
    try {
      await task();
      return true;
    } catch (error) {
      onError?.call(error);
      return false;
    }
  }
}
