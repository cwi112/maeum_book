import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';

/// 로그인 방법 (로그인 · 계정 연결에 같이 쓴다)
enum LoginMethod {
  kakao('kakao', '카카오'),
  apple('apple', 'Apple');

  const LoginMethod(this.id, this.label);

  /// Supabase에서 쓰는 이름 ('kakao' · 'apple')
  final String id;
  final String label;

  /// 이 기기에서 쓸 수 있는 로그인 방법. Apple 로그인은 iOS에서만. (Android는 카카오만)
  static List<LoginMethod> get availableHere =>
      defaultTargetPlatform == TargetPlatform.iOS ? LoginMethod.values : const [LoginMethod.kakao];
}

/// 로그인 화면 ViewModel. 상태(state) = 지금 진행 중인 로그인 방법 (없으면 null).
///
/// 로그인 중에는 버튼을 다시 누를 수 없게 하고, 누른 버튼에만 로딩 표시를 한다.
class LoginViewModel extends BaseViewModel<LoginMethod?> {
  @override
  LoginMethod? build() => null;

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  /// 로그인한다. 성공하면 true. 실패하면 false를 돌려주고, 취소가 아니면 [onFailure]로 이유를 알린다.
  ///
  /// 비회원으로 쓰던 기록은 기기 DB에 그대로 남는다. (로그인은 계정만 만들 뿐 기록을 지우지 않는다)
  Future<bool> signIn(LoginMethod method, {void Function(AuthFailure failure)? onFailure}) async {
    if (state != null) return false; // 이미 로그인 진행 중 (버튼 연타)
    state = method;
    try {
      switch (method) {
        case LoginMethod.kakao:
          await _repository.signInWithKakao();
        case LoginMethod.apple:
          await _repository.signInWithApple();
      }
      // 회원이 됐으므로 비회원 표시는 지운다. (나중에 로그아웃하면 시작 화면이 다시 나오게)
      await ref.read(guestModeProvider.notifier).exit();
      return true;
    } on AuthFailure catch (failure) {
      if (!failure.isCanceled) onFailure?.call(failure); // 사용자가 닫은 것은 오류로 보지 않는다.
      return false;
    } catch (error) {
      onFailure?.call(AuthFailure(AuthFailureType.unknown, error));
      return false;
    } finally {
      if (ref.mounted) state = null;
    }
  }

  /// "로그인 없이 시작하기"
  Future<void> continueAsGuest() => ref.read(guestModeProvider.notifier).enter();
}

final loginViewModelProvider = NotifierProvider.autoDispose<LoginViewModel, LoginMethod?>(LoginViewModel.new);
