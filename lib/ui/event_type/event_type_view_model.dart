import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';

/// 경조사 종류 관리 ViewModel. 상태 = 종류 목록 (DB 구독)
///
/// 추가·이름 변경·삭제하면 DB Stream이 새 목록을 보내서, 이 화면뿐 아니라
/// 입력 화면 칩·목록의 종류 이름·필터·통계까지 앱 전체가 함께 바뀐다. (eventTypesProvider를 같이 구독하므로)
class EventTypeViewModel extends BaseAsyncViewModel<List<EventType>> {
  EventTypeRepository get _repository => ref.read(eventTypeRepositoryProvider);

  @override
  Stream<List<EventType>> watch() => ref.watch(eventTypeRepositoryProvider).watchAll();

  Future<bool> add(String name, {ErrorCallback? onError}) async =>
      await runTask(() async {
        await _repository.add(name);
        return true;
      }, onError: onError) ??
      false;

  Future<bool> rename(int id, String name, {ErrorCallback? onError}) async =>
      await runTask(() async {
        await _repository.rename(id, name);
        return true;
      }, onError: onError) ??
      false;

  /// 이 종류를 쓰는 기록·행사 수 (삭제 확인 문구용)
  Future<int> countUsage(int id) => _repository.countUsage(id);

  Future<bool> remove(EventType type, {ErrorCallback? onError}) async =>
      await runTask(() async {
        await _repository.remove(type);
        return true;
      }, onError: onError) ??
      false;
}

final eventTypeViewModelProvider = AsyncNotifierProvider.autoDispose<EventTypeViewModel, List<EventType>>(
  EventTypeViewModel.new,
);
