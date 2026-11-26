// 스토어 · TestFlight용 스크린샷 생성기.
//
// 실제 앱 화면(샘플 데이터)을 휴대폰 · 태블릿 틀에 넣고 위에 소개 문구를 얹어, 각 스토어 규격 해상도로 PNG를 만든다.
// 일반 테스트(flutter test)에는 포함되지 않는다. 화면을 바꾼 뒤 다시 만들 때만 아래 명령을 실행한다.
//
//   fvm flutter test screenshots/store_screenshots_test.dart --update-goldens
//
// 결과: store_assets/<규격>/01_*.png ...  (규격별 크기는 아래 _specs 참고)
import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maeum_book/app.dart';
import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';
import 'package:maeum_book/router/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/fakes/fake_auth_repository.dart';
import '../test/fakes/fake_remote_ledger_store.dart';

/// 스토어 규격 하나
class _Spec {
  const _Spec(this.folder, this.width, this.height, this.pixelRatio, this.platform, this.device);

  final String folder;

  /// 최종 PNG 크기 (px)
  final int width;
  final int height;
  final double pixelRatio;
  final TargetPlatform platform;

  /// 틀 안에 그릴 기기 화면 (논리 크기 · 상단/하단 여백 · 틀 둥글기)
  final _Device device;

  bool get isTablet => device.size.shortestSide > 600;
}

class _Device {
  const _Device(this.size, this.top, this.bottom, this.radius);

  final Size size;
  final double top;
  final double bottom;
  final double radius;
}

const _iphone = _Device(Size(393, 852), 54, 34, 55);
const _ipad = _Device(Size(1032, 1376), 24, 20, 30);
const _android = _Device(Size(412, 915), 32, 16, 40);

const _specs = [
  // App Store: iPhone 6.9" (필수) · 6.5" · iPad 13" (iPad 지원 앱은 필수)
  _Spec('ios_iphone_6.9', 1320, 2868, 3, TargetPlatform.iOS, _iphone),
  _Spec('ios_iphone_6.5', 1284, 2778, 3, TargetPlatform.iOS, _iphone),
  _Spec('ios_ipad_13', 2064, 2752, 2, TargetPlatform.iOS, _ipad),
  // Google Play: 휴대전화 9:16 (긴 변이 짧은 변의 2배 이하여야 함)
  _Spec('android_phone', 1080, 1920, 2.5, TargetPlatform.android, _android),
];

/// 화면 하나: 파일 이름, 제목, 설명, 보여줄 경로
class _Shot {
  const _Shot(this.file, this.title, this.subtitle, this.route, {this.signedOutStart = false});

  final String file;
  final String title;
  final String subtitle;
  final String Function(_Ids ids) route;

  /// 로그인 시작 화면 (비회원 선택 전)
  final bool signedOutStart;
}

class _Ids {
  _Ids(this.weddingEventId);
  final int weddingEventId;
}

final _shots = [
  _Shot('01_sent', '보낸 마음을\n한눈에', '축의금 · 부조금, 누구에게 얼마나 보냈는지', (_) => AppRoutes.sent),
  _Shot('02_received', '내 행사별로\n받은 마음 정리', '결혼식 · 돌잔치마다 마음을 준 분들을 모아서', (_) => AppRoutes.received),
  _Shot('03_event', '고마운 분들을\n잊지 않도록', '누가 얼마나 마음을 전했는지 행사 안에서 바로', (ids) => AppRoutes.eventDetail(ids.weddingEventId)),
  _Shot('04_stats', '한 해의 마음 흐름을\n통계로', '월별 흐름 · 종류별 · 관계별 · 많이 주고받은 사람', (_) => AppRoutes.stats),
  _Shot('05_entry', '몇 번의 터치로\n간편하게 기록', '날짜 · 종류 · 이름 · 금액만 고르면 끝', (_) => AppRoutes.entryNew(RecordDirection.sent)),
  _Shot('06_login', '어느 기기에서든\n이어서 쓰기', '카카오 · Apple 로그인, 로그인 없이도 바로 시작', (_) => AppRoutes.login, signedOutStart: true),
];

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    loader.addFont(Future.value(ByteData.sublistView(File(path).readAsBytesSync())));
  }
  await loader.load();
}

Future<void> _loadFonts() async {
  const pretendard = [
    'assets/fonts/Pretendard-Regular.otf',
    'assets/fonts/Pretendard-Medium.otf',
    'assets/fonts/Pretendard-SemiBold.otf',
    'assets/fonts/Pretendard-Bold.otf',
  ];
  await _loadFont('Pretendard', pretendard);
  await _loadFont('GowunBatang', ['assets/fonts/GowunBatang-Regular.ttf', 'assets/fonts/GowunBatang-Bold.ttf']);
  await _loadFont('MaterialIcons', ['.fvm/flutter_sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf']);
  // 로그인 버튼처럼 "OS 기본 서체"를 쓰는 글자: 테스트 환경에는 시스템 서체가 없어서 Pretendard로 대신 그린다.
  for (final family in [
    'FlutterTest', // 테스트 환경에서 글꼴을 지정하지 않은 글자의 기본 서체
    'Roboto',
    'CupertinoSystemText',
    'CupertinoSystemDisplay',
    '.SF Pro Text',
    '.SF Pro Display',
    '.SF UI Text',
    '.SF UI Display',
  ]) {
    await _loadFont(family, pretendard);
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  setUpAll(_loadFonts);

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  for (final spec in _specs) {
    for (final shot in _shots) {
      testWidgets('${spec.folder}/${shot.file}', (tester) async {
        debugDefaultTargetPlatformOverride = spec.platform;
        tester.view.physicalSize = Size(spec.width.toDouble(), spec.height.toDouble());
        tester.view.devicePixelRatio = spec.pixelRatio;

        final guestDb = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
        final memberDb = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
        await tester.runAsync(() => SampleData.insertInto(guestDb, now: DateTime(2026, 11, 26)));
        final events = (await tester.runAsync(() => guestDb.select(guestDb.events).get()))!;
        final ids = _Ids(events.firstWhere((e) => e.title == '우리 결혼식').id);

        // ignore: invalid_use_of_visible_for_testing_member
        SharedPreferences.setMockInitialValues({if (!shot.signedOutStart) 'guest_mode': true});
        final prefs = await SharedPreferences.getInstance();

        final container = ProviderContainer(
          overrides: [
            guestDatabaseProvider.overrideWithValue(guestDb),
            memberDatabaseProvider.overrideWith((ref, _) => memberDb),
            serverStoreProvider.overrideWithValue(FakeRemoteLedgerStore()),
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            sharedPreferencesProvider.overrideWithValue(prefs),
            isOnlineProvider.overrideWith((ref) => Stream.value(true)),
          ],
        );

        final canvasKey = GlobalKey();
        await tester.pumpWidget(
          _StoreFrame(
            key: canvasKey,
            spec: spec,
            shot: shot,
            app: UncontrolledProviderScope(container: container, child: const App()),
          ),
        );
        await settle(tester);
        if (!shot.signedOutStart) container.read(appRouterProvider).go(shot.route(ids));
        await settle(tester);
        await tester.pumpAndSettle();
        await settle(tester);

        await expectLater(find.byKey(canvasKey), matchesGoldenFile('../store_assets/${spec.folder}/${shot.file}.png'));

        await tester.pumpWidget(const SizedBox.shrink());
        container.dispose();
        await tester.runAsync(guestDb.close);
        await tester.runAsync(memberDb.close);
        debugDefaultTargetPlatformOverride = null;
        tester.view.reset();
      });
    }
  }

  // Google Play 그래픽 이미지 (1024 x 500, 스토어 상단 배너. 필수)
  testWidgets('android_feature_graphic', (tester) async {
    tester.view.physicalSize = const Size(1024, 500);
    tester.view.devicePixelRatio = 1;
    final icon = File('assets/icon/app_icon.png').readAsBytesSync();
    final key = GlobalKey();
    await tester.pumpWidget(_FeatureGraphic(key: key, icon: icon));
    await tester.runAsync(() => precacheImage(MemoryImage(icon), tester.element(find.byKey(key))));
    await tester.pumpAndSettle();
    await expectLater(find.byKey(key), matchesGoldenFile('../store_assets/android_feature_graphic.png'));
    tester.view.reset();
  });
}

/// 스크린샷 한 장: 따뜻한 배경 + 제목 · 설명 + 기기 틀 안의 실제 앱 화면
class _StoreFrame extends StatelessWidget {
  const _StoreFrame({super.key, required this.spec, required this.shot, required this.app});

  final _Spec spec;
  final _Shot shot;
  final Widget app;

  @override
  Widget build(BuildContext context) {
    final canvas = Size(spec.width / spec.pixelRatio, spec.height / spec.pixelRatio);
    final unit = canvas.width / 100; // 캔버스 너비의 1%
    final device = spec.device;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        width: canvas.width,
        height: canvas.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, AppColors.primaryLight],
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: canvas.height * (spec.isTablet ? 0.045 : 0.065)),
            Text(
              shot.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'GowunBatang',
                fontWeight: FontWeight.w700,
                fontSize: unit * (spec.isTablet ? 5.2 : 8.2),
                height: 1.3,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: unit * 2.4),
            Text(
              shot.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
                fontSize: unit * (spec.isTablet ? 2.4 : 3.9),
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: canvas.height * 0.035),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  unit * (spec.isTablet ? 9 : 10),
                  0,
                  unit * (spec.isTablet ? 9 : 10),
                  canvas.height * 0.04,
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    alignment: Alignment.topCenter,
                    child: _DeviceFrame(device: device, platform: spec.platform, child: app),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 기기 틀: 검은 테두리 + 둥근 화면 + 상태 표시줄(9:41)
class _DeviceFrame extends StatelessWidget {
  const _DeviceFrame({required this.device, required this.platform, required this.child});

  final _Device device;
  final TargetPlatform platform;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const bezel = 14.0;
    final media = MediaQueryData(
      size: device.size,
      devicePixelRatio: 3,
      padding: EdgeInsets.only(top: device.top, bottom: device.bottom),
      viewPadding: EdgeInsets.only(top: device.top, bottom: device.bottom),
    );
    return Container(
      padding: const EdgeInsets.all(bezel),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1A19),
        borderRadius: BorderRadius.circular(device.radius + bezel),
        boxShadow: const [BoxShadow(color: Color(0x553B2F2A), blurRadius: 40, offset: Offset(0, 16))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(device.radius),
        child: SizedBox.fromSize(
          size: device.size,
          child: MediaQuery(
            data: media,
            child: Stack(
              children: [
                Positioned.fill(child: child),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: device.top,
                  child: _StatusBar(platform: platform),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.platform});

  final TargetPlatform platform;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontFamily: 'Pretendard',
      fontWeight: FontWeight.w600,
      fontSize: 16,
      color: AppColors.textPrimary,
    );
    final ios = platform == TargetPlatform.iOS;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ios ? 34 : 22),
      child: Row(
        crossAxisAlignment: ios ? CrossAxisAlignment.center : CrossAxisAlignment.center,
        children: [
          const Text('9:41', style: style),
          const Spacer(),
          for (final icon in [Icons.signal_cellular_alt_rounded, Icons.wifi_rounded, Icons.battery_full_rounded])
            Padding(
              padding: const EdgeInsets.only(left: 5),
              child: Icon(icon, size: 18, color: AppColors.textPrimary),
            ),
        ],
      ),
    );
  }
}

/// Google Play 그래픽 이미지: 테라코타 배경 + 앱 아이콘 + 이름 · 한 줄 소개
class _FeatureGraphic extends StatelessWidget {
  const _FeatureGraphic({super.key, required this.icon});

  final Uint8List icon;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        width: 1024,
        height: 500,
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, Color(0xFFD08A64)])),
        padding: const EdgeInsets.symmetric(horizontal: 96),
        child: Row(
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(48), child: Image.memory(icon, width: 220, height: 220)),
            const SizedBox(width: 64),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '마음장부',
                    style: TextStyle(
                      fontFamily: 'GowunBatang',
                      fontWeight: FontWeight.w700,
                      fontSize: 84,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '주고받은 마음을 잊지 않도록\n경조사 기록 · 통계 · 어느 기기에서든',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w500,
                      fontSize: 32,
                      height: 1.45,
                      color: Color(0xF2FFFFFF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
