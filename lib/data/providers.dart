import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maeum_book/data/database/app_database.dart';
import 'package:maeum_book/data/repositories/ledger_repository.dart';

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
