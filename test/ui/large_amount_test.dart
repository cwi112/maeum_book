import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:maeum_book/app.dart';
import 'package:maeum_book/core/define/app_define.dart';
import 'package:maeum_book/core/define/app_routes.dart';
import 'package:maeum_book/data/data.dart';
import 'package:maeum_book/router/app_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_auth_repository.dart';
import '../fakes/fake_remote_ledger_store.dart';

/// 금액이 아주 클 때(한 건 최대 1억, 합계 수십억) 좁은 화면 · 큰 글씨에서도 화면이 겹치거나 넘치지 않는지 확인한다.
/// 넘치면 Flutter가 "RenderFlex overflowed" 오류를 내서 테스트가 실패한다.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  for (final (width, textScale) in [(320.0, 1.0), (360.0, 1.3)]) {
    testWidgets('큰 금액: 폭 $width · 글씨 $textScale배에서 모든 화면이 넘치지 않는다', (tester) async {
      tester.view.physicalSize = Size(width * 3, 2000 * 3);
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
      final repo = LedgerRepository(db.ledgerDao);
      final events = EventRepository(db.eventDao);
      late int eventId;
      await tester.runAsync(() async {
        eventId = await events.add(title: '아주 긴 이름의 우리 결혼식 피로연 행사', eventTypeId: 1, date: DateTime(2026, 5, 10));
        for (var i = 0; i < 30; i++) {
          for (final direction in RecordDirection.values) {
            await repo.add(
              direction: direction,
              eventTypeId: (i % 7) + 1,
              eventId: direction == RecordDirection.received ? eventId : null,
              personName: '홍길동김철수이영희박민수$i',
              amount: AppDefine.amountMax - i,
              date: DateTime(2026, (i % 12) + 1, 1),
              relation: Relation.values[i % Relation.values.length],
              memo: '아주 긴 메모가 들어가는 경우를 확인하기 위한 문장입니다',
            );
          }
        }
      });

      SharedPreferences.setMockInitialValues({'guest_mode': true});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          guestDatabaseProvider.overrideWithValue(db),
          memberDatabaseProvider.overrideWith((ref, _) => db),
          serverStoreProvider.overrideWithValue(FakeRemoteLedgerStore()),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          sharedPreferencesProvider.overrideWithValue(prefs),
          isOnlineProvider.overrideWith((ref) => Stream.value(true)),
        ],
      );
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const App()));

      Future<void> settle() async {
        for (var i = 0; i < 6; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      final failures = <String>[];
      final router = container.read(appRouterProvider);
      for (final route in [AppRoutes.sent, AppRoutes.received, AppRoutes.eventDetail(eventId), AppRoutes.stats]) {
        router.go(route);
        await settle();
        final error = tester.takeException();
        if (error != null) failures.add('$route: $error');
      }
      // 통계는 길어서 아래까지 내려 본다
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
      await settle();
      final bottomError = tester.takeException();
      if (bottomError != null) failures.add('통계 아래쪽: $bottomError');
      expect(failures, isEmpty, reason: failures.join('\n'));

      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await tester.runAsync(db.close);
    });
  }
}
