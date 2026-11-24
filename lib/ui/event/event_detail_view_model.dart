import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';

/// 행사 상세 화면의 상태: 행사 정보 + 마음을 준 사람들.
class EventDetailState {
  const EventDetailState({required this.event, required this.entries});

  /// 행사 (지워졌으면 null)
  final LedgerEvent? event;

  /// 받은 기록 (금액 큰 순)
  final List<LedgerEntry> entries;

  int get total => entries.fold(0, (sum, entry) => sum + entry.amount);
}

/// 행사 상세 화면의 ViewModel.
///
/// 행사 Stream과 받은 기록 Stream을 [combineLatest2]로 합쳐서 구독한다.
/// 그래서 행사 이름을 고치거나(행사 Stream), 준 사람을 추가·삭제하면(기록 Stream) 어느 쪽이든 화면이 바로 바뀐다.
class EventDetailViewModel extends BaseAsyncViewModel<EventDetailState> {
  EventDetailViewModel(this.eventId);

  final int eventId;

  EventRepository get _events => ref.read(eventRepositoryProvider);
  LedgerRepository get _ledger => ref.read(ledgerRepositoryProvider);

  @override
  Stream<EventDetailState> watch() {
    final repository = ref.watch(eventRepositoryProvider);
    return combineLatest2(
      repository.watchEvent(eventId),
      repository.watchEntries(eventId),
      (event, entries) => EventDetailState(event: event, entries: entries),
    );
  }

  /// 행사를 지운다. 안의 받은 기록도 함께 지워진다. (화면에서 확인 창을 거친 뒤 호출)
  Future<bool> deleteEvent({ErrorCallback? onError}) async =>
      await runTask(() => _events.remove(eventId), onError: onError) ?? false;

  /// 받은 기록 하나 삭제 / 되돌리기 (EntrySwipeTile이 사용)
  Future<bool> removeEntry(int id, {ErrorCallback? onError}) async =>
      await runTask(() => _ledger.remove(id), onError: onError) ?? false;

  Future<bool> restoreEntry(LedgerEntry entry, {ErrorCallback? onError}) async =>
      await runTask(() async {
        await _ledger.restore(entry);
        return true;
      }, onError: onError) ??
      false;
}

final eventDetailViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<EventDetailViewModel, EventDetailState, int>(EventDetailViewModel.new);
