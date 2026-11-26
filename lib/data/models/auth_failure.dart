/// 로그인 · 계정 작업이 실패한 이유. 이유마다 사용자에게 보여줄 문구가 정해져 있다.
///
/// Repository가 카카오 · Apple · Supabase의 여러 예외를 이 하나로 바꿔서 던진다.
/// 그래서 화면은 예외 종류를 몰라도 `failure.message`만 보여주면 된다.
enum AuthFailureType {
  /// 사용자가 로그인 창을 닫거나 동의를 거절함 → 아무것도 띄우지 않는다.
  canceled(''),

  /// 인터넷 연결 없음 · 응답 없음
  network('인터넷 연결을 확인하고 다시 시도해 주세요'),

  /// 로그인이 만료됨 (오래 안 써서 · 다른 곳에서 탈퇴 · 연결 해제) → 다시 로그인 안내
  sessionExpired('로그인이 만료됐어요. 다시 로그인해 주세요'),

  /// 서버에서 이 로그인 방법을 꺼 둠
  providerDisabled('지금은 이 방법으로 로그인할 수 없어요'),

  /// 짧은 시간에 너무 많이 시도함
  rateLimited('요청이 많아요. 잠시 후 다시 시도해 주세요'),

  /// 연결하려는 카카오 · Apple 계정이 이미 다른 마음장부 계정으로 가입돼 있음
  alreadyLinkedElsewhere('이미 다른 마음장부 계정으로 가입된 계정이에요. 그 계정을 탈퇴한 뒤 연결해 주세요'),

  /// 이용이 제한된 계정
  userBanned('이용이 제한된 계정이에요'),

  /// 이 기기에서 지원하지 않음 (예: Apple 로그인을 지원하지 않는 기기)
  notSupported('이 기기에서는 쓸 수 없는 로그인 방법이에요'),

  /// 카카오 · Apple 콘솔 설정 문제 (키 해시 · 번들 ID · OpenID Connect 등). 개발자가 고쳐야 한다.
  misconfigured('로그인 설정에 문제가 있어요. 잠시 후 다시 시도해 주세요'),

  /// 그 밖의 알 수 없는 오류
  unknown('로그인하지 못했어요. 잠시 후 다시 시도해 주세요');

  const AuthFailureType(this.message);

  /// 사용자에게 보여줄 문구 (canceled는 빈 문자열)
  final String message;
}

class AuthFailure implements Exception {
  const AuthFailure(this.type, [this.cause]);

  final AuthFailureType type;

  /// 원래 예외 (로그 · 디버깅용)
  final Object? cause;

  String get message => type.message;

  bool get isCanceled => type == AuthFailureType.canceled;

  @override
  String toString() => 'AuthFailure(${type.name}, cause: $cause)';
}
