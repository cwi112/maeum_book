import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maeum_book/data/database/app_database.dart';

/// 샘플 둘러보기 모드인지. (설정 → 샘플 데이터로 둘러보기)
///
/// - 켜면 화면들이 **메모리에만 있는 임시 DB**를 쓴다. 기기 DB 파일에도, 서버에도 아무것도 쓰지 않는다.
/// - 끄거나 앱을 종료하면 임시 DB가 통째로 사라진다. 실제 장부(비로그인 기기 DB · 회원 서버)는 그대로.
/// - 기기에 저장하지 않는 값이라 앱을 다시 켜면 항상 꺼진 상태로 시작한다.
class SampleModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void enter() => state = true;

  void exit() {
    if (!state) return;
    state = false;
    ref.invalidate(sampleDatabaseProvider); // 임시 DB를 닫아 메모리에서 지운다.
  }
}

final sampleModeProvider = NotifierProvider<SampleModeNotifier, bool>(SampleModeNotifier.new);

/// 샘플 둘러보기용 임시 DB (메모리 전용, 파일 없음)
final sampleDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
  ref.onDispose(database.close);
  return database;
});
