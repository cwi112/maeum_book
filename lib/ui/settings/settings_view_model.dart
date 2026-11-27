import 'dart:isolate';

import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/core/utils/app_monitor.dart';
import 'package:maeum_book/data/data.dart';
import 'package:maeum_book/ui/login/login_view_model.dart';

part 'settings_state.dart';

/// 설정 탭의 ViewModel. 상태(state) = [SettingsState].
///
/// 데이터 관리 기능(샘플 넣기·모두 지우기)은 결과 건수만 돌려주고, 목록·통계 화면은 DB Stream으로 자동 갱신된다.
class SettingsViewModel extends BaseViewModel<SettingsState> {
  @override
  SettingsState build() {
    _loadVersion();
    return const SettingsState();
  }

  LedgerRepository get _repository => ref.read(ledgerRepositoryProvider);
  AppUpdateRepository get _updateRepository => ref.read(appUpdateRepositoryProvider);

  /// 설치된 앱 버전을 기기에서 읽어 화면에 보여준다. (앱을 업데이트하면 자동으로 새 버전이 보인다)
  Future<void> _loadVersion() async {
    final version = await runTask(_updateRepository.currentVersion);
    if (version != null && ref.mounted) state = state.copyWith(appVersion: version);
  }

  /// 샘플 둘러보기를 시작한다: 메모리 임시 DB로 바꾸고 샘플 기록을 채운다. 성공하면 넣은 건수, 실패하면 null.
  /// 기기 DB 파일 · 서버에는 아무것도 쓰지 않는다. (저장 · 통신 비용 없음)
  Future<int?> startSampleTour({ErrorCallback? onError}) {
    ref.read(samplePhotoFilesProvider).clear(); // 지난 둘러보기에서 넣은 사진은 비운다
    ref.read(sampleModeProvider.notifier).enter();
    AppMonitor.logEvent(AppEvents.sampleTour);
    // enter 뒤에 읽어야 임시 DB를 쓰는 Repository가 나온다.
    return runTask(ref.read(ledgerRepositoryProvider).addSamples, onError: onError);
  }

  /// 샘플 둘러보기를 끝낸다: 임시 DB를 지우고 내 장부로 돌아간다.
  void endSampleTour() {
    ref.read(sampleModeProvider.notifier).exit();
    ref.read(samplePhotoFilesProvider).clear();
  }

  /// 모든 기록을 지운다. 성공하면 지운 건수, 실패하면 null. (화면에서 확인 창을 거친 뒤 호출)
  Future<int?> clearAll({ErrorCallback? onError}) => runTask(_repository.clearAll, onError: onError);

  // ── 엑셀로 내보내기 ─────────────────────

  /// 지금 장부(비회원 기기 기록 · 회원 계정 사본 · 샘플 중 지금 보이는 것)로 엑셀 파일을 만든다.
  /// 기록이 하나도 없으면 null. 만들다 실패하면 [onError]로 알리고 null.
  ///
  /// 파일은 휴대폰 안에서 만들고 서버에 올리지 않는다. 회원도 기기에 받아 둔 사본에서 읽어서 인터넷이 필요 없다.
  Future<ExcelExportFile?> prepareExcel({ErrorCallback? onError, DateTime? now}) async {
    if (state.isExporting) return null;
    state = state.copyWith(isExporting: true);
    try {
      final entries = await _repository.fetchAllForExport();
      if (entries.isEmpty) return null;
      final events = await ref.read(eventRepositoryProvider).fetchAll();
      final types = await ref.read(eventTypeRepositoryProvider).watchAll().first;
      final exporter = LedgerExcelExporter(
        entries: entries,
        events: events,
        typeNames: {for (final type in types) type.id: type.name},
        exportedAt: now ?? DateTime.now(),
        isSample: ref.read(sampleModeProvider),
      );
      final isMember = ref.read(authRepositoryProvider).currentUser != null;
      return ExcelExportFile(
        // 기록이 수천 건이면 파일 만들기가 오래 걸려서, 화면이 멈추지 않게 다른 일꾼(Isolate)에게 맡긴다.
        bytes: await Isolate.run(exporter.encode),
        fileName: exporter.fileName,
        sentCount: exporter.sentCount,
        receivedCount: exporter.receivedCount,
        mayBeOutdated: isMember && ref.read(isOnlineProvider).value == false,
      );
    } catch (error, stack) {
      AppMonitor.recordError(error, stack, reason: '엑셀 만들기');
      onError?.call(error);
      return null;
    } finally {
      if (ref.mounted) state = state.copyWith(isExporting: false);
    }
  }

  /// 공유 창으로 보낸다. 끝까지 공유했으면 true.
  Future<bool> shareExcel(ExcelExportFile file, {Rect? origin}) async {
    final done = await ref.read(exportFileServiceProvider).share(file.bytes, file.fileName, origin: origin);
    if (done) AppMonitor.logEvent(AppEvents.excelExport, {'action': 'share'});
    return done;
  }

  /// 휴대폰에 저장한다 (저장 위치 고르기). 저장했으면 true.
  Future<bool> saveExcel(ExcelExportFile file) async {
    final done = await ref.read(exportFileServiceProvider).saveToDevice(file.bytes, file.fileName);
    if (done) AppMonitor.logEvent(AppEvents.excelExport, {'action': 'save'});
    return done;
  }

  AuthRepository get _authRepository => ref.read(authRepositoryProvider);

  /// 로그아웃. 성공하면 true. (인터넷이 없어도 기기에서는 로그아웃된다)
  /// 서버의 계정 장부는 그대로 남고, 이 기기에 받아 둔 계정 사본만 지운다. (다음에 이 기기를 쓰는 사람이 못 보게)
  Future<bool> signOut({void Function(AuthFailure failure)? onFailure}) =>
      _runAuth(_authRepository.signOut, onFailure: onFailure, thenClearLocalCopy: true);

  /// 회원 탈퇴: 계정과 서버의 장부를 모두 지운다. 이 기기의 계정 사본도 지운다. (비로그인 기록은 그대로) 성공하면 true.
  Future<bool> deleteAccount({void Function(AuthFailure failure)? onFailure}) => _runAuth(
    // 서버 Storage의 사진 파일은 계정을 지워도 남아서, 계정을 지우기 직전에 먼저 지운다.
    () => _authRepository.deleteAccount(beforeDelete: ref.read(serverStoreProvider).deleteAllPhotoFiles),
    onFailure: onFailure,
    thenClearLocalCopy: true,
  );

  /// 지금 계정에 다른 로그인 방법을 연결한다. 성공하면 true.
  Future<bool> link(LoginMethod provider, {void Function(AuthFailure failure)? onFailure}) async {
    if (state.linkingProvider != null) return false;
    state = state.withLinking(provider);
    final linked = await _runAuth(
      provider == LoginMethod.kakao ? _authRepository.linkKakao : _authRepository.linkApple,
      onFailure: onFailure,
    );
    if (ref.mounted) state = state.withLinking(null);
    return linked;
  }

  /// 계정 작업을 실행하고, 실패하면 이유([AuthFailure])를 알린다.
  Future<bool> _runAuth(
    Future<void> Function() action, {
    void Function(AuthFailure failure)? onFailure,
    bool thenClearLocalCopy = false,
  }) async {
    // 로그아웃하면 화면용 DB가 비로그인 DB로 바뀌므로, 지울 계정 사본을 미리 잡아 둔다.
    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    final memberDb = userId == null ? null : ref.read(memberDatabaseProvider(userId));
    try {
      await action();
      if (thenClearLocalCopy && memberDb != null) {
        await MemberSyncNotifier.clearLocalCopy(memberDb, photos: ref.read(memberPhotoFilesProvider(userId!)));
      }
      return true;
    } on AuthFailure catch (failure) {
      if (!failure.isCanceled) onFailure?.call(failure);
      return false;
    } catch (error, stack) {
      AppMonitor.recordError(error, stack, reason: '계정 작업');
      onFailure?.call(AuthFailure(AuthFailureType.unknown, error));
      return false;
    }
  }

  /// 최신 버전인지 확인한다. 이미 확인 중이면 null.
  Future<AppUpdateResult?> checkUpdate() async {
    if (state.isCheckingUpdate) return null;
    state = state.copyWith(isCheckingUpdate: true);
    final result = await _updateRepository.check();
    if (ref.mounted) state = state.copyWith(isCheckingUpdate: false);
    return result;
  }
}

final settingsViewModelProvider = NotifierProvider.autoDispose<SettingsViewModel, SettingsState>(SettingsViewModel.new);
