import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';
import 'package:maeum_book/ui/event/event_photo_view_model.dart';
import 'package:maeum_book/ui/event/widgets/event_photo_image.dart';
import 'package:maeum_book/ui/event/widgets/photo_info_sheet.dart';

/// 행사 사진 전체 화면. 경로 `/event/3/photos?index=2`
///
/// - 옆으로 넘겨 다른 사진 보기, 두 손가락으로 벌려 확대 (리본 글씨 확인)
/// - 아래: 보낸 분 · 메모. 받은 기록과 연결됐으면 그 기록 금액도 함께
/// - 오른쪽 위: 정보 수정(보낸 분 · 메모) / 삭제(확인 창)
class EventPhotoView extends BaseAsyncView<EventPhotoViewModel, EventPhotoState> {
  const EventPhotoView({super.key, required this.eventId, this.initialIndex = 0});

  final int eventId;
  final int initialIndex;

  @override
  AsyncNotifierProvider<EventPhotoViewModel, EventPhotoState> get provider => eventPhotoViewModelProvider(eventId);

  @override
  Widget buildView(BuildContext context, WidgetRef ref, EventPhotoState state, EventPhotoViewModel viewModel) =>
      _PhotoPager(state: state, viewModel: viewModel, initialIndex: initialIndex);
}

/// 넘기는 위치(몇 번째 사진)를 기억해야 해서 State가 있는 위젯으로 둔다.
class _PhotoPager extends StatefulWidget {
  const _PhotoPager({required this.state, required this.viewModel, required this.initialIndex});

  final EventPhotoState state;
  final EventPhotoViewModel viewModel;
  final int initialIndex;

  @override
  State<_PhotoPager> createState() => _PhotoPagerState();
}

class _PhotoPagerState extends State<_PhotoPager> {
  late int _index = widget.initialIndex.clamp(0, (widget.state.photos.length - 1).clamp(0, 999));
  late final _controller = PageController(initialPage: _index);

  List<EventPhoto> get _photos => widget.state.photos;

  @override
  void didUpdateWidget(_PhotoPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 사진을 지워 개수가 줄면 마지막 사진으로 맞춘다.
    if (_photos.isNotEmpty && _index >= _photos.length) _index = _photos.length - 1;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showError(Object error) => context.showErrorToast(error, '처리하지 못했어요. 다시 시도해 주세요');

  Future<void> _editInfo(EventPhoto photo) async {
    final info = await PhotoInfoSheet.show(context, photo: photo, entries: widget.state.entries);
    if (info == null || !mounted) return;
    final saved = await widget.viewModel.saveInfo(photo, info, onError: _showError);
    if (saved && mounted) context.showToast('사진 정보를 저장했어요');
  }

  Future<void> _delete(EventPhoto photo) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: '사진을 지울까요?',
      message: '되돌릴 수 없어요.',
      confirmLabel: '지우기',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    // 지우는 동안 목록이 먼저 줄어들 수 있어서, 마지막 한 장이었는지는 지우기 전에 알아 둔다.
    final wasLast = _photos.length == 1;
    final removed = await widget.viewModel.remove(photo, onError: _showError);
    if (!removed || !mounted) return;
    context.showToast('사진을 지웠어요', type: ToastType.info);
    if (wasLast) context.pop(); // 마지막 사진이었으면 닫는다
  }

  @override
  Widget build(BuildContext context) {
    if (_photos.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyView(icon: Icons.image_not_supported_outlined, title: '사진이 없어요', message: '이미 지워졌을 수 있어요'),
      );
    }
    final photo = _photos[_index.clamp(0, _photos.length - 1)];
    final entry = widget.state.entryOf(photo);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${_photos.length}'),
        actions: [
          IconButton(
            onPressed: () => _editInfo(photo),
            icon: const Icon(Icons.edit_outlined),
            tooltip: '보낸 분 · 메모',
          ).testId(TestIds.photoEdit),
          IconButton(
            onPressed: () => _delete(photo),
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: '사진 삭제',
          ).testId(TestIds.photoDelete),
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: _photos.length,
        onPageChanged: (index) => setState(() => _index = index),
        // InteractiveViewer: 두 손가락으로 확대 · 이동 (리본 글씨를 크게 보려고)
        itemBuilder: (_, index) => InteractiveViewer(
          maxScale: 5,
          child: Center(
            child: EventPhotoImage(photoId: _photos[index].id, thumb: false, fit: BoxFit.contain),
          ),
        ),
      ),
      bottomNavigationBar: _InfoBar(photo: photo, entry: entry, onEdit: () => _editInfo(photo)),
    );
  }
}

/// 아래 정보 줄: 🌸 보낸 분 (받은 기록 금액) / 메모. 비어 있으면 "보낸 분을 적어 보세요"
class _InfoBar extends StatelessWidget {
  const _InfoBar({required this.photo, required this.entry, required this.onEdit});

  final EventPhoto photo;
  final LedgerEntry? entry;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final sender = photo.senderName;
    return Material(
      color: Colors.black,
      child: InkWell(
        onTap: onEdit,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.md, AppSpacing.screen, AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_florist_outlined, color: Colors.white70, size: 18),
                    const SizedBox(width: AppSpacing.xs),
                    AppText.subtitle(sender ?? '보낸 분을 적어 보세요', color: Colors.white, maxLines: 1).flexible(),
                    if (entry != null)
                      AppText.caption('  · 받은 마음 ${entry!.amount.won}', color: Colors.white70, maxLines: 1),
                  ],
                ),
                if (photo.memo != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  AppText.bodySmall(photo.memo!, color: Colors.white70),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
