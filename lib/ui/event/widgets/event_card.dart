import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';

/// 행사 카드 한 장. (받아요 탭 목록)
///
/// ```
/// ┌──────────────────────────────────┐
/// │ [결혼]  우리 결혼식            >  │
/// │         2025.05.10 (토)            │
/// │  12명 · 1,350,000원                │
/// └──────────────────────────────────┘
/// ```
class EventCard extends ConsumerWidget {
  const EventCard({super.key, required this.summary, required this.onTap});

  final EventSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = summary.event;
    final typeName = ref.watch(eventTypeNamesProvider)[event.eventTypeId] ?? '';
    return Card(
      clipBehavior: Clip.antiAlias, // 눌렀을 때 물결이 카드의 둥근 모서리 밖으로 나가지 않게
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md + 2),
          child: Row(
            children: [
              Container(
                width: 52,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: AppText.label(typeName, color: AppColors.primary, align: TextAlign.center, maxLines: 1),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.subtitle(event.title, maxLines: 1),
                  const SizedBox(height: 2),
                  AppText.caption('${event.date.toDotDate} (${event.date.koreanWeekday})'),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      AppText.bodySmall('${summary.count}명', color: AppColors.textSecondary),
                      const AppText.bodySmall(' · ', color: AppColors.textHint),
                      // 금액이 아주 크면(수십억) 자리가 모자라 넘친다 → 모자랄 때만 글자를 줄여 다 보이게 (숫자는 자르지 않음)
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: AppText.amount(summary.total.won, color: AppColors.received),
                        ),
                      ),
                    ],
                  ),
                ],
              ).expanded(),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    ).testId(TestIds.eventCard(event.id));
  }
}
