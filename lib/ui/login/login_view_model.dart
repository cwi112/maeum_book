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

  // ── 첫 로그인: 비로그인 기록 연동 ───────

  /// 이 기기에 비로그인 기록이 있으면, 팝업에 보여줄 개수를 돌려준다. 없으면 null (팝업 없음)
  ///
  /// 계정(서버)에 이미 기록이 있는지도 같이 센다. (다른 기기에서 쓰던 계정이면 "합칠까요?"로 묻기 위해)
  /// 서버 개수를 못 세면(인터넷 문제) 0으로 보고 "옮길까요?"로 묻는다.
  Future<GuestImportOffer?> checkGuestRecords() async {
    final local = await LedgerSync.countRecords(ref.read(guestDatabaseProvider));
    if (local.isEmpty) return null;
    var serverEntries = 0;
    try {
      serverEntries = (await ref.read(serverStoreProvider).fetchAll()).entries.length;
    } catch (_) {}
    return GuestImportOffer(localEntries: local.entries, localEvents: local.events, serverEntries: serverEntries);
  }

  /// 비로그인 기록을 계정(서버)으로 옮기고 옮긴 기록 수를 돌려준다. 이어서 계정 장부를 다시 받아 화면에 보여준다.
  /// 인터넷 문제면 [NetworkException] (비로그인 기록은 그대로 남아서 다음 로그인 때 다시 물어본다)
  Future<int> importGuestRecords() async {
    final count = await LedgerSync.importGuest(
      guestDb: ref.read(guestDatabaseProvider),
      remote: ref.read(serverStoreProvider),
    );
    await ref.read(memberSyncProvider.notifier).pull();
    return count;
  }
}

/// 첫 로그인 연동 팝업에 보여줄 개수
class GuestImportOffer {
  const GuestImportOffer({required this.localEntries, required this.localEvents, required this.serverEntries});

  /// 이 기기의 비로그인 기록 · 행사 수
  final int localEntries;
  final int localEvents;

  /// 계정에 이미 있는 기록 수 (0이면 새 계정)
  final int serverEntries;
}

final loginViewModelProvider = NotifierProvider.autoDispose<LoginViewModel, LoginMethod?>(LoginViewModel.new);
