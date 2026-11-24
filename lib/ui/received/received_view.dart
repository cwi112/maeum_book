import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/ui/received/received_view_model.dart';

/// 받아요 탭: 내가 받은 마음 목록.
class ReceivedView extends BaseAsyncView<ReceivedViewModel, List<String>> {
  const ReceivedView({super.key});

  @override
  AsyncNotifierProvider<ReceivedViewModel, List<String>> get provider => receivedViewModelProvider;

  @override
  Widget buildView(BuildContext context, WidgetRef ref, List<String> data, ReceivedViewModel viewModel) {
    return LedgerListLayout(
      title: '받아요',
      summaryLabel: '지금까지 받은 마음',
      total: 0,
      color: AppColors.received,
      items: data,
      emptyIcon: Icons.move_to_inbox_outlined,
      emptyTitle: '아직 받은 마음이 없어요',
      emptyMessage: '고마운 분들께 받은 마음을\n잊지 않도록 기록해 보세요',
      addLabel: '받은 마음 기록',
      onAdd: () => context.showSnackBar('곧 추가될 기능이에요'),
    );
  }
}
