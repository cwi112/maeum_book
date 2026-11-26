import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';
import 'package:maeum_book/ui/event/event_detail_view_model.dart';
import 'package:maeum_book/ui/ledger/widgets/entry_swipe_tile.dart';

/// 행사 상세: 행사 정보와 그 행사에 마음을 준 사람들. 경로 `/event/3`
///
/// - 위: 행사 종류·날짜·메모, 받은 합계와 인원
/// - 목록: 준 사람들 (금액 큰 순). 왼쪽으로 밀어 수정·삭제, 삭제 후 되돌리기
/// - 오른쪽 위 메뉴: 행사 수정 / 행사 삭제(안의 기록도 함께 삭제, 확인 창)
/// - 아래 버튼: 이 행사로 미리 골라진 "받은 마음 기록" 화면을 연다
class EventDetailView extends BaseAsyncView<EventDetailViewModel, EventDetailState> {
  const EventDetailView({super.key, required this.eventId});

  final int eventId;

  @override
  AsyncNotifierProvider<EventDetailViewModel, EventDetailState> get provider => eventDetailViewModelProvider(eventId);

  Future<void> _delete(BuildContext context, EventDetailViewModel viewModel, EventDetailState state) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: '행사를 지울까요?',
      message: state.entries.isEmpty ? '되돌릴 수 없어요.' : '안에 있는 받은 기록 ${state.entries.length}건도 함께 지워지고, 되돌릴 수 없어요.',
      confirmLabel: '지우기',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final deleted = await viewModel.deleteEvent(onError: (e) => context.showErrorToast(e, '처리하지 못했어요. 다시 시도해 주세요'));
    if (deleted && context.mounted) {
      context.showToast('행사를 지웠어요', type: ToastType.info);
      context.pop();
    }
  }

  @override
  Widget buildView(BuildContext context, WidgetRef ref, EventDetailState state, EventDetailViewModel viewModel) {
    final event = state.event;
    if (event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyView(icon: Icons.search_off_rounded, title: '행사를 찾을 수 없어요', message: '이미 삭제되었을 수 있어요'),
      );
    }
    final typeName = ref.watch(eventTypeNamesProvider)[event.eventTypeId] ?? '';

    return AppListScaffold(
      title: event.title,
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.eventEdit(event.id)),
          icon: const Icon(Icons.edit_outlined),
          tooltip: '행사 수정',
        ).testId(TestIds.eventEditButton),
        IconButton(
          onPressed: () => _delete(context, viewModel, state),
          icon: const Icon(Icons.delete_outline_rounded),
          tooltip: '행사 삭제',
        ).testId(TestIds.eventDeleteButton),
      ],
      body: SlidableAutoCloseBehavior(
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.caption('$typeName · ${event.date.toKoreanFullDate} (${event.date.koreanWeekday})'),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        AppText.amountLarge(state.total.won, color: AppColors.received).expanded(),
                        AppText.label('${state.entries.length}명', color: AppColors.textSecondary),
                      ],
                    ),
                    if (event.memo != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      AppText.bodySmall(event.memo!, color: AppColors.textSecondary),
                    ],
                  ],
                ),
              ),
            ).paddingOnly(left: AppSpacing.screen, top: AppSpacing.sm, right: AppSpacing.screen, bottom: AppSpacing.md),
            if (state.entries.isEmpty)
              const EmptyView(
                icon: Icons.volunteer_activism_outlined,
                title: '아직 기록된 마음이 없어요',
                message: '이 행사에 마음을 준 분들을 기록해 보세요',
              )
            else
              for (final entry in state.entries) ...[
                EntrySwipeTile(
                  key: ValueKey(entry.id),
                  entry: entry,
                  onRemove: viewModel.removeEntry,
                  onRestore: viewModel.restoreEntry,
                ),
                const Divider(indent: AppSpacing.screen, endIndent: AppSpacing.screen),
              ],
          ],
        ),
      ),
      fab: AppListFab(
        label: '받은 마음 기록',
        icon: Icons.edit_outlined,
        onPressed: () => context.push(AppRoutes.entryNewForEvent(event.id)),
        testId: TestIds.eventAddEntry,
      ),
    );
  }
}
