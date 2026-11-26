import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maeum_book/app.dart';
import 'package:maeum_book/core/define/test_ids.dart';
import 'package:maeum_book/data/data.dart';
import 'package:material_ui/material_ui.dart';

import 'fakes/fake_auth_repository.dart';

void main() {
  late AppDatabase database;
  late FakeAuthRepository auth;

  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  // 실제 기기 DB 대신 메모리 DB를 끼워 넣는다. (provider override)
  // closeStreamsSynchronously: 화면이 사라질 때 Stream을 바로 닫아, 테스트 종료 시 남는 타이머가 없게 한다.
  setUp(() {
    database = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    auth = FakeAuthRepository(); // 실제 카카오 · Supabase에 접속하지 않게
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
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database), authRepositoryProvider.overrideWithValue(auth)],
        child: const App(),
      ),
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
    expect(find.text('아직 만든 행사가 없어요'), findsOneWidget);

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
        eventTypeId: 1,
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
        eventTypeId: 1,
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

  testWidgets('통계 탭: 보낸·받은 비율, 월별, 종류별, 관계별, 사람별 TOP 5를 보여준다', (tester) async {
    await pumpApp(tester);
    await seed(tester);

    await tester.tap(find.bySemanticsIdentifier(TestIds.tabStats));
    await settle(tester);

    expect(find.bySemanticsIdentifier(TestIds.statsBalanceChart), findsOneWidget);
    expect(find.text('-50,000원'), findsOneWidget); // 가운데 차액
    expect(find.bySemanticsIdentifier(TestIds.statsMonthlyChart), findsOneWidget);

    // 아래쪽 그래프는 스크롤해야 그려진다 (ListView는 보이는 부분만 그림)
    final scrollable = find.byType(Scrollable).last;
    for (final id in [TestIds.statsTypeChart, TestIds.statsRelationChart, TestIds.statsTopPeople]) {
      await tester.scrollUntilVisible(find.bySemanticsIdentifier(id), 300, scrollable: scrollable);
      expect(find.bySemanticsIdentifier(id), findsOneWidget);
    }
    expect(find.text('김철수'), findsOneWidget); // TOP 5에 보임

    // 받은 기준으로 바꾸면 받은 기록이 없으므로 종류별·관계별 모두 안내 문구
    await tester.scrollUntilVisible(
      find.bySemanticsIdentifier(TestIds.statsTypeDirection(RecordDirection.received)),
      -300,
      scrollable: scrollable,
    );
    await tester.tap(find.bySemanticsIdentifier(TestIds.statsTypeDirection(RecordDirection.received)));
    await settle(tester);
    expect(find.text('아직 받음 기록이 없어요'), findsWidgets);

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
    await tester.tap(find.bySemanticsIdentifier('${TestIds.filterEventType}_2'));
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
    expect(find.text('샘플 기록 ${SampleData.totalCount}개를 넣었어요'), findsOneWidget);

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
    expect(find.text('기록 ${SampleData.totalCount}개를 지웠어요'), findsOneWidget);

    await closeApp(tester);
  });

  testWidgets('받아요: 행사를 만들고, 행사 안에서 받은 마음을 기록하면 바로 보인다', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.bySemanticsIdentifier(TestIds.tabReceived));
    await settle(tester);

    // 행사 만들기
    await tester.tap(find.bySemanticsIdentifier(TestIds.eventAdd));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextFormField, '예) 우리 결혼식, 아버지 칠순'), '우리 결혼식');
    await tester.tap(find.bySemanticsIdentifier('${TestIds.eventFormType}_1'));
    await tester.tap(find.bySemanticsIdentifier(TestIds.eventFormSave));
    await settle(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('우리 결혼식'), findsOneWidget);

    // 행사 상세 → 받은 마음 기록 (행사가 미리 골라져 있음)
    await tester.tap(find.text('우리 결혼식'));
    await settle(tester);
    expect(find.text('아직 기록된 마음이 없어요'), findsOneWidget);
    await tester.tap(find.bySemanticsIdentifier(TestIds.eventAddEntry));
    await settle(tester);
    expect(find.text('경조사 종류'), findsNothing); // 받은 기록은 행사의 종류·날짜를 따름
    await tester.enterText(find.widgetWithText(TextFormField, '이름'), '김철수');
    await tester.tap(find.bySemanticsIdentifier(TestIds.formAmountAdd(100000)));
    await tester.tap(find.bySemanticsIdentifier(TestIds.formSave));
    await settle(tester);
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('김철수'), findsOneWidget); // 행사 상세에 바로 나타남
    expect(find.text('100,000원'), findsNWidgets(2)); // 상단 합계 + 목록

    await closeApp(tester);
  });

  testWidgets('경조사 종류 관리: 추가한 종류가 입력 화면 칩에 바로 나타난다', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.bySemanticsIdentifier(TestIds.tabSettings));
    await settle(tester);
    await tester.tap(find.bySemanticsIdentifier(TestIds.settingsEventTypes));
    await settle(tester);

    await tester.tap(find.bySemanticsIdentifier(TestIds.eventTypeAdd));
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, '환갑');
    await tester.pump();
    await tester.tap(find.bySemanticsIdentifier(TestIds.dialogConfirm));
    await settle(tester);
    await settle(tester);
    expect(find.text('환갑'), findsOneWidget);

    // 보내요 → 기록 입력 화면의 종류 칩에도 보인다
    await tester.tap(find.byTooltip('뒤로')); // material_ui 뒤로 버튼은 pageBack()이 찾지 못해 툴팁으로 누른다
    await settle(tester);
    await tester.tap(find.bySemanticsIdentifier(TestIds.tabSent));
    await settle(tester);
    await tester.tap(find.text('보낸 마음 기록'));
    await settle(tester);
    expect(find.text('환갑'), findsOneWidget);

    await closeApp(tester);
  });

  testWidgets('목록을 내리면 위쪽에 그림자가 생기고 기록 버튼이 동그라미로 접히며, 끝에 닿으면 숨고, 맨 위로 오면 다시 펼쳐진다', (tester) async {
    await pumpApp(tester);
    for (var i = 0; i < 25; i++) {
      await seed(tester, name: '사람$i', amount: 10000 + i);
    }
    final list = find.byType(ListView);
    bool hasShadow() => tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .any((c) => ((c.decoration as BoxDecoration?)?.boxShadow ?? const []).isNotEmpty);

    expect(find.text('보낸 마음 기록'), findsOneWidget); // 처음: 글자 버튼
    expect(hasShadow(), isFalse);

    await tester.drag(list, const Offset(0, -300)); // 아래로 내림
    await tester.pumpAndSettle();
    expect(find.text('보낸 마음 기록'), findsNothing); // 동그라미로 접힘
    expect(find.bySemanticsIdentifier(TestIds.ledgerAdd(RecordDirection.sent)), findsOneWidget);
    expect(hasShadow(), isTrue);

    await tester.fling(list, const Offset(0, -5000), 3000); // 끝까지
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity).last).opacity, 0); // 숨김

    await tester.fling(list, const Offset(0, 5000), 3000); // 맨 위로
    await tester.pumpAndSettle();
    expect(find.text('보낸 마음 기록'), findsOneWidget); // 다시 펼쳐짐
    expect(hasShadow(), isFalse);

    await closeApp(tester);
  });

  testWidgets('목록을 끝까지 내린 상태에서 기록이 모두 지워지면 그림자가 사라지고 기록 버튼이 다시 보인다', (tester) async {
    await pumpApp(tester);
    for (var i = 0; i < 25; i++) {
      await seed(tester, name: '사람$i', amount: 10000 + i);
    }
    bool hasShadow() => tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .any((c) => ((c.decoration as BoxDecoration?)?.boxShadow ?? const []).isNotEmpty);

    await tester.fling(find.byType(ListView), const Offset(0, -5000), 3000); // 끝까지 → 버튼 숨김
    await tester.pumpAndSettle();
    expect(hasShadow(), isTrue);

    await tester.runAsync(() => database.delete(database.ledgerEntries).go()); // 설정의 "모두 지우기"와 같은 상황
    await settle(tester);
    await tester.pumpAndSettle();

    expect(find.text('아직 보낸 마음이 없어요'), findsOneWidget);
    expect(hasShadow(), isFalse);
    expect(find.text('보낸 마음 기록'), findsOneWidget);
    expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity).last).opacity, 1);

    await closeApp(tester);
  });

  testWidgets('설정에서 카카오로 로그인하면 이름이 보이고, 로그아웃 · 탈퇴하면 다시 로그인 버튼이 보인다', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.bySemanticsIdentifier(TestIds.tabSettings));
    await settle(tester);
    expect(find.text('로그인'), findsOneWidget);

    // 로그인 화면: Android 테스트 환경이라 Apple 버튼은 없다.
    await tester.tap(find.bySemanticsIdentifier(TestIds.settingsAccount));
    await tester.pumpAndSettle();
    expect(find.text('카카오 로그인'), findsOneWidget);
    expect(find.text('Apple로 로그인'), findsNothing);

    // 취소하면 아무 안내 없이 화면에 그대로 남는다.
    auth.failNext = AuthFailureType.canceled;
    await tester.tap(find.text('카카오 로그인'));
    await tester.pumpAndSettle();
    expect(find.text('카카오 로그인'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    // 인터넷이 없으면 이유를 알려 주고 화면에 남는다.
    auth.failNext = AuthFailureType.network;
    await tester.tap(find.text('카카오 로그인'));
    await tester.pumpAndSettle();
    expect(find.text(AuthFailureType.network.message), findsOneWidget);
    expect(find.text('카카오 로그인'), findsOneWidget);
    ScaffoldMessenger.of(tester.element(find.text('카카오 로그인'))).removeCurrentSnackBar();
    await tester.pumpAndSettle();

    // 로그인 성공 → 설정으로 돌아와 이름이 보인다.
    await tester.tap(find.text('카카오 로그인'));
    await settle(tester);
    await tester.pumpAndSettle();
    expect(find.text('홍길동'), findsOneWidget);
    expect(find.text('카카오 계정으로 로그인됨'), findsOneWidget);

    // 로그아웃 (확인 창)
    await tester.tap(find.bySemanticsIdentifier(TestIds.settingsSignOut));
    await tester.pumpAndSettle();
    await tester.tap(find.text('로그아웃').last);
    await settle(tester);
    await tester.pumpAndSettle();
    expect(find.text('홍길동'), findsNothing);

    // 다시 로그인 후 탈퇴
    await tester.tap(find.bySemanticsIdentifier(TestIds.settingsAccount));
    await tester.pumpAndSettle();
    await tester.tap(find.text('카카오 로그인'));
    await settle(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsIdentifier(TestIds.settingsDeleteAccount));
    await tester.pumpAndSettle();
    await tester.tap(find.text('탈퇴하기'));
    await settle(tester);
    await tester.pumpAndSettle();
    expect(auth.deleteCount, 1);
    expect(find.text('로그인'), findsOneWidget);

    await closeApp(tester);
  });

  testWidgets('로그인이 만료되면 어느 화면에서든 안내가 뜨고, [다시 로그인]을 누르면 로그인 화면으로 간다', (tester) async {
    await pumpApp(tester);
    await tester.runAsync(auth.signInWithKakao);
    await settle(tester);

    // 보내요 탭에 있을 때 서버가 로그인을 만료시킴
    auth.expireSession();
    await settle(tester);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(AuthFailureType.sessionExpired.message), findsOneWidget);

    await tester.tap(find.text('다시 로그인'));
    await tester.pumpAndSettle();
    expect(find.text('카카오 로그인'), findsOneWidget);

    await closeApp(tester);
  });

  testWidgets('탈퇴할 때 로그인이 만료돼 있으면 다시 로그인을 안내하고 계정은 그대로다', (tester) async {
    await pumpApp(tester);
    await tester.runAsync(auth.signInWithKakao);
    await tester.tap(find.bySemanticsIdentifier(TestIds.tabSettings));
    await settle(tester);

    auth.failNext = AuthFailureType.sessionExpired;
    await tester.tap(find.bySemanticsIdentifier(TestIds.settingsDeleteAccount));
    await tester.pumpAndSettle();
    await tester.tap(find.text('탈퇴하기'));
    await settle(tester);
    await tester.pumpAndSettle();

    expect(auth.deleteCount, 0);
    expect(find.text(AuthFailureType.sessionExpired.message), findsOneWidget);
    expect(find.text('다시 로그인'), findsOneWidget);

    await closeApp(tester);
  });
}
