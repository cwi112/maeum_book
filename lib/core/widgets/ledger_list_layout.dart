import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:maeum_book/core/extensions/extensions.dart';
import 'package:maeum_book/core/theme/app_colors.dart';
import 'package:maeum_book/core/theme/app_dimens.dart';
import 'package:maeum_book/core/widgets/empty_view.dart';
import 'package:maeum_book/core/widgets/summary_card.dart';
import 'package:material_ui/material_ui.dart';

/// "합계 카드 + 목록 + 기록 버튼" 구조의 화면 레이아웃. (보내요·받아요 화면)
///
/// 목록 한 줄을 어떻게 그릴지는 [itemBuilder]로 받는다. 그래서 이 레이아웃은 데이터 종류를 몰라도 되고,
/// 다른 목록 화면에서도 그대로 재사용할 수 있다.
///
/// ```dart
/// LedgerListLayout(
///   title: '보내요',
///   summaryLabel: '지금까지 보낸 마음',
///   total: 150000,
///   color: AppColors.sent,
///   itemCount: entries.length,
///   itemBuilder: (context, index) => LedgerEntryTile(entry: entries[index]),
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
    required this.itemCount,
    required this.itemBuilder,
    required this.emptyIcon,
    required this.emptyTitle,
    this.emptyMessage,
    required this.addLabel,
    required this.onAdd,
    this.addTestId,
    this.summaryTestId,
    this.header,
    this.emptyActionLabel,
    this.onEmptyAction,
  });

  /// 상단 제목
  final String title;

  /// 합계 카드 설명 문구
  final String summaryLabel;

  /// 합계 금액 (원)
  final int total;

  /// 금액 강조 색 (보냄: AppColors.sent, 받음: AppColors.received)
  final Color color;

  /// 목록 개수. 0이면 빈 화면([EmptyView])을 보여준다.
  final int itemCount;

  /// 목록 한 줄을 그리는 함수
  final IndexedWidgetBuilder itemBuilder;

  final IconData emptyIcon;
  final String emptyTitle;
  final String? emptyMessage;

  /// 기록 버튼 문구와 동작
  final String addLabel;
  final VoidCallback onAdd;

  /// 자동화 테스트용 이름 (TestIds 참고)
  final String? addTestId;
  final String? summaryTestId;

  /// 합계 카드와 목록 사이에 넣을 위젯 (예: 검색창·필터)
  final Widget? header;

  /// 빈 화면 버튼 (예: 검색 결과가 없을 때 "조건 초기화")
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          SummaryCard(label: summaryLabel, amount: total.won, count: itemCount, color: color)
              .testIdOrSelf(summaryTestId)
              .paddingOnly(left: AppSpacing.screen, top: AppSpacing.sm, right: AppSpacing.screen),
          ?header,
          (itemCount == 0
                  ? EmptyView(
                      icon: emptyIcon,
                      title: emptyTitle,
                      message: emptyMessage,
                      actionLabel: emptyActionLabel,
                      onAction: onEmptyAction,
                    )
                  // ListView.separated: 화면에 보이는 줄만 그려서 기록이 많아도 가볍다. 줄 사이에 구분선을 넣는다.
                  // SlidableAutoCloseBehavior: 한 줄을 밀어 열면 다른 열린 줄은 자동으로 닫히게 한다.
                  : SlidableAutoCloseBehavior(
                      child: ListView.separated(
                        // 아래쪽 여백: 마지막 줄이 기록 버튼에 가려지지 않게 한다.
                        padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: 96),
                        itemCount: itemCount,
                        itemBuilder: itemBuilder,
                        separatorBuilder: (_, _) => const Divider(
                          indent: AppSpacing.screen,
                          endIndent: AppSpacing.screen,
                          color: AppColors.divider,
                        ),
                      ),
                    ))
              .expanded(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: title,
        onPressed: onAdd,
        icon: const Icon(Icons.edit_outlined),
        label: Text(addLabel),
      ).testIdOrSelf(addTestId),
    );
  }
}
