import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';
import 'package:maeum_book/ui/event/event_form_view_model.dart';

/// 행사 만들기·수정 화면. 경로 `/event/new`, `/event/3/edit`
///
/// 입력 폼 컴포넌트(FormSection, AppTextField, ChoiceChipGroup, DateField)를 기록 입력 화면과 똑같이 재사용한다.
class EventFormView extends BaseAsyncView<EventFormViewModel, EventFormState> {
  const EventFormView({super.key, this.eventId});

  /// null이면 새 행사
  final int? eventId;

  @override
  AsyncNotifierProvider<EventFormViewModel, EventFormState> get provider => eventFormViewModelProvider(eventId);

  Future<void> _save(BuildContext context, EventFormViewModel viewModel, {required bool isEditing}) async {
    context.hideKeyboard();
    final saved = await viewModel.save(onError: (e) => context.showErrorToast(e, '저장하지 못했어요. 잠시 후 다시 시도해 주세요'));
    if (saved && context.mounted) {
      context.showToast(isEditing ? '행사를 수정했어요' : '행사를 만들었어요');
      context.pop();
    }
  }

  @override
  Widget buildError(BuildContext context, Object error, VoidCallback retry) => Scaffold(
    appBar: AppBar(),
    body: const EmptyView(icon: Icons.search_off_rounded, title: '행사를 찾을 수 없어요', message: '이미 삭제되었을 수 있어요'),
  );

  @override
  Widget buildView(BuildContext context, WidgetRef ref, EventFormState state, EventFormViewModel viewModel) {
    final types = ref.watch(eventTypesProvider).value ?? const <EventType>[];
    final typeNames = ref.watch(eventTypeNamesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(state.isEditing ? '행사 수정' : '행사 만들기')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.xl),
        children: [
          FormSection(
            label: '행사 이름',
            isRequired: true,
            child: AppTextField(
              initialValue: state.title,
              hint: '예) 우리 결혼식, 아버지 칠순',
              maxLength: AppDefine.eventTitleMaxLength,
              onChanged: viewModel.setTitle,
              errorText: state.titleError,
            ).testId(TestIds.eventFormTitle),
          ),
          const SizedBox(height: AppSpacing.lg),
          FormSection(
            label: '경조사 종류',
            isRequired: true,
            errorText: state.eventTypeError,
            child: ChoiceChipGroup<int>(
              values: [for (final type in types) type.id],
              selected: state.eventTypeId,
              labelOf: (id) => typeNames[id] ?? '',
              onSelected: viewModel.setEventType,
              testIdPrefix: TestIds.eventFormType,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FormSection(
            label: '날짜',
            isRequired: true,
            child: DateField(value: state.date, onChanged: viewModel.setDate).testId(TestIds.eventFormDate),
          ),
          const SizedBox(height: AppSpacing.lg),
          FormSection(
            label: '메모',
            child: AppTextField(
              initialValue: state.memo,
              hint: '예) 장소, 함께 준비한 사람',
              maxLength: AppDefine.memoMaxLength,
              maxLines: 3,
              textInputAction: TextInputAction.newline,
              onChanged: viewModel.setMemo,
            ).testId(TestIds.eventFormMemo),
          ),
          if (state.isEditing) ...[
            const SizedBox(height: AppSpacing.md),
            const AppText.caption('날짜나 종류를 바꾸면 이 행사에서 받은 기록에도 함께 반영돼요.'),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.md),
        child: FilledButton(
          onPressed: state.isSaving ? null : () => _save(context, viewModel, isEditing: state.isEditing),
          child: state.isSaving
              ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
              : Text(state.isEditing ? '수정하기' : '만들기'),
        ).testId(TestIds.eventFormSave),
      ),
    );
  }
}
