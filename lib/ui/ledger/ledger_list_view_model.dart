import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';

part 'ledger_filter.dart';
part 'ledger_list_state.dart';

/// 보내요·받아요 화면이 **같이 쓰는** ViewModel.
///
/// 두 화면은 "어느 방향(보냄/받음)의 기록을 보여주느냐"만 다르기 때문에, ViewModel을 하나만 만들고
/// [direction]을 바꿔 끼운다. (Riverpod의 family 기능)
///
/// ## 동작 순서
/// 1. 화면이 열리면 [watch]가 Repository의 Stream을 구독한다.
/// 2. DB에서 해당 방향의 기록 목록이 오면 [LedgerListState]로 감싸 화면에 전달한다.
/// 3. 이후 기록이 저장·수정·삭제되면 Drift가 새 목록을 보내 주고, 화면이 자동으로 다시 그려진다.
class LedgerListViewModel extends BaseAsyncViewModel<LedgerListState> {
  LedgerListViewModel(this.direction);

  /// 이 화면이 보여줄 방향 (보냄 / 받음)
  final RecordDirection direction;

  LedgerFilter _filter = LedgerFilter.none;

  LedgerRepository get _repository => ref.read(ledgerRepositoryProvider);

  @override
  Stream<LedgerListState> watch() => ref
      .watch(ledgerRepositoryProvider)
      .watchEntries(direction)
      .map((entries) => LedgerListState(allEntries: entries, filter: _filter, now: DateTime.now()));

  // ── 검색·필터 ──────────────────────────
  /// 조건을 바꾼다. DB를 다시 읽지 않고, 들고 있는 전체 목록에서 다시 거른다.
  void _applyFilter(LedgerFilter filter) {
    _filter = filter;
    final current = state.value;
    if (current != null) state = AsyncData(current.copyWith(filter: filter));
  }

  void setQuery(String query) => _applyFilter(_filter.copyWith(query: query));

  /// 필터 시트에서 고른 기간·종류를 한 번에 적용한다. (검색어는 그대로 둠)
  void setSheetFilter({required LedgerPeriod period, required EventType? eventType}) =>
      _applyFilter(_filter.copyWith(period: period, eventType: () => eventType));

  void clearPeriod() => _applyFilter(_filter.copyWith(period: LedgerPeriod.all));
  void clearEventType() => _applyFilter(_filter.copyWith(eventType: () => null));

  /// 검색어까지 모든 조건을 지운다.
  void resetFilter() => _applyFilter(LedgerFilter.none);

  /// 기록을 삭제한다. 목록·합계·통계는 Stream이 알아서 갱신하므로 따로 상태를 바꿀 필요가 없다.
  Future<bool> remove(int id, {ErrorCallback? onError}) async =>
      await runTask(() => _repository.remove(id), onError: onError) ?? false;

  /// 삭제한 기록을 되돌린다. (삭제 토스트의 "되돌리기" 버튼)
  Future<bool> restore(LedgerEntry entry, {ErrorCallback? onError}) async =>
      await runTask(() async {
        await _repository.restore(entry);
        return true;
      }, onError: onError) ??
      false;
}

/// 방향별 ViewModel provider.
///
/// `ledgerListViewModelProvider(RecordDirection.sent)`처럼 **방향을 넣어 부르면** 그 방향 전용 ViewModel이 만들어진다.
/// 보냄용과 받음용은 서로 다른 인스턴스라 상태가 섞이지 않는다.
final ledgerListViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<LedgerListViewModel, LedgerListState, RecordDirection>(LedgerListViewModel.new);
