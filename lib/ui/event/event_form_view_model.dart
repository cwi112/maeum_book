import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/core/utils/app_monitor.dart';
import 'package:maeum_book/data/data.dart';

/// 행사 만들기·수정 화면의 상태.
///
/// | 항목 | 필수 | 기본값 |
/// |---|:---:|---|
/// | 행사 이름 [title] | 필수 | 빈칸 |
/// | 경조사 종류 [eventTypeId] | 필수 | 없음 |
/// | 날짜 [date] | 필수 | 오늘 |
/// | 메모 [memo] | 선택 | 빈칸 |
class EventFormState {
  const EventFormState({
    required this.date,
    this.title = '',
    this.eventTypeId,
    this.memo = '',
    this.showErrors = false,
    this.isSaving = false,
    this.original,
  });

  factory EventFormState.fromEvent(LedgerEvent event) => EventFormState(
    title: event.title,
    eventTypeId: event.eventTypeId,
    date: event.date,
    memo: event.memo ?? '',
    original: event,
  );

  final String title;
  final int? eventTypeId;
  final DateTime date;
  final String memo;
  final bool showErrors;
  final bool isSaving;

  /// 수정 중인 원래 행사 (새 행사면 null)
  final LedgerEvent? original;

  bool get isEditing => original != null;

  String? get titleError => showErrors && title.isBlank ? '행사 이름을 입력해 주세요' : null;
  String? get eventTypeError => showErrors && eventTypeId == null ? '경조사 종류를 골라 주세요' : null;
  bool get isValid => title.isNotBlank && eventTypeId != null;

  EventFormState copyWith({
    String? title,
    ValueGetter<int?>? eventTypeId,
    DateTime? date,
    String? memo,
    bool? showErrors,
    bool? isSaving,
  }) => EventFormState(
    title: title ?? this.title,
    eventTypeId: eventTypeId != null ? eventTypeId() : this.eventTypeId,
    date: date ?? this.date,
    memo: memo ?? this.memo,
    showErrors: showErrors ?? this.showErrors,
    isSaving: isSaving ?? this.isSaving,
    original: original,
  );
}

/// 행사 만들기·수정 ViewModel. [eventId]가 null이면 새 행사.
///
/// 행사를 고치면 안의 받은 기록의 날짜·종류도 같이 바뀐다. (EventDao.updateEvent에서 한 트랜잭션으로 처리)
class EventFormViewModel extends BaseAsyncViewModel<EventFormState> {
  EventFormViewModel(this.eventId);

  final int? eventId;

  EventRepository get _repository => ref.read(eventRepositoryProvider);

  @override
  Future<EventFormState> load() async {
    final id = eventId;
    if (id == null) return EventFormState(date: DateTime.now().dateOnly);
    final event = await _repository.findById(id);
    if (event == null) throw StateError('행사를 찾을 수 없어요');
    return EventFormState.fromEvent(event);
  }

  EventFormState get _form => state.requireValue;
  void _update(EventFormState next) => state = AsyncData(next);

  void setTitle(String value) => _update(_form.copyWith(title: value));
  void setEventType(int? value) => _update(_form.copyWith(eventTypeId: () => value));
  void setDate(DateTime value) => _update(_form.copyWith(date: value.dateOnly));
  void setMemo(String value) => _update(_form.copyWith(memo: value));

  /// 저장. 성공하면 true. (입력 누락은 칸 아래 오류, 저장 실패는 [onError], 연타 방지)
  Future<bool> save({ErrorCallback? onError}) async {
    final form = _form;
    if (form.isSaving) return false;
    if (!form.isValid) {
      _update(form.copyWith(showErrors: true));
      return false;
    }
    _update(form.copyWith(isSaving: true));
    try {
      final original = form.original;
      if (original == null) {
        await _repository.add(title: form.title, eventTypeId: form.eventTypeId!, date: form.date, memo: form.memo);
      } else {
        await _repository.edit(
          original,
          title: form.title,
          eventTypeId: form.eventTypeId!,
          date: form.date,
          memo: form.memo,
        );
      }
      AppMonitor.logEvent(AppEvents.eventSave, {'mode': original == null ? 'new' : 'edit'});
      return true;
    } catch (error, stack) {
      AppMonitor.recordError(error, stack, reason: '행사 저장');
      onError?.call(error);
      return false;
    } finally {
      if (ref.mounted) _update(_form.copyWith(isSaving: false));
    }
  }
}

final eventFormViewModelProvider = AsyncNotifierProvider.autoDispose.family<EventFormViewModel, EventFormState, int?>(
  EventFormViewModel.new,
);
