import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';
import 'package:maeum_book/ui/entry/entry_form_view_model.dart';

/// 기록 입력 화면 (보낸 마음 / 받은 마음).
///
/// 탭 화면 위에 한 단계 깊이 쌓이는 화면이라, 하단 탭 없이 전체 화면으로 열리고 뒤로 가기로 돌아간다.
/// 경로: `/entry/new/sent`, `/entry/new/received` ([AppRoutes.entryNew])
///
/// ## 저장 결과 알림
/// - 성공: "기록했어요" 토스트를 띄우고 화면을 닫는다. (화면이 닫혀도 토스트는 목록 화면 위에 남아 보인다)
/// - 입력 누락: 토스트 없이 해당 칸 아래에 빨간 문구로 알려 준다. (어디를 고쳐야 하는지 바로 보이게)
/// - 저장 실패(DB 오류): 오류 토스트를 띄우고, 입력한 내용은 그대로 둔다.
class EntryFormView extends BaseView<EntryFormViewModel, EntryFormState> {
  const EntryFormView({super.key, required this.direction});

  final RecordDirection direction;

  @override
  NotifierProvider<EntryFormViewModel, EntryFormState> get provider => entryFormViewModelProvider(direction);

  Future<void> _save(BuildContext context, EntryFormViewModel viewModel) async {
    context.hideKeyboard();
    final saved = await viewModel.save(
      onError: (_) => context.showToast('저장하지 못했어요. 잠시 후 다시 시도해 주세요', type: ToastType.error),
    );
    // await 사이에 화면이 닫혔을 수 있으므로 확인한 뒤 context를 쓴다.
    if (saved && context.mounted) {
      context.showToast('기록했어요');
      context.pop();
    }
  }

  @override
  Widget buildView(BuildContext context, WidgetRef ref, EntryFormState state, EntryFormViewModel viewModel) {
    return Scaffold(
      appBar: AppBar(title: const Text('마음 기록')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.xl),
        children: [
          // ── 필수 ────────────────────────
          FormSection(
            label: '구분',
            isRequired: true,
            child: SegmentedButton<RecordDirection>(
              segments: [
                for (final value in RecordDirection.values) ButtonSegment(value: value, label: Text(value.actionLabel)),
              ],
              selected: {state.direction},
              showSelectedIcon: false,
              onSelectionChanged: (values) => viewModel.setDirection(values.first),
            ),
          ),
          const _Gap(),
          FormSection(
            label: '날짜',
            isRequired: true,
            child: DateField(value: state.date, onChanged: viewModel.setDate),
          ),
          const _Gap(),
          FormSection(
            label: '경조사 종류',
            isRequired: true,
            errorText: state.eventTypeError,
            child: ChoiceChipGroup<EventType>(
              values: EventType.values,
              selected: state.eventType,
              labelOf: (type) => type.label,
              onSelected: viewModel.setEventType,
            ),
          ),
          const _Gap(),
          FormSection(
            label: state.direction == RecordDirection.sent ? '누구에게' : '누구에게서',
            isRequired: true,
            child: AppTextField(
              hint: '이름',
              maxLength: AppDefine.personNameMaxLength,
              onChanged: viewModel.setPersonName,
              errorText: state.personNameError,
            ),
          ),
          const _Gap(),
          FormSection(
            label: '금액',
            isRequired: true,
            child: AmountField(
              value: state.amount,
              onChanged: viewModel.setAmount,
              maxAmount: AppDefine.amountMax,
              errorText: state.amountError,
            ),
          ),

          // ── 선택 ────────────────────────
          const _Gap(),
          FormSection(
            label: '관계',
            child: ChoiceChipGroup<Relation>(
              values: Relation.values,
              selected: state.relation,
              labelOf: (relation) => relation.label,
              onSelected: viewModel.setRelation,
              allowDeselect: true,
            ),
          ),
          const _Gap(),
          FormSection(
            label: '메모',
            child: AppTextField(
              hint: '예) 대학 동기 결혼식, 화환도 보냄',
              maxLength: AppDefine.memoMaxLength,
              maxLines: 3,
              textInputAction: TextInputAction.newline,
              onChanged: viewModel.setMemo,
            ),
          ),
        ],
      ),
      // 저장 버튼은 화면 아래에 고정. 저장 중에는 눌리지 않고 로딩 표시로 바뀐다.
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.md),
        child: FilledButton(
          onPressed: state.isSaving ? null : () => _save(context, viewModel),
          child: state.isSaving
              ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
              : const Text('기록하기'),
        ),
      ),
    );
  }
}

/// 항목 사이 간격
class _Gap extends StatelessWidget {
  const _Gap();

  @override
  Widget build(BuildContext context) => const SizedBox(height: AppSpacing.lg);
}
