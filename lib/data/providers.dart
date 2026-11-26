import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maeum_book/core/define/app_define.dart';
import 'package:maeum_book/data/database/app_database.dart';
import 'package:maeum_book/data/models/app_user.dart';
import 'package:maeum_book/data/remote/remote_ledger_store.dart';
import 'package:maeum_book/data/repositories/app_update_repository.dart';
import 'package:maeum_book/data/repositories/auth_repository.dart';
import 'package:maeum_book/data/repositories/event_repository.dart';
import 'package:maeum_book/data/repositories/event_type_repository.dart';
import 'package:maeum_book/data/repositories/ledger_repository.dart';
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

/// 지금 화면들이 쓰는 DB: 비로그인이면 비로그인 DB, 로그인이면 그 계정의 사본 DB.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return userId == null ? ref.watch(guestDatabaseProvider) : ref.watch(memberDatabaseProvider(userId));
});

/// 서버 창구 (로그인 여부와 상관없이 하나). 테스트에서는 메모리에 저장하는 가짜로 바꿔 끼운다.
/// (main.dart에서 Supabase.initialize를 먼저 해야 한다)
final serverStoreProvider = Provider<RemoteLedgerStore>((ref) => SupabaseRemoteLedgerStore(Supabase.instance.client));

/// Repository가 쓰는 서버 창구. 로그인했을 때만 있고, 비로그인이면 null (기기 DB에만 저장).
final remoteStoreProvider = Provider<RemoteLedgerStore?>(
  (ref) => ref.watch(currentUserIdProvider) == null ? null : ref.watch(serverStoreProvider),
);

/// 경조사 기록 Repository.
final ledgerRepositoryProvider = Provider<LedgerRepository>(
  (ref) => LedgerRepository(ref.watch(appDatabaseProvider).ledgerDao, remote: ref.watch(remoteStoreProvider)),
);

/// 경조사 종류 Repository.
final eventTypeRepositoryProvider = Provider<EventTypeRepository>(
  (ref) => EventTypeRepository(ref.watch(appDatabaseProvider).eventTypeDao, remote: ref.watch(remoteStoreProvider)),
);

/// 행사 Repository.
final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => EventRepository(ref.watch(appDatabaseProvider).eventDao, remote: ref.watch(remoteStoreProvider)),
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
