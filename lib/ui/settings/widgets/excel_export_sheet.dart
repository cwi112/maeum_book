import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';

/// 엑셀 파일을 만든 뒤 아래에서 올라오는 창: 파일 이름 · 건수 + "공유하기" / "내 휴대폰에 저장"
///
/// ```
/// ┌──────────────────────────────┐
/// │  📄 마음장부_2026-11-26.xlsx  │
/// │  보낸 40건 · 받은 45건        │
/// │  [ 공유하기 (카톡 · 메일) ]   │
/// │  [ 내 휴대폰에 저장 ]         │
/// └──────────────────────────────┘
/// ```
/// 버튼을 누르면 창을 닫고 [onShare] / [onSave]를 부른다. 공유 버튼의 화면 위치를 함께 넘긴다. (iPad 공유 창 위치)
class ExcelExportSheet extends StatelessWidget {
  const ExcelExportSheet({super.key, required this.file, required this.onShare, required this.onSave});

  final ExcelExportFile file;
  final void Function(Rect? origin) onShare;
  final VoidCallback onSave;

  static Future<void> show(
    BuildContext context, {
    required ExcelExportFile file,
    required void Function(Rect? origin) onShare,
    required VoidCallback onSave,
  }) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => ExcelExportSheet(file: file, onShare: onShare, onSave: onSave),
  );

  /// 누른 버튼의 화면 위치 (iPad 공유 창이 그 버튼을 가리키며 뜬다)
  static Rect? _originOf(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.table_view_outlined, color: AppColors.success),
                const SizedBox(width: AppSpacing.sm),
                AppText.subtitle(file.fileName, maxLines: 1).expanded(),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            AppText.caption('보낸 ${file.sentCount}건 · 받은 ${file.receivedCount}건 · 합계는 엑셀 함수로 들어 있어요'),
            if (file.mayBeOutdated) ...[
              const SizedBox(height: AppSpacing.xs),
              const AppText.caption('인터넷이 끊겨 있어서 마지막으로 받아 온 기록 기준이에요', color: AppColors.error),
            ],
            const SizedBox(height: AppSpacing.lg),
            Builder(
              builder: (buttonContext) => FilledButton.icon(
                onPressed: () {
                  final origin = _originOf(buttonContext);
                  Navigator.of(context).pop();
                  onShare(origin);
                },
                icon: const Icon(Icons.ios_share_rounded),
                label: const Text('공유하기 (카톡 · 메일)'),
              ).testId(TestIds.excelShare),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onSave();
              },
              icon: const Icon(Icons.download_rounded),
              label: const Text('내 휴대폰에 저장'),
            ).testId(TestIds.excelSave),
          ],
        ),
      ),
    );
  }
}
