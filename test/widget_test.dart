import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maeum_book/app.dart';
import 'package:maeum_book/data/data.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  late AppDatabase database;

  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  // 실제 기기 DB 대신 메모리 DB를 끼워 넣는다. (provider override)
  // closeStreamsSynchronously: 화면이 사라질 때 Stream을 바로 닫아, 테스트 종료 시 남는 타이머가 없게 한다.
  setUp(() {
    database = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
  });

  // 로딩 중에는 스피너가 계속 돌아서 pumpAndSettle이 끝나지 않는다.
  // 그래서 실제 시간으로 DB 작업이 끝나기를 잠깐 기다린 뒤, 화면을 몇 번 다시 그린다.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(overrides: [appDatabaseProvider.overrideWithValue(database)], child: const App()),
    );
    await settle(tester);
  }

  // 화면을 먼저 내려 Stream 구독을 끊은 뒤 DB를 닫는다.
  Future<void> closeApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(database.close);
  }

  testWidgets('하단 탭 4개로 화면을 전환할 수 있다', (tester) async {
    await pumpApp(tester);
    expect(find.text('아직 보낸 마음이 없어요'), findsOneWidget);

    await tester.tap(find.text('받아요').last);
    await settle(tester);
    expect(find.text('아직 받은 마음이 없어요'), findsOneWidget);

    await tester.tap(find.text('통계').last);
    await settle(tester);
    expect(find.text('아직 통계가 없어요'), findsOneWidget);

    await tester.tap(find.text('설정').last);
    await settle(tester);
    expect(find.text('앱 정보'), findsOneWidget);

    await closeApp(tester);
  });

  testWidgets('DB에 기록이 추가되면 보내요 목록과 합계가 자동으로 바뀐다', (tester) async {
    await pumpApp(tester);
    expect(find.text('아직 보낸 마음이 없어요'), findsOneWidget);

    await tester.runAsync(
      () => LedgerRepository(database.ledgerDao).add(
        direction: RecordDirection.sent,
        eventType: EventType.wedding,
        personName: '김철수',
        amount: 50000,
        date: DateTime(2026, 11, 24),
      ),
    );
    await settle(tester);

    expect(find.text('김철수'), findsOneWidget);
    expect(find.text('50,000원'), findsNWidgets(2)); // 합계 카드 + 목록
    expect(find.text('1건'), findsOneWidget);

    await closeApp(tester);
  });

  testWidgets('기록 버튼을 누르면 입력 화면이 위에 쌓이고, 뒤로 가면 돌아온다', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('보낸 마음 기록'));
    await settle(tester);
    expect(find.text('입력 화면 준비 중이에요'), findsOneWidget);

    await tester.pageBack();
    await settle(tester);
    expect(find.text('아직 보낸 마음이 없어요'), findsOneWidget);

    await closeApp(tester);
  });
}
