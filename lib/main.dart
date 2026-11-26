import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' show KakaoSdk;
import 'package:maeum_book/app.dart';
import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/core/define/app_env.dart';
import 'package:maeum_book/data/data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

Future<void> main() async {
  // runApp 전에 플러그인(카카오 · Supabase)을 쓰려면 Flutter 엔진을 먼저 준비해야 한다.
  WidgetsFlutterBinding.ensureInitialized();

  // 카카오 로그인 SDK 준비
  await KakaoSdk.init(nativeAppKey: AppEnv.kakaoNativeAppKey);

  // Supabase 준비: 지난번 로그인 정보(세션)도 기기에서 불러온다(자동 로그인). 인터넷이 없어도 앱은 그대로 켜진다.
  await Supabase.initialize(url: AppEnv.supabaseUrl, publishableKey: AppEnv.supabasePublishableKey);

  // 비회원 모드 같은 간단한 설정값 (첫 화면을 정하려고 앱을 그리기 전에 미리 읽는다)
  final prefs = await SharedPreferences.getInstance();

  // ProviderScope: Riverpod의 모든 provider(ViewModel)가 이 안에서 동작한다.
  runApp(ProviderScope(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)], child: const App()));
}
