import 'dart:async';

import 'package:maeum_book/data/data.dart';

/// 테스트용 가짜 로그인. 실제 카카오 · Apple · Supabase에 접속하지 않고 메모리에서만 로그인 상태를 바꾼다.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository();

  AppUser? _user; // 처음엔 로그아웃 상태
  final _controller = StreamController<AppUser?>.broadcast();

  /// 다음 로그인 시도를 취소로 만들지
  bool cancelNext = false;

  int deleteCount = 0;

  void _set(AppUser? user) {
    _user = user;
    _controller.add(user);
  }

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> watchUser() async* {
    yield _user;
    yield* _controller.stream;
  }

  Future<void> _signIn(String provider) async {
    if (cancelNext) {
      cancelNext = false;
      throw const LoginCanceledException();
    }
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
    deleteCount++;
    _set(null);
  }
}
