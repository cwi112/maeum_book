import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';
import 'package:maeum_book/ui/ledger/ledger_list_view_model.dart';

/// 목록 위 검색·필터 영역.
///
/// ```
/// [🔍 이름, 메모 검색          ] [필터•]
/// [올해 ✕] [결혼 ✕]  초기화              ← 조건이 걸려 있을 때만
/// ```
/// - 검색창: 입력하는 즉시 목록이 걸러진다.
/// - 필터 버튼: 기간·종류를 고르는 시트를 연다. 조건이 걸려 있으면 버튼 위에 점이 찍힌다.
/// - 아래 칩: 지금 걸린 조건. ✕로 하나씩 지우거나 "초기화"로 모두 지운다.
///   (다른 탭에 갔다 와도 조건이 유지되므로, 걸러진 목록이라는 걸 놓치지 않게 항상 보여준다)
class LedgerFilterBar extends StatelessWidget {
  const LedgerFilterBar({super.key, required this.direction, required this.filter, required this.viewModel});

  final RecordDirection direction;
  final LedgerFilter filter;
  final LedgerListViewModel viewModel;

  Future<void> _openSheet(BuildContext context) async {
    final result = await showModalBottomSheet<LedgerFilter>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FilterSheet(initial: filter),
    );
    if (result != null) viewModel.setSheetFilter(period: result.period, eventType: result.eventType);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.md, AppSpacing.screen, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SearchField(
                value: filter.query,
                hint: '이름, 메모 검색',
                onChanged: viewModel.setQuery,
              ).testId(TestIds.ledgerSearch(direction)).expanded(),
              const SizedBox(width: AppSpacing.sm),
              Badge(
                isLabelVisible: filter.hasSheetFilter,
                backgroundColor: AppColors.primary,
                smallSize: 8,
                child: IconButton.outlined(
                  onPressed: () => _openSheet(context),
                  icon: const Icon(Icons.tune_rounded),
                  tooltip: '필터',
                ),
              ).testId(TestIds.ledgerFilter(direction)),
            ],
          ),
          if (filter.isActive)
            Wrap(
              spacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (filter.period != LedgerPeriod.all)
                  InputChip(label: Text(filter.period.label), onDeleted: viewModel.clearPeriod),
                if (filter.eventType != null)
                  InputChip(label: Text(filter.eventType!.label), onDeleted: viewModel.clearEventType),
                TextButton(onPressed: viewModel.resetFilter, child: const Text('초기화')),
              ],
            ).paddingOnly(top: AppSpacing.sm),
        ],
      ),
    );
  }
}

/// 기간·종류를 고르는 아래 시트. "적용"을 눌러야 반영된다. (고르는 도중에는 목록이 바뀌지 않음)
///
/// 시트 안에서만 쓰는 임시 선택값이라 ViewModel이 아닌 이 위젯의 State에 둔다.
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});

  final LedgerFilter initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late LedgerPeriod _period = widget.initial.period;
  late EventType? _eventType = widget.initial.eventType;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText.title('필터'),
            const SizedBox(height: AppSpacing.lg),
            FormSection(
              label: '기간',
              child: ChoiceChipGroup<LedgerPeriod>(
                values: LedgerPeriod.values,
                selected: _period,
                labelOf: (period) => period.label,
                onSelected: (period) => setState(() => _period = period ?? LedgerPeriod.all),
                testIdPrefix: TestIds.filterPeriod,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FormSection(
              label: '경조사 종류',
              child: ChoiceChipGroup<EventType>(
                values: EventType.values,
                selected: _eventType,
                labelOf: (type) => type.label,
                onSelected: (type) => setState(() => _eventType = type),
                allowDeselect: true,
                testIdPrefix: TestIds.filterEventType,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () => setState(() {
                    _period = LedgerPeriod.all;
                    _eventType = null;
                  }),
                  child: const Text('초기화'),
                ).testId(TestIds.filterReset).expanded(),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(LedgerFilter(period: _period, eventType: _eventType)),
                  child: const Text('적용'),
                ).testId(TestIds.filterApply).expanded(flex: 2),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
