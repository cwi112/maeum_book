import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';

part 'entry_form_state.dart';

/// 입력 화면을 여는 방법.
/// - 새 기록: [direction]만 (+ 행사 화면에서 왔다면 [eventId])
/// - 수정: [entryId]
///
/// Dart의 record 타입이라 값이 같으면 같은 것으로 취급된다. 그래서 Riverpod family의 구분 값(key)으로 쓸 수 있다.
typedef EntryFormArgs = ({RecordDirection direction, int? entryId, int? eventId});

/// 기록 입력·수정 화면의 ViewModel.
///
/// ## 동작 순서
/// 1. 화면이 열리면 [load]가 처음 상태를 만든다. 받은 기록용 행사 목록도 함께 읽는다.
///    - 새 기록: 들어온 방향 + 오늘 날짜 (+ 미리 고른 행사)
///    - 수정: DB에서 기록을 읽어 모든 칸을 채움 (없으면 "기록을 찾을 수 없어요" 화면)
/// 2. 사용자가 입력할 때마다 `setXxx`가 상태를 바꾸고, 화면이 다시 그려진다.
/// 3. 저장을 누르면 [save]가 검사 → 추가 또는 수정 → 결과를 돌려준다.
///    받은 기록은 고른 행사의 날짜·종류로 저장된다.
class EntryFormViewModel extends BaseAsyncViewModel<EntryFormState> {
  EntryFormViewModel(this.args);

  final EntryFormArgs args;

  LedgerRepository get _repository => ref.read(ledgerRepositoryProvider);

  @override
  Future<EntryFormState> load() async {
    final events = await ref.read(eventRepositoryProvider).fetchAll();
    final id = args.entryId;
    if (id == null) {
      return EntryFormState(
        direction: args.direction,
        date: DateTime.now().dateOnly,
        events: events,
        eventId: args.eventId,
      );
    }

    final entry = await _repository.findById(id);
    if (entry == null) throw StateError('기록을 찾을 수 없어요. 이미 삭제되었을 수 있어요.');
    return EntryFormState.fromEntry(entry, events);
  }

  /// 지금 입력 상태. (불러오기가 끝난 뒤에만 입력할 수 있으므로 항상 값이 있다)
  EntryFormState get _form => state.requireValue;

  void _update(EntryFormState next) => state = AsyncData(next);

  // ── 입력값 반영 ────────────────────────
  void setDirection(RecordDirection value) => _update(_form.copyWith(direction: value));
  void setEvent(int? value) => _update(_form.copyWith(eventId: () => value));
  void setDate(DateTime value) => _update(_form.copyWith(date: value.dateOnly));
  void setEventType(int? value) => _update(_form.copyWith(eventTypeId: () => value));
  void setPersonName(String value) => _update(_form.copyWith(personName: value));
  void setAmount(int value) => _update(_form.copyWith(amount: value));
  void setRelation(Relation? value) => _update(_form.copyWith(relation: () => value));
  void setMemo(String value) => _update(_form.copyWith(memo: value));

  /// 행사 목록을 다시 읽는다. (입력 화면에서 "행사 만들기"를 다녀온 뒤 새 행사가 보이게)
  Future<void> refreshEvents() async {
    final events = await ref.read(eventRepositoryProvider).fetchAll();
    if (!ref.mounted) return;
    final form = _form;
    _update(
      EntryFormState(
        direction: form.direction,
        date: form.date,
        events: events,
        // 방금 만든 행사(가장 최근에 추가된 것)를 자동으로 고른다.
        eventId: form.eventId ?? (events.isEmpty ? null : events.reduce((a, b) => a.id > b.id ? a : b).id),
        eventTypeId: form.eventTypeId,
        personName: form.personName,
        amount: form.amount,
        relation: form.relation,
        memo: form.memo,
        showErrors: form.showErrors,
        original: form.original,
      ),
    );
  }

  /// 기록을 저장한다(새 기록은 추가, 수정은 덮어쓰기). 성공하면 true.
  ///
  /// - 이미 저장 중이면 아무것도 하지 않는다. (버튼 연타로 같은 기록이 두 번 저장되는 것을 방지)
  /// - 필수 항목이 비었으면 저장하지 않고 오류 문구를 켠다. (토스트 없이 칸 아래에 표시)
  /// - DB 저장 중 오류가 나면 [onError]로 알린다. (화면에서 오류 토스트를 띄움)
  Future<bool> save({ErrorCallback? onError}) async {
    final form = _form;
    if (form.isSaving) return false;
    if (!form.isValid) {
      _update(form.copyWith(showErrors: true));
      return false;
    }

    // 받은 기록은 행사의 날짜·종류를 따른다. 보낸 기록은 행사가 없다.
    final event = form.isReceived ? form.selectedEvent : null;
    final date = event?.date ?? form.date;
    final eventTypeId = event?.eventTypeId ?? form.eventTypeId!;

    _update(form.copyWith(isSaving: true));
    try {
      final original = form.original;
      if (original == null) {
        await _repository.add(
          direction: form.direction,
          eventTypeId: eventTypeId,
          eventId: event?.id,
          personName: form.personName,
          amount: form.amount,
          date: date,
          relation: form.relation,
          memo: form.memo,
        );
      } else {
        // 원래 기록을 바탕으로 바꾼 값만 덮어쓴다. (id·작성 시각은 그대로 유지)
        await _repository.edit(
          original,
          direction: form.direction,
          eventTypeId: eventTypeId,
          eventId: event?.id,
          personName: form.personName,
          amount: form.amount,
          date: date,
          relation: form.relation,
          memo: form.memo,
        );
      }
      return true;
    } catch (error) {
      onError?.call(error);
      return false;
    } finally {
      // 저장이 끝나기 전에 화면이 닫혔을 수 있으므로, ViewModel이 살아 있을 때만 상태를 바꾼다.
      if (ref.mounted) _update(_form.copyWith(isSaving: false));
    }
  }
}

/// 입력 화면 ViewModel. 화면이 닫히면(autoDispose) 입력하던 내용도 함께 정리된다.
final entryFormViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<EntryFormViewModel, EntryFormState, EntryFormArgs>(EntryFormViewModel.new);
