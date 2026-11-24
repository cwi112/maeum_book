import 'package:maeum_book/core/extensions/extensions.dart';
import 'package:maeum_book/core/theme/app_dimens.dart';
import 'package:maeum_book/core/widgets/app_text.dart';
import 'package:maeum_book/core/widgets/empty_view.dart';
import 'package:maeum_book/core/widgets/summary_card.dart';
import 'package:material_ui/material_ui.dart';

/// 보내요·받아요처럼 "합계 카드 + 목록 + 기록 버튼" 구조의 화면 레이아웃.
///
/// ```dart
/// LedgerListLayout(
///   title: '보내요',
///   summaryLabel: '지금까지 보낸 마음',
///   total: 0,
///   color: AppColors.sent,
///   items: data,
///   emptyIcon: Icons.outbox_outlined,
///   emptyTitle: '아직 보낸 마음이 없어요',
///   addLabel: '보낸 마음 기록',
///   onAdd: () {},
/// )
/// ```
class LedgerListLayout extends StatelessWidget {
  const LedgerListLayout({
    super.key,
    required this.title,
    required this.summaryLabel,
    required this.total,
    required this.color,
    required this.items,
    required this.emptyIcon,
    required this.emptyTitle,
    this.emptyMessage,
    required this.addLabel,
    required this.onAdd,
  });

  /// 상단 제목
  final String title;

  /// 합계 카드 설명 문구
  final String summaryLabel;

  /// 합계 금액 (원)
  final int total;

  /// 금액 강조 색 (보냄: AppColors.sent, 받음: AppColors.received)
  final Color color;

  // TODO: 내역 모델이 생기면 List<String> 대신 모델 목록으로 바꾼다.
  final List<String> items;

  final IconData emptyIcon;
  final String emptyTitle;
  final String? emptyMessage;

  /// 기록 버튼 문구와 동작
  final String addLabel;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          SummaryCard(
            label: summaryLabel,
            amount: total.won,
            count: items.length,
            color: color,
          ).paddingOnly(left: AppSpacing.screen, top: AppSpacing.sm, right: AppSpacing.screen),
          (items.isEmpty
                  ? EmptyView(icon: emptyIcon, title: emptyTitle, message: emptyMessage)
                  : ListView(children: [for (final item in items) ListTile(title: AppText.subtitle(item))]))
              .expanded(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: title,
        onPressed: onAdd,
        icon: const Icon(Icons.edit_outlined),
        label: Text(addLabel),
      ),
    );
  }
}
