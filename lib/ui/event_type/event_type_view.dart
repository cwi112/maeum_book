import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';
import 'package:maeum_book/ui/event_type/event_type_view_model.dart';

/// 설정 → 경조사 종류 관리. 경로 `/settings/event-types`
///
/// - 추가: 오른쪽 위 + 버튼 → 이름 입력 창 (최대 10글자, 같은 이름은 안 됨)
/// - 이름 변경: 줄을 누르면 이름 입력 창. 이 종류를 쓰는 기록은 번호로 연결돼 있어 자동으로 새 이름이 보인다.
/// - 삭제: 왼쪽으로 밀어 삭제. 쓰고 있는 기록·행사가 있으면 "N건이 기타로 옮겨져요" 확인 후 삭제.
/// - "기타"는 지울 수 없다. (지운 종류의 기록이 옮겨 갈 곳이라서)
class EventTypeView extends BaseAsyncView<EventTypeViewModel, List<EventType>> {
  const EventTypeView({super.key});

  @override
  AsyncNotifierProvider<EventTypeViewModel, List<EventType>> get provider => eventTypeViewModelProvider;

  /// 같은 이름이 이미 있으면 DB가 막는다(unique). 그 경우를 알아듣기 쉬운 문구로 바꿔 보여준다.
  static void _showError(BuildContext context, Object error) {
    // 기기 DB는 'UNIQUE', 서버 DB는 'duplicate key'로 알려 준다.
    final text = error.toString();
    final duplicated = text.contains('UNIQUE') || text.contains('duplicate key');
    context.showErrorToast(error, duplicated ? '이미 있는 이름이에요' : '처리하지 못했어요. 다시 시도해 주세요');
  }

  Future<void> _add(BuildContext context, EventTypeViewModel viewModel) async {
    final name = await AppDialog.prompt(
      context,
      title: '종류 추가',
      hint: '예) 환갑, 졸업',
      maxLength: AppDefine.eventTypeNameMaxLength,
      confirmLabel: '추가',
    );
    if (name == null || !context.mounted) return;
    final added = await viewModel.add(name, onError: (e) => _showError(context, e));
    if (added && context.mounted) context.showToast("'$name' 종류를 추가했어요");
  }

  Future<void> _rename(BuildContext context, EventTypeViewModel viewModel, EventType type) async {
    final name = await AppDialog.prompt(
      context,
      title: '이름 바꾸기',
      initialValue: type.name,
      maxLength: AppDefine.eventTypeNameMaxLength,
      confirmLabel: '바꾸기',
    );
    if (name == null || name == type.name || !context.mounted) return;
    await viewModel.rename(type.id, name, onError: (e) => _showError(context, e));
  }

  Future<void> _delete(BuildContext context, EventTypeViewModel viewModel, EventType type) async {
    if (type.isProtected) {
      context.showToast("'${type.name}'은(는) 지울 수 없어요", type: ToastType.info);
      return;
    }
    final usage = await viewModel.countUsage(type.id);
    if (!context.mounted) return;
    final confirmed = await AppDialog.confirm(
      context,
      title: "'${type.name}' 종류를 지울까요?",
      message: usage == 0 ? '이 종류를 쓰는 기록은 없어요.' : '이 종류를 쓰는 기록·행사 $usage건은 \'기타\'로 옮겨져요.',
      confirmLabel: '지우기',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final removed = await viewModel.remove(type, onError: (e) => _showError(context, e));
    if (removed && context.mounted) context.showToast("'${type.name}' 종류를 지웠어요", type: ToastType.info);
  }

  @override
  Widget buildView(BuildContext context, WidgetRef ref, List<EventType> types, EventTypeViewModel viewModel) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('경조사 종류'),
        actions: [
          IconButton(
            onPressed: () => _add(context, viewModel),
            icon: const Icon(Icons.add_rounded),
            tooltip: '종류 추가',
          ).testId(TestIds.eventTypeAdd),
        ],
      ),
      body: SlidableAutoCloseBehavior(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          children: [
            const AppText.caption('눌러서 이름을 바꾸고, 왼쪽으로 밀어서 지울 수 있어요.')
                .paddingSymmetric(horizontal: AppSpacing.screen, vertical: AppSpacing.sm),
            for (final type in types) ...[
              SwipeActionTile(
                key: ValueKey(type.id),
                // "기타"는 밀어도 삭제 버튼이 나오지 않는다.
                actions: [
                  if (!type.isProtected)
                    SwipeAction.delete(
                      onPressed: () => _delete(context, viewModel, type),
                      testId: TestIds.eventTypeDelete(type.id),
                    ),
                ],
                child: ListTile(
                  title: AppText.body(type.name),
                  trailing: type.isProtected
                      ? const AppText.caption('기본')
                      : const Icon(Icons.edit_outlined, size: 18, color: AppColors.textHint),
                  onTap: () => _rename(context, viewModel, type),
                ).testId(TestIds.eventTypeTile(type.id)),
              ),
              const Divider(indent: AppSpacing.screen, endIndent: AppSpacing.screen),
            ],
          ],
        ),
      ),
    );
  }
}
