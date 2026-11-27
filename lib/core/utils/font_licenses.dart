import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 앱에 넣은 글꼴의 라이선스(SIL 오픈 폰트 라이선스)를 "오픈소스 라이선스" 화면에 더한다.
///
/// 패키지 라이선스는 Flutter가 자동으로 모으지만, 글꼴 파일은 패키지가 아니라서 직접 등록해야 한다.
/// 이 라이선스는 글꼴을 앱에 넣어 배포할 때 라이선스 전문을 함께 넣는 것이 조건이다.
/// 글은 화면을 열 때만 읽는다. (앱 시작이 느려지지 않게)
abstract final class FontLicenses {
  /// (글꼴 이름, 라이선스 파일) — 파일은 pubspec.yaml assets에도 있어야 한다.
  static const List<(String, String)> fonts = [
    ('Pretendard', 'assets/fonts/OFL-Pretendard.txt'),
    ('Gowun Batang (고운바탕)', 'assets/fonts/OFL-GowunBatang.txt'),
  ];

  static void register() {
    LicenseRegistry.addLicense(() async* {
      for (final (name, path) in fonts) {
        yield LicenseEntryWithLineBreaks([name], await rootBundle.loadString(path));
      }
    });
  }
}
