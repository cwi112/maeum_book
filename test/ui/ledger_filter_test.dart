import 'package:flutter_test/flutter_test.dart';
import 'package:maeum_book/data/data.dart';
import 'package:maeum_book/ui/ledger/ledger_list_view_model.dart';

void main() {
  final now = DateTime(2026, 11, 24);

  LedgerEntry entry(String name, DateTime date, {EventType type = EventType.wedding, String? memo}) => LedgerEntry(
    id: 1,
    direction: RecordDirection.sent,
    eventType: type,
    personName: name,
    amount: 50000,
    date: date,
    memo: memo,
    createdAt: now,
    updatedAt: now,
  );

  test('검색어는 이름과 메모에서 대소문자 구분 없이 찾는다', () {
    const filter = LedgerFilter(query: 'kim');
    expect(filter.matches(entry('Kim', now), now), isTrue);
    expect(filter.matches(entry('이영희', now, memo: 'KIM 결혼식'), now), isTrue);
    expect(filter.matches(entry('이영희', now), now), isFalse);
  });

  test('기간 필터는 올해·작년·최근 3개월을 구분한다', () {
    expect(LedgerPeriod.thisYear.contains(DateTime(2026, 1, 1), now), isTrue);
    expect(LedgerPeriod.thisYear.contains(DateTime(2025, 12, 31), now), isFalse);
    expect(LedgerPeriod.lastYear.contains(DateTime(2025, 6, 1), now), isTrue);
    expect(LedgerPeriod.recent3Months.contains(DateTime(2026, 8, 24), now), isTrue);
    expect(LedgerPeriod.recent3Months.contains(DateTime(2026, 8, 23), now), isFalse);
  });

  test('여러 조건은 모두 만족해야 한다(AND)', () {
    const filter = LedgerFilter(query: '김', eventType: EventType.funeral, period: LedgerPeriod.thisYear);
    expect(filter.matches(entry('김철수', now, type: EventType.funeral), now), isTrue);
    expect(filter.matches(entry('김철수', now), now), isFalse);
    expect(filter.matches(entry('김철수', DateTime(2025), type: EventType.funeral), now), isFalse);
  });

  test('필터 결과에 맞춰 합계와 건수가 바뀐다', () {
    final state = LedgerListState(
      allEntries: [entry('김철수', now), entry('이영희', now)],
      filter: const LedgerFilter(query: '김'),
      now: now,
    );
    expect(state.count, 1);
    expect(state.total, 50000);
    expect(state.hasNoRecords, isFalse);
  });
}
