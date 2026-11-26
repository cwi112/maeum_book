import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:maeum_book/core/core.dart';

/// 공통 로딩 막: 작업 중에는 터치 · 뒤로 가기를 막고, 모양은 두 가지(버튼 · 어두운 화면)
void main() {
  late int taps;
  late BuildContext pageContext;

  Future<void> pumpPage(WidgetTester tester) async {
    taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppLoading(child: child!),
        home: Builder(
          builder: (context) {
            pageContext = context;
            return Scaffold(
              body: Center(
                child: TextButton(onPressed: () => taps++, child: const Text('누르기')),
              ),
            );
          },
        ),
      ),
    );
  }

  testWidgets('어두운 화면: 0.3초 뒤부터 흰 스피너와 문구가 보이고, 그동안 누를 수 없다', (tester) async {
    await pumpPage(tester);
    final work = Completer<String>();
    final result = pageContext.withLoading(() => work.future, message: '지우는 중이에요');
    await tester.pump();

    // 0.3초 전: 아직 화면은 그대로지만 이미 눌리지 않는다.
    expect(find.text('지우는 중이에요'), findsNothing);
    await tester.tap(find.text('누르기'), warnIfMissed: false);
    expect(taps, 0);

    await tester.pump(AppLoading.showDelay);
    expect(find.text('지우는 중이에요'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // 10초가 넘으면 "연결이 느려요"
    await tester.pump(AppLoading.slowAfter);
    expect(find.textContaining('연결이 느려요'), findsOneWidget);

    work.complete('끝');
    expect(await result, '끝');
    await tester.pump();
    expect(find.text('지우는 중이에요'), findsNothing);
    await tester.tap(find.text('누르기'));
    expect(taps, 1); // 끝나면 다시 눌린다
  });

  testWidgets('버튼 모양: 화면은 덮지 않고 터치만 막는다', (tester) async {
    await pumpPage(tester);
    final work = Completer<void>();
    unawaited(pageContext.withLoading(() => work.future, style: LoadingStyle.button));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(CircularProgressIndicator), findsNothing); // 스피너는 버튼이 직접 그린다
    await tester.tap(find.text('누르기'), warnIfMissed: false);
    expect(taps, 0);

    work.complete();
    await tester.pumpAndSettle(); // 끝난 뒤 막을 걷는 화면을 그린다
    await tester.tap(find.text('누르기'));
    expect(taps, 1);
  });

  testWidgets('작업 중에는 안드로이드 뒤로 버튼이 화면을 닫지 않는다', (tester) async {
    await pumpPage(tester);
    final work = Completer<void>();
    unawaited(pageContext.withLoading(() => work.future));
    await tester.pump();

    expect(await tester.binding.handlePopRoute(), isTrue); // 로딩 막이 먼저 받아서 처리함

    work.complete();
    await tester.pumpAndSettle();
    expect(await tester.binding.handlePopRoute(), isFalse); // 끝나면 원래대로 (첫 화면이라 닫을 곳 없음)
  });

  testWidgets('작업이 실패해도 막은 풀리고 오류는 그대로 전달된다', (tester) async {
    await pumpPage(tester);
    await expectLater(pageContext.withLoading(() async => throw StateError('실패')), throwsStateError);
    await tester.pump(AppLoading.showDelay);
    await tester.tap(find.text('누르기'));
    expect(taps, 1);
  });
}
