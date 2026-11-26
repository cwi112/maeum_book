import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 만든 파일(바이트)을 밖으로 내보낸다: 공유 창 / 휴대폰에 저장.
///
/// | 방법 | 동작 |
/// |---|---|
/// | [share] | 기기 임시 폴더에 파일을 두고 공유 창을 띄운다 → 카톡 · 메일 · "파일에 저장" · 드라이브 … |
/// | [saveToDevice] | 시스템 "저장 위치 고르기" 창을 띄운다. 안드로이드는 다운로드 폴더, 아이폰은 파일 앱에서 고른 폴더 |
///
/// 서버에는 올리지 않는다. 파일은 사용자가 고른 곳으로만 나간다. (개인정보 · 비용)
/// 테스트에서는 실제 공유 창 대신 가짜로 바꿔 끼운다. ([exportFileServiceProvider] override)
class ExportFileService {
  const ExportFileService();

  static const xlsxMimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  /// 공유 창을 띄운다. 공유를 끝까지 했으면 true, 닫았으면 false.
  ///
  /// [origin]: iPad는 공유 창이 말풍선으로 뜨므로 누른 버튼의 화면 위치를 넘겨야 한다. (없으면 iPad에서 오류)
  Future<bool> share(Uint8List bytes, String fileName, {Rect? origin}) async {
    // 지난번에 공유한 임시 파일은 지운다. (기기 공간이 쌓이지 않게)
    final dir = Directory('${(await getTemporaryDirectory()).path}/export');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: xlsxMimeType)],
        sharePositionOrigin: origin,
      ),
    );
    return result.status == ShareResultStatus.success;
  }

  /// 저장 위치를 고르는 창을 띄워 저장한다. 저장했으면 true, 취소했으면 false.
  Future<bool> saveToDevice(Uint8List bytes, String fileName) async {
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: xlsxMimeType,
      dialogTitle: '엑셀 파일 저장',
    );
    return uri != null;
  }
}

final exportFileServiceProvider = Provider<ExportFileService>((ref) => const ExportFileService());
