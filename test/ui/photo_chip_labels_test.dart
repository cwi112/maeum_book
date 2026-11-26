import 'package:flutter_test/flutter_test.dart';
import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';
import 'package:maeum_book/ui/event/widgets/photo_info_sheet.dart';

/// 사진 보낸 분 칩 이름표: 동명이인이 어디까지 같아도 칩끼리 겹치지 않는다.
void main() {
  LedgerEntry entry(int id, String name, {Relation? relation, int amount = 100000, String? memo}) => LedgerEntry(
    id: id,
    direction: RecordDirection.received,
    eventTypeId: 1,
    eventId: 1,
    personName: name,
    amount: amount,
    date: DateTime(2026, 5, 10),
    relation: relation,
    memo: memo,
    createdAt: DateTime(2026, 5, 10),
    updatedAt: DateTime(2026, 5, 10),
  );

  test('이름이 하나뿐이면 이름만, 같은 이름이면 관계 · 금액을 붙인다', () {
    final labels = PhotoInfoSheet.chipLabels([
      entry(1, '이서연'),
      entry(2, '김민준', relation: Relation.friend),
      entry(3, '김민준', relation: Relation.work, amount: 50000),
    ]);
    expect(labels, {1: '이서연', 2: '김민준 (친구 · 10만원)', 3: '김민준 (직장 · 5만원)'});
  });

  test('이름 · 관계 · 금액까지 같으면 메모, 메모까지 같으면 기록한 순서 번호를 붙인다', () {
    final labels = PhotoInfoSheet.chipLabels([
      entry(1, '김민준', relation: Relation.friend, memo: '회사 동기'),
      entry(2, '김민준', relation: Relation.friend, memo: '고향 친구'),
      entry(3, '박지훈', relation: Relation.friend),
      entry(4, '박지훈', relation: Relation.friend),
    ]);
    expect(labels[1], '김민준 (친구 · 10만원 · 회사 동기)');
    expect(labels[2], '김민준 (친구 · 10만원 · 고향 친구)');
    expect(labels[3], '박지훈 (친구 · 10만원) 1');
    expect(labels[4], '박지훈 (친구 · 10만원) 2');
    expect(labels.values.toSet(), hasLength(4)); // 모두 다르다
  });

  test('앱이 연 화면(앨범 등)에 다녀오는 동안 · 직후에는 "돌아오는 중"으로 본다', () async {
    expect(InAppHandoff.isReturning, isFalse);
    var during = false;
    await InAppHandoff.run(() async => during = InAppHandoff.isReturning);
    expect(during, isTrue);
    expect(InAppHandoff.isReturning, isTrue); // 끝난 직후 (몇 초 여유)
  });
}
