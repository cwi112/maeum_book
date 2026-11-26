import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';
import 'package:maeum_book/ui/ledger/widgets/ledger_entry_tile.dart';

/// 기록 한 줄 + 왼쪽으로 밀면 나오는 수정·삭제 버튼. (보내요 목록, 행사 상세에서 함께 씀)
///
/// - 누르거나 "수정": 수정 화면으로 이동
/// - "삭제": 바로 지우고, 4초 동안 "되돌리기" 토스트를 띄운다. 지운 기록을 들고 있다가 그대로 다시 넣는다.
///
/// 실제 삭제·복원은 화면의 ViewModel이 하도록 [onRemove]·[onRestore]로 받는다. (이 위젯은 화면 동작만 담당)
class EntrySwipeTile extends ConsumerWidget {
  const EntrySwipeTile({
    super.key,
    required this.entry,
    required this.onRemove,
    required this.onRestore,
    this.hasPhoto = false,
  });

  /// 이 사람이 보낸 화환 · 꽃 사진이 있으면 true (이름 옆 꽃 표시)
  final bool hasPhoto;

  final LedgerEntry entry;

  /// 삭제. 성공하면 true
  final Future<bool> Function(int id, {ErrorCallback? onError}) onRemove;

  /// 되돌리기
  final Future<bool> Function(LedgerEntry entry, {ErrorCallback? onError}) onRestore;

  Future<void> _delete(BuildContext context) async {
    void showError(Object e) => context.showErrorToast(e, '처리하지 못했어요. 다시 시도해 주세요');

    // 지운 줄은 화면에서 사라지므로, 되돌리기 때 쓸 로딩 막을 미리 잡아 둔다.
    final loading = context.loadingRunner;
    final removed = await loading(() => onRemove(entry.id, onError: showError), message: '지우는 중이에요');
    if (!removed || !context.mounted) return;
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
        hasPhoto: hasPhoto,
        onTap: openEdit,
      ).testId(TestIds.entryTile(entry.id)),
    );
  }
}
