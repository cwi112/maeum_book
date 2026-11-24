import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';
import 'package:maeum_book/ui/ledger/ledger_list_view_model.dart';
import 'package:maeum_book/ui/ledger/widgets/ledger_entry_tile.dart';

/// 보내요·받아요 탭 화면. [direction]에 따라 문구·색·데이터만 바뀌고 구조는 같다.
///
/// ```dart
/// const LedgerListView(direction: RecordDirection.sent)      // 보내요
/// const LedgerListView(direction: RecordDirection.received)  // 받아요
/// ```
class LedgerListView extends BaseAsyncView<LedgerListViewModel, LedgerListState> {
  const LedgerListView({super.key, required this.direction});

  final RecordDirection direction;

  /// 방향에 맞는 ViewModel을 연결한다. (family provider에 방향을 넣어 호출)
  @override
  AsyncNotifierProvider<LedgerListViewModel, LedgerListState> get provider => ledgerListViewModelProvider(direction);

  @override
  Widget buildView(BuildContext context, WidgetRef ref, LedgerListState state, LedgerListViewModel viewModel) {
    final texts = _LedgerTexts.of(direction);
    return LedgerListLayout(
      title: texts.title,
      summaryLabel: texts.summaryLabel,
      total: state.total,
      color: direction == RecordDirection.sent ? AppColors.sent : AppColors.received,
      itemCount: state.count,
      itemBuilder: (context, index) => LedgerEntryTile(entry: state.entries[index]),
      emptyIcon: texts.emptyIcon,
      emptyTitle: texts.emptyTitle,
      emptyMessage: texts.emptyMessage,
      addLabel: texts.addLabel,
      // TODO: 기록 입력 화면을 만들면 여기서 연다.
      onAdd: () => context.showSnackBar('곧 추가될 기능이에요'),
    );
  }
}

/// 방향별 화면 문구 모음. 문구를 한곳에 모아 두어 화면 코드에 if문이 흩어지지 않게 한다.
class _LedgerTexts {
  const _LedgerTexts({
    required this.title,
    required this.summaryLabel,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.addLabel,
  });

  factory _LedgerTexts.of(RecordDirection direction) => switch (direction) {
    RecordDirection.sent => const _LedgerTexts(
      title: '보내요',
      summaryLabel: '지금까지 보낸 마음',
      emptyIcon: Icons.outbox_outlined,
      emptyTitle: '아직 보낸 마음이 없어요',
      emptyMessage: '축의금·부조금처럼 보낸 마음을\n하나씩 기록해 보세요',
      addLabel: '보낸 마음 기록',
    ),
    RecordDirection.received => const _LedgerTexts(
      title: '받아요',
      summaryLabel: '지금까지 받은 마음',
      emptyIcon: Icons.move_to_inbox_outlined,
      emptyTitle: '아직 받은 마음이 없어요',
      emptyMessage: '고마운 분들께 받은 마음을\n잊지 않도록 기록해 보세요',
      addLabel: '받은 마음 기록',
    ),
  };

  final String title;
  final String summaryLabel;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;
  final String addLabel;
}
