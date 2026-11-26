import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' show KakaoSdk;
import 'package:maeum_book/app.dart';
import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/core/define/app_env.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

Future<void> main() async {
  // runApp 전에 플러그인(카카오 · Supabase)을 쓰려면 Flutter 엔진을 먼저 준비해야 한다.
  WidgetsFlutterBinding.ensureInitialized();

  // 카카오 로그인 SDK 준비
  await KakaoSdk.init(nativeAppKey: AppEnv.kakaoNativeAppKey);

  // Supabase 준비: 지난번 로그인 정보(세션)도 기기에서 불러온다. 인터넷이 없어도 앱은 그대로 켜진다.
  await Supabase.initialize(url: AppEnv.supabaseUrl, publishableKey: AppEnv.supabasePublishableKey);

  // ProviderScope: Riverpod의 모든 provider(ViewModel)가 이 안에서 동작한다.
  runApp(const ProviderScope(child: App()));
}
