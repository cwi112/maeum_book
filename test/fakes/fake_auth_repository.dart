import 'dart:async';

import 'package:maeum_book/data/data.dart';

/// 테스트용 가짜 로그인. 실제 카카오 · Apple · Supabase에 접속하지 않고 메모리에서만 로그인 상태를 바꾼다.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository();

  AppUser? _user; // 처음엔 로그아웃 상태
  final _userController = StreamController<AppUser?>.broadcast();
  final _expiredController = StreamController<void>.broadcast();

  /// 다음 작업(로그인 · 탈퇴)을 이 이유로 실패시킨다. (한 번 쓰면 비워짐)
  AuthFailureType? failNext;

  int deleteCount = 0;

  void _set(AppUser? user) {
    _user = user;
    _userController.add(user);
  }

  void _throwIfFailNext() {
    final type = failNext;
    if (type == null) return;
    failNext = null;
    throw AuthFailure(type);
  }

  /// 서버가 로그인을 만료시킨 상황을 흉내 낸다. (토큰 갱신 거절)
  void expireSession() {
    _set(null);
    _expiredController.add(null);
  }

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> watchUser() async* {
    yield _user;
    yield* _userController.stream;
  }

  @override
  Stream<void> watchSessionExpired() => _expiredController.stream;

  @override
  Future<void> checkProviderConnection() async {}

  Future<void> _signIn(String provider) async {
    _throwIfFailNext();
    _set(AppUser(id: 'test-user', provider: provider, name: '홍길동'));
  }

  @override
  Future<void> signInWithKakao() => _signIn('kakao');

  @override
  Future<void> signInWithApple() => _signIn('apple');

  @override
  Future<void> signOut() async => _set(null);

  @override
  Future<void> deleteAccount() async {
    _throwIfFailNext();
    deleteCount++;
    _set(null);
  }
}
