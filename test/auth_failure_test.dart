import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:maeum_book/data/data.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 카카오 · Apple · Supabase · 네트워크 예외가 알맞은 이유(AuthFailureType)로 바뀌는지 확인한다.
void main() {
  AuthFailureType typeOf(Object error) => SupabaseAuthRepository.toFailure(error).type;

  group('취소', () {
    test('카카오톡 로그인 창 닫기', () => expect(typeOf(PlatformException(code: 'CANCELED')), AuthFailureType.canceled));
    test(
      '카카오계정 로그인 창 닫기',
      () => expect(typeOf(kakao.KakaoClientException(kakao.ClientErrorCause.cancelled, 'x')), AuthFailureType.canceled),
    );
    test(
      '카카오 동의 화면에서 취소',
      () => expect(typeOf(kakao.KakaoAuthException(kakao.AuthErrorCause.accessDenied, 'x')), AuthFailureType.canceled),
    );
    test(
      'Apple 로그인 창 닫기',
      () => expect(
        typeOf(const SignInWithAppleAuthorizationException(code: AuthorizationErrorCode.canceled, message: 'x')),
        AuthFailureType.canceled,
      ),
    );
  });

  group('네트워크', () {
    test('인터넷 없음', () => expect(typeOf(const SocketException('x')), AuthFailureType.network));
    test('응답 없음', () => expect(typeOf(TimeoutException('x')), AuthFailureType.network));
    test('Supabase 재시도 가능 오류', () => expect(typeOf(AuthRetryableFetchException()), AuthFailureType.network));
  });

  group('설정 문제', () {
    test(
      '카카오 키 해시 · 번들 ID 불일치',
      () => expect(
        typeOf(kakao.KakaoAuthException(kakao.AuthErrorCause.misconfigured, 'x')),
        AuthFailureType.misconfigured,
      ),
    );
    test(
      'Supabase Client ID에 네이티브 앱 키가 없음',
      () => expect(typeOf(const AuthApiException('Unacceptable audience in id_token')), AuthFailureType.misconfigured),
    );
  });

  group('Supabase', () {
    test(
      '만료',
      () => expect(typeOf(const AuthApiException('x', code: 'session_expired')), AuthFailureType.sessionExpired),
    );
    test('세션 없음', () => expect(typeOf(AuthSessionMissingException()), AuthFailureType.sessionExpired));
    test(
      '로그인 방법 꺼짐',
      () => expect(typeOf(const AuthApiException('x', code: 'provider_disabled')), AuthFailureType.providerDisabled),
    );
    test('이용 제한', () => expect(typeOf(const AuthApiException('x', code: 'user_banned')), AuthFailureType.userBanned));
    test('요청 너무 많음', () => expect(typeOf(const AuthApiException('x', statusCode: '429')), AuthFailureType.rateLimited));
    test(
      '탈퇴 중 토큰 만료 (DB)',
      () => expect(
        typeOf(const PostgrestException(message: 'JWT expired', code: 'PGRST301')),
        AuthFailureType.sessionExpired,
      ),
    );
  });

  test('모르는 오류는 unknown', () => expect(typeOf(Exception('?')), AuthFailureType.unknown));
}
