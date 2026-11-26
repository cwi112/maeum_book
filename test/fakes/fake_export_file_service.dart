import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:maeum_book/data/data.dart';

/// 테스트용 내보내기: 실제 공유 창 · 저장 창을 띄우지 않고, 무엇을 내보냈는지만 기억한다.
class FakeExportFileService implements ExportFileService {
  final List<String> shared = [];
  final List<String> saved = [];
  Uint8List? lastBytes;

  @override
  Future<bool> share(Uint8List bytes, String fileName, {Rect? origin}) async {
    lastBytes = bytes;
    shared.add(fileName);
    return true;
  }

  @override
  Future<bool> saveToDevice(Uint8List bytes, String fileName) async {
    lastBytes = bytes;
    saved.add(fileName);
    return true;
  }
}
