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

  /// 삭제: 확인 창 없이 바로 지우고, 4초 동안 "되돌리기" 버튼이 있는 토스트를 띄운다. (아이폰 메일과 같은 방식)
  /// 지운 기록(entry)을 그대로 들고 있다가, 되돌리기를 누르면 id까지 똑같이 다시 넣는다.
  Future<void> _delete(BuildContext context, LedgerListViewModel viewModel, LedgerEntry entry) async {
    void showError(Object _) => context.showToast('처리하지 못했어요. 다시 시도해 주세요', type: ToastType.error);

    final removed = await viewModel.remove(entry.id, onError: showError);
    if (!removed || !context.mounted) return;
    context.showToast(
      '${entry.personName}님 기록을 삭제했어요',
      type: ToastType.info,
      actionLabel: '되돌리기',
      onAction: () => viewModel.restore(entry, onError: showError),
    );
  }

  @override
  Widget buildView(BuildContext context, WidgetRef ref, LedgerListState state, LedgerListViewModel viewModel) {
    final texts = _LedgerTexts.of(direction);
    return LedgerListLayout(
      title: texts.title,
      summaryLabel: texts.summaryLabel,
      total: state.total,
      color: direction == RecordDirection.sent ? AppColors.sent : AppColors.received,
      itemCount: state.count,
      itemBuilder: (context, index) {
        final entry = state.entries[index];
        void openEdit() => context.push(AppRoutes.entryEdit(entry.id));
        return SwipeActionTile(
          key: ValueKey(entry.id),
          actions: [
            SwipeAction.edit(onPressed: openEdit, testId: TestIds.entryEdit(entry.id)),
            SwipeAction.delete(
              onPressed: () => _delete(context, viewModel, entry),
              testId: TestIds.entryDelete(entry.id),
            ),
          ],
          child: LedgerEntryTile(entry: entry, onTap: openEdit).testId(TestIds.entryTile(entry.id)),
        );
      },
      emptyIcon: texts.emptyIcon,
      emptyTitle: texts.emptyTitle,
      emptyMessage: texts.emptyMessage,
      addLabel: texts.addLabel,
      addTestId: TestIds.ledgerAdd(direction),
      summaryTestId: TestIds.ledgerSummary(direction),
      onAdd: () => context.push(AppRoutes.entryNew(direction)),
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
