import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maeum_book/core/define/app_define.dart';
import 'package:maeum_book/data/database/app_database.dart';
import 'package:maeum_book/data/models/app_user.dart';
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
/// appDatabaseProvider ──▶ ledgerRepositoryProvider ──▶ 각 화면의 ViewModel
/// ```
/// ViewModel에서는 `ref.watch(ledgerRepositoryProvider)`로 Repository를 받아 쓴다.
/// 테스트에서는 `ProviderScope(overrides: [appDatabaseProvider.overrideWithValue(테스트용DB)])`로
/// 실제 DB 대신 메모리 DB를 끼워 넣을 수 있다.

/// 앱 전체에서 공유하는 DB 하나.
///
/// autoDispose가 아닌 일반 Provider라서 앱이 살아 있는 동안 계속 유지된다.
/// 앱이 종료되며 ProviderScope가 정리될 때 [AppDatabase.close]로 DB 연결을 닫는다.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

/// 경조사 기록 Repository.
final ledgerRepositoryProvider = Provider<LedgerRepository>(
  (ref) => LedgerRepository(ref.watch(appDatabaseProvider).ledgerDao),
);

/// 경조사 종류 Repository.
final eventTypeRepositoryProvider = Provider<EventTypeRepository>(
  (ref) => EventTypeRepository(ref.watch(appDatabaseProvider).eventTypeDao),
);

/// 행사 Repository.
final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => EventRepository(ref.watch(appDatabaseProvider).eventDao),
);

/// 앱 버전 확인 Repository. 테스트에서는 가짜로 바꿔 끼운다.
final appUpdateRepositoryProvider = Provider<AppUpdateRepository>(
  (ref) => AppUpdateRepository(versionUrl: AppDefine.versionCheckUrl),
);

/// 로그인 Repository. 테스트에서는 가짜로 바꿔 끼운다. (main.dart에서 Supabase.initialize를 먼저 해야 한다)
final authRepositoryProvider = Provider<AuthRepository>((ref) => SupabaseAuthRepository(Supabase.instance.client));

/// 지금 로그인한 사용자 (로그인 안 했으면 null). 로그인 · 로그아웃하면 이 값을 쓰는 화면이 자동으로 다시 그려진다.
final currentUserProvider = StreamProvider<AppUser?>((ref) => ref.watch(authRepositoryProvider).watchUser());

/// 모든 경조사 종류 (여러 화면이 함께 씀: 입력 칩, 목록의 종류 이름, 필터, 통계).
///
/// StreamProvider라 종류를 추가·이름 변경·삭제하면 이 값을 쓰는 모든 화면이 자동으로 다시 그려진다.
final eventTypesProvider = StreamProvider<List<EventType>>((ref) => ref.watch(eventTypeRepositoryProvider).watchAll());

/// 종류 id → 종류 이름. 목록 한 줄에 "결혼" 같은 이름을 보여줄 때 쓴다. 아직 못 읽었으면 빈 Map.
final eventTypeNamesProvider = Provider<Map<int, String>>(
  (ref) => {for (final type in ref.watch(eventTypesProvider).value ?? const <EventType>[]) type.id: type.name},
);
