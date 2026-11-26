// 스토어 · TestFlight용 스크린샷 생성기.
//
// 실제 앱 화면(샘플 데이터)을 휴대폰 · 태블릿 화면에 넣고 위에 소개 문구를 얹어, 각 스토어 규격 해상도로 PNG를 만든다.
// 일반 테스트(flutter test)에는 포함되지 않는다. 화면을 바꾼 뒤 다시 만들 때만 아래 명령을 실행한다.
//
//   fvm flutter test screenshots/store_screenshots_test.dart --update-goldens
//
// 결과: store_assets/<규격>/01_*.png ...  (규격별 크기는 아래 _specs 참고)
//
// ## 디자인
// - 배경: 테라코타(진한) · 크림(밝은)을 번갈아 써서 스토어에서 넘겨 볼 때 리듬이 생기게
// - 글씨: 작은 꼬리표(무슨 기능인지) → 굵은 제목 두 줄 → 한 줄 설명
// - 기기: 얇은 테두리, 아래쪽은 캔버스 밖으로 살짝 잘려 나가게 (화면이 더 크게 보이고 잘린 목록이 자연스러움)
// - 화환 사진: 실제 사진 대신 이 파일이 그리는 단순한 그림 (저작권 · 초상권 걱정 없음)
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' show DatabaseConnection, Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:maeum_book/app.dart';
import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';
import 'package:maeum_book/data/database/app_database.dart' show EventPhotosCompanion;
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

  /// 틀 안에 그릴 기기 화면 (논리 크기 · 상단/하단 여백 · 화면 둥글기)
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

/// 화면 하나
class _Shot {
  const _Shot(this.file, this.tag, this.title, this.subtitle, this.route, {required this.dark, this.action});

  final String file;

  /// 제목 위 작은 꼬리표 (무슨 기능인지)
  final String tag;
  final String title;
  final String subtitle;
  final String Function(_Ids ids) route;

  /// 테라코타 배경이면 true, 크림 배경이면 false
  final bool dark;

  /// 화면을 연 뒤 할 동작 (예: 엑셀 창 띄우기)
  final Future<void> Function(WidgetTester tester)? action;
}

class _Ids {
  _Ids(this.weddingEventId);
  final int weddingEventId;
}

final _shots = [
  _Shot('01_sent', '마음장부', '주고받은 마음,\n잊지 않게', '축의금 · 부조금을 한곳에 차곡차곡', (_) => AppRoutes.sent, dark: true),
  _Shot('02_received', '받아요', '내 행사별로\n받은 마음 정리', '결혼식 · 돌잔치마다 누가 와 주셨는지', (_) => AppRoutes.received, dark: false),
  _Shot(
    '03_event',
    '화환 · 사진',
    '고마운 분,\n한 분 한 분 기억해요',
    '받은 마음과 화환 사진을 행사 안에 함께',
    (ids) => AppRoutes.eventDetail(ids.weddingEventId),
    dark: true,
  ),
  _Shot('04_stats', '통계', '한 해의 마음 흐름이\n한눈에', '월별 · 종류별 · 관계별 · 많이 주고받은 사람', (_) => AppRoutes.stats, dark: false),
  _Shot(
    '05_excel',
    '엑셀 내보내기',
    '장부는 언제든\n엑셀로 꺼내요',
    '합계까지 계산된 파일을 카톡 · 메일로',
    (_) => AppRoutes.settings,
    dark: true,
    action: (tester) async {
      await tester.tap(find.bySemanticsIdentifier(TestIds.settingsExcelExport));
    },
  ),
  _Shot(
    '06_entry',
    '기록',
    '몇 번의 터치로\n간편하게 기록',
    '날짜 · 종류 · 이름 · 금액만 고르면 끝',
    (_) => AppRoutes.entryNew(RecordDirection.sent),
    dark: false,
  ),
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
  // "OS 기본 서체"를 쓰는 글자: 테스트 환경에는 시스템 서체가 없어서 Pretendard로 대신 그린다.
  for (final family in [
    'FlutterTest',
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

/// 화환 그림 한 장 (JPEG). 받침대 위 둥근 꽃 장식 + 리본. 번호마다 꽃 색이 다르다.
Uint8List _wreathPhoto(int seed, int size) {
  final random = Random(seed);
  const backgrounds = [(246, 238, 229), (241, 236, 228), (247, 236, 234), (236, 240, 232)];
  const flowerSets = [
    [(255, 255, 255), (247, 205, 210), (255, 236, 190)],
    [(255, 255, 255), (250, 222, 160), (240, 180, 150)],
    [(255, 250, 245), (236, 200, 230), (255, 255, 255)],
    [(255, 255, 255), (214, 232, 250), (250, 240, 200)],
  ];
  final (br, bg, bb) = backgrounds[seed % backgrounds.length];
  final image = img.Image(width: size, height: size)..clear(img.ColorRgb8(br, bg, bb));
  final cx = size ~/ 2;
  final cy = (size * 0.42).round();
  final ring = size * 0.27;

  // 받침대 (나무 다리 세 개)
  final wood = img.ColorRgb8(150, 110, 80);
  for (final dx in [-0.18, 0.0, 0.18]) {
    img.drawLine(
      image,
      x1: cx,
      y1: cy + (ring * 0.7).round(), // 꽃 고리 아래에서 시작 (고리 뒤로 숨겨진 받침대)
      x2: cx + (dx * size).round(),
      y2: (size * 0.96).round(),
      color: wood,
      thickness: size / 70,
      antialias: true,
    );
  }
  // 잎 고리
  for (var a = 0.0; a < pi * 2; a += pi / 14) {
    final green = [
      img.ColorRgb8(96, 138, 92),
      img.ColorRgb8(120, 160, 110),
      img.ColorRgb8(80, 120, 84),
    ][random.nextInt(3)];
    img.fillCircle(
      image,
      x: cx + (cos(a) * ring).round(),
      y: cy + (sin(a) * ring).round(),
      radius: (size * 0.075).round(),
      color: green,
      antialias: true,
    );
  }
  // 꽃 (고리 위에 겹겹이)
  final flowers = flowerSets[seed % flowerSets.length];
  for (var a = 0.0; a < pi * 2; a += pi / 9) {
    final (r, g, b) = flowers[random.nextInt(flowers.length)];
    final jitter = (random.nextDouble() - 0.5) * size * 0.04;
    img.fillCircle(
      image,
      x: cx + (cos(a) * (ring + jitter)).round(),
      y: cy + (sin(a) * (ring + jitter)).round(),
      radius: (size * 0.058).round(),
      color: img.ColorRgb8(r, g, b),
      antialias: true,
    );
  }
  // 가운데 리본 띠 두 줄
  final ribbon = img.ColorRgb8(255, 252, 246);
  // 리본: 꽃 고리 아래쪽에 매달려 조금 벌어지며 내려온다. (보낸 분 이름이 적히는 띠)
  final top = cy + (ring * 0.85).round();
  img.fillPolygon(
    image,
    vertices: [
      img.Point(cx - size * 0.05, top),
      img.Point(cx - size * 0.01, top),
      img.Point(cx - size * 0.06, size * 0.9),
      img.Point(cx - size * 0.12, size * 0.88),
    ],
    color: ribbon,
  );
  img.fillPolygon(
    image,
    vertices: [
      img.Point(cx + size * 0.01, top),
      img.Point(cx + size * 0.05, top),
      img.Point(cx + size * 0.12, size * 0.88),
      img.Point(cx + size * 0.06, size * 0.9),
    ],
    color: ribbon,
  );
  return img.encodeJpg(image, quality: 90);
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

        // 회원 장부처럼 보이게 한다. ("이 기기에만 있어요" 비회원 안내가 화면에 나오지 않게)
        const userId = 'store';
        final memberDb = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
        final guestDb = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
        await tester.runAsync(() => SampleData.insertInto(memberDb, now: DateTime(2026, 11, 26)));
        final events = (await tester.runAsync(() => memberDb.select(memberDb.events).get()))!;
        final wedding = events.firstWhere((e) => e.title == '우리 결혼식');
        final ids = _Ids(wedding.id);

        // 결혼식 화환 사진 4장: 받은 기록 앞쪽 네 분이 보낸 것으로 연결
        final photoRoot = Directory.systemTemp.createTempSync('store_photos_');
        await tester.runAsync(() async {
          final givers = await memberDb.eventDao.watchEntries(wedding.id).first;
          final folder = Directory('${photoRoot.path}/$userId')..createSync(recursive: true);
          for (var i = 0; i < 4; i++) {
            final giver = givers[i];
            final photoId = await memberDb.eventPhotoDao.insertPhoto(
              EventPhotosCompanion.insert(
                eventId: wedding.id,
                senderName: Value(giver.personName),
                entryId: Value(giver.id),
              ),
            );
            File('${folder.path}/$photoId.jpg').writeAsBytesSync(_wreathPhoto(i, 800));
            File('${folder.path}/${photoId}_thumb.jpg').writeAsBytesSync(_wreathPhoto(i, 300));
          }
        });

        // ignore: invalid_use_of_visible_for_testing_member
        SharedPreferences.setMockInitialValues({'guest_mode': true});
        final prefs = await SharedPreferences.getInstance();

        final container = ProviderContainer(
          overrides: [
            currentUserIdProvider.overrideWithValue(userId),
            guestDatabaseProvider.overrideWithValue(guestDb),
            memberDatabaseProvider.overrideWith((ref, _) => memberDb),
            serverStoreProvider.overrideWithValue(FakeRemoteLedgerStore()),
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            sharedPreferencesProvider.overrideWithValue(prefs),
            isOnlineProvider.overrideWith((ref) => Stream.value(true)),
            photoRootProvider.overrideWithValue(() async => photoRoot),
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
        container.read(appRouterProvider).go(shot.route(ids));
        await settle(tester);
        await tester.pumpAndSettle();
        if (shot.action != null) {
          await shot.action!(tester);
          await settle(tester);
          await tester.pumpAndSettle();
        }
        // 화환 사진이 그려지도록 실제 시간으로 조금 더 기다린다.
        await settle(tester);
        for (final element in find.byType(Image).evaluate()) {
          final image = (element.widget as Image).image;
          await tester.runAsync(() => precacheImage(image, element));
        }
        await tester.pumpAndSettle();

        await expectLater(find.byKey(canvasKey), matchesGoldenFile('../store_assets/${spec.folder}/${shot.file}.png'));

        await tester.pumpWidget(const SizedBox.shrink());
        container.dispose();
        await tester.runAsync(guestDb.close);
        await tester.runAsync(memberDb.close);
        try {
          photoRoot.deleteSync(recursive: true);
        } on FileSystemException catch (_) {}
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

/// 스크린샷 한 장: 배경 + 꼬리표 · 제목 · 설명 + 아래로 살짝 잘려 나가는 기기 화면
class _StoreFrame extends StatelessWidget {
  const _StoreFrame({super.key, required this.spec, required this.shot, required this.app});

  final _Spec spec;
  final _Shot shot;
  final Widget app;

  static const _cream = Color(0xFFFBF5EE);
  static const _deepPrimary = Color(0xFFB4643E);

  @override
  Widget build(BuildContext context) {
    final canvas = Size(spec.width / spec.pixelRatio, spec.height / spec.pixelRatio);
    final unit = canvas.width / 100; // 캔버스 너비의 1%
    final tablet = spec.isTablet;
    final dark = shot.dark;
    final background = dark ? AppColors.primary : _cream;
    final titleColor = dark ? Colors.white : AppColors.textPrimary;
    final subColor = dark ? const Color(0xE6FFFFFF) : AppColors.textSecondary;
    final tagBackground = dark ? const Color(0x26FFFFFF) : AppColors.primaryLight;
    final tagColor = dark ? Colors.white : _deepPrimary;

    // 기기 화면: 캔버스 너비의 일정 비율, 위치는 글씨 아래. 아래쪽은 캔버스 밖으로 나간다.
    final deviceWidth = canvas.width * (tablet ? 0.78 : 0.84);
    final scale = deviceWidth / (spec.device.size.width + _DeviceFrame.bezel * 2);
    // 안드로이드(9:16)는 아이폰(약 9:19.5)보다 세로가 짧아서 글씨와 겹치지 않게 조금 더 내린다.
    final deviceTop = canvas.height * (tablet ? 0.27 : (canvas.height / canvas.width < 2 ? 0.315 : 0.285));

    return Directionality(
      textDirection: TextDirection.ltr,
      child: ClipRect(
        child: SizedBox(
          width: canvas.width,
          height: canvas.height,
          child: Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: background)),
              // 오른쪽 위의 큰 원: 단색 배경에 은은한 깊이를 준다.
              Positioned(
                right: -canvas.width * 0.28,
                top: -canvas.width * 0.32,
                child: Container(
                  width: canvas.width * 0.9,
                  height: canvas.width * 0.9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dark ? const Color(0x14FFFFFF) : const Color(0x0FC0714A),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: canvas.height * (tablet ? 0.05 : 0.065),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: unit * (tablet ? 1.6 : 2.6),
                        vertical: unit * (tablet ? 0.6 : 1),
                      ),
                      decoration: BoxDecoration(color: tagBackground, borderRadius: BorderRadius.circular(100)),
                      child: Text(
                        shot.tag,
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w600,
                          fontSize: unit * (tablet ? 1.9 : 3.2),
                          color: tagColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    SizedBox(height: unit * (tablet ? 1.8 : 3)),
                    Text(
                      shot.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        fontSize: unit * (tablet ? 5.4 : 8.6),
                        height: 1.25,
                        letterSpacing: -unit * (tablet ? 0.12 : 0.2),
                        color: titleColor,
                      ),
                    ),
                    SizedBox(height: unit * (tablet ? 1.4 : 2.4)),
                    Text(
                      shot.subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                        fontSize: unit * (tablet ? 2.1 : 3.7),
                        letterSpacing: -unit * 0.03,
                        color: subColor,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: deviceTop,
                left: (canvas.width - deviceWidth) / 2,
                width: deviceWidth,
                height: (spec.device.size.height + _DeviceFrame.bezel * 2) * scale,
                child: FittedBox(
                  child: _DeviceFrame(device: spec.device, platform: spec.platform, dark: dark, child: app),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 기기: 얇은 진한 테두리 + 둥근 화면 + 상태 표시줄(9:41) + 부드러운 그림자
class _DeviceFrame extends StatelessWidget {
  const _DeviceFrame({required this.device, required this.platform, required this.dark, required this.child});

  final _Device device;
  final TargetPlatform platform;
  final bool dark;
  final Widget child;

  static const bezel = 9.0;

  @override
  Widget build(BuildContext context) {
    final media = MediaQueryData(
      size: device.size,
      devicePixelRatio: 3,
      padding: EdgeInsets.only(top: device.top, bottom: device.bottom),
      viewPadding: EdgeInsets.only(top: device.top, bottom: device.bottom),
    );
    return Container(
      padding: const EdgeInsets.all(bezel),
      decoration: BoxDecoration(
        color: const Color(0xFF221E1C),
        borderRadius: BorderRadius.circular(device.radius + bezel),
        border: Border.all(color: const Color(0xFF3A3431), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: dark ? const Color(0x55401E0E) : const Color(0x333B2F2A),
            blurRadius: 60,
            offset: const Offset(0, 24),
          ),
        ],
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
      child: ClipRect(
        child: Container(
          width: 1024,
          height: 500,
          color: AppColors.primary,
          child: Stack(
            children: [
              Positioned(
                right: -160,
                top: -220,
                child: Container(
                  width: 620,
                  height: 620,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x14FFFFFF)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 96),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(48),
                        boxShadow: const [BoxShadow(color: Color(0x40401E0E), blurRadius: 40, offset: Offset(0, 16))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(48),
                        child: Image.memory(icon, width: 210, height: 210),
                      ),
                    ),
                    const SizedBox(width: 64),
                    const Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '마음장부',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w700,
                              fontSize: 88,
                              letterSpacing: -2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            '주고받은 마음, 잊지 않게',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w600,
                              fontSize: 34,
                              letterSpacing: -0.5,
                              color: Color(0xF2FFFFFF),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            '경조사 기록 · 화환 사진 · 통계 · 엑셀 내보내기',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w500,
                              fontSize: 24,
                              color: Color(0xCCFFFFFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
