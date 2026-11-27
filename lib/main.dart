import 'dart:async';

import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' show KakaoSdk;
import 'package:maeum_book/app.dart';
import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/core/define/app_env.dart';
import 'package:maeum_book/core/utils/font_licenses.dart';
import 'package:maeum_book/data/data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

/// 스플래시(마음장부 로고 화면)를 보여 주는 최소 시간.
/// 너무 빨리 지나가면 깜빡이는 것처럼 보여서, 앱 준비가 금방 끝나도 이만큼은 보여 준다. (준비가 더 걸리면 기다리지 않음)
const _minSplash = Duration(seconds: 1);

Future<void> main() async {
  final started = DateTime.now();
  // runApp 전에 플러그인(카카오 · Supabase)을 쓰려면 Flutter 엔진을 먼저 준비해야 한다.
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // 스플래시는 Flutter가 첫 화면을 그리는 순간 사라진다. 첫 화면 그리기를 잠시 미뤄서 스플래시를 붙잡아 둔다.
  binding.deferFirstFrame();

  // 카카오 로그인 SDK 준비
  await KakaoSdk.init(nativeAppKey: AppEnv.kakaoNativeAppKey);

  // Supabase 준비: 지난번 로그인 정보(세션)도 기기에서 불러온다(자동 로그인). 인터넷이 없어도 앱은 그대로 켜진다.
  // httpClient: 시간이 지나면 요청을 실제로 끊는 연결 (TimeoutHttpClient). 표 15초 · 사진 40초 · 로그인 20초
  await Supabase.initialize(
    url: AppEnv.supabaseUrl,
    publishableKey: AppEnv.supabasePublishableKey,
    httpClient: TimeoutHttpClient(),
  );

  // 글꼴 라이선스를 오픈소스 라이선스 화면에 더한다. (패키지 라이선스는 자동)
  FontLicenses.register();

  // 비회원 모드 같은 간단한 설정값 (첫 화면을 정하려고 앱을 그리기 전에 미리 읽는다)
  final prefs = await SharedPreferences.getInstance();

  // ProviderScope: Riverpod의 모든 provider(ViewModel)가 이 안에서 동작한다.
  runApp(ProviderScope(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)], child: const App()));

  // 켠 지 1초가 될 때까지 기다렸다가 첫 화면을 그린다. → 스플래시가 사라지고 앱 화면이 나온다.
  final remaining = _minSplash - DateTime.now().difference(started);
  if (remaining > Duration.zero) await Future<void>.delayed(remaining);
  binding.allowFirstFrame();
}
