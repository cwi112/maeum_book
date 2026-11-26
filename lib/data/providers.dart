import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maeum_book/core/define/app_define.dart';
import 'package:maeum_book/data/database/app_database.dart';
import 'package:maeum_book/data/models/app_user.dart';
import 'package:maeum_book/data/photos/photo_files.dart';
import 'package:maeum_book/data/photos/photo_picker_service.dart';
import 'package:maeum_book/data/photos/photo_processor.dart';
import 'package:maeum_book/data/remote/remote_ledger_store.dart';
import 'package:maeum_book/data/repositories/app_update_repository.dart';
import 'package:maeum_book/data/repositories/auth_repository.dart';
import 'package:maeum_book/data/repositories/event_photo_repository.dart';
import 'package:maeum_book/data/repositories/event_repository.dart';
import 'package:maeum_book/data/repositories/event_type_repository.dart';
import 'package:maeum_book/data/repositories/ledger_repository.dart';
import 'package:maeum_book/data/repositories/sample_mode.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

/// 데이터 계층의 Riverpod provider 모음.
///
/// ## 의존 관계
/// ```
/// currentUserIdProvider ─┬▶ appDatabaseProvider ─┬▶ ledgerRepositoryProvider ──▶ 각 화면의 ViewModel
///                        └▶ remoteStoreProvider ─┘   (회원이면 서버에도 쓴다)
/// ```
/// ## 기록이 남는 곳
/// | 상태 | 기기 DB 파일 | 서버 |
/// |---|---|---|
/// | 비로그인 | `maeum_book.sqlite` (원본) | 안 씀 |
/// | 로그인 | `maeum_book_<사용자 id>.sqlite` (계정별 사본) | **원본** |
/// | 샘플 둘러보기 | 메모리 임시 DB (파일 없음, 앱을 끄면 사라짐) | 안 씀 |
///
/// 로그인 · 로그아웃하면 [currentUserIdProvider]가 바뀌고, DB · Repository · 화면이 그 계정 것으로 자동으로 다시 만들어진다.
/// 테스트에서는 [guestDatabaseProvider] · [memberDatabaseProvider] · [serverStoreProvider]를 메모리 DB · 가짜 서버로 바꿔 끼운다.

/// 지금 로그인한 사용자 id (비로그인이면 null). 같은 사람이면 값이 그대로라 DB를 다시 만들지 않는다.
final currentUserIdProvider = Provider<String?>((ref) {
  ref.watch(currentUserProvider); // 로그인 상태가 바뀔 때마다 다시 계산
  return ref.read(authRepositoryProvider).currentUser?.id;
});

/// 비로그인 기록이 있는 기기 DB. 로그인 중에도 "기록을 계정으로 옮길까요?"에서 읽으려고 따로 둔다.
final guestDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

/// 계정별 기기 사본 DB. (서버 원본을 받아 둔 것, 계정마다 파일이 따로)
final memberDatabaseProvider = Provider.family<AppDatabase, String>((ref, userId) {
  final database = AppDatabase.named('${AppDefine.databaseName}_$userId');
  ref.onDispose(database.close);
  return database;
});

/// 지금 화면들이 쓰는 DB: 샘플 둘러보기 중이면 메모리 임시 DB, 아니면 비로그인 DB 또는 그 계정의 사본 DB.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  if (ref.watch(sampleModeProvider)) return ref.watch(sampleDatabaseProvider);
  final userId = ref.watch(currentUserIdProvider);
  return userId == null ? ref.watch(guestDatabaseProvider) : ref.watch(memberDatabaseProvider(userId));
});

/// 서버 창구 (로그인 여부와 상관없이 하나). 테스트에서는 메모리에 저장하는 가짜로 바꿔 끼운다.
/// (main.dart에서 Supabase.initialize를 먼저 해야 한다)
final serverStoreProvider = Provider<RemoteLedgerStore>((ref) => SupabaseRemoteLedgerStore(Supabase.instance.client));

/// Repository가 쓰는 서버 창구. 로그인했을 때만 있고, 비로그인 · 샘플 둘러보기 중이면 null (서버에 안 씀).
final remoteStoreProvider = Provider<RemoteLedgerStore?>((ref) {
  if (ref.watch(sampleModeProvider) || ref.watch(currentUserIdProvider) == null) return null;
  return ref.watch(serverStoreProvider);
});

// ── 행사 사진 파일 ───────────────────────

/// 사진 폴더들의 뿌리: `<앱 문서 폴더>/photos`. 테스트에서는 임시 폴더로 바꿔 끼운다.
final photoRootProvider = Provider<Future<Directory> Function()>(
  (ref) =>
      () async => Directory('${(await getApplicationDocumentsDirectory()).path}/photos'),
);

PhotoFiles _photoFolder(Ref ref, String name) =>
    PhotoFiles(() async => Directory('${(await ref.read(photoRootProvider)()).path}/$name'));

/// 비회원 사진 (원본)
final guestPhotoFilesProvider = Provider<PhotoFiles>((ref) => _photoFolder(ref, 'guest'));

/// 회원 사진 캐시 (원본은 서버). 계정마다 폴더가 따로다.
final memberPhotoFilesProvider = Provider.family<PhotoFiles, String>(_photoFolder);

/// 샘플 둘러보기 사진 (시작 · 끝낼 때 비운다)
final samplePhotoFilesProvider = Provider<PhotoFiles>((ref) => _photoFolder(ref, 'sample'));

/// 지금 장부의 사진 폴더 ([appDatabaseProvider]와 같은 규칙)
final photoFilesProvider = Provider<PhotoFiles>((ref) {
  if (ref.watch(sampleModeProvider)) return ref.watch(samplePhotoFilesProvider);
  final userId = ref.watch(currentUserIdProvider);
  return userId == null ? ref.watch(guestPhotoFilesProvider) : ref.watch(memberPhotoFilesProvider(userId));
});

/// 사진 줄이기. 테스트에서는 빠른 가짜로 바꿔 끼운다.
final photoProcessorProvider = Provider<PhotoProcessor>((ref) => const PhotoProcessor());

/// 카메라 · 앨범. 테스트에서는 가짜로 바꿔 끼운다.
final photoPickerProvider = Provider<PhotoPickerService>((ref) => PhotoPickerService());

/// 행사 사진 Repository.
final eventPhotoRepositoryProvider = Provider<EventPhotoRepository>(
  (ref) => EventPhotoRepository(
    ref.watch(appDatabaseProvider).eventPhotoDao,
    files: ref.watch(photoFilesProvider),
    remote: ref.watch(remoteStoreProvider),
    processor: ref.watch(photoProcessorProvider),
  ),
);

/// 사진 한 장의 그림 (photoId, 작은 사진인지). 기기에 없으면 회원은 서버에서 받는다. 못 읽으면 null.
final eventPhotoImageProvider = FutureProvider.autoDispose.family<Uint8List?, (int, bool)>(
  (ref, key) => ref.watch(eventPhotoRepositoryProvider).loadImage(key.$1, thumb: key.$2),
);

/// 경조사 기록 Repository.
final ledgerRepositoryProvider = Provider<LedgerRepository>(
  (ref) => LedgerRepository(
    ref.watch(appDatabaseProvider).ledgerDao,
    remote: ref.watch(remoteStoreProvider),
    photoFiles: ref.watch(photoFilesProvider),
  ),
);

/// 경조사 종류 Repository.
final eventTypeRepositoryProvider = Provider<EventTypeRepository>(
  (ref) => EventTypeRepository(ref.watch(appDatabaseProvider).eventTypeDao, remote: ref.watch(remoteStoreProvider)),
);

/// 행사 Repository.
final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => EventRepository(
    ref.watch(appDatabaseProvider).eventDao,
    remote: ref.watch(remoteStoreProvider),
    photoFiles: ref.watch(photoFilesProvider),
  ),
);

/// 앱 버전 확인 Repository. 테스트에서는 가짜로 바꿔 끼운다.
final appUpdateRepositoryProvider = Provider<AppUpdateRepository>(
  (ref) => AppUpdateRepository(versionUrl: AppDefine.versionCheckUrl),
);

/// 로그인 Repository. 테스트에서는 가짜로 바꿔 끼운다. (main.dart에서 Supabase.initialize를 먼저 해야 한다)
final authRepositoryProvider = Provider<AuthRepository>((ref) => SupabaseAuthRepository(Supabase.instance.client));

/// 지금 로그인한 사용자 (로그인 안 했으면 null). 로그인 · 로그아웃하면 이 값을 쓰는 화면이 자동으로 다시 그려진다.
final currentUserProvider = StreamProvider<AppUser?>((ref) => ref.watch(authRepositoryProvider).watchUser());

/// 사용자가 직접 하지 않은 로그아웃(만료 · 연결 해제)이 일어날 때마다 1씩 커지는 번호. → 앱 전체에서 다시 로그인 안내
/// (같은 값이면 Riverpod이 알리지 않으므로, 매번 다른 번호를 보낸다)
final sessionExpiredProvider = StreamProvider<int>((ref) {
  var count = 0;
  return ref.watch(authRepositoryProvider).watchSessionExpired().map((_) => ++count);
});

/// 모든 경조사 종류 (여러 화면이 함께 씀: 입력 칩, 목록의 종류 이름, 필터, 통계).
///
/// StreamProvider라 종류를 추가·이름 변경·삭제하면 이 값을 쓰는 모든 화면이 자동으로 다시 그려진다.
final eventTypesProvider = StreamProvider<List<EventType>>((ref) => ref.watch(eventTypeRepositoryProvider).watchAll());

/// 종류 id → 종류 이름. 목록 한 줄에 "결혼" 같은 이름을 보여줄 때 쓴다. 아직 못 읽었으면 빈 Map.
final eventTypeNamesProvider = Provider<Map<int, String>>(
  (ref) => {for (final type in ref.watch(eventTypesProvider).value ?? const <EventType>[]) type.id: type.name},
);
