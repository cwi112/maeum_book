import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maeum_book/core/utils/xlsx_writer.dart';
import 'package:maeum_book/data/data.dart';
import 'package:xml/xml.dart';

/// 엑셀 내보내기: 파일이 올바른 xlsx인지, 시트 · 함수 · 계산값 · 서식이 기획안대로인지 확인한다.
///
/// 샘플 데이터로 만든 파일은 `build/excel_sample.xlsx`에 남긴다. → PC 엑셀에서 열어 눈으로 확인할 수 있다.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase database;
  late LedgerRepository repository;
  final now = DateTime(2026, 11, 26);

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = LedgerRepository(database.ledgerDao);
  });
  tearDown(() => database.close());

  Future<LedgerExcelExporter> exporterFromDb({bool isSample = false}) async {
    final types = await EventTypeRepository(database.eventTypeDao).watchAll().first;
    return LedgerExcelExporter(
      entries: await repository.fetchAllForExport(),
      events: await EventRepository(database.eventDao).fetchAll(),
      typeNames: {for (final type in types) type.id: type.name},
      exportedAt: now,
      isSample: isSample,
    );
  }

  /// zip을 풀어 파일 이름 → 내용
  Map<String, String> unzip(List<int> bytes) => {
    for (final file in ZipDecoder().decodeBytes(bytes))
      if (file.isFile) file.name: utf8.decode(file.content),
  };

  test('샘플 데이터로 만든 파일은 올바른 xlsx이고, 시트 4개와 파일 이름에 "샘플"이 들어간다', () async {
    await repository.addSamples(now: now);
    final exporter = await exporterFromDb(isSample: true);
    final bytes = exporter.encode();

    // PC에서 열어 볼 수 있게 남겨 둔다.
    File('build/excel_sample.xlsx')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes);

    expect(exporter.fileName, '마음장부_샘플_2026-11-26.xlsx');
    final files = unzip(bytes);
    expect(
      files.keys,
      containsAll([
        '[Content_Types].xml',
        '_rels/.rels',
        'xl/workbook.xml',
        'xl/styles.xml',
        'xl/sharedStrings.xml',
        'xl/worksheets/sheet1.xml',
        'xl/worksheets/sheet4.xml',
      ]),
    );
    // 모든 XML이 문법에 맞아야 엑셀이 연다.
    for (final entry in files.entries) {
      expect(() => XmlDocument.parse(entry.value), returnsNormally, reason: entry.key);
    }
    final workbook = XmlDocument.parse(files['xl/workbook.xml']!);
    expect(workbook.findAllElements('sheet').map((e) => e.getAttribute('name')), ['요약', '보낸 마음', '받은 마음', '사람별']);
    expect(files['xl/sharedStrings.xml'], contains('샘플 데이터예요'));
  });

  test('합계는 함수와 앱이 계산한 값이 함께 들어 있고, 그 값이 실제 합계와 같다', () async {
    await repository.addSamples(now: now);
    final entries = await repository.fetchAllForExport();
    final sentTotal = entries.where((e) => e.direction == RecordDirection.sent).fold(0, (s, e) => s + e.amount);
    final receivedTotal = entries.where((e) => e.direction == RecordDirection.received).fold(0, (s, e) => s + e.amount);

    final book = (await exporterFromDb()).build();
    final summary = book.sheets[0];

    // 요약 4행: 합계 (보낸 = SUM, 받은 = 받은 마음 시트의 총합계 칸)
    final sentSum = summary.valueAt(3, 1)! as XlsxFormula;
    final receivedSum = summary.valueAt(3, 2)! as XlsxFormula;
    expect(sentSum.formula, startsWith("SUM('보낸 마음'!\$E\$4:\$E\$"));
    expect(sentSum.cached, sentTotal);
    expect(receivedSum.formula, startsWith("'받은 마음'!F"));
    expect(receivedSum.cached, receivedTotal);

    // 차액 (받은 - 보낸)
    final balance = summary.valueAt(6, 1)! as XlsxFormula;
    expect(balance.formula, 'C4-B4');
    expect(balance.cached, receivedTotal - sentTotal);

    // 보낸 마음 시트의 맨 아래 합계 줄
    final sent = book.sheets[1];
    final sentCount = entries.where((e) => e.direction == RecordDirection.sent).length;
    final totalCell = sent.valueAt(3 + sentCount, 4)! as XlsxFormula;
    expect(totalCell.formula, 'SUM(E4:E${3 + sentCount})');
    expect(totalCell.cached, sentTotal);

    // 받은 마음: 소계 줄마다 SUM, 총합계는 소계 줄만 더한다
    final received = book.sheets[2];
    final subtotalRows = [
      for (var row = 3; row <= received.lastRow; row++)
        if ((received.valueAt(row, 0) as XlsxText?)?.text.startsWith('소계') ?? false) row,
    ];
    expect(subtotalRows, isNotEmpty);
    final subtotalSum = subtotalRows.fold<num>(0, (s, row) => s + (received.valueAt(row, 5)! as XlsxFormula).cached);
    expect(subtotalSum, receivedTotal);
    final grandTotal = received.valueAt(received.lastRow, 5)! as XlsxFormula;
    expect(grandTotal.formula, contains('SUMIF(A4:A'));
    expect(grandTotal.formula, contains('"소계*"'));
    expect(grandTotal.cached, receivedTotal);

    // 사람별: SUMIFS로 이름 + 관계를 찾는다. 합계 줄이 보낸 · 받은 합계와 같다.
    final people = book.sheets[3];
    expect((people.valueAt(3, 2)! as XlsxFormula).formula, startsWith("SUMIFS('보낸 마음'!"));
    final peopleTotalRow = people.lastRow;
    expect((people.valueAt(peopleTotalRow, 2)! as XlsxFormula).cached, sentTotal);
    expect((people.valueAt(peopleTotalRow, 3)! as XlsxFormula).cached, receivedTotal);
  });

  test('함수 칸은 XML에 함수(<f>)와 계산값(<v>)이 함께 저장된다 → 미리보기에서도 숫자가 보인다', () async {
    await repository.add(
      direction: RecordDirection.sent,
      eventTypeId: 1,
      personName: '김철수',
      amount: 50000,
      date: DateTime(2026, 11, 24),
    );
    final files = unzip((await exporterFromDb()).encode());
    final sentSheet = XmlDocument.parse(files['xl/worksheets/sheet2.xml']!);
    final total = sentSheet.findAllElements('c').firstWhere((c) => c.getAttribute('r') == 'E5');
    expect(total.getElement('f')!.innerText, 'SUM(E4:E4)');
    expect(total.getElement('v')!.innerText, '50000');

    // 날짜는 글자가 아니라 엑셀 날짜 숫자 (2026-11-24 = 46350)
    final date = sentSheet.findAllElements('c').firstWhere((c) => c.getAttribute('r') == 'A4');
    expect(date.getAttribute('t'), isNull);
    expect(date.getElement('v')!.innerText, '46350');

    // 머리글 고정 · 자동 필터
    expect(sentSheet.findAllElements('pane').single.getAttribute('state'), 'frozen');
    expect(sentSheet.findAllElements('autoFilter').single.getAttribute('ref'), 'A3:F4');

    // 금액 · 날짜 서식이 styles.xml에 있다
    expect(files['xl/styles.xml'], contains('formatCode="yyyy-mm-dd"'));
    expect(files['xl/styles.xml'], contains('numFmtId="3"')); // #,##0
  });

  test('기록이 하나도 없어도 깨지지 않는 파일이 만들어진다', () async {
    final exporter = await exporterFromDb();
    expect(exporter.fileName, '마음장부_2026-11-26.xlsx');
    final files = unzip(exporter.encode());
    for (final entry in files.entries) {
      expect(() => XmlDocument.parse(entry.value), returnsNormally, reason: entry.key);
    }
  });

  test('엑셀 열 이름과 주소를 만든다', () {
    expect(xlsxColumn(0), 'A');
    expect(xlsxColumn(25), 'Z');
    expect(xlsxColumn(26), 'AA');
    expect(xlsxCell(4, 3), 'E4');
    expect(xlsxRange('보낸 마음', 4, 3, 4, 42), "'보낸 마음'!\$E\$4:\$E\$43");
  });
}
