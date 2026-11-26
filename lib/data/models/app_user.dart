import 'package:supabase_flutter/supabase_flutter.dart' show User;

/// 로그인한 사용자. 화면에서는 Supabase의 User 대신 이 모델만 쓴다. (필요한 값만, 테스트에서 만들기 쉽게)
class AppUser {
  const AppUser({required this.id, required this.provider, this.name, this.linkedProviders = const []});

  /// Supabase의 User를 바꾼다. null이면 null (로그인 안 함).
  static AppUser? fromSupabase(User? user) {
    if (user == null) return null;
    return AppUser(
      id: user.id,
      provider: (user.appMetadata['provider'] as String?) ?? 'unknown',
      name: user.userMetadata?['name'] as String?,
      // 이 계정에 연결된 로그인 방법 전체. 예) ['kakao', 'apple']
      linkedProviders: [...?(user.appMetadata['providers'] as List?)?.whereType<String>()],
    );
  }

  /// 사용자 고유 번호 (UUID)
  final String id;

  /// 처음 가입한 로그인 방법: 'kakao' 또는 'apple'
  final String provider;

  /// 표시 이름 (카카오 닉네임 · Apple 이름). 없을 수 있다.
  final String? name;

  /// 이 계정에 연결된 로그인 방법들. 여기 있는 방법이면 어느 쪽으로 로그인해도 같은 계정이다.
  final List<String> linkedProviders;

  bool isLinked(String provider) => provider == this.provider || linkedProviders.contains(provider);

  /// 화면에 보여줄 로그인 방법 이름
  String get providerLabel => switch (provider) {
    'kakao' => '카카오',
    'apple' => 'Apple',
    _ => provider,
  };
}
