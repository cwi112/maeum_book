import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';

part 'entry_form_state.dart';

/// 기록 입력 화면의 ViewModel.
///
/// ## 동작 순서
/// 1. 화면이 열리면 [build]가 기본값(들어온 탭의 방향, 오늘 날짜)으로 상태를 만든다.
/// 2. 사용자가 입력할 때마다 `setXxx`가 상태를 바꾸고, 화면이 다시 그려진다.
/// 3. 저장을 누르면 [save]가 검사 → 저장 → 결과를 돌려준다.
///    저장된 기록은 DB Stream을 타고 보내요·받아요·통계 화면에 자동으로 반영된다.
class EntryFormViewModel extends BaseViewModel<EntryFormState> {
  EntryFormViewModel(this.initialDirection);

  /// 어느 탭에서 들어왔는지 (보내요 → sent, 받아요 → received)
  final RecordDirection initialDirection;

  @override
  EntryFormState build() => EntryFormState(direction: initialDirection, date: DateTime.now().dateOnly);

  // ── 입력값 반영 ────────────────────────
  void setDirection(RecordDirection value) => state = state.copyWith(direction: value);
  void setDate(DateTime value) => state = state.copyWith(date: value.dateOnly);
  void setEventType(EventType? value) => state = state.copyWith(eventType: () => value);
  void setPersonName(String value) => state = state.copyWith(personName: value);
  void setAmount(int value) => state = state.copyWith(amount: value);
  void setRelation(Relation? value) => state = state.copyWith(relation: () => value);
  void setMemo(String value) => state = state.copyWith(memo: value);

  /// 기록을 저장한다. 저장에 성공하면 true.
  ///
  /// - 이미 저장 중이면 아무것도 하지 않는다. (버튼 연타로 같은 기록이 두 번 저장되는 것을 방지)
  /// - 필수 항목이 비었으면 저장하지 않고 오류 문구를 켠다. (토스트 없이 칸 아래에 표시)
  /// - DB 저장 중 오류가 나면 [onError]로 알린다. (화면에서 오류 토스트를 띄움)
  Future<bool> save({ErrorCallback? onError}) async {
    if (state.isSaving) return false;
    if (!state.isValid) {
      state = state.copyWith(showErrors: true);
      return false;
    }

    state = state.copyWith(isSaving: true);
    try {
      await ref
          .read(ledgerRepositoryProvider)
          .add(
            direction: state.direction,
            eventType: state.eventType!,
            personName: state.personName,
            amount: state.amount,
            date: state.date,
            relation: state.relation,
            memo: state.memo,
          );
      return true;
    } catch (error) {
      onError?.call(error);
      return false;
    } finally {
      // 저장이 끝나기 전에 화면이 닫혔을 수 있으므로, ViewModel이 살아 있을 때만 상태를 바꾼다.
      if (ref.mounted) state = state.copyWith(isSaving: false);
    }
  }
}

/// 방향별 입력 화면 ViewModel. 화면이 닫히면(autoDispose) 입력하던 내용도 함께 정리된다.
final entryFormViewModelProvider = NotifierProvider.autoDispose
    .family<EntryFormViewModel, EntryFormState, RecordDirection>(EntryFormViewModel.new);
