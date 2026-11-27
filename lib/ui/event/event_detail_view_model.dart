import 'dart:typed_data';

import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/core/utils/app_monitor.dart';
import 'package:maeum_book/data/data.dart';

/// 사진을 어디서 가져올지
enum PhotoSource { camera, album }

/// 행사 상세 화면의 상태: 행사 정보 + 마음을 준 사람들 + 화환 · 꽃 사진.
class EventDetailState {
  const EventDetailState({
    required this.event,
    required this.entries,
    this.photos = const [],
    this.isAddingPhotos = false,
  });

  /// 행사 (지워졌으면 null)
  final LedgerEvent? event;

  /// 받은 기록 (금액 큰 순)
  final List<LedgerEntry> entries;

  /// 행사 사진 (추가한 순서)
  final List<EventPhoto> photos;

  /// 사진을 줄이고 저장하는 중이면 true (사진 줄에 로딩 표시)
  final bool isAddingPhotos;

  int get total => entries.fold(0, (sum, entry) => sum + entry.amount);

  /// 이 받은 기록과 연결된 사진 수 (목록에 🌸 표시 · 지울 때 확인 창)
  int photoCountOf(int entryId) => photos.where((photo) => photo.entryId == entryId).length;

  EventDetailState copyWith({bool? isAddingPhotos}) => EventDetailState(
    event: event,
    entries: entries,
    photos: photos,
    isAddingPhotos: isAddingPhotos ?? this.isAddingPhotos,
  );
}

/// 행사 상세 화면의 ViewModel.
///
/// 행사 · 받은 기록 · 사진 Stream을 [combineLatest3]로 합쳐서 구독한다.
/// 그래서 행사 이름을 고치거나, 준 사람을 추가 · 삭제하거나, 사진을 넣으면 어느 쪽이든 화면이 바로 바뀐다.
class EventDetailViewModel extends BaseAsyncViewModel<EventDetailState> {
  EventDetailViewModel(this.eventId);

  final int eventId;

  EventRepository get _events => ref.read(eventRepositoryProvider);
  LedgerRepository get _ledger => ref.read(ledgerRepositoryProvider);
  EventPhotoRepository get _photos => ref.read(eventPhotoRepositoryProvider);

  /// 사진을 넣는 중인지 (Stream이 새 값을 보내도 유지되게 따로 들고 있는다)
  bool _adding = false;

  @override
  Stream<EventDetailState> watch() {
    final repository = ref.watch(eventRepositoryProvider);
    return combineLatest3(
      repository.watchEvent(eventId),
      repository.watchEntries(eventId),
      ref.watch(eventPhotoRepositoryProvider).watchByEvent(eventId),
      (event, entries, photos) =>
          EventDetailState(event: event, entries: entries, photos: photos, isAddingPhotos: _adding),
    );
  }

  /// 행사를 지운다. 안의 받은 기록 · 사진도 함께 지워진다. (화면에서 확인 창을 거친 뒤 호출)
  Future<bool> deleteEvent({ErrorCallback? onError}) async =>
      await runTask(() => _events.remove(eventId), onError: onError) ?? false;

  /// 받은 기록 하나 삭제 / 되돌리기 (EntrySwipeTile이 사용)
  ///
  /// 이 기록과 연결된 화환 사진도 함께 지운다. (화면에서 확인 창을 거친 뒤)
  /// 사진은 기록 이름이 아니라 **기록 번호**로 연결돼 있어서, 같은 이름의 다른 사람 사진은 지워지지 않는다.
  Future<bool> removeEntry(int id, {ErrorCallback? onError}) async =>
      await runTask(() async {
        final linked = (state.value?.photos ?? const <EventPhoto>[]).where((photo) => photo.entryId == id).toList();
        for (final photo in linked) {
          await _photos.remove(photo);
        }
        return _ledger.remove(id);
      }, onError: onError) ??
      false;

  Future<bool> restoreEntry(LedgerEntry entry, {ErrorCallback? onError}) async =>
      await runTask(() async {
        await _ledger.restore(entry);
        return true;
      }, onError: onError) ??
      false;

  // ── 사진 ───────────────────────────────

  /// 카메라로 찍거나 앨범에서 골라 행사에 넣는다. 넣은 장 수를 돌려준다. (취소하면 0)
  ///
  /// 한 장씩 차례로 넣는다. 중간에 실패하면(인터넷 끊김 등) 거기서 멈추고 [onError]로 알린다. 앞서 넣은 사진은 남는다.
  Future<int> addPhotos(PhotoSource source, {ErrorCallback? onError}) async {
    if (_adding) return 0;
    final remaining = await _photos.remaining(eventId);
    if (remaining <= 0) {
      onError?.call(const PhotoLimitException(EventPhotoRepository.maxPerEvent));
      return 0;
    }
    final picker = ref.read(photoPickerProvider);
    final List<Uint8List> picked;
    try {
      picked = switch (source) {
        PhotoSource.camera => [?await picker.takePhoto()],
        PhotoSource.album => await picker.pickFromAlbum(limit: remaining),
      };
    } catch (error) {
      onError?.call(error); // 카메라 · 사진 권한을 거절한 경우 등
      return 0;
    }
    if (picked.isEmpty || !ref.mounted) return 0;

    _setAdding(true);
    var added = 0;
    try {
      for (final raw in picked) {
        await _photos.add(eventId, raw);
        added++;
      }
    } catch (error, stack) {
      AppMonitor.recordError(error, stack, reason: '사진 추가');
      onError?.call(error);
    } finally {
      _setAdding(false);
    }
    if (added > 0) AppMonitor.logEvent(AppEvents.photoAdd, {'source': source.name, 'count': added});
    return added;
  }

  void _setAdding(bool value) {
    _adding = value;
    if (!ref.mounted) return;
    final current = state.value;
    if (current != null) state = AsyncData(current.copyWith(isAddingPhotos: value));
  }
}

final eventDetailViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<EventDetailViewModel, EventDetailState, int>(EventDetailViewModel.new);
