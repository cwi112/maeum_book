import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart' show PlatformException;
import 'package:http/http.dart' as http;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:maeum_book/core/errors/network_exception.dart';
import 'package:maeum_book/data/models/app_user.dart';
import 'package:maeum_book/data/models/auth_failure.dart';
import 'package:maeum_book/data/remote/timeout_http_client.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 로그인 · 로그아웃 · 탈퇴 Repository.
///
/// ## 로그인 흐름 (카카오 · Apple 같음)
/// ```
/// 1. 임의의 문자열(nonce)을 만들고, 그 해시를 카카오/Apple에 넘겨 로그인 → ID 토큰을 받는다
///    (ID 토큰 안에 해시된 nonce가 들어 있다)
/// 2. ID 토큰 + 원래 nonce를 Supabase에 넘긴다 → Supabase가 서명과 nonce를 확인하고 계정을 만들거나 로그인시킨다
/// ```
/// nonce: 누가 ID 토큰을 가로채 다시 쓰는 걸(재사용 공격) 막는 일회용 값.
///
/// ## 자동 로그인 · 만료
/// - 로그인 정보(세션)는 기기에 저장되고, 앱을 켜면 Supabase가 불러온다 → **자동 로그인**.
/// - 접속 토큰(1시간)은 Supabase가 만료 전에 알아서 새로 받는다. 인터넷이 없을 때는 로그인 상태를 유지한 채 나중에 다시 시도한다.
/// - 갱신이 거절되면(오래 안 씀 · 다른 기기에서 탈퇴 등) Supabase가 로그아웃시키고, [watchSessionExpired]로 알린다 → 화면이 다시 로그인을 안내.
/// - Apple은 사용자가 아이폰 설정에서 "Apple로 로그인" 사용을 끊을 수 있어서 [checkProviderConnection]으로 따로 확인한다.
///
/// ## 오류
/// 모든 메서드는 실패하면 [AuthFailure]만 던진다. (카카오 · Apple · Supabase 예외를 여기서 하나로 바꿈)
///
/// 테스트에서는 [authRepositoryProvider]를 가짜 구현으로 바꿔 끼운다. (실제 서버에 접속하지 않게)
abstract interface class AuthRepository {
  /// 지금 로그인한 사용자. 로그인 안 했으면 null.
  AppUser? get currentUser;

  /// 로그인 상태가 바뀔 때마다(로그인 · 로그아웃 · 탈퇴 · 만료) 새 값을 보낸다. 구독하면 현재 값을 먼저 한 번 보낸다.
  Stream<AppUser?> watchUser();

  /// 사용자가 직접 하지 않은 로그아웃(만료 · 연결 해제)이 일어나면 알린다. → "다시 로그인해 주세요" 안내용
  Stream<void> watchSessionExpired();

  /// 로그인 방법 쪽에서 연결이 끊겼는지 확인한다. (앱을 켤 때 · 다시 열 때 호출)
  /// 끊겼으면 로그아웃시키고 [watchSessionExpired]로 알린다.
  Future<void> checkProviderConnection();

  Future<void> signInWithKakao();

  /// Apple 로그인 (iOS 전용)
  Future<void> signInWithApple();

  /// 지금 계정에 카카오 로그인을 연결한다. 이미 다른 계정으로 가입된 카카오면 [AuthFailureType.alreadyLinkedElsewhere].
  Future<void> linkKakao();

  /// 지금 계정에 Apple 로그인을 연결한다. (iOS 전용)
  Future<void> linkApple();

  Future<void> signOut();

  /// 계정과 서버 데이터를 지운다. (기기 안의 장부는 지우지 않는다)
  /// [beforeDelete]: 계정을 지우기 직전에 할 일. (서버 Storage의 사진 파일은 계정과 함께 지워지지 않아서 먼저 지운다)
  Future<void> deleteAccount({Future<void> Function()? beforeDelete});
}

/// Supabase를 쓰는 실제 구현.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client) {
    // Supabase가 직접 로그아웃시킨 경우(토큰 갱신 거절 · 저장된 세션 손상)만 "만료"로 알린다.
    // 사용자가 로그아웃 버튼을 누른 경우(userInitiated)는 알리지 않는다.
    // Repository는 앱이 살아 있는 동안 하나만 있으므로 구독을 따로 끊지 않는다.
    _auth.onAuthStateChange.listen((state) {
      final reason = state.signOutReason;
      if (state.event == AuthChangeEvent.signedOut &&
          (reason == SignOutReason.sessionExpired || reason == SignOutReason.sessionMissing)) {
        _expiredController.add(null);
      }
    }, onError: (Object error) => _log('auth stream', error));
  }

  final SupabaseClient _client;
  final _expiredController = StreamController<void>.broadcast();

  GoTrueClient get _auth => _client.auth;

  /// 서버 응답을 기다리는 최대 시간. 넘으면 인터넷 문제로 본다.
  /// (Supabase 요청은 TimeoutHttpClient가 시간이 되면 끊는다. 카카오 SDK 요청은 이 시간까지만 기다린다)
  static final _timeout = AppTimeouts.auth + const Duration(seconds: 5);

  @override
  AppUser? get currentUser => AppUser.fromSupabase(_auth.currentUser);

  @override
  Stream<AppUser?> watchUser() async* {
    yield currentUser;
    // 갱신 실패 같은 오류도 이 Stream으로 오는데, 화면에는 "로그인 상태"만 필요하므로 오류는 걸러낸다.
    yield* _auth.onAuthStateChange
        .map((state) => AppUser.fromSupabase(state.session?.user))
        .handleError((Object error) => _log('auth stream', error));
  }

  @override
  Stream<void> watchSessionExpired() => _expiredController.stream;

  @override
  Future<void> checkProviderConnection() async {
    final user = _auth.currentUser;
    if (user == null || kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    if (!(AppUser.fromSupabase(user)?.isLinked('apple') ?? false)) return;

    // Apple 사용자 번호 = Supabase identity의 sub
    final appleUserId = user.identities
        ?.where((identity) => identity.provider == 'apple')
        .map((identity) => identity.identityData?['sub'] as String? ?? identity.id)
        .firstOrNull;
    if (appleUserId == null) return;
    try {
      final state = await SignInWithApple.getCredentialState(appleUserId);
      if (state == CredentialState.revoked || state == CredentialState.notFound) {
        await _signOutQuietly();
        _expiredController.add(null);
      }
    } catch (error) {
      _log('apple credential state', error); // 확인 실패(오프라인 등)는 로그인 상태를 그대로 둔다.
    }
  }

  // ── 로그인 ─────────────────────────────

  @override
  Future<void> signInWithKakao() => _guard(() async {
    final token = await _kakaoIdToken();
    await _auth
        .signInWithIdToken(
          provider: OAuthProvider.kakao,
          idToken: token.idToken,
          accessToken: token.accessToken,
          nonce: token.rawNonce,
        )
        .timeout(_timeout);
    await _saveName(await _kakaoNickname(), onlyIfEmpty: false);
  });

  @override
  Future<void> signInWithApple() => _guard(() async {
    final token = await _appleIdToken();
    await _auth
        .signInWithIdToken(provider: OAuthProvider.apple, idToken: token.idToken, nonce: token.rawNonce)
        .timeout(_timeout);
    await _saveName(token.name, onlyIfEmpty: false);
  });

  // ── 계정 연결 ──────────────────────────
  // 지금 로그인한 계정에 다른 로그인 방법을 붙인다. 붙인 뒤에는 카카오 · Apple 어느 쪽으로 로그인해도 같은 계정이 된다.
  // Supabase 대시보드에서 "Allow manual linking"을 켜 둬야 한다. (docs/AUTH_SETUP.md)

  @override
  Future<void> linkKakao() => _guard(() async {
    _requireSignedIn();
    final token = await _kakaoIdToken();
    await _auth
        .linkIdentityWithIdToken(
          provider: OAuthProvider.kakao,
          idToken: token.idToken,
          accessToken: token.accessToken,
          nonce: token.rawNonce,
        )
        .timeout(_timeout);
    await _saveName(await _kakaoNickname(), onlyIfEmpty: true);
  });

  @override
  Future<void> linkApple() => _guard(() async {
    _requireSignedIn();
    final token = await _appleIdToken();
    await _auth
        .linkIdentityWithIdToken(provider: OAuthProvider.apple, idToken: token.idToken, nonce: token.rawNonce)
        .timeout(_timeout);
    await _saveName(token.name, onlyIfEmpty: true);
  });

  void _requireSignedIn() {
    if (_auth.currentUser == null) throw const AuthFailure(AuthFailureType.sessionExpired);
  }

  // ── 카카오 · Apple에서 ID 토큰 받기 (로그인 · 연결이 같이 씀) ──

  Future<_IdToken> _kakaoIdToken() async {
    final rawNonce = _generateNonce();
    final token = await _kakaoLogin(_sha256(rawNonce));
    final idToken = token.idToken;
    // ID 토큰은 카카오 콘솔에서 OpenID Connect를 켜야 나온다.
    if (idToken == null) throw const AuthFailure(AuthFailureType.misconfigured, 'ID 토큰 없음: OpenID Connect 꺼짐');
    return _IdToken(idToken: idToken, rawNonce: rawNonce, accessToken: token.accessToken);
  }

  /// 카카오톡이 있으면 카카오톡으로 로그인하고, 카카오톡 로그인이 안 되면(로그아웃 상태 · 오래된 버전 등) 카카오계정 로그인으로 넘어간다.
  /// 사용자가 취소했을 때는 넘어가지 않는다. (카카오 공식 권장 흐름)
  Future<kakao.OAuthToken> _kakaoLogin(String hashedNonce) async {
    if (await kakao.isKakaoTalkInstalled()) {
      try {
        return await kakao.UserApi.instance.loginWithKakaoTalk(nonce: hashedNonce);
      } catch (error) {
        if (_isCanceled(error)) rethrow;
        _log('kakao talk login → account login', error);
      }
    }
    return kakao.UserApi.instance.loginWithKakaoAccount(nonce: hashedNonce);
  }

  Future<String?> _kakaoNickname() async {
    try {
      final user = await kakao.UserApi.instance.me();
      return user.kakaoAccount?.profile?.nickname;
    } catch (error) {
      _log('kakao me', error);
      return null;
    }
  }

  Future<_IdToken> _appleIdToken() async {
    if (!await SignInWithApple.isAvailable()) throw const AuthFailure(AuthFailureType.notSupported);
    final rawNonce = _generateNonce();
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      nonce: _sha256(rawNonce),
    );
    final idToken = credential.identityToken;
    if (idToken == null) throw const AuthFailure(AuthFailureType.unknown, 'Apple ID 토큰 없음');
    // Apple은 이름을 "처음 로그인할 때 한 번만" 준다.
    final name = [credential.familyName, credential.givenName].whereType<String>().join();
    return _IdToken(idToken: idToken, rawNonce: rawNonce, name: name.isEmpty ? null : name);
  }

  /// 표시 이름을 Supabase 사용자 정보에 저장한다. 실패해도 로그인 · 연결은 성공으로 본다.
  /// [onlyIfEmpty]: 계정 연결 때는 이미 있는 이름을 덮어쓰지 않는다.
  Future<void> _saveName(String? name, {required bool onlyIfEmpty}) async {
    final current = currentUser?.name;
    if (name == null || name == current || (onlyIfEmpty && current != null)) return;
    try {
      await _auth.updateUser(UserAttributes(data: {'name': name})).timeout(_timeout);
    } catch (error) {
      _log('save name', error);
    }
  }
  // ── 로그아웃 · 탈퇴 ────────────────────

  /// 로그아웃은 인터넷이 없어도 기기에서는 항상 끝난다. (Supabase가 기기 세션을 먼저 지운 뒤 서버에 알린다)
  @override
  Future<void> signOut() => _guard(_signOutQuietly);

  Future<void> _signOutQuietly() async {
    if (currentUser?.isLinked('kakao') ?? false) {
      try {
        await kakao.UserApi.instance.logout(); // 카카오 SDK에 남은 토큰도 지운다.
      } catch (error) {
        _log('kakao logout', error);
      }
    }
    try {
      await _auth.signOut().timeout(_timeout);
    } catch (error) {
      // 기기 세션은 이미 지워졌다. 서버에 알리는 것만 실패한 경우라 로그아웃은 된 것으로 본다.
      _log('supabase signOut', error);
    }
  }

  @override
  Future<void> deleteAccount({Future<void> Function()? beforeDelete}) => _guard(() async {
    if (_auth.currentUser == null) throw const AuthFailure(AuthFailureType.sessionExpired);
    final wasKakao = currentUser?.isLinked('kakao') ?? false;

    // 오래 켜 둔 앱이면 접속 토큰이 만료됐을 수 있어 먼저 새로 받는다. 거절되면 sessionExpired.
    if (_auth.currentSession?.isExpired ?? false) await _auth.refreshSession().timeout(_timeout);

    await beforeDelete?.call();

    // DB 함수 delete_my_account(): 로그인한 본인 계정만 지운다. (supabase/migrations 참고)
    await _client.rpc<void>('delete_my_account').timeout(_timeout);
    if (wasKakao) {
      try {
        await kakao.UserApi.instance.unlink(); // 카카오와 앱의 연결도 끊는다. (실패해도 계정은 이미 지워짐)
      } catch (error) {
        _log('kakao unlink', error);
      }
    }
    await _signOutQuietly();
  });

  // ── 오류 변환 ──────────────────────────

  /// [action]에서 나는 모든 예외를 [AuthFailure]로 바꾼다.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error) {
      final failure = toFailure(error);
      if (!failure.isCanceled) _log('auth failure ${failure.type.name}', error);
      throw failure;
    }
  }

  static bool _isCanceled(Object error) => toFailure(error).isCanceled;

  /// 카카오 · Apple · Supabase · 네트워크 예외를 [AuthFailure]로 바꾼다. (테스트하기 쉽게 static)
  static AuthFailure toFailure(Object error) {
    AuthFailure of(AuthFailureType type) => AuthFailure(type, error);

    return switch (error) {
      AuthFailure() => error,

      // 네트워크
      SocketException() || TimeoutException() || http.ClientException() => of(AuthFailureType.network),
      NetworkException() => of(AuthFailureType.network),
      AuthRetryableFetchException() => of(AuthFailureType.network),

      // 카카오: 취소 (카카오톡 로그인 창 닫기 · 계정 로그인 창 닫기 · 동의 화면에서 취소)
      PlatformException(code: 'CANCELED') => of(AuthFailureType.canceled),
      kakao.KakaoClientException(reason: kakao.ClientErrorCause.cancelled) => of(AuthFailureType.canceled),
      kakao.KakaoClientException(reason: kakao.ClientErrorCause.notSupported) => of(AuthFailureType.notSupported),
      kakao.KakaoAuthException(error: kakao.AuthErrorCause.accessDenied) => of(AuthFailureType.canceled),
      // 카카오: 앱 키 · 키 해시 · 번들 ID · 리다이렉트 URI 등 콘솔 설정 문제 (KOE 오류)
      kakao.KakaoAuthException(
        error: kakao.AuthErrorCause.invalidClient ||
            kakao.AuthErrorCause.misconfigured ||
            kakao.AuthErrorCause.unauthorized ||
            kakao.AuthErrorCause.invalidScope,
      ) =>
        of(AuthFailureType.misconfigured),
      kakao.KakaoException() => of(AuthFailureType.unknown),

      // Apple
      SignInWithAppleAuthorizationException(code: AuthorizationErrorCode.canceled) => of(AuthFailureType.canceled),
      SignInWithAppleNotSupportedException() => of(AuthFailureType.notSupported),
      SignInWithAppleException() => of(AuthFailureType.unknown),

      // Supabase
      AuthSessionMissingException() => of(AuthFailureType.sessionExpired),
      AuthException(:final code, :final statusCode, :final message) => switch (code) {
        'session_expired' ||
        'session_not_found' ||
        'refresh_token_not_found' ||
        'refresh_token_already_used' ||
        'bad_jwt' ||
        'user_not_found' => of(AuthFailureType.sessionExpired),
        'provider_disabled' => of(AuthFailureType.providerDisabled),
        // 연결하려는 카카오 · Apple 계정이 이미 다른 사용자로 가입돼 있음
        'identity_already_exists' => of(AuthFailureType.alreadyLinkedElsewhere),
        // 대시보드에서 Allow manual linking이 꺼져 있음
        'manual_linking_disabled' => of(AuthFailureType.misconfigured),
        'user_banned' => of(AuthFailureType.userBanned),
        'over_request_rate_limit' => of(AuthFailureType.rateLimited),
        'request_timeout' => of(AuthFailureType.network),
        _ when statusCode == '429' => of(AuthFailureType.rateLimited),
        // ID 토큰의 발급 대상(aud) · nonce가 Supabase 설정과 안 맞음 → Client ID 칸 확인
        _ when message.contains('audience') || message.contains('nonce') => of(AuthFailureType.misconfigured),
        _ => of(AuthFailureType.unknown),
      },
      // DB 함수 호출(탈퇴) 중 토큰 만료
      PostgrestException(:final code) when code == 'PGRST301' || code == 'PGRST303' => of(
        AuthFailureType.sessionExpired,
      ),
      PostgrestException() => of(AuthFailureType.unknown),

      _ => of(AuthFailureType.unknown),
    };
  }

  // ── 도우미 ─────────────────────────────

  static void _log(String where, Object error) => debugPrint('[Auth] $where: $error');

  /// 32자리 임의 문자열
  static String _generateNonce() {
    const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(32, (_) => chars[random.nextInt(chars.length)]).join();
  }

  static String _sha256(String input) => sha256.convert(utf8.encode(input)).toString();
}

/// 카카오 · Apple에서 받은 ID 토큰 묶음
class _IdToken {
  const _IdToken({required this.idToken, required this.rawNonce, this.accessToken, this.name});

  final String idToken;

  /// 해시하기 전 원래 nonce (Supabase에 넘김)
  final String rawNonce;
  final String? accessToken;

  /// Apple이 처음 로그인 때만 주는 이름
  final String? name;
}
