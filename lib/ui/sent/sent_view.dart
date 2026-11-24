import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/ui/sent/sent_view_model.dart';

/// 보내요 탭: 내가 보낸 마음(축의금·부조금 등) 목록.
class SentView extends BaseAsyncView<SentViewModel, List<String>> {
  const SentView({super.key});

  @override
  AsyncNotifierProvider<SentViewModel, List<String>> get provider => sentViewModelProvider;

  @override
  Widget buildView(BuildContext context, WidgetRef ref, List<String> data, SentViewModel viewModel) {
    return LedgerListLayout(
      title: '보내요',
      summaryLabel: '지금까지 보낸 마음',
      total: 0,
      color: AppColors.sent,
      items: data,
      emptyIcon: Icons.outbox_outlined,
      emptyTitle: '아직 보낸 마음이 없어요',
      emptyMessage: '축의금·부조금처럼 보낸 마음을\n하나씩 기록해 보세요',
      addLabel: '보낸 마음 기록',
      onAdd: () => context.showSnackBar('곧 추가될 기능이에요'),
    );
  }
}
