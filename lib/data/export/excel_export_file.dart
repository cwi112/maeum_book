import 'dart:typed_data';

/// 다 만든 엑셀 파일 한 개. (공유 · 저장하기 전에 화면에 이름과 건수를 보여 준다)
class ExcelExportFile {
  const ExcelExportFile({
    required this.bytes,
    required this.fileName,
    required this.sentCount,
    required this.receivedCount,
    this.mayBeOutdated = false,
  });

  final Uint8List bytes;
  final String fileName;
  final int sentCount;
  final int receivedCount;

  /// 회원인데 인터넷이 끊겨 있어 "마지막으로 받아 온 기록 기준"일 수 있으면 true
  final bool mayBeOutdated;
}
