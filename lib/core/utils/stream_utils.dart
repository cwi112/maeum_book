import 'dart:async';

/// 두 Stream을 합쳐서, **둘 중 하나라도 새 값을 보내면** 두 최신 값을 묶어 보내는 Stream을 만든다.
/// (흔히 combineLatest라고 부르는 동작. 외부 패키지 없이 직접 구현)
///
/// ```dart
/// combineLatest2(eventStream, entriesStream, (event, entries) => EventDetailState(event, entries))
/// ```
/// - 두 Stream 모두 한 번 이상 값을 보낸 뒤부터 결과를 보낸다.
/// - 결과 Stream 구독을 끊으면 두 원본 구독도 함께 끊고, 두 원본이 모두 끝나면 결과 Stream도 닫는다. (메모리 누수 방지)
Stream<R> combineLatest2<A, B, R>(Stream<A> streamA, Stream<B> streamB, R Function(A a, B b) combiner) {
  late final StreamController<R> controller;
  StreamSubscription<A>? subA;
  StreamSubscription<B>? subB;
  A? latestA;
  B? latestB;
  var hasA = false;
  var hasB = false;
  var doneCount = 0;

  // 두 원본이 모두 끝나면 결과 Stream도 닫는다.
  void onDone() {
    if (++doneCount == 2) controller.close();
  }

  void emitIfReady() {
    if (hasA && hasB) controller.add(combiner(latestA as A, latestB as B));
  }

  controller = StreamController<R>(
    onListen: () {
      subA = streamA.listen((value) {
        latestA = value;
        hasA = true;
        emitIfReady();
      }, onError: controller.addError, onDone: onDone);
      subB = streamB.listen((value) {
        latestB = value;
        hasB = true;
        emitIfReady();
      }, onError: controller.addError, onDone: onDone);
    },
    onCancel: () async {
      await subA?.cancel();
      await subB?.cancel();
    },
  );
  return controller.stream;
}
