import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';
import 'package:maeum_book/ui/event/widgets/event_photo_image.dart';

/// 행사 상세의 "화환 · 사진" 줄. 가로로 넘기는 작은 사진들 + 맨 앞 [추가] 칸.
///
/// ```
///  화환 · 사진 3                         (30장까지)
///  ┌────┐ ┌────┐ ┌────┐ ┌────┐
///  │ +  │ │🌸  │ │🌸  │ │🌸  │
///  │추가│ │김민준│ │OO회사│ │    │
///  └────┘ └────┘ └────┘ └────┘
/// ```
class EventPhotoStrip extends StatelessWidget {
  const EventPhotoStrip({
    super.key,
    required this.photos,
    required this.isAdding,
    required this.onAdd,
    required this.onOpen,
  });

  final List<EventPhoto> photos;

  /// 사진을 저장하는 중이면 추가 칸에 로딩 표시
  final bool isAdding;
  final VoidCallback onAdd;

  /// 사진을 누르면 그 사진의 순서(0부터)
  final ValueChanged<int> onOpen;

  static const double _size = 84;

  @override
  Widget build(BuildContext context) {
    final full = photos.length >= EventPhotoRepository.maxPerEvent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.local_florist_outlined, size: 18, color: AppColors.primary),
            const SizedBox(width: AppSpacing.xs),
            AppText.label('화환 · 사진 ${photos.length}'),
            const Spacer(),
            const AppText.caption('${EventPhotoRepository.maxPerEvent}장까지'),
          ],
        ).paddingSymmetric(horizontal: AppSpacing.screen),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          // 사진 + 아래 이름 한 줄. 글씨를 크게 쓰는 사람도 이름이 잘리지 않게 글씨 크기에 맞춰 높이를 늘린다.
          height: _size + 6 + MediaQuery.textScalerOf(context).scale(20),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            itemCount: photos.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _AddTile(size: _size, isAdding: isAdding, disabled: full, onTap: onAdd);
              }
              final photo = photos[index - 1];
              return _PhotoTile(size: _size, photo: photo, onTap: () => onOpen(index - 1));
            },
          ),
        ),
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.size, required this.isAdding, required this.disabled, required this.onTap});

  final double size;
  final bool isAdding;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          // 흰 바탕 + 얇은 테두리: 크림색 화면 위에서 사진 칸처럼 또렷하게 보이고, 테라코타 아이콘이 돋보인다.
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            side: const BorderSide(color: AppColors.divider),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isAdding || disabled ? null : onTap,
            child: SizedBox.square(
              dimension: size,
              child: isAdding
                  ? const Center(
                      child: SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : Icon(Icons.add_a_photo_outlined, color: disabled ? AppColors.textHint : AppColors.primary),
            ),
          ),
        ).testId(TestIds.eventPhotoAdd),
        const SizedBox(height: 4),
        AppText.caption(isAdding ? '저장 중' : '추가'),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.size, required this.photo, required this.onTap});

  final double size;
  final EventPhoto photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      child: Column(
        children: [
          Material(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Ink(
                width: size,
                height: size,
                child: EventPhotoImage(photoId: photo.id),
              ),
            ),
          ).testId(TestIds.eventPhoto(photo.id)),
          const SizedBox(height: 4),
          AppText.caption(photo.senderName ?? '보낸 분 미입력', maxLines: 1),
        ],
      ),
    );
  }
}
