import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:maeum_book/data/models/app_user.dart';
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
/// 테스트에서는 [authRepositoryProvider]를 가짜 구현으로 바꿔 끼운다. (실제 서버에 접속하지 않게)
abstract interface class AuthRepository {
  /// 지금 로그인한 사용자. 로그인 안 했으면 null.
  AppUser? get currentUser;

  /// 로그인 상태가 바뀔 때마다(로그인 · 로그아웃 · 탈퇴) 새 값을 보낸다. 구독하면 현재 값을 먼저 한 번 보낸다.
  Stream<AppUser?> watchUser();

  /// 카카오 로그인. 사용자가 취소하면 [LoginCanceledException].
  Future<void> signInWithKakao();

  /// Apple 로그인 (iOS 전용). 사용자가 취소하면 [LoginCanceledException].
  Future<void> signInWithApple();

  Future<void> signOut();

  /// 계정과 서버 데이터를 지운다. (기기 안의 장부는 지우지 않는다)
  Future<void> deleteAccount();
}

/// 사용자가 로그인 창에서 취소함. 오류 토스트를 띄우지 않기 위해 구분한다.
class LoginCanceledException implements Exception {
  const LoginCanceledException();
}

/// Supabase를 쓰는 실제 구현.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  @override
  AppUser? get currentUser => AppUser.fromSupabase(_auth.currentUser);

  @override
  Stream<AppUser?> watchUser() async* {
    yield currentUser;
    yield* _auth.onAuthStateChange.map((state) => AppUser.fromSupabase(state.session?.user));
  }

  @override
  Future<void> signInWithKakao() async {
    final rawNonce = _generateNonce();
    final kakao.OAuthToken token;
    try {
      // 카카오톡이 설치돼 있으면 카카오톡으로, 없으면 카카오계정(웹) 로그인 창으로.
      token = await kakao.isKakaoTalkInstalled()
          ? await kakao.UserApi.instance.loginWithKakaoTalk(nonce: _sha256(rawNonce))
          : await kakao.UserApi.instance.loginWithKakaoAccount(nonce: _sha256(rawNonce));
    } on PlatformException catch (e) {
      if (e.code == 'CANCELED') throw const LoginCanceledException();
      rethrow;
    }
    final idToken = token.idToken;
    // ID 토큰은 카카오 콘솔에서 OpenID Connect를 켜야 나온다.
    if (idToken == null) throw StateError('카카오 ID 토큰이 없어요. 카카오 콘솔에서 OpenID Connect를 켜 주세요');

    await _auth.signInWithIdToken(
      provider: OAuthProvider.kakao,
      idToken: idToken,
      accessToken: token.accessToken,
      nonce: rawNonce,
    );

    // 카카오 닉네임을 Supabase 사용자 정보에 저장해 둔다. (설정 화면 표시용)
    final nickname = await _kakaoNickname();
    if (nickname != null) await _auth.updateUser(UserAttributes(data: {'name': nickname}));
  }

  Future<String?> _kakaoNickname() async {
    try {
      final user = await kakao.UserApi.instance.me();
      return user.kakaoAccount?.profile?.nickname;
    } catch (_) {
      return null; // 닉네임은 없어도 로그인에는 문제없다.
    }
  }

  @override
  Future<void> signInWithApple() async {
    final rawNonce = _generateNonce();
    final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: _sha256(rawNonce),
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) throw const LoginCanceledException();
      rethrow;
    }
    final idToken = credential.identityToken;
    if (idToken == null) throw StateError('Apple ID 토큰이 없어요');

    await _auth.signInWithIdToken(provider: OAuthProvider.apple, idToken: idToken, nonce: rawNonce);

    // Apple은 이름을 "처음 로그인할 때 한 번만" 준다. 받았으면 바로 저장한다.
    final name = [credential.familyName, credential.givenName].whereType<String>().join();
    if (name.isNotEmpty) await _auth.updateUser(UserAttributes(data: {'name': name}));
  }

  @override
  Future<void> signOut() async {
    if (currentUser?.provider == 'kakao') {
      try {
        await kakao.UserApi.instance.logout(); // 카카오 SDK에 남은 토큰도 지운다.
      } catch (_) {}
    }
    await _auth.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    final wasKakao = currentUser?.provider == 'kakao';
    // DB 함수 delete_my_account(): 로그인한 본인 계정만 지운다. (supabase/migrations 참고)
    await _client.rpc<void>('delete_my_account');
    if (wasKakao) {
      try {
        await kakao.UserApi.instance.unlink(); // 카카오와 앱의 연결도 끊는다.
      } catch (_) {}
    }
    await _auth.signOut();
  }

  /// 32자리 임의 문자열
  static String _generateNonce() {
    const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(32, (_) => chars[random.nextInt(chars.length)]).join();
  }

  static String _sha256(String input) => sha256.convert(utf8.encode(input)).toString();
}
