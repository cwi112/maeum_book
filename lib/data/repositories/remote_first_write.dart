import 'package:drift/drift.dart';
import 'package:maeum_book/data/database/app_database.dart';
import 'package:maeum_book/data/remote/remote_ledger_store.dart';

/// 저장 · 수정 · 삭제를 "회원이면 서버에도" 반영하는 공통 규칙. (Repository들이 같이 쓴다)
///
/// | 상태 | [remote] | 동작 |
/// |---|---|---|
/// | 비로그인 | null | 기기 DB에만 쓴다 |
/// | 로그인 | 있음 | 기기 DB에 쓰고 **같은 트랜잭션 안에서** 서버에 보낸다. 서버가 실패하면(인터넷 없음 등) 기기 쪽도 취소된다 |
///
/// 그래서 회원의 기기 사본은 항상 서버 원본과 같고, 인터넷이 없으면 저장되지 않는다. ([NetworkException])
mixin RemoteFirstWrite {
  AppDatabase get db;

  RemoteLedgerStore? get remote;

  /// [local]로 기기 DB를 바꾸고, 회원이면 [push]로 서버에 보낸다. 둘 다 성공해야 남는다.
  Future<T> write<T>(Future<T> Function() local, Future<void> Function(T result, RemoteLedgerStore remote) push) {
    final server = remote;
    if (server == null) return local();
    return db.transaction(() async {
      final result = await local();
      await push(result, server);
      return result;
    });
  }

  /// 새 행의 id. 비로그인은 기기 DB가 1, 2, 3… 자동으로, 회원은 서버와 겹치지 않는 임의의 수.
  Value<int> newIdValue() {
    final server = remote;
    return server == null ? const Value.absent() : Value(server.newId());
  }
}
