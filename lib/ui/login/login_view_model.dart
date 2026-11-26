import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';

/// 로그인 방법
enum LoginMethod { kakao, apple }

/// 로그인 화면 ViewModel. 상태(state) = 지금 진행 중인 로그인 방법 (없으면 null).
///
/// 로그인 중에는 버튼을 다시 누를 수 없게 하고, 누른 버튼에만 로딩 표시를 한다.
class LoginViewModel extends BaseViewModel<LoginMethod?> {
  @override
  LoginMethod? build() => null;

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  /// 로그인한다. 성공하면 true, 취소 · 실패하면 false. 실패(취소 제외)는 [onError]로 알린다.
  Future<bool> signIn(LoginMethod method, {ErrorCallback? onError}) async {
    if (state != null) return false;
    state = method;
    try {
      switch (method) {
        case LoginMethod.kakao:
          await _repository.signInWithKakao();
        case LoginMethod.apple:
          await _repository.signInWithApple();
      }
      return true;
    } on LoginCanceledException {
      return false; // 사용자가 닫은 것이므로 오류로 보지 않는다.
    } catch (error) {
      onError?.call(error);
      return false;
    } finally {
      if (ref.mounted) state = null;
    }
  }
}

final loginViewModelProvider = NotifierProvider.autoDispose<LoginViewModel, LoginMethod?>(LoginViewModel.new);
