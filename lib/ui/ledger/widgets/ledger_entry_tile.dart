import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';

/// 기록 한 건을 보여주는 목록 한 줄.
///
/// ```
/// [결혼]  김철수                    50,000원
///         11월 24일 (화) · 메모
/// ```
/// 금액 색은 보냄(장밋빛) / 받음(청록)으로 자동으로 정해진다.
class LedgerEntryTile extends StatelessWidget {
  const LedgerEntryTile({super.key, required this.entry, this.onTap, this.onLongPress});

  final LedgerEntry entry;

  /// 눌렀을 때 (예: 수정 화면 열기)
  final VoidCallback? onTap;

  /// 길게 눌렀을 때 (예: 삭제 확인)
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final amountColor = entry.direction == RecordDirection.sent ? AppColors.sent : AppColors.received;
    // 날짜 뒤에 메모가 있으면 " · 메모"를 붙인다.
    final subtitle = [entry.date.toKoreanDate, if (entry.memo != null) entry.memo!].join(' · ');

    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      leading: _EventTypeBadge(label: entry.eventType.label),
      title: AppText.subtitle(entry.personName, maxLines: 1),
      subtitle: AppText.caption(subtitle, maxLines: 1),
      trailing: AppText.amount(entry.amount.won, color: amountColor),
    );
  }
}

/// 경조사 종류를 보여주는 둥근 배지 (이 파일 안에서만 쓰므로 이름 앞에 _를 붙여 숨김)
class _EventTypeBadge extends StatelessWidget {
  const _EventTypeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: AppText.label(label, color: AppColors.primary, align: TextAlign.center, maxLines: 1),
    );
  }
}
