import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoDatePicker;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/core/utils/font_licenses.dart';

Widget _wrap(Widget child, {double width = 360}) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: Center(
      child: SizedBox(width: width, child: child),
    ),
  ),
);

void main() {
  group('ChoiceChipGroup: 3줄을 넘으면 가로 스크롤', () {
    Widget chips(int count, {String? selectedLabel}) => ChoiceChipGroup<int>(
      values: [for (var i = 0; i < count; i++) i],
      selected: null,
      labelOf: (i) => '행사 이름 $i · 2026.11.$i',
      onSelected: (_) {},
      testIdPrefix: 'chip',
    );

    Finder horizontalScroll() =>
        find.byWidgetPredicate((w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal);

    testWidgets('칩이 적으면 그냥 줄바꿈', (tester) async {
      await tester.pumpWidget(_wrap(chips(3)));
      expect(horizontalScroll(), findsNothing);
      expect(find.byType(Wrap), findsOneWidget);
    });

    testWidgets('칩이 많으면 3줄로 나눠 가로로 넘긴다 (순서 · 테스트 이름 유지)', (tester) async {
      await tester.pumpWidget(_wrap(chips(20)));
      expect(horizontalScroll(), findsOneWidget);
      // 3줄 = Row 3개, 칩 20개가 모두 들어 있다.
      final rows = find.descendant(of: horizontalScroll(), matching: find.byType(Row));
      expect(rows, findsNWidgets(3));
      expect(find.byType(ChoiceChip, skipOffstage: false), findsNWidgets(20));
      // 첫 칩은 첫 줄 맨 앞
      final firstRowChips = find.descendant(of: rows.first, matching: find.byType(ChoiceChip));
      expect(find.descendant(of: firstRowChips.first, matching: find.text('행사 이름 0 · 2026.11.0')), findsOneWidget);
      expect(find.bySemanticsIdentifier('chip_19', skipOffstage: false), findsOneWidget);
    });
  });

  group('AppTextField: 전체 지우기', () {
    testWidgets('글자가 있을 때만 ⓧ가 보이고, 누르면 비우고 빈 값을 알린다', (tester) async {
      String? changed;
      await tester.pumpWidget(_wrap(AppTextField(initialValue: '김민준', onChanged: (v) => changed = v)));
      expect(find.byTooltip(ClearTextButton.tooltip), findsOneWidget);

      await tester.tap(find.byTooltip(ClearTextButton.tooltip));
      await tester.pump();
      expect(changed, '');
      expect(find.text('김민준'), findsNothing);
      expect(find.byTooltip(ClearTextButton.tooltip), findsNothing); // 비면 숨김

      await tester.enterText(find.byType(TextFormField), '이서연');
      await tester.pump();
      expect(find.byTooltip(ClearTextButton.tooltip), findsOneWidget);
    });

    testWidgets('여러 줄 메모: ⓧ는 줄이 늘어도 첫 줄 높이(오른쪽 위)에 있다', (tester) async {
      await tester.pumpWidget(_wrap(AppTextField(initialValue: '첫 줄\n둘째 줄\n셋째 줄', maxLines: 3, onChanged: (_) {})));
      final field = tester.getRect(find.byType(TextFormField));
      final button = tester.getRect(find.byTooltip(ClearTextButton.tooltip));
      expect(button.top - field.top, lessThan(8)); // 위쪽에 붙어 있다 (가운데로 내려가지 않음)
      expect(field.right - button.right, lessThan(8)); // 오른쪽 끝 (터치 영역 여백 정도만)
      expect(field.height, greaterThan(button.height * 1.5)); // 입력칸은 여러 줄로 커져 있다
    });
  });

  testWidgets('AmountField: +50만 · +100만 버튼과 ⓧ 전체 지우기', (tester) async {
    var amount = 0;
    await tester.pumpWidget(
      _wrap(
        StatefulBuilder(
          builder: (context, setState) => AmountField(value: amount, onChanged: (v) => setState(() => amount = v)),
        ),
      ),
    );
    await tester.tap(find.text('+50만'));
    await tester.pump();
    await tester.tap(find.text('+100만'));
    await tester.pump();
    expect(amount, 1500000);
    expect(find.text('1,500,000'), findsOneWidget);

    await tester.tap(find.byTooltip(ClearTextButton.tooltip));
    await tester.pump();
    expect(amount, 0);
  });

  group('DateField: 휴대폰마다 익숙한 날짜 고르기', () {
    Widget field(DateTime value, void Function(DateTime) onChanged) => MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('ko'),
      supportedLocales: const [Locale('ko')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(
        body: DateField(value: value, onChanged: onChanged),
      ),
    );

    testWidgets('아이폰: 돌림판이 올라오고, 완료를 눌러야 반영된다', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      DateTime? picked;
      await tester.pumpWidget(field(DateTime(2026, 11, 24), (d) => picked = d));
      await tester.tap(find.byType(DateField));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoDatePicker), findsOneWidget);
      expect(find.byType(DatePickerDialog), findsNothing);

      // 취소하면 그대로
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(picked, isNull);

      // 돌림판을 돌린 뒤 완료 → 바뀐 날짜
      await tester.tap(find.byType(DateField));
      await tester.pumpAndSettle();
      final picker = tester.widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker));
      picker.onDateTimeChanged(DateTime(2025, 3, 1));
      await tester.pump();
      expect(find.text('2025년 3월 1일 (토)'), findsOneWidget); // 위에 고른 날짜 미리 보기
      await tester.tap(find.bySemanticsIdentifier(TestIds.datePickerDone));
      await tester.pumpAndSettle();
      expect(picked, DateTime(2025, 3, 1));
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('안드로이드: 기본 달력 창', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await tester.pumpWidget(field(DateTime(2026, 11, 24), (_) {}));
      await tester.tap(find.byType(DateField));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(find.byType(CupertinoDatePicker), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    });
  });

  test('오픈소스 라이선스: 글꼴 두 개의 라이선스 전문이 등록된다', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    FontLicenses.register();
    final entries = await LicenseRegistry.licenses.toList();
    for (final (name, _) in FontLicenses.fonts) {
      final entry = entries.firstWhere((e) => e.packages.contains(name));
      expect(entry.paragraphs.map((p) => p.text).join(' '), contains('SIL OPEN FONT LICENSE'));
    }
  });
}
