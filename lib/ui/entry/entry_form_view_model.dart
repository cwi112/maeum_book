import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';

part 'entry_form_state.dart';

/// 입력 화면을 여는 방법. 새 기록이면 [direction]만, 수정이면 [entryId]를 넣는다.
///
/// Dart의 record 타입이라 값이 같으면 같은 것으로 취급된다. 그래서 Riverpod family의 구분 값(key)으로 쓸 수 있다.
typedef EntryFormArgs = ({RecordDirection direction, int? entryId});

/// 기록 입력·수정 화면의 ViewModel.
///
/// ## 동작 순서
/// 1. 화면이 열리면 [load]가 처음 상태를 만든다.
///    - 새 기록: 들어온 탭의 방향 + 오늘 날짜
///    - 수정: DB에서 기록을 읽어 모든 칸을 채움 (없으면 오류 화면 → "다시 시도")
/// 2. 사용자가 입력할 때마다 `setXxx`가 상태를 바꾸고, 화면이 다시 그려진다.
/// 3. 저장을 누르면 [save]가 검사 → 추가 또는 수정 → 결과를 돌려준다.
///    바뀐 기록은 DB Stream을 타고 보내요·받아요·통계 화면에 자동으로 반영된다.
class EntryFormViewModel extends BaseAsyncViewModel<EntryFormState> {
  EntryFormViewModel(this.args);

  final EntryFormArgs args;

  LedgerRepository get _repository => ref.read(ledgerRepositoryProvider);

  @override
  Future<EntryFormState> load() async {
    final id = args.entryId;
    if (id == null) return EntryFormState(direction: args.direction, date: DateTime.now().dateOnly);

    final entry = await _repository.findById(id);
    if (entry == null) throw StateError('기록을 찾을 수 없어요. 이미 삭제되었을 수 있어요.');
    return EntryFormState.fromEntry(entry);
  }

  /// 지금 입력 상태. (불러오기가 끝난 뒤에만 입력할 수 있으므로 항상 값이 있다)
  EntryFormState get _form => state.requireValue;

  void _update(EntryFormState next) => state = AsyncData(next);

  // ── 입력값 반영 ────────────────────────
  void setDirection(RecordDirection value) => _update(_form.copyWith(direction: value));
  void setDate(DateTime value) => _update(_form.copyWith(date: value.dateOnly));
  void setEventType(EventType? value) => _update(_form.copyWith(eventType: () => value));
  void setPersonName(String value) => _update(_form.copyWith(personName: value));
  void setAmount(int value) => _update(_form.copyWith(amount: value));
  void setRelation(Relation? value) => _update(_form.copyWith(relation: () => value));
  void setMemo(String value) => _update(_form.copyWith(memo: value));

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

    _update(form.copyWith(isSaving: true));
    try {
      final original = form.original;
      if (original == null) {
        await _repository.add(
          direction: form.direction,
          eventType: form.eventType!,
          personName: form.personName,
          amount: form.amount,
          date: form.date,
          relation: form.relation,
          memo: form.memo,
        );
      } else {
        // 원래 기록을 바탕으로 바꾼 값만 덮어쓴다. (id·작성 시각은 그대로 유지)
        await _repository.edit(
          original,
          direction: form.direction,
          eventType: form.eventType!,
          personName: form.personName,
          amount: form.amount,
          date: form.date,
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
