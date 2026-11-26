import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maeum_book/core/errors/network_exception.dart';
import 'package:maeum_book/data/database/app_database.dart';
import 'package:maeum_book/data/photos/photo_files.dart';
import 'package:maeum_book/data/providers.dart';
import 'package:maeum_book/data/remote/remote_ledger_store.dart';
import 'package:maeum_book/data/sync/ledger_sync.dart';

/// 인터넷 연결 여부. 연결 방법(와이파이 · 데이터)이 하나도 없으면 false.
///
/// "연결은 됐는데 너무 느린" 경우는 여기서 알 수 없어서, 서버 작업이 [NetworkException]으로 실패할 때 따로 알린다.
/// 테스트에서는 원하는 값으로 바꿔 끼운다.
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  bool online(List<ConnectivityResult> results) => results.any((r) => r != ConnectivityResult.none);
  yield online(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(online).distinct();
});

/// 회원 장부를 서버에서 받아 오는 일. (로그인 직후 · 앱을 켤 때 · 앱으로 돌아올 때)
///
/// 상태(state) = 마지막으로 받아 오다 인터넷 문제로 실패했는지. 화면 맨 위의 감시 위젯이 이 값을 보고 토스트를 띄운다.
class MemberSyncNotifier extends Notifier<int> {
  /// 인터넷 문제로 실패한 횟수 (바뀔 때마다 화면이 알 수 있게 숫자로 둔다)
  @override
  int build() => 0;

  Future<void>? _running;

  /// 서버의 내 장부로 기기 사본을 바꾼다. 비로그인이면 아무것도 안 한다. 이미 받아 오는 중이면 그 작업을 기다린다.
  ///
  /// 로그인 직후에는 화면용 provider들이 아직 비로그인 값일 수 있어서, 로그인 정보에서 사용자 id를 직접 읽어
  /// 그 계정의 사본 DB를 고른다. (비로그인 DB를 서버 내용으로 덮어쓰는 일이 없게)
  Future<void> pull() {
    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    if (userId == null) return Future.value();
    final db = ref.read(memberDatabaseProvider(userId));
    final remote = ref.read(serverStoreProvider);
    final photos = ref.read(memberPhotoFilesProvider(userId));
    return _running ??= _pullAndTidy(db, remote, photos)
        .catchError((Object error) {
          if (error is NetworkException) {
            state++; // 기기 사본은 그대로 두고, 감시 위젯이 "인터넷 연결" 토스트를 띄운다.
          } else {
            throw error;
          }
        })
        .whenComplete(() => _running = null);
  }

  /// 받아 온 뒤, 다른 기기에서 지운 사진의 캐시 파일을 정리한다.
  static Future<void> _pullAndTidy(AppDatabase db, RemoteLedgerStore remote, PhotoFiles photos) async {
    await LedgerSync.pull(db, remote);
    final ids = {for (final photo in await db.eventPhotoDao.getAll()) photo.id};
    await photos.retainOnly(ids);
  }

  /// 로그아웃 · 탈퇴 뒤 이 기기에 남은 계정 사본을 지운다. (서버 원본은 그대로. 다음 사람이 이 기기에서 볼 수 없게)
  /// [photos]: 그 계정의 사진 캐시 폴더 (같이 비운다)
  static Future<void> clearLocalCopy(AppDatabase db, {PhotoFiles? photos}) async {
    await db.transaction(() async {
      await db.delete(db.eventPhotos).go();
      await db.delete(db.ledgerEntries).go();
      await db.delete(db.events).go();
      await db.delete(db.eventTypes).go();
    });
    await photos?.clear();
  }
}

final memberSyncProvider = NotifierProvider<MemberSyncNotifier, int>(MemberSyncNotifier.new);
