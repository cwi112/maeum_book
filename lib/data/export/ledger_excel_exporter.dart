import 'dart:typed_data';

import 'package:maeum_book/core/utils/xlsx_writer.dart';
import 'package:maeum_book/data/database/app_database.dart';
import 'package:maeum_book/data/models/models.dart';

/// 장부 기록 → 엑셀 파일. (기획안: docs/EXCEL_EXPORT_PLAN.md)
///
/// | 시트 | 내용 |
/// |---|---|
/// | 요약 | 보낸 · 받은 합계 · 건수 · 평균 · 차액, 종류별 · 연도별 합계 (모두 다른 시트를 가리키는 함수) |
/// | 보낸 마음 | 날짜 · 종류 · 이름 · 관계 · 금액 · 메모 (최신순) + 합계 |
/// | 받은 마음 | 행사별로 묶고 행사마다 소계 + 총합계 |
/// | 사람별 | 이름 + 관계로 묶은 보낸 · 받은 합계 · 차액 · 마지막 날짜 |
///
/// 합계 · 소계는 모두 **엑셀 함수 + 앱이 미리 계산한 값**으로 넣는다. ([XlsxFormula])
/// 엑셀에서 기록을 고치면 다시 계산되고, 계산을 안 하는 미리보기에서도 숫자가 보인다.
///
/// 화면 · 저장과 상관없는 순수한 변환이라 테스트하기 쉽다. (기록을 넣으면 바이트가 나온다)
class LedgerExcelExporter {
  LedgerExcelExporter({
    required this.entries,
    required this.events,
    required this.typeNames,
    required this.exportedAt,
    this.isSample = false,
  });

  final List<LedgerEntry> entries;
  final List<LedgerEvent> events;

  /// 경조사 종류 id → 이름
  final Map<int, String> typeNames;
  final DateTime exportedAt;

  /// 샘플 둘러보기 중이면 true → 파일 이름 · 요약 시트에 "샘플" 표시
  final bool isSample;

  static const summarySheet = '요약';
  static const sentSheet = '보낸 마음';
  static const receivedSheet = '받은 마음';
  static const peopleSheet = '사람별';

  /// 관계를 고르지 않은 기록의 관계 칸. (빈칸이면 엑셀 SUMIFS가 사람별 합계를 못 찾아서 글자로 넣는다)
  static const noRelation = '-';

  /// 데이터가 시작하는 행 (0부터: 1행 제목, 2행 안내, 3행 머리글 → 4행부터 데이터)
  static const _firstDataRow = 3;

  /// 파일 이름. 예) 마음장부_2026-11-26.xlsx / 마음장부_샘플_2026-11-26.xlsx
  String get fileName => '마음장부_${isSample ? '샘플_' : ''}${_date(exportedAt)}.xlsx';

  List<LedgerEntry> get _sent => _sorted(RecordDirection.sent);
  List<LedgerEntry> get _received => entries.where((e) => e.direction == RecordDirection.received).toList();

  int get sentCount => entries.where((e) => e.direction == RecordDirection.sent).length;
  int get receivedCount => entries.length - sentCount;

  List<LedgerEntry> _sorted(RecordDirection direction) =>
      entries.where((e) => e.direction == direction).toList()..sort((a, b) {
        final byDate = b.date.compareTo(a.date); // 최신순
        return byDate != 0 ? byDate : b.id.compareTo(a.id);
      });

  Uint8List encode() => build().encode();

  /// 시트를 채운 엑셀 문서. (테스트에서 칸 값을 바로 확인할 수 있게 따로 둔다)
  XlsxWorkbook build() {
    final book = XlsxWorkbook();
    final summary = book.addSheet(summarySheet); // 첫 시트가 열리므로 요약을 맨 앞에
    final sent = _writeSent(book.addSheet(sentSheet));
    final received = _writeReceived(book.addSheet(receivedSheet));
    _writePeople(book.addSheet(peopleSheet), sent, received);
    _writeSummary(summary, sent, received);
    return book;
  }

  // ── 보낸 마음 ─────────────────────────────

  _SentRanges _writeSent(XlsxSheet sheet) {
    final rows = _sent;
    const headers = ['날짜', '종류', '이름', '관계', '금액', '메모'];
    _title(sheet, sentSheet, headers.length, '${rows.length}건 · 최신순');
    _headers(sheet, headers);
    sheet.setColumnWidths(const [13, 9, 13, 8, 14, 32]);

    for (final (i, entry) in rows.indexed) {
      final row = _firstDataRow + i;
      final zebra = i.isOdd;
      sheet
        ..set(row, 0, XlsxDate(entry.date), _Styles.date(zebra))
        ..set(row, 1, XlsxText(typeNames[entry.eventTypeId] ?? ''), _Styles.center(zebra))
        ..set(row, 2, XlsxText(entry.personName), _Styles.text(zebra))
        ..set(row, 3, XlsxText(entry.relation?.label ?? noRelation), _Styles.center(zebra))
        ..set(row, 4, XlsxNumber(entry.amount), _Styles.money(zebra))
        ..set(row, 5, XlsxText(entry.memo ?? ''), _Styles.memo(zebra));
    }

    final last = _firstDataRow + rows.length - 1;
    final totalRow = _firstDataRow + rows.length;
    final total = rows.fold<int>(0, (sum, e) => sum + e.amount);
    if (rows.isEmpty) {
      sheet.set(_firstDataRow, 0, const XlsxText('아직 보낸 기록이 없어요'), _Styles.text(false));
    } else {
      sheet
        ..freezeRows(_firstDataRow) // 내려도 머리글이 보이게
        ..autoFilter(_firstDataRow - 1, 0, last, headers.length - 1); // 머리글에 ▼ 필터
    }
    final totalAt = rows.isEmpty ? totalRow + 1 : totalRow;
    _totalLabel(sheet, totalAt, headers.length, '합계');
    sheet.set(
      totalAt,
      4,
      rows.isEmpty ? const XlsxNumber(0) : XlsxFormula('SUM(E${_firstDataRow + 1}:E${last + 1})', cached: total),
      _Styles.totalMoney,
    );
    sheet.outline(_firstDataRow - 1, 0, totalAt, headers.length - 1, _Styles.frame); // 표 바깥 테두리
    return _SentRanges(rowCount: rows.length, last: last, totalRow: totalAt, total: total);
  }

  // ── 받은 마음 ─────────────────────────────

  _ReceivedRanges _writeReceived(XlsxSheet sheet) {
    const headers = ['행사', '행사 날짜', '종류', '이름', '관계', '금액', '메모'];
    final received = _received;
    _title(sheet, receivedSheet, headers.length, '${received.length}건 · 행사별 소계');
    _headers(sheet, headers);
    sheet.setColumnWidths(const [20, 13, 9, 13, 8, 14, 28]);

    // 행사 최신순. 행사가 없는 받은 기록(예전 버전 기록)은 맨 뒤 "행사 없음"으로 묶는다.
    final byEvent = <int?, List<LedgerEntry>>{};
    for (final entry in received) {
      (byEvent[entry.eventId] ??= []).add(entry);
    }
    final eventById = {for (final event in events) event.id: event};
    final groups = byEvent.keys.toList()
      ..sort((a, b) {
        if (a == null) return 1;
        if (b == null) return -1;
        final byDate = (eventById[b]?.date ?? DateTime(0)).compareTo(eventById[a]?.date ?? DateTime(0));
        return byDate != 0 ? byDate : b.compareTo(a);
      });

    var row = _firstDataRow;
    var zebra = false;
    var total = 0;
    for (final eventId in groups) {
      final event = eventById[eventId];
      final list = byEvent[eventId]!..sort((a, b) => a.id.compareTo(b.id)); // 기록한 순서
      final title = event?.title ?? '행사 없음';
      final from = row;
      for (final entry in list) {
        sheet
          ..set(row, 0, XlsxText(title), _Styles.text(zebra))
          ..set(row, 1, XlsxDate(event?.date ?? entry.date), _Styles.date(zebra))
          ..set(row, 2, XlsxText(typeNames[event?.eventTypeId ?? entry.eventTypeId] ?? ''), _Styles.center(zebra))
          ..set(row, 3, XlsxText(entry.personName), _Styles.text(zebra))
          ..set(row, 4, XlsxText(entry.relation?.label ?? noRelation), _Styles.center(zebra))
          ..set(row, 5, XlsxNumber(entry.amount), _Styles.money(zebra))
          ..set(row, 6, XlsxText(entry.memo ?? ''), _Styles.memo(zebra));
        row++;
        zebra = !zebra;
      }
      // 소계 줄: "소계 · 행사 이름" + 사람 수 + 합계
      final subtotal = list.fold<int>(0, (sum, e) => sum + e.amount);
      total += subtotal;
      final range = '${from + 1}:F$row'; // 예) F4:F15
      _totalLabel(sheet, row, headers.length, '소계 · $title', subtotal: true);
      sheet
        ..set(row, 4, XlsxFormula('COUNT(F$range)', cached: list.length), _Styles.subtotalCount)
        ..set(row, 5, XlsxFormula('SUM(F$range)', cached: subtotal), _Styles.subtotalMoney);
      row++;
      zebra = false;
    }

    final last = row - 1; // 마지막 소계 줄
    if (received.isEmpty) {
      sheet.set(_firstDataRow, 0, const XlsxText('아직 받은 기록이 없어요'), _Styles.text(false));
      row++;
    } else {
      sheet.freezeRows(_firstDataRow);
    }
    // 총합계 = 소계 줄들의 합 (A열이 "소계"로 시작하는 줄만 더한다)
    final aRange = 'A${_firstDataRow + 1}:A${last + 1}';
    _totalLabel(sheet, row, headers.length, '총합계');
    sheet
      ..set(
        row,
        4,
        received.isEmpty
            ? const XlsxNumber(0)
            : XlsxFormula('SUMIF($aRange,"소계*",E${_firstDataRow + 1}:E${last + 1})', cached: received.length),
        _Styles.totalCount,
      )
      ..set(
        row,
        5,
        received.isEmpty
            ? const XlsxNumber(0)
            : XlsxFormula('SUMIF($aRange,"소계*",F${_firstDataRow + 1}:F${last + 1})', cached: total),
        _Styles.totalMoney,
      );
    sheet.outline(_firstDataRow - 1, 0, row, headers.length - 1, _Styles.frame);
    return _ReceivedRanges(rowCount: received.length, last: last, totalRow: row, total: total);
  }

  // ── 사람별 ───────────────────────────────

  void _writePeople(XlsxSheet sheet, _SentRanges sent, _ReceivedRanges received) {
    const headers = ['이름', '관계', '보낸 합계', '받은 합계', '받은 - 보낸', '마지막 날짜'];
    final people = <(String, String), _Person>{};
    for (final entry in entries) {
      final key = (entry.personName, entry.relation?.label ?? noRelation);
      final person = people[key] ??= _Person();
      if (entry.direction == RecordDirection.sent) {
        person.sent += entry.amount;
      } else {
        person.received += entry.amount;
      }
      if (person.lastDate == null || entry.date.isAfter(person.lastDate!)) person.lastDate = entry.date;
    }
    final list = people.entries.toList()..sort((a, b) => b.value.volume.compareTo(a.value.volume)); // 많이 주고받은 순

    _title(sheet, peopleSheet, headers.length, '${list.length}명 · 이름과 관계가 같으면 한 사람으로 묶어요');
    _headers(sheet, headers);
    sheet.setColumnWidths(const [13, 8, 14, 14, 14, 13]);

    // 보낸 · 받은 시트에서 이 사람(이름 + 관계)의 금액만 더하는 함수
    String sentFormula(int row) =>
        'SUMIFS(${xlsxRange(sentSheet, 4, _firstDataRow, 4, sent.last)},'
        '${xlsxRange(sentSheet, 2, _firstDataRow, 2, sent.last)},A${row + 1},'
        '${xlsxRange(sentSheet, 3, _firstDataRow, 3, sent.last)},B${row + 1})';
    String receivedFormula(int row) =>
        'SUMIFS(${xlsxRange(receivedSheet, 5, _firstDataRow, 5, received.last)},'
        '${xlsxRange(receivedSheet, 3, _firstDataRow, 3, received.last)},A${row + 1},'
        '${xlsxRange(receivedSheet, 4, _firstDataRow, 4, received.last)},B${row + 1})';

    for (final (i, item) in list.indexed) {
      final row = _firstDataRow + i;
      final zebra = i.isOdd;
      final person = item.value;
      sheet
        ..set(row, 0, XlsxText(item.key.$1), _Styles.text(zebra))
        ..set(row, 1, XlsxText(item.key.$2), _Styles.center(zebra))
        ..set(
          row,
          2,
          sent.rowCount == 0 ? const XlsxNumber(0) : XlsxFormula(sentFormula(row), cached: person.sent),
          _Styles.money(zebra),
        )
        ..set(
          row,
          3,
          received.rowCount == 0 ? const XlsxNumber(0) : XlsxFormula(receivedFormula(row), cached: person.received),
          _Styles.money(zebra),
        )
        ..set(
          row,
          4,
          XlsxFormula('D${row + 1}-C${row + 1}', cached: person.balance),
          _Styles.balance(person.balance, zebra),
        )
        ..set(row, 5, XlsxDate(person.lastDate!), _Styles.date(zebra));
    }

    final last = _firstDataRow + list.length - 1;
    var totalRow = _firstDataRow + list.length;
    if (list.isEmpty) {
      sheet.set(_firstDataRow, 0, const XlsxText('아직 기록이 없어요'), _Styles.text(false));
      totalRow++;
    } else {
      sheet
        ..freezeRows(_firstDataRow)
        ..autoFilter(_firstDataRow - 1, 0, last, headers.length - 1);
    }
    final sentTotal = list.fold<int>(0, (sum, e) => sum + e.value.sent);
    final receivedTotal = list.fold<int>(0, (sum, e) => sum + e.value.received);
    _totalLabel(sheet, totalRow, headers.length, '합계');
    for (final (col, cached) in [(2, sentTotal), (3, receivedTotal), (4, receivedTotal - sentTotal)]) {
      final column = xlsxColumn(col);
      sheet.set(
        totalRow,
        col,
        list.isEmpty
            ? const XlsxNumber(0)
            : XlsxFormula('SUM($column${_firstDataRow + 1}:$column${last + 1})', cached: cached),
        col == 4 ? _Styles.totalBalance(cached) : _Styles.totalMoney,
      );
    }
    sheet.outline(_firstDataRow - 1, 0, totalRow, headers.length - 1, _Styles.frame);
  }

  // ── 요약 ─────────────────────────────────

  void _writeSummary(XlsxSheet sheet, _SentRanges sent, _ReceivedRanges received) {
    const width = 3;
    sheet.setColumnWidths(const [20, 16, 16]);
    // 맨 위에는 내보낸 날짜만 (시트 이름이 "요약"이라 제목은 따로 달지 않는다). 샘플이면 빨간 경고.
    sheet
      ..set(
        0,
        0,
        XlsxText('${isSample ? '샘플 데이터예요 (실제 장부 아님) · ' : ''}내보낸 날짜 ${_date(exportedAt)}'),
        isSample ? _Styles.sampleWarning : _Styles.note,
      )
      ..merge(0, 0, 0, width - 1);

    final sentSum = xlsxRange(sentSheet, 4, _firstDataRow, 4, sent.last);
    final receivedTotalCell = "'$receivedSheet'!F${received.totalRow + 1}";
    final receivedCountCell = "'$receivedSheet'!E${received.totalRow + 1}";

    // 3행 머리글: 항목 | 보낸 마음 | 받은 마음
    var row = 2;
    _headers(sheet, const ['항목', '보낸 마음', '받은 마음'], row: row);
    row++;
    final totalRow = row;
    _summaryRow(
      sheet,
      row++,
      '합계',
      sent.rowCount == 0 ? const XlsxNumber(0) : XlsxFormula('SUM($sentSum)', cached: sent.total),
      XlsxFormula(receivedTotalCell, cached: received.total),
      _Styles.money(false),
    );
    final countRow = row;
    _summaryRow(
      sheet,
      row++,
      '건수',
      sent.rowCount == 0 ? const XlsxNumber(0) : XlsxFormula('COUNT($sentSum)', cached: sent.rowCount),
      XlsxFormula(receivedCountCell, cached: received.rowCount),
      _Styles.count(false),
    );
    _summaryRow(
      sheet,
      row++,
      '평균 (1건)',
      XlsxFormula('IFERROR(ROUND(B${totalRow + 1}/B${countRow + 1},0),0)', cached: _average(sent.total, sent.rowCount)),
      XlsxFormula(
        'IFERROR(ROUND(C${totalRow + 1}/C${countRow + 1},0),0)',
        cached: _average(received.total, received.rowCount),
      ),
      _Styles.money(true),
    );

    // 차액 줄: 받은 - 보낸 (두 칸 합쳐서 크게)
    final balance = received.total - sent.total;
    sheet
      ..set(row, 0, const XlsxText('받은 - 보낸'), _Styles.totalLabel)
      ..set(row, 1, XlsxFormula('C${totalRow + 1}-B${totalRow + 1}', cached: balance), _Styles.totalBalance(balance))
      ..set(row, 2, const XlsxText(''), _Styles.totalBalance(balance))
      ..merge(row, 1, row, 2);
    row++;
    final dates = entries.map((e) => e.date).toList()..sort();
    sheet
      ..set(row, 0, const XlsxText('기간'), _Styles.text(false))
      ..set(
        row,
        1,
        XlsxText(dates.isEmpty ? '-' : '${_date(dates.first)} ~ ${_date(dates.last)}'),
        _Styles.center(false),
      )
      ..set(row, 2, const XlsxText(''), _Styles.center(false))
      ..merge(row, 1, row, 2);
    sheet.outline(2, 0, row, 2, _Styles.frame); // 표 바깥 테두리
    row += 2;

    // 종류별 합계
    final typeIds = {for (final entry in entries) entry.eventTypeId}.toList()
      ..sort((a, b) => (typeNames.keys.toList().indexOf(a)).compareTo(typeNames.keys.toList().indexOf(b)));
    if (typeIds.isNotEmpty) {
      _subTitle(sheet, row++, '종류별 합계', width);
      _headers(sheet, const ['종류', '보낸 마음', '받은 마음'], row: row++);
      final from = row;
      for (final (i, typeId) in typeIds.indexed) {
        final name = typeNames[typeId] ?? '';
        final zebra = i.isOdd;
        int sumOf(RecordDirection d) =>
            entries.where((e) => e.direction == d && e.eventTypeId == typeId).fold(0, (s, e) => s + e.amount);
        sheet.set(row, 0, XlsxText(name), _Styles.center(zebra));
        sheet.set(
          row,
          1,
          sent.rowCount == 0
              ? const XlsxNumber(0)
              : XlsxFormula(
                  'SUMIF(${xlsxRange(sentSheet, 1, _firstDataRow, 1, sent.last)},A${row + 1},$sentSum)',
                  cached: sumOf(RecordDirection.sent),
                ),
          _Styles.money(zebra),
        );
        sheet.set(
          row,
          2,
          received.rowCount == 0
              ? const XlsxNumber(0)
              : XlsxFormula(
                  'SUMIF(${xlsxRange(receivedSheet, 2, _firstDataRow, 2, received.last)},A${row + 1},'
                  '${xlsxRange(receivedSheet, 5, _firstDataRow, 5, received.last)})',
                  cached: sumOf(RecordDirection.received),
                ),
          _Styles.money(zebra),
        );
        row++;
      }
      _columnTotals(sheet, row++, from, sent.total, received.total);
      sheet.outline(from - 1, 0, row - 1, 2, _Styles.frame);
      row++;
    }

    // 연도별 합계 (날짜가 그 해 1월 1일 ~ 다음 해 1월 1일 전인 기록만 더한다)
    final years = {for (final entry in entries) entry.date.year}.toList()..sort((a, b) => b.compareTo(a));
    if (years.isNotEmpty) {
      _subTitle(sheet, row++, '연도별 합계', width);
      _headers(sheet, const ['연도', '보낸 마음', '받은 마음'], row: row++);
      final from = row;
      for (final (i, year) in years.indexed) {
        final zebra = i.isOdd;
        int sumOf(RecordDirection d) =>
            entries.where((e) => e.direction == d && e.date.year == year).fold(0, (s, e) => s + e.amount);
        String byYear(String sumRange, String dateRange) =>
            'SUMIFS($sumRange,$dateRange,">="&DATE(A${row + 1},1,1),$dateRange,"<"&DATE(A${row + 1}+1,1,1))';
        sheet
          ..set(row, 0, XlsxNumber(year), _Styles.year(zebra))
          ..set(
            row,
            1,
            sent.rowCount == 0
                ? const XlsxNumber(0)
                : XlsxFormula(
                    byYear(sentSum, xlsxRange(sentSheet, 0, _firstDataRow, 0, sent.last)),
                    cached: sumOf(RecordDirection.sent),
                  ),
            _Styles.money(zebra),
          )
          ..set(
            row,
            2,
            received.rowCount == 0
                ? const XlsxNumber(0)
                : XlsxFormula(
                    byYear(
                      xlsxRange(receivedSheet, 5, _firstDataRow, 5, received.last),
                      xlsxRange(receivedSheet, 1, _firstDataRow, 1, received.last),
                    ),
                    cached: sumOf(RecordDirection.received),
                  ),
            _Styles.money(zebra),
          );
        row++;
      }
      _columnTotals(sheet, row, from, sent.total, received.total);
      sheet.outline(from - 1, 0, row, 2, _Styles.frame);
    }
  }

  // ── 공통 모양 ─────────────────────────────

  /// 1행 시트 제목(칸 합침) + 2행 작은 안내
  void _title(XlsxSheet sheet, String title, int width, String note) {
    sheet
      ..set(0, 0, XlsxText(title), _Styles.title)
      ..merge(0, 0, 0, width - 1)
      ..setRowHeight(0, 28)
      ..set(1, 0, XlsxText(note), _Styles.note)
      ..merge(1, 0, 1, width - 1);
  }

  void _subTitle(XlsxSheet sheet, int row, String title, int width) {
    sheet
      ..set(row, 0, XlsxText(title), _Styles.subTitle)
      ..merge(row, 0, row, width - 1)
      ..setRowHeight(row, 22);
  }

  void _headers(XlsxSheet sheet, List<String> headers, {int row = _firstDataRow - 1}) {
    for (final (col, header) in headers.indexed) {
      sheet.set(row, col, XlsxText(header), _Styles.header);
    }
    sheet.setRowHeight(row, 22);
  }

  /// 합계 · 소계 줄의 글자 칸. 금액 칸 외의 칸도 같은 배경 · 테두리로 채워 한 줄처럼 보이게 한다.
  void _totalLabel(XlsxSheet sheet, int row, int width, String label, {bool subtotal = false}) {
    final style = subtotal ? _Styles.subtotalLabel : _Styles.totalLabel;
    for (var col = 0; col < width; col++) {
      sheet.set(row, col, XlsxText(col == 0 ? label : ''), style);
    }
  }

  void _summaryRow(XlsxSheet sheet, int row, String label, XlsxValue sent, XlsxValue received, XlsxStyle style) {
    sheet
      ..set(row, 0, XlsxText(label), _Styles.text(false))
      ..set(row, 1, sent, style)
      ..set(row, 2, received, style);
  }

  /// 표 아래 "합계" 줄: B · C열을 위 표 범위로 더한다.
  void _columnTotals(XlsxSheet sheet, int row, int from, int sent, int received) {
    _totalLabel(sheet, row, 3, '합계');
    sheet
      ..set(row, 1, XlsxFormula('SUM(B${from + 1}:B$row)', cached: sent), _Styles.totalMoney)
      ..set(row, 2, XlsxFormula('SUM(C${from + 1}:C$row)', cached: received), _Styles.totalMoney);
  }

  static int _average(int total, int count) => count == 0 ? 0 : (total / count).round();

  static String _date(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// 보낸 마음 시트에서 다른 시트가 가리킬 위치
class _SentRanges {
  const _SentRanges({required this.rowCount, required this.last, required this.totalRow, required this.total});

  final int rowCount;

  /// 마지막 데이터 행 (0부터)
  final int last;
  final int totalRow;
  final int total;
}

class _ReceivedRanges {
  const _ReceivedRanges({required this.rowCount, required this.last, required this.totalRow, required this.total});

  final int rowCount;

  /// 마지막 소계 줄 (0부터)
  final int last;
  final int totalRow;
  final int total;
}

class _Person {
  int sent = 0;
  int received = 0;
  DateTime? lastDate;

  int get balance => received - sent;
  int get volume => sent + received;
}

/// 엑셀 서식 모음. 앱의 AppColors와 같은 색을 쓴다.
///
/// | 부분 | 모양 |
/// |---|---|
/// | 표 바깥 | 테라코타 굵은 선 ([frame]) |
/// | 머리글 | 테라코타 배경 + 흰 굵은 글자 + 아래 진한 선 |
/// | 데이터 줄 | 따뜻한 베이지 얇은 선, 한 줄 건너 연한 배경 |
/// | 소계 | 연한 테라코타 배경 + 위 점선 |
/// | 합계 | 진한 베이지 배경 + 위 이중선 |
abstract final class _Styles {
  static const _primary = 'C0714A';
  static const _primaryDark = '9A5434';
  static const _primaryLight = 'F6E6DC';
  static const _zebra = 'FCF6F1';
  static const _totalFill = 'EFE1D5';
  static const _gridColor = 'E3D3C6';
  static const _textSecondary = '8C7B70';
  static const _receivedColor = '3F7F86';
  static const _sentColor = 'CB5C5C';

  static const _money = '#,##0';
  static const _balance = '+#,##0;-#,##0;0';

  /// 표 바깥 테두리
  static const frame = XlsxLine(XlsxLineStyle.medium, _primary);
  static const _grid = XlsxBorder.all(XlsxLine(XlsxLineStyle.thin, _gridColor));
  static final _headerBorder = _grid.copyWith(bottom: const XlsxLine(XlsxLineStyle.medium, _primaryDark));
  static final _subtotalBorder = _grid.copyWith(top: const XlsxLine(XlsxLineStyle.dashed, _primary));
  static final _totalBorder = _grid.copyWith(top: const XlsxLine(XlsxLineStyle.double, _primary));

  static const title = XlsxStyle(bold: true, fontSize: 15, fontColor: _primary);
  static const subTitle = XlsxStyle(bold: true, fontSize: 12, fontColor: _primary);
  static const note = XlsxStyle(fontSize: 10, fontColor: _textSecondary);
  static const sampleWarning = XlsxStyle(bold: true, fontSize: 11, fontColor: 'C9503F');
  static final header = XlsxStyle(
    bold: true,
    fontColor: 'FFFFFF',
    fill: _primary,
    align: XlsxAlign.center,
    border: _headerBorder,
  );

  static XlsxStyle _cell(bool zebra) => XlsxStyle(border: _grid, fill: zebra ? _zebra : null);

  static XlsxStyle text(bool zebra) => _cell(zebra);
  static XlsxStyle center(bool zebra) => _cell(zebra).copyWith(align: XlsxAlign.center);
  static XlsxStyle memo(bool zebra) => _cell(zebra).copyWith(wrap: true);
  static XlsxStyle date(bool zebra) => _cell(zebra).copyWith(align: XlsxAlign.center, numberFormat: 'yyyy-mm-dd');
  static XlsxStyle year(bool zebra) => _cell(zebra).copyWith(align: XlsxAlign.center, numberFormat: '0"년"');
  static XlsxStyle money(bool zebra) => _cell(zebra).copyWith(align: XlsxAlign.right, numberFormat: _money);
  static XlsxStyle count(bool zebra) => _cell(zebra).copyWith(align: XlsxAlign.right, numberFormat: '0"건"');
  static XlsxStyle balance(int value, bool zebra) =>
      _cell(zebra).copyWith(align: XlsxAlign.right, numberFormat: _balance, fontColor: _balanceColor(value));

  static final totalLabel = XlsxStyle(bold: true, fill: _totalFill, border: _totalBorder);
  static final totalMoney = totalLabel.copyWith(align: XlsxAlign.right, numberFormat: _money);
  static final totalCount = totalLabel.copyWith(align: XlsxAlign.right, numberFormat: '0"명"');
  static XlsxStyle totalBalance(int value) =>
      totalLabel.copyWith(align: XlsxAlign.right, numberFormat: _balance, fontColor: _balanceColor(value));

  static final subtotalLabel = XlsxStyle(
    bold: true,
    fontColor: _primaryDark,
    fill: _primaryLight,
    border: _subtotalBorder,
  );
  static final subtotalMoney = subtotalLabel.copyWith(align: XlsxAlign.right, numberFormat: _money);
  static final subtotalCount = subtotalLabel.copyWith(align: XlsxAlign.right, numberFormat: '0"명"');

  /// 받은 게 많으면 받은 색(청록), 보낸 게 많으면 보낸 색(빨강), 같으면 기본
  static String? _balanceColor(int value) => value > 0 ? _receivedColor : (value < 0 ? _sentColor : null);
}
