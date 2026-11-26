import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';

/// 사진 전체 화면의 상태: 행사 사진들 + 보낸 분으로 고를 수 있는 이 행사의 받은 기록들
class EventPhotoState {
  const EventPhotoState({required this.photos, required this.entries});

  final List<EventPhoto> photos;
  final List<LedgerEntry> entries;

  /// 사진에 연결된 받은 기록 (없으면 null)
  LedgerEntry? entryOf(EventPhoto photo) => entries.where((entry) => entry.id == photo.entryId).firstOrNull;
}

/// 사진 전체 화면의 ViewModel. 사진 정보(보낸 분 · 메모) 고치기 · 지우기
class EventPhotoViewModel extends BaseAsyncViewModel<EventPhotoState> {
  EventPhotoViewModel(this.eventId);

  final int eventId;

  EventPhotoRepository get _photos => ref.read(eventPhotoRepositoryProvider);

  @override
  Stream<EventPhotoState> watch() => combineLatest2(
    ref.watch(eventPhotoRepositoryProvider).watchByEvent(eventId),
    ref.watch(eventRepositoryProvider).watchEntries(eventId),
    (photos, entries) => EventPhotoState(photos: photos, entries: entries),
  );

  /// 보낸 분 · 메모를 저장한다. 성공하면 true.
  Future<bool> saveInfo(EventPhoto photo, PhotoInfo info, {ErrorCallback? onError}) async =>
      await runTask(() async {
        await _photos.updateInfo(photo, senderName: info.senderName, entryId: info.entryId, memo: info.memo);
        return true;
      }, onError: onError) ??
      false;

  /// 사진을 지운다. 성공하면 true. (화면에서 확인 창을 거친 뒤 호출)
  Future<bool> remove(EventPhoto photo, {ErrorCallback? onError}) async =>
      await runTask(() async {
        await _photos.remove(photo);
        return true;
      }, onError: onError) ??
      false;
}

/// 사진 정보 창에서 고친 값
typedef PhotoInfo = ({String? senderName, int? entryId, String? memo});

final eventPhotoViewModelProvider = AsyncNotifierProvider.autoDispose.family<EventPhotoViewModel, EventPhotoState, int>(
  EventPhotoViewModel.new,
);
