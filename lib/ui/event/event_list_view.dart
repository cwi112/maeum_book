import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/ui/event/event_list_view_model.dart';
import 'package:maeum_book/ui/event/widgets/event_card.dart';

/// 받아요 탭: 내가 연 행사 목록. 행사를 누르면 그 행사에 마음을 준 사람들이 보인다.
///
/// ```
/// [지금까지 받은 마음  4,250,000원  45건]
/// [🔍 행사, 이름 검색                  ]
/// [결혼] 우리 결혼식   12명 · 1,350,000원 >
/// [돌잔치] 첫째 돌잔치  8명 · 520,000원   >
///                               [+ 행사 만들기]
/// ```
class EventListView extends BaseAsyncView<EventListViewModel, EventListState> {
  const EventListView({super.key});

  @override
  AsyncNotifierProvider<EventListViewModel, EventListState> get provider => eventListViewModelProvider;

  @override
  Widget buildView(BuildContext context, WidgetRef ref, EventListState state, EventListViewModel viewModel) {
    final events = state.events;
    final hasNoEvents = state.allEvents.isEmpty;

    return AppListScaffold(
      title: '받아요',
      top: Column(
        children: [
          SummaryCard(
            label: state.isSearching ? '검색 결과' : '지금까지 받은 마음',
            amount: state.total.won,
            count: state.count,
            color: AppColors.received,
          ).paddingOnly(left: AppSpacing.screen, top: AppSpacing.sm, right: AppSpacing.screen),
          // 행사가 하나도 없으면 찾을 게 없으므로 검색창을 숨긴다.
          if (!hasNoEvents)
            SearchField(value: state.query, hint: '행사, 이름 검색', onChanged: viewModel.setQuery)
                .testId(TestIds.eventSearch)
                .paddingOnly(left: AppSpacing.screen, top: AppSpacing.md, right: AppSpacing.screen),
        ],
      ),
      body: events.isEmpty
          ? EmptyView(
              icon: hasNoEvents ? Icons.celebration_outlined : Icons.search_off_rounded,
              title: hasNoEvents ? '아직 만든 행사가 없어요' : '찾는 행사가 없어요',
              message: hasNoEvents ? '결혼식·돌잔치처럼 내 행사를 만들고\n마음을 준 분들을 기록해 보세요' : '행사 이름이나 이름을 바꿔 보세요',
              actionLabel: hasNoEvents ? null : '검색 지우기',
              onAction: hasNoEvents ? null : () => viewModel.setQuery(''),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.md),
              itemCount: events.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) => EventCard(
                key: ValueKey(events[index].event.id),
                summary: events[index],
                onTap: () => context.pushOnce(AppRoutes.eventDetail(events[index].event.id)),
              ),
            ),
      fab: AppListFab(
        label: '행사 만들기',
        icon: Icons.add_rounded,
        onPressed: () => context.pushOnce(AppRoutes.eventNew),
        testId: TestIds.eventAdd,
      ),
    );
  }
}
