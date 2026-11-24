import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';
import 'package:maeum_book/ui/entry/entry_form_view_model.dart';

/// 기록 입력·수정 화면.
///
/// 탭 화면 위에 한 단계 깊이 쌓이는 화면이라, 하단 탭 없이 전체 화면으로 열리고 뒤로 가기로 돌아간다.
/// - 새 기록: `/entry/new/sent`, `/entry/new/received` ([AppRoutes.entryNew])
/// - 수정: `/entry/12/edit` ([AppRoutes.entryEdit]) — 기존 값을 불러오는 동안 로딩이 잠깐 보인다.
///
/// ## 저장 결과 알림
/// - 성공: "기록했어요"/"수정했어요" 토스트를 띄우고 화면을 닫는다. (토스트는 목록 화면 위에 남아 보인다)
/// - 입력 누락: 토스트 없이 해당 칸 아래에 빨간 문구로 알려 준다. (어디를 고쳐야 하는지 바로 보이게)
/// - 저장 실패(DB 오류): 오류 토스트를 띄우고, 입력한 내용은 그대로 둔다.
class EntryFormView extends BaseAsyncView<EntryFormViewModel, EntryFormState> {
  const EntryFormView.create({super.key, required RecordDirection direction})
    : args = (direction: direction, entryId: null);

  /// 수정 화면. 방향은 불러온 기록 값으로 바뀌므로 아무 값이나 넣어도 된다.
  const EntryFormView.edit({super.key, required int entryId})
    : args = (direction: RecordDirection.sent, entryId: entryId);

  final EntryFormArgs args;

  @override
  AsyncNotifierProvider<EntryFormViewModel, EntryFormState> get provider => entryFormViewModelProvider(args);

  Future<void> _save(BuildContext context, EntryFormViewModel viewModel, {required bool isEditing}) async {
    context.hideKeyboard();
    final saved = await viewModel.save(
      onError: (_) => context.showToast('저장하지 못했어요. 잠시 후 다시 시도해 주세요', type: ToastType.error),
    );
    // await 사이에 화면이 닫혔을 수 있으므로 확인한 뒤 context를 쓴다.
    if (saved && context.mounted) {
      context.showToast(isEditing ? '수정했어요' : '기록했어요');
      context.pop();
    }
  }

  /// 수정할 기록을 못 찾으면(이미 삭제 등) 기본 오류 화면 대신 안내 문구를 보여준다.
  @override
  Widget buildError(BuildContext context, Object error, VoidCallback retry) => Scaffold(
    appBar: AppBar(),
    body: const EmptyView(icon: Icons.search_off_rounded, title: '기록을 찾을 수 없어요', message: '이미 삭제되었을 수 있어요'),
  );

  @override
  Widget buildView(BuildContext context, WidgetRef ref, EntryFormState state, EntryFormViewModel viewModel) {
    return Scaffold(
      appBar: AppBar(title: Text(state.isEditing ? '기록 수정' : '마음 기록')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.xl),
        children: [
          // ── 필수 ────────────────────────
          FormSection(
            label: '구분',
            isRequired: true,
            child: SegmentedButton<RecordDirection>(
              segments: [
                for (final value in RecordDirection.values)
                  ButtonSegment(value: value, label: Text(value.actionLabel).testId(TestIds.formDirection(value))),
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
            child: DateField(value: state.date, onChanged: viewModel.setDate).testId(TestIds.formDate),
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
              testIdPrefix: TestIds.formEventType,
            ),
          ),
          const _Gap(),
          FormSection(
            label: state.direction == RecordDirection.sent ? '누구에게' : '누구에게서',
            isRequired: true,
            child: AppTextField(
              initialValue: state.personName,
              hint: '이름',
              maxLength: AppDefine.personNameMaxLength,
              onChanged: viewModel.setPersonName,
              errorText: state.personNameError,
            ).testId(TestIds.formPersonName),
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
              testId: TestIds.formAmount,
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
              testIdPrefix: TestIds.formRelation,
            ),
          ),
          const _Gap(),
          FormSection(
            label: '메모',
            child: AppTextField(
              initialValue: state.memo,
              hint: '예) 대학 동기 결혼식, 화환도 보냄',
              maxLength: AppDefine.memoMaxLength,
              maxLines: 3,
              textInputAction: TextInputAction.newline,
              onChanged: viewModel.setMemo,
            ).testId(TestIds.formMemo),
          ),
        ],
      ),
      // 저장 버튼은 화면 아래에 고정. 저장 중에는 눌리지 않고 로딩 표시로 바뀐다.
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.md),
        child: FilledButton(
          onPressed: state.isSaving ? null : () => _save(context, viewModel, isEditing: state.isEditing),
          child: state.isSaving
              ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
              : Text(state.isEditing ? '수정하기' : '기록하기'),
        ).testId(TestIds.formSave),
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
