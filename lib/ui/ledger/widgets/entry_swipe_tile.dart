import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';
import 'package:maeum_book/ui/ledger/widgets/ledger_entry_tile.dart';

/// 기록 한 줄 + 왼쪽으로 밀면 나오는 수정·삭제 버튼. (보내요 목록, 행사 상세에서 함께 씀)
///
/// - 누르거나 "수정": 수정 화면으로 이동
/// - "삭제": 바로 지우고, 4초 동안 "되돌리기" 토스트를 띄운다. 지운 기록을 들고 있다가 그대로 다시 넣는다.
/// - 이 사람과 연결된 화환 사진이 있으면([linkedPhotoCount] > 0): **먼저 확인 창**을 띄우고, 사진도 함께 지운다.
///   사진은 되살릴 수 없어서 이때는 "되돌리기"를 주지 않는다.
///
/// 실제 삭제·복원은 화면의 ViewModel이 하도록 [onRemove]·[onRestore]로 받는다. (이 위젯은 화면 동작만 담당)
class EntrySwipeTile extends ConsumerWidget {
  const EntrySwipeTile({
    super.key,
    required this.entry,
    required this.onRemove,
    required this.onRestore,
    this.linkedPhotoCount = 0,
    this.showRelation = false,
  });

  /// 이 사람(이 기록)과 연결된 화환 · 꽃 사진 수. 1장 이상이면 이름 옆에 꽃 표시, 지울 때 확인 창
  final int linkedPhotoCount;

  /// true면 줄 앞 배지에 경조사 종류 대신 관계를 보여 준다. (행사 상세: 종류는 행사가 이미 알려 줌)
  final bool showRelation;

  final LedgerEntry entry;

  /// 삭제. 성공하면 true. (연결된 사진도 함께 지우는 것은 ViewModel 몫)
  final Future<bool> Function(int id, {ErrorCallback? onError}) onRemove;

  /// 되돌리기
  final Future<bool> Function(LedgerEntry entry, {ErrorCallback? onError}) onRestore;

  Future<void> _delete(BuildContext context) async {
    void showError(Object e) => context.showErrorToast(e, '처리하지 못했어요. 다시 시도해 주세요');
    final withPhotos = linkedPhotoCount > 0;
    if (withPhotos) {
      final confirmed = await AppDialog.confirm(
        context,
        title: '${entry.personName}님 기록을 지울까요?',
        message: '이 분이 보낸 화환 · 꽃 사진 $linkedPhotoCount장도 함께 지워지고, 되돌릴 수 없어요.',
        confirmLabel: '사진까지 지우기',
        isDestructive: true,
      );
      if (!confirmed || !context.mounted) return;
    }

    // 지운 줄은 화면에서 사라지므로, 되돌리기 때 쓸 로딩 막을 미리 잡아 둔다.
    final loading = context.loadingRunner;
    final removed = await loading(() => onRemove(entry.id, onError: showError), message: '지우는 중이에요');
    if (!removed || !context.mounted) return;
    if (withPhotos) {
      context.showToast('${entry.personName}님 기록과 사진 $linkedPhotoCount장을 지웠어요', type: ToastType.info);
      return;
    }
    context.showToast(
      '${entry.personName}님 기록을 삭제했어요',
      type: ToastType.info,
      actionLabel: '되돌리기',
      onAction: () => loading(() => onRestore(entry, onError: showError), message: '되돌리는 중이에요'),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 종류 이름은 종류 목록이 바뀌면(이름 변경 등) 자동으로 다시 그려진다.
    final typeName = ref.watch(eventTypeNamesProvider)[entry.eventTypeId] ?? '';
    void openEdit() => context.pushOnce(AppRoutes.entryEdit(entry.id));

    return SwipeActionTile(
      actions: [
        SwipeAction.edit(onPressed: openEdit, testId: TestIds.entryEdit(entry.id)),
        SwipeAction.delete(onPressed: () => _delete(context), testId: TestIds.entryDelete(entry.id)),
      ],
      child: LedgerEntryTile(
        entry: entry,
        typeName: typeName,
        hasPhoto: linkedPhotoCount > 0,
        showRelation: showRelation,
        onTap: openEdit,
      ).testId(TestIds.entryTile(entry.id)),
    );
  }
}
