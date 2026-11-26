import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';

/// 행사 사진 한 장을 그린다. 기기에 있으면 바로, 없으면(회원이 다른 기기에서 올린 사진) 서버에서 받아서 보여 준다.
///
/// - [thumb]: 목록용 작은 사진 (사진 줄) / 원본 (전체 화면)
/// - 받는 중: 연한 배경 + 작은 로딩, 못 받으면(인터넷 없음): 사진 아이콘
class EventPhotoImage extends ConsumerWidget {
  const EventPhotoImage({super.key, required this.photoId, this.thumb = true, this.fit = BoxFit.cover});

  final int photoId;
  final bool thumb;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = ref.watch(eventPhotoImageProvider((photoId, thumb)));
    return switch (image) {
      AsyncData(value: final bytes?) => Image.memory(bytes, fit: fit, gaplessPlayback: true),
      AsyncLoading() => _Placeholder(child: const CircularProgressIndicator(strokeWidth: 2).sized(20)),
      _ => const _Placeholder(child: Icon(Icons.image_not_supported_outlined, color: AppColors.textHint)),
    };
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.divider,
    child: Center(child: child),
  );
}

extension on Widget {
  Widget sized(double size) => SizedBox.square(dimension: size, child: this);
}
