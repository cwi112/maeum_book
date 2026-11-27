import 'package:maeum_book/core/extensions/widget_extension.dart';
import 'package:maeum_book/core/theme/app_colors.dart';
import 'package:maeum_book/core/theme/app_dimens.dart';
import 'package:maeum_book/core/widgets/app_text.dart';
import 'package:material_ui/material_ui.dart';

/// 간단한 마크다운 글을 앱 글꼴 · 색으로 보여 준다. (개인정보 처리방침처럼 저장소 문서를 앱 안에서 그대로 보여 줄 때)
///
/// ```dart
/// SimpleMarkdown(text: await rootBundle.loadString('docs/PRIVACY_POLICY.md'))
/// ```
///
/// 지원: `#` · `##` 제목, `-` 목록, `|` 표(행마다 "제목: 값" 줄로), `>` 인용, `**굵게**`(굵게 표시 없이 글자만), 빈 줄.
/// 패키지 없이 이 앱 문서에 쓰는 정도만 다룬다.
class SimpleMarkdown extends StatelessWidget {
  const SimpleMarkdown({super.key, required this.text});

  final String text;

  static String _plain(String line) => line.replaceAll('**', '').replaceAll('`', '').trim();

  static List<String> _cells(String row) =>
      row.trim().replaceAll(RegExp(r'^\||\|$'), '').split('|').map(_plain).toList();

  @override
  Widget build(BuildContext context) {
    final lines = text.replaceAll('\r', '').split('\n');
    final children = <Widget>[];
    List<String>? tableHeader;

    for (final raw in lines) {
      final line = raw.trimRight();
      if (line.startsWith('|')) {
        final cells = _cells(line);
        if (cells.every((cell) => RegExp(r'^:?-{3,}:?$').hasMatch(cell))) continue; // 구분 줄 |---|
        if (tableHeader == null) {
          tableHeader = cells;
          continue;
        }
        // 표의 한 행 → "첫 칸" 굵게 + 나머지 칸은 "머리글: 값"
        children.add(
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.label(cells.first),
                for (var i = 1; i < cells.length; i++)
                  if (cells[i].isNotEmpty)
                    AppText.bodySmall(
                      i < tableHeader.length ? '${tableHeader[i]}: ${cells[i]}' : cells[i],
                      color: AppColors.textSecondary,
                    ),
              ],
            ),
          ),
        );
        continue;
      }
      tableHeader = null;

      if (line.trim().isEmpty) {
        children.add(const SizedBox(height: AppSpacing.sm));
      } else if (line.startsWith('# ')) {
        children.add(AppText.title(_plain(line.substring(2))).paddingOnly(bottom: AppSpacing.sm));
      } else if (line.startsWith('## ')) {
        children.add(
          AppText.subtitle(_plain(line.substring(3))).paddingOnly(top: AppSpacing.lg, bottom: AppSpacing.xs),
        );
      } else if (line.startsWith('- ')) {
        children.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.body('•  ', color: AppColors.textSecondary),
              AppText.body(_plain(line.substring(2))).expanded(),
            ],
          ).paddingOnly(bottom: AppSpacing.xs),
        );
      } else if (line.startsWith('> ')) {
        children.add(AppText.bodySmall(_plain(line.substring(2)), color: AppColors.textSecondary));
      } else {
        children.add(AppText.body(_plain(line)).paddingOnly(bottom: AppSpacing.xs));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}
