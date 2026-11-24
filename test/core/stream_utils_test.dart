import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:maeum_book/core/utils/stream_utils.dart';

void main() {
  test('combineLatest2: 두 Stream 모두 값이 온 뒤부터, 어느 쪽이 바뀌어도 최신 값을 묶어 보낸다', () async {
    final a = StreamController<int>();
    final b = StreamController<String>();
    final results = <String>[];
    final subscription = combineLatest2(a.stream, b.stream, (x, y) => '$x$y').listen(results.add);

    a.add(1);
    await pumpEventQueue();
    expect(results, isEmpty); // b가 아직 없음

    b.add('a');
    await pumpEventQueue();
    a.add(2);
    await pumpEventQueue();
    b.add('b');
    await pumpEventQueue();
    expect(results, ['1a', '2a', '2b']);

    await subscription.cancel();
    expect(a.hasListener, isFalse); // 구독을 끊으면 원본 구독도 끊긴다
    await a.close();
    await b.close();
  });
}
