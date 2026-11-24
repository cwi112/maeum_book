import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maeum_book/app.dart';
import 'package:maeum_book/core/define/test_ids.dart';
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
    // 기본 테스트 화면(800x600)은 폼이 잘려서, 실제 휴대폰 크기(1080x2400)로 맞춘다.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
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

  testWidgets('필수 항목을 비우고 저장하면 칸 아래에 오류가 보이고 화면이 닫히지 않는다', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('보낸 마음 기록'));
    await settle(tester);

    await tester.tap(find.text('기록하기'));
    await settle(tester);

    expect(find.text('경조사 종류를 골라 주세요'), findsOneWidget);
    expect(find.text('이름을 입력해 주세요'), findsOneWidget);
    expect(find.text('금액을 입력해 주세요'), findsOneWidget);
    expect(find.text('마음 기록'), findsOneWidget); // 입력 화면 그대로

    await closeApp(tester);
  });

  testWidgets('입력 후 저장하면 화면이 닫히고, 토스트와 함께 목록에 바로 나타난다', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('보낸 마음 기록'));
    await settle(tester);

    await tester.tap(find.text('결혼'));
    await tester.enterText(find.widgetWithText(TextFormField, '이름'), '김철수');
    await tester.ensureVisible(find.text('+5만'));
    await tester.tap(find.text('+5만'));
    await settle(tester);
    await tester.tap(find.text('기록하기'));
    await settle(tester);

    expect(find.text('기록했어요'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1)); // 화면 닫힘 애니메이션이 끝나길 기다림
    expect(find.text('김철수'), findsOneWidget);
    expect(find.text('50,000원'), findsNWidgets(2)); // 합계 카드 + 목록

    await closeApp(tester);
  });

  /// 테스트용 기록을 DB에 바로 넣는다.
  Future<int> seed(WidgetTester tester, {String name = '김철수', int amount = 50000}) async {
    final id = await tester.runAsync(
      () => LedgerRepository(database.ledgerDao).add(
        direction: RecordDirection.sent,
        eventType: EventType.wedding,
        personName: name,
        amount: amount,
        date: DateTime(2026, 11, 24),
      ),
    );
    await settle(tester);
    return id!;
  }

  testWidgets('왼쪽으로 밀어 삭제하면 목록에서 사라지고, 되돌리기를 누르면 다시 나타난다', (tester) async {
    await pumpApp(tester);
    final id = await seed(tester);

    await tester.drag(find.bySemanticsIdentifier(TestIds.entryTile(id)), const Offset(-300, 0));
    await settle(tester);
    await tester.tap(find.bySemanticsIdentifier(TestIds.entryDelete(id)));
    await settle(tester);

    expect(find.text('김철수'), findsNothing);
    expect(find.text('김철수님 기록을 삭제했어요'), findsOneWidget);

    await tester.tap(find.text('되돌리기'));
    await settle(tester);
    expect(find.text('김철수'), findsOneWidget);

    await closeApp(tester);
  });

  testWidgets('기록을 눌러 수정하면 기존 값이 채워져 있고, 바꾼 값이 목록에 반영된다', (tester) async {
    await pumpApp(tester);
    final id = await seed(tester);

    await tester.tap(find.bySemanticsIdentifier(TestIds.entryTile(id)));
    await settle(tester);
    expect(find.text('기록 수정'), findsOneWidget);
    expect(find.text('50,000'), findsOneWidget); // 금액 칸에 기존 값

    await tester.ensureVisible(find.bySemanticsIdentifier(TestIds.formAmountAdd(10000)));
    await tester.tap(find.bySemanticsIdentifier(TestIds.formAmountAdd(10000)));
    await tester.tap(find.bySemanticsIdentifier(TestIds.formSave));
    await settle(tester);

    expect(find.text('수정했어요'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('60,000원'), findsNWidgets(2)); // 합계 카드 + 목록

    await closeApp(tester);
  });

  testWidgets('통계 탭에서 보낸·받은 그래프와 종류별 그래프를 보여준다', (tester) async {
    await pumpApp(tester);
    await seed(tester);

    await tester.tap(find.bySemanticsIdentifier(TestIds.tabStats));
    await settle(tester);

    expect(find.bySemanticsIdentifier(TestIds.statsBalanceChart), findsOneWidget);
    expect(find.bySemanticsIdentifier(TestIds.statsTypeChart), findsOneWidget);
    expect(find.text('-50,000원'), findsOneWidget); // 가운데 차액

    await tester.tap(find.bySemanticsIdentifier(TestIds.statsTypeDirection(RecordDirection.received)));
    await settle(tester);
    expect(find.text('아직 받음 기록이 없어요'), findsOneWidget);

    await closeApp(tester);
  });

  testWidgets('검색하면 목록과 합계가 바로 걸러지고, 다른 탭에 갔다 와도 검색어가 유지된다', (tester) async {
    await pumpApp(tester);
    await seed(tester, name: '김철수', amount: 50000);
    await seed(tester, name: '이영희', amount: 30000);

    await tester.enterText(find.byType(TextField).first, '영희');
    await settle(tester);
    expect(find.text('김철수'), findsNothing);
    expect(find.text('검색 결과'), findsOneWidget);
    expect(find.text('30,000원'), findsNWidgets(2)); // 합계 카드 + 목록

    await tester.tap(find.bySemanticsIdentifier(TestIds.tabStats));
    await settle(tester);
    await tester.tap(find.bySemanticsIdentifier(TestIds.tabSent));
    await settle(tester);
    expect(find.text('김철수'), findsNothing);
    expect(find.text('이영희'), findsOneWidget);

    await tester.tap(find.text('초기화'));
    await settle(tester);
    expect(find.text('김철수'), findsOneWidget);

    await closeApp(tester);
  });

  testWidgets('필터 시트에서 종류를 고르면 맞는 기록만 남고, 없으면 조건 초기화 버튼이 보인다', (tester) async {
    await pumpApp(tester);
    await seed(tester);

    await tester.tap(find.bySemanticsIdentifier(TestIds.ledgerFilter(RecordDirection.sent)));
    await settle(tester);
    await tester.tap(find.bySemanticsIdentifier('${TestIds.filterEventType}_${EventType.funeral.name}'));
    await tester.tap(find.bySemanticsIdentifier(TestIds.filterApply));
    await settle(tester);

    expect(find.text('조건에 맞는 기록이 없어요'), findsOneWidget);
    await tester.tap(find.text('조건 초기화'));
    await settle(tester);
    expect(find.text('김철수'), findsOneWidget);

    await closeApp(tester);
  });

  testWidgets('설정에서 샘플 데이터를 넣고, 확인 후 모두 지울 수 있다', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.bySemanticsIdentifier(TestIds.tabSettings));
    await settle(tester);

    await tester.tap(find.bySemanticsIdentifier(TestIds.settingsSeed));
    await settle(tester);
    expect(find.text('샘플 기록 ${SampleData.defaultCount}개를 넣었어요'), findsOneWidget);

    await tester.tap(find.bySemanticsIdentifier(TestIds.settingsClear));
    await settle(tester);
    await tester.tap(find.bySemanticsIdentifier(TestIds.dialogCancel));
    await settle(tester);
    expect(await tester.runAsync(() => LedgerRepository(database.ledgerDao).fetchAllForExport()), isNotEmpty);

    await tester.tap(find.bySemanticsIdentifier(TestIds.settingsClear));
    await settle(tester);
    await tester.tap(find.bySemanticsIdentifier(TestIds.dialogConfirm));
    await settle(tester);
    await settle(tester); // 확인 창이 닫히는 애니메이션 + DB 삭제가 끝나길 기다림
    expect(find.text('기록 ${SampleData.defaultCount}개를 지웠어요'), findsOneWidget);

    await closeApp(tester);
  });
}
