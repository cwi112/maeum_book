/// 외부 서비스 연결 값 (Supabase · 카카오).
///
/// 여기 있는 값은 모두 **앱 안에 그대로 들어가는 공개용 값**이라 저장소에 두어도 된다.
/// - Supabase publishable key: 앱에서 쓰라고 만든 공개 키. 데이터는 DB의 RLS(본인 데이터만 접근) 규칙이 지킨다.
/// - 카카오 네이티브 앱 키: AndroidManifest · Info.plist의 URL scheme(`kakao{키}`)에도 들어가야 해서 어차피 공개된다.
///   카카오 콘솔에 등록한 번들 ID · 패키지명 · 키 해시가 맞는 앱에서만 로그인된다.
///
/// ⚠️ 비밀 값(Supabase secret key · DB 비밀번호, 카카오 클라이언트 시크릿)은 절대 여기에 넣지 않는다.
///    클라이언트 시크릿은 Supabase 대시보드에만 저장돼 있다.
abstract final class AppEnv {
  static const String supabaseUrl = 'https://xbffchkgqhiebqtsvyrh.supabase.co';
  static const String supabasePublishableKey = 'sb_publishable_MX17ECzmaKeJ2Lr8DtLpug_ImNz2lUy';

  /// 카카오 네이티브 앱 키. 바꾸면 AndroidManifest.xml · Info.plist의 `kakao{키}` scheme도 같이 바꾼다.
  static const String kakaoNativeAppKey = 'c69743d6fa0bbd629e9ce037cd23a5ea';
}
