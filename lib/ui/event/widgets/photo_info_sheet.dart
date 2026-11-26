import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';
import 'package:maeum_book/ui/event/event_photo_view_model.dart';

/// 사진의 보낸 분 · 메모를 고치는 창 (아래에서 올라옴).
///
/// - 보낸 분: 직접 입력하거나, 이 행사의 받은 기록 이름 칩을 눌러 고른다. (고르면 그 기록과 연결 → 목록에 🌸)
/// - 칩을 고른 뒤 이름을 고쳐 쓰면 연결은 풀린다. (다른 사람일 수 있으니)
/// - 저장을 누르면 고친 값([PhotoInfo])을, 닫으면 null을 돌려준다.
class PhotoInfoSheet extends StatefulWidget {
  const PhotoInfoSheet({super.key, required this.photo, required this.entries});

  final EventPhoto photo;
  final List<LedgerEntry> entries;

  static Future<PhotoInfo?> show(
    BuildContext context, {
    required EventPhoto photo,
    required List<LedgerEntry> entries,
  }) => showModalBottomSheet<PhotoInfo>(
    context: context,
    isScrollControlled: true, // 키보드가 올라와도 가려지지 않게
    showDragHandle: true,
    builder: (_) => PhotoInfoSheet(photo: photo, entries: entries),
  );

  @override
  State<PhotoInfoSheet> createState() => _PhotoInfoSheetState();
}

class _PhotoInfoSheetState extends State<PhotoInfoSheet> {
  late final _sender = TextEditingController(text: widget.photo.senderName ?? '');
  late final _memo = TextEditingController(text: widget.photo.memo ?? '');
  late int? _entryId = widget.photo.entryId;

  @override
  void dispose() {
    _sender.dispose();
    _memo.dispose();
    super.dispose();
  }

  void _pick(LedgerEntry entry) => setState(() {
    _entryId = entry.id;
    _sender.text = entry.personName;
  });

  @override
  Widget build(BuildContext context) {
    // 같은 이름이 여러 번 있으면 칩은 한 번만
    final seen = <String>{};
    final choices = widget.entries.where((entry) => seen.add(entry.personName)).toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppText.title('사진 정보'),
              const SizedBox(height: AppSpacing.lg),
              FormSection(
                label: '보낸 분',
                child: TextField(
                  controller: _sender,
                  maxLength: AppDefine.personNameMaxLength,
                  textInputAction: TextInputAction.next,
                  // 직접 고쳐 쓰면 받은 기록과의 연결은 푼다.
                  onChanged: (_) => setState(() => _entryId = null),
                  decoration: const InputDecoration(hintText: '예) 김민준, OO회사 일동', counterText: ''),
                ).testId(TestIds.photoSenderField),
              ),
              if (choices.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                const AppText.caption('받은 기록에서 고르기'),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final entry in choices)
                      ChoiceChip(
                        label: Text(entry.personName),
                        selected: _entryId == entry.id,
                        onSelected: (_) => _pick(entry),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              FormSection(
                label: '메모',
                child: TextField(
                  controller: _memo,
                  maxLength: AppDefine.memoMaxLength,
                  decoration: const InputDecoration(hintText: '예) 쌀화환 20kg, 꽃바구니', counterText: ''),
                ).testId(TestIds.photoMemoField),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).pop((senderName: _sender.text, entryId: _entryId, memo: _memo.text)),
                child: const Text('저장'),
              ).testId(TestIds.photoInfoSave),
            ],
          ),
        ),
      ),
    );
  }
}
