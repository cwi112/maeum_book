import 'dart:typed_data';

import 'package:archive/archive.dart';

/// 엑셀(.xlsx) 파일을 직접 만드는 작은 도구. (패키지 없이, 이 앱에 필요한 기능만)
///
/// xlsx는 "XML 파일 몇 개를 zip으로 묶은 것"이다. 이 파일이 그 XML을 만들어 zip으로 묶는다.
///
/// ```dart
/// final book = XlsxWorkbook();
/// final sheet = book.addSheet('보낸 마음')..setColumnWidths([12, 30]);
/// sheet.set(0, 0, const XlsxText('이름'), header);
/// sheet.set(1, 1, const XlsxNumber(50000), money);
/// sheet.set(2, 1, const XlsxFormula('SUM(B2:B2)', cached: 50000), money);
/// final bytes = book.encode();
/// ```
///
/// ## 왜 직접 만드나
/// 함수(`SUM` 등)를 넣을 때 **계산된 값도 함께** 넣으려고. 함수만 넣으면 아이폰 미리보기 · 카톡 미리보기처럼
/// 계산을 하지 않는 뷰어에서 0이나 빈칸으로 보인다. 계산값을 같이 넣으면 어디서 열어도 숫자가 보이고,
/// 엑셀에서 기록을 고치면 함수가 다시 계산한다. (덤으로 틀 고정 · 자동 필터도 쓸 수 있다)
///
/// 행 · 열 번호는 모두 0부터 센다. (엑셀 화면의 A1 = row 0, col 0) 함수 문자열은 엑셀 주소를 그대로 쓴다.
class XlsxWorkbook {
  final List<XlsxSheet> _sheets = [];

  /// 시트를 추가한다. 이름은 31자까지, `\ / ? * [ ] :` 는 쓸 수 없다. (엑셀 규칙)
  XlsxSheet addSheet(String name) {
    final sheet = XlsxSheet._(name);
    _sheets.add(sheet);
    return sheet;
  }

  List<XlsxSheet> get sheets => List.unmodifiable(_sheets);

  /// xlsx 파일 내용(바이트)을 만든다.
  Uint8List encode() {
    final strings = _SharedStrings();
    final styles = _StyleTable();
    final sheetXmls = [for (final sheet in _sheets) sheet._toXml(strings, styles)];

    final archive = Archive()
      ..addFile(ArchiveFile.string('[Content_Types].xml', _contentTypes(_sheets.length)))
      ..addFile(ArchiveFile.string('_rels/.rels', _rootRels))
      ..addFile(ArchiveFile.string('xl/workbook.xml', _workbookXml()))
      ..addFile(ArchiveFile.string('xl/_rels/workbook.xml.rels', _workbookRels(_sheets.length)))
      ..addFile(ArchiveFile.string('xl/styles.xml', styles.toXml()))
      ..addFile(ArchiveFile.string('xl/sharedStrings.xml', strings.toXml()));
    for (var i = 0; i < sheetXmls.length; i++) {
      archive.addFile(ArchiveFile.string('xl/worksheets/sheet${i + 1}.xml', sheetXmls[i]));
    }
    return ZipEncoder().encodeBytes(archive);
  }

  String _workbookXml() {
    final sheets = StringBuffer();
    final names = StringBuffer();
    for (var i = 0; i < _sheets.length; i++) {
      final sheet = _sheets[i];
      sheets.write('<sheet name="${_escape(sheet.name)}" sheetId="${i + 1}" r:id="rId${i + 1}"/>');
      // 자동 필터를 쓰는 시트는 엑셀이 만드는 숨은 이름을 같이 넣어 둔다. (없으면 일부 엑셀이 복구 안내를 띄움)
      final filter = sheet._autoFilter;
      if (filter != null) {
        names.write(
          '<definedName name="_xlnm._FilterDatabase" localSheetId="$i" hidden="1">'
          '${_escape(_quoteSheet(sheet.name))}!${_absolute(filter)}</definedName>',
        );
      }
    }
    return '$_xmlHeader<workbook xmlns="$_ns" xmlns:r="$_nsR">'
        '<bookViews><workbookView/></bookViews>'
        '<sheets>$sheets</sheets>'
        '${names.isEmpty ? '' : '<definedNames>$names</definedNames>'}'
        // 엑셀에서 열 때 모든 함수를 다시 계산하게 한다. (넣어 둔 계산값보다 엑셀 계산이 우선)
        '<calcPr calcId="191029" fullCalcOnLoad="1"/>'
        '</workbook>';
  }
}

/// 시트 하나.
class XlsxSheet {
  XlsxSheet._(this.name);

  final String name;
  final Map<int, Map<int, (XlsxValue, XlsxStyle)>> _rows = {};
  final Map<int, double> _rowHeights = {};
  final List<String> _merges = [];
  List<double> _columnWidths = const [];
  int _frozenRows = 0;
  String? _autoFilter;

  /// 칸 하나에 값을 넣는다.
  void set(int row, int col, XlsxValue value, [XlsxStyle style = XlsxStyle.plain]) {
    (_rows[row] ??= {})[col] = (value, style);
  }

  /// 넣은 값 (테스트 · 확인용). 없으면 null.
  XlsxValue? valueAt(int row, int col) => _rows[row]?[col]?.$1;

  /// 넣은 서식 (테스트 · 확인용). 없으면 null.
  XlsxStyle? styleAt(int row, int col) => _rows[row]?[col]?.$2;

  /// 값이 들어 있는 마지막 행 번호 (없으면 -1)
  int get lastRow => _rows.isEmpty ? -1 : _rows.keys.reduce((a, b) => a > b ? a : b);

  /// 열 너비 (글자 수 단위, 엑셀 기본 8.43). 앞에서부터 A, B, C… 순서.
  void setColumnWidths(List<double> widths) => _columnWidths = widths;

  void setRowHeight(int row, double height) => _rowHeights[row] = height;

  /// 칸 합치기. 예) `merge(0, 0, 0, 5)` = A1:F1
  void merge(int fromRow, int fromCol, int toRow, int toCol) =>
      _merges.add('${xlsxCell(fromCol, fromRow)}:${xlsxCell(toCol, toRow)}');

  /// 표 바깥쪽에 [line] 테두리를 두른다. (안쪽 칸 테두리는 그대로) 비어 있는 칸은 빈 글자 칸으로 채워 선이 끊기지 않게 한다.
  void outline(int fromRow, int fromCol, int toRow, int toCol, XlsxLine line) {
    for (var row = fromRow; row <= toRow; row++) {
      for (var col = fromCol; col <= toCol; col++) {
        final edge = row == fromRow || row == toRow || col == fromCol || col == toCol;
        if (!edge) continue;
        final cell = _rows[row]?[col];
        final style = cell?.$2 ?? XlsxStyle.plain;
        set(
          row,
          col,
          cell?.$1 ?? const XlsxText(''),
          style.copyWith(
            border: style.border.copyWith(
              top: row == fromRow ? line : null,
              bottom: row == toRow ? line : null,
              left: col == fromCol ? line : null,
              right: col == toCol ? line : null,
            ),
          ),
        );
      }
    }
  }

  /// 위에서부터 [rows]개 행을 고정한다. (아래로 내려도 머리글이 보이게)
  void freezeRows(int rows) => _frozenRows = rows;

  /// 머리글 행에 자동 필터(▼ 버튼)를 단다. 예) `autoFilter(2, 0, 40, 5)` = A3:F41
  void autoFilter(int fromRow, int fromCol, int toRow, int toCol) =>
      _autoFilter = '${xlsxCell(fromCol, fromRow)}:${xlsxCell(toCol, toRow)}';

  String _toXml(_SharedStrings strings, _StyleTable styles) {
    final out = StringBuffer('$_xmlHeader<worksheet xmlns="$_ns" xmlns:r="$_nsR">');

    out.write('<sheetViews><sheetView workbookViewId="0"');
    if (_frozenRows > 0) {
      final topLeft = xlsxCell(0, _frozenRows);
      out.write(
        '><pane ySplit="$_frozenRows" topLeftCell="$topLeft" activePane="bottomLeft" state="frozen"/>'
        '<selection pane="bottomLeft" activeCell="$topLeft" sqref="$topLeft"/></sheetView>',
      );
    } else {
      out.write('/>');
    }
    out.write('</sheetViews><sheetFormatPr defaultRowHeight="18"/>');

    if (_columnWidths.isNotEmpty) {
      out.write('<cols>');
      for (var i = 0; i < _columnWidths.length; i++) {
        out.write('<col min="${i + 1}" max="${i + 1}" width="${_columnWidths[i]}" customWidth="1"/>');
      }
      out.write('</cols>');
    }

    out.write('<sheetData>');
    for (final row in _rows.keys.toList()..sort()) {
      final height = _rowHeights[row];
      out.write('<row r="${row + 1}"${height == null ? '' : ' ht="$height" customHeight="1"'}>');
      final cells = _rows[row]!;
      for (final col in cells.keys.toList()..sort()) {
        final (value, style) = cells[col]!;
        out.write(value._toXml(xlsxCell(col, row), styles.indexOf(style), strings));
      }
      out.write('</row>');
    }
    out.write('</sheetData>');

    // 순서가 정해져 있다: sheetData → autoFilter → mergeCells → pageMargins
    if (_autoFilter != null) out.write('<autoFilter ref="$_autoFilter"/>');
    if (_merges.isNotEmpty) {
      out.write('<mergeCells count="${_merges.length}">');
      for (final ref in _merges) {
        out.write('<mergeCell ref="$ref"/>');
      }
      out.write('</mergeCells>');
    }
    out.write('<pageMargins left="0.5" right="0.5" top="0.6" bottom="0.6" header="0.3" footer="0.3"/></worksheet>');
    return out.toString();
  }
}

// ── 값 ────────────────────────────────────

/// 칸에 들어가는 값: 글자 · 숫자 · 날짜 · 함수
sealed class XlsxValue {
  const XlsxValue();

  String _toXml(String ref, int style, _SharedStrings strings);
}

class XlsxText extends XlsxValue {
  const XlsxText(this.text);

  final String text;

  @override
  String _toXml(String ref, int style, _SharedStrings strings) =>
      '<c r="$ref" s="$style" t="s"><v>${strings.indexOf(text)}</v></c>';
}

class XlsxNumber extends XlsxValue {
  const XlsxNumber(this.value);

  final num value;

  @override
  String _toXml(String ref, int style, _SharedStrings strings) => '<c r="$ref" s="$style"><v>$value</v></c>';
}

/// 날짜 칸. 엑셀은 날짜를 "1899-12-30부터 며칠째"라는 숫자로 저장하고, 날짜 형식 서식으로 보여 준다.
class XlsxDate extends XlsxValue {
  const XlsxDate(this.date);

  final DateTime date;

  /// 엑셀 날짜 숫자 (예: 2026-11-26 → 46352)
  int get serial => DateTime.utc(date.year, date.month, date.day).difference(DateTime.utc(1899, 12, 30)).inDays;

  @override
  String _toXml(String ref, int style, _SharedStrings strings) => '<c r="$ref" s="$style"><v>$serial</v></c>';
}

/// 함수 칸. [formula]는 앞의 `=` 없이 쓴다. 예) `SUM(E4:E43)`
///
/// [cached]: 앱이 미리 계산한 결과. 계산하지 않는 뷰어(미리보기)에서는 이 값이 보이고, 엑셀은 열 때 다시 계산한다.
class XlsxFormula extends XlsxValue {
  const XlsxFormula(this.formula, {required this.cached});

  final String formula;
  final num cached;

  @override
  String _toXml(String ref, int style, _SharedStrings strings) =>
      '<c r="$ref" s="$style"><f>${_escape(formula)}</f><v>$cached</v></c>';
}

// ── 서식 ──────────────────────────────────

enum XlsxAlign { general, left, center, right }

/// 선 모양 (엑셀 이름 그대로)
enum XlsxLineStyle { thin, medium, thick, double, dashed, dotted, hair }

/// 테두리 선 하나: 모양 + 색(`RRGGBB`)
class XlsxLine {
  const XlsxLine(this.style, this.color);

  final XlsxLineStyle style;
  final String color;

  @override
  bool operator ==(Object other) => other is XlsxLine && other.style == style && other.color == color;

  @override
  int get hashCode => Object.hash(style, color);
}

/// 칸 테두리: 위 · 아래 · 왼쪽 · 오른쪽 선 (없으면 null)
class XlsxBorder {
  const XlsxBorder({this.left, this.right, this.top, this.bottom});

  /// 네 변 모두 같은 선
  const XlsxBorder.all(XlsxLine line) : left = line, right = line, top = line, bottom = line;

  static const none = XlsxBorder();

  final XlsxLine? left;
  final XlsxLine? right;
  final XlsxLine? top;
  final XlsxLine? bottom;

  bool get isNone => left == null && right == null && top == null && bottom == null;

  XlsxBorder copyWith({XlsxLine? left, XlsxLine? right, XlsxLine? top, XlsxLine? bottom}) => XlsxBorder(
    left: left ?? this.left,
    right: right ?? this.right,
    top: top ?? this.top,
    bottom: bottom ?? this.bottom,
  );

  @override
  bool operator ==(Object other) =>
      other is XlsxBorder && other.left == left && other.right == right && other.top == top && other.bottom == bottom;

  @override
  int get hashCode => Object.hash(left, right, top, bottom);
}

/// 칸 서식. 같은 값이면 같은 서식으로 묶여 파일 안에 한 번만 저장된다.
///
/// 색은 `RRGGBB` 6자리 (예: `C0714A`). [numberFormat] 예) `#,##0`, `yyyy-mm-dd`, `0"명"`
class XlsxStyle {
  const XlsxStyle({
    this.bold = false,
    this.fontSize = 11,
    this.fontColor,
    this.fill,
    this.align = XlsxAlign.general,
    this.wrap = false,
    this.border = XlsxBorder.none,
    this.numberFormat,
  });

  static const plain = XlsxStyle();

  /// 이 앱 기본 한글 글꼴 (엑셀 기본 한글 글꼴. 없는 기기에서는 비슷한 글꼴로 보인다)
  static const fontName = '맑은 고딕';

  final bool bold;
  final double fontSize;
  final String? fontColor;
  final String? fill;
  final XlsxAlign align;
  final bool wrap;
  final XlsxBorder border;
  final String? numberFormat;

  XlsxStyle copyWith({
    bool? bold,
    double? fontSize,
    String? fontColor,
    String? fill,
    XlsxAlign? align,
    bool? wrap,
    XlsxBorder? border,
    String? numberFormat,
  }) => XlsxStyle(
    bold: bold ?? this.bold,
    fontSize: fontSize ?? this.fontSize,
    fontColor: fontColor ?? this.fontColor,
    fill: fill ?? this.fill,
    align: align ?? this.align,
    wrap: wrap ?? this.wrap,
    border: border ?? this.border,
    numberFormat: numberFormat ?? this.numberFormat,
  );

  Object get _key => (bold, fontSize, fontColor, fill, align, wrap, border, numberFormat);
  Object get _fontKey => (bold, fontSize, fontColor);

  @override
  bool operator ==(Object other) => other is XlsxStyle && other._key == _key;

  @override
  int get hashCode => _key.hashCode;
}

// ── 주소 ──────────────────────────────────

/// 열 번호(0부터) → 엑셀 열 이름. 0 → A, 25 → Z, 26 → AA
String xlsxColumn(int col) {
  var n = col + 1;
  final letters = StringBuffer();
  while (n > 0) {
    final rem = (n - 1) % 26;
    letters.write(String.fromCharCode(65 + rem));
    n = (n - 1) ~/ 26;
  }
  return letters.toString().split('').reversed.join();
}

/// (열, 행) 0부터 → 엑셀 주소. (4, 3) → E4
String xlsxCell(int col, int row) => '${xlsxColumn(col)}${row + 1}';

/// 다른 시트를 가리키는 주소. 시트 이름에 띄어쓰기가 있으면 작은따옴표로 감싼다. → `'보낸 마음'!$E$4:$E$43`
String xlsxRange(String sheet, int fromCol, int fromRow, int toCol, int toRow) =>
    '${_quoteSheet(sheet)}!\$${xlsxColumn(fromCol)}\$${fromRow + 1}:\$${xlsxColumn(toCol)}\$${toRow + 1}';

String _quoteSheet(String name) => "'${name.replaceAll("'", "''")}'";

String _absolute(String range) => range
    .split(':')
    .map((cell) {
      final match = RegExp(r'^([A-Z]+)(\d+)$').firstMatch(cell)!;
      return '\$${match[1]}\$${match[2]}';
    })
    .join(':');

// ── 파일 안의 공통 부분 ─────────────────────

const _xmlHeader = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>';
const _ns = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
const _nsR = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
const _relType = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships';

String _escape(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    // XML에 넣을 수 없는 제어 문자는 지운다. (줄바꿈 · 탭은 남김)
    .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');

String _contentTypes(int sheetCount) {
  final sheets = StringBuffer();
  for (var i = 1; i <= sheetCount; i++) {
    sheets.write(
      '<Override PartName="/xl/worksheets/sheet$i.xml" '
      'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>',
    );
  }
  return '$_xmlHeader<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/xl/workbook.xml" '
      'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
      '$sheets'
      '<Override PartName="/xl/styles.xml" '
      'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
      '<Override PartName="/xl/sharedStrings.xml" '
      'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>'
      '</Types>';
}

const _rootRels =
    '$_xmlHeader<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
    '<Relationship Id="rId1" Type="$_relType/officeDocument" Target="xl/workbook.xml"/>'
    '</Relationships>';

String _workbookRels(int sheetCount) {
  final out = StringBuffer(
    '$_xmlHeader<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">',
  );
  for (var i = 1; i <= sheetCount; i++) {
    out.write('<Relationship Id="rId$i" Type="$_relType/worksheet" Target="worksheets/sheet$i.xml"/>');
  }
  out
    ..write('<Relationship Id="rId${sheetCount + 1}" Type="$_relType/styles" Target="styles.xml"/>')
    ..write('<Relationship Id="rId${sheetCount + 2}" Type="$_relType/sharedStrings" Target="sharedStrings.xml"/>')
    ..write('</Relationships>');
  return out.toString();
}

/// 글자 칸은 글자를 한곳(sharedStrings.xml)에 모아 두고 번호로 가리킨다. (같은 글자는 한 번만 저장)
class _SharedStrings {
  final Map<String, int> _index = {};
  int _count = 0;

  int indexOf(String text) {
    _count++;
    return _index.putIfAbsent(text, () => _index.length);
  }

  String toXml() {
    final out = StringBuffer('$_xmlHeader<sst xmlns="$_ns" count="$_count" uniqueCount="${_index.length}">');
    for (final text in _index.keys) {
      out.write('<si><t xml:space="preserve">${_escape(text)}</t></si>');
    }
    out.write('</sst>');
    return out.toString();
  }
}

/// 쓰인 서식들을 모아 styles.xml을 만든다. 칸은 서식 번호(s="3")로 가리킨다.
class _StyleTable {
  _StyleTable() {
    indexOf(XlsxStyle.plain); // 0번은 기본 서식이어야 한다.
  }

  final Map<XlsxStyle, int> _styles = {};
  final Map<Object, int> _fonts = {};
  final Map<String?, int> _fills = {null: 0, '__gray125': 1}; // 0 · 1번 채우기는 엑셀이 정해 둔 것
  final Map<String, int> _numberFormats = {};
  final Map<XlsxBorder, int> _borders = {XlsxBorder.none: 0}; // 0번은 테두리 없음

  /// 엑셀에 미리 정해진 숫자 형식 번호
  static const _builtInFormats = {'General': 0, '0': 1, '#,##0': 3};

  int indexOf(XlsxStyle style) => _styles.putIfAbsent(style, () {
    _fonts.putIfAbsent(style._fontKey, () => _fonts.length);
    _fills.putIfAbsent(style.fill, () => _fills.length);
    _borders.putIfAbsent(style.border, () => _borders.length);
    final format = style.numberFormat;
    if (format != null && !_builtInFormats.containsKey(format)) {
      _numberFormats.putIfAbsent(format, () => 164 + _numberFormats.length); // 직접 만든 형식은 164번부터
    }
    return _styles.length;
  });

  String toXml() {
    final out = StringBuffer('$_xmlHeader<styleSheet xmlns="$_ns">');

    if (_numberFormats.isNotEmpty) {
      out.write('<numFmts count="${_numberFormats.length}">');
      _numberFormats.forEach((code, id) => out.write('<numFmt numFmtId="$id" formatCode="${_escape(code)}"/>'));
      out.write('</numFmts>');
    }

    out.write('<fonts count="${_fonts.length}">');
    for (final style in _uniqueBy((s) => s._fontKey)) {
      out
        ..write('<font>')
        ..write(style.bold ? '<b/>' : '')
        ..write('<sz val="${style.fontSize}"/>')
        ..write(style.fontColor == null ? '' : '<color rgb="FF${style.fontColor}"/>')
        ..write('<name val="${XlsxStyle.fontName}"/><family val="2"/><charset val="129"/></font>');
    }
    out.write('</fonts>');

    out.write('<fills count="${_fills.length}">');
    for (final fill in _fills.keys) {
      if (fill == null) {
        out.write('<fill><patternFill patternType="none"/></fill>');
      } else if (fill == '__gray125') {
        out.write('<fill><patternFill patternType="gray125"/></fill>');
      } else {
        out.write(
          '<fill><patternFill patternType="solid"><fgColor rgb="FF$fill"/><bgColor indexed="64"/></patternFill></fill>',
        );
      }
    }
    out.write('</fills>');

    out.write('<borders count="${_borders.length}">');
    for (final border in _borders.keys) {
      out.write(_borderXml(border));
    }
    out.write('</borders>');

    out
      ..write('<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>')
      ..write('<cellXfs count="${_styles.length}">');
    for (final style in _styles.keys) {
      final format = style.numberFormat;
      final formatId = format == null ? 0 : (_builtInFormats[format] ?? _numberFormats[format]!);
      final alignment = style.align != XlsxAlign.general || style.wrap
          ? '<alignment${style.align == XlsxAlign.general ? '' : ' horizontal="${style.align.name}"'}'
                ' vertical="center"${style.wrap ? ' wrapText="1"' : ''}/>'
          : '';
      out.write(
        '<xf numFmtId="$formatId" fontId="${_fonts[style._fontKey]}" fillId="${_fills[style.fill]}" '
        'borderId="${_borders[style.border]}" xfId="0"'
        '${formatId == 0 ? '' : ' applyNumberFormat="1"'} applyFont="1"'
        '${style.fill == null ? '' : ' applyFill="1"'}'
        '${style.border.isNone ? '' : ' applyBorder="1"'}'
        '${alignment.isEmpty ? '/>' : ' applyAlignment="1">$alignment</xf>'}',
      );
    }
    out
      ..write('</cellXfs>')
      ..write('<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>')
      ..write('</styleSheet>');
    return out.toString();
  }

  /// 같은 글꼴을 쓰는 서식 중 처음 것만 (글꼴 번호 순서대로)
  Iterable<XlsxStyle> _uniqueBy(Object Function(XlsxStyle) key) {
    final seen = <Object>{};
    return _styles.keys.where((style) => seen.add(key(style)));
  }

  static String _borderXml(XlsxBorder border) {
    String side(String name, XlsxLine? line) =>
        line == null ? '<$name/>' : '<$name style="${line.style.name}"><color rgb="FF${line.color}"/></$name>';
    return '<border>${side('left', border.left)}${side('right', border.right)}'
        '${side('top', border.top)}${side('bottom', border.bottom)}<diagonal/></border>';
  }
}
