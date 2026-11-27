import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';
import 'package:maeum_book/ui/event/event_detail_view_model.dart';
import 'package:maeum_book/ui/event/widgets/event_photo_strip.dart';
import 'package:maeum_book/ui/ledger/widgets/entry_swipe_tile.dart';

/// 행사 상세: 행사 정보와 그 행사에 마음을 준 사람들. 경로 `/event/3`
///
/// - 위: 행사 종류·날짜·메모, 받은 합계와 인원
/// - 화환 · 사진 줄: 찍기 / 앨범에서 고르기, 누르면 전체 화면 (보낸 분 · 메모)
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
    final deleted = await context.withLoading(
      () => viewModel.deleteEvent(onError: (e) => context.showErrorToast(e, '처리하지 못했어요. 다시 시도해 주세요')),
      message: '행사를 지우는 중이에요',
    );
    if (deleted && context.mounted) {
      context.showToast('행사를 지웠어요', type: ToastType.info);
      context.pop();
    }
  }

  /// 사진 추가: 찍기 / 앨범에서 고르기 → 줄여서 저장 → "n장 넣었어요"
  Future<void> _addPhotos(BuildContext context, EventDetailViewModel viewModel) async {
    final source = await showModalBottomSheet<PhotoSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('사진 찍기'),
              onTap: () => Navigator.of(sheetContext).pop(PhotoSource.camera),
            ).testId(TestIds.photoCamera),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('앨범에서 고르기'),
              subtitle: const Text('여러 장을 한 번에 고를 수 있어요'),
              onTap: () => Navigator.of(sheetContext).pop(PhotoSource.album),
            ).testId(TestIds.photoAlbum),
          ],
        ),
      ),
    );
    if (source == null || !context.mounted) return;
    // 사진 추가 칸 안에서 스피너가 돌고, 저장이 끝날 때까지 다른 곳은 눌리지 않는다.
    final added = await context.withLoading(
      style: LoadingStyle.button,
      () => viewModel.addPhotos(
        source,
        onError: (e) {
          if (!context.mounted) return;
          if (e is PhotoLimitException) {
            context.showToast(e.toString(), type: ToastType.info);
          } else {
            context.showErrorToast(e, '사진을 넣지 못했어요. 다시 시도해 주세요');
          }
        },
      ),
    );
    if (added > 0 && context.mounted) context.showToast('사진 $added장을 넣었어요. 사진을 눌러 보낸 분을 적어 보세요');
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
          onPressed: () => context.pushOnce(AppRoutes.eventEdit(event.id)),
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
            // 화환 · 꽃 사진 줄
            EventPhotoStrip(
              photos: state.photos,
              isAdding: state.isAddingPhotos,
              entryNames: {for (final entry in state.entries) entry.id: entry.personName},
              onAdd: () => _addPhotos(context, viewModel),
              onOpen: (index) => context.pushOnce(AppRoutes.eventPhotos(event.id, index: index)),
            ),
            if (ref.watch(currentUserIdProvider) == null && !ref.watch(sampleModeProvider))
              const AppText.caption('로그인하지 않으면 사진은 이 기기에만 있어요. 앱을 지우면 사라져요')
                  .paddingOnly(left: AppSpacing.screen, top: AppSpacing.xs, right: AppSpacing.screen),
            const SizedBox(height: AppSpacing.md),
            const Divider(indent: AppSpacing.screen, endIndent: AppSpacing.screen),
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
                  linkedPhotoCount: state.photoCountOf(entry.id),
                  showRelation: true, // 행사 안에서는 종류가 모두 같으니 사람마다 다른 관계를 보여 준다
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
        onPressed: () => context.pushOnce(AppRoutes.entryNewForEvent(event.id)),
        testId: TestIds.eventAddEntry,
      ),
    );
  }
}
