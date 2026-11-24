import 'package:flutter_test/flutter_test.dart';
import 'package:maeum_book/core/extensions/extensions.dart';

void main() {
  group('IntX', () {
    test('세 자리마다 쉼표를 넣는다', () {
      expect(0.comma, '0');
      expect(1000.comma, '1,000');
      expect(1234567.comma, '1,234,567');
      expect((-50000).comma, '-50,000');
    });

    test('원 단위로 표시한다', () => expect(50000.won, '50,000원'));

    test('만 원 단위로 표시한다', () {
      expect(5000.manWon, '5,000원');
      expect(50000.manWon, '5만원');
      expect(55000.manWon, '5만 5,000원');
      expect(1500000.manWon, '150만원');
    });
  });

  group('StringX', () {
    test('금액 문자열을 정수로 바꾼다', () {
      expect('50,000원'.toAmount, 50000);
      expect('abc'.toAmount, isNull);
    });

    test('공백 문자열을 판별한다', () {
      expect('  '.isBlank, isTrue);
      expect((null as String?).isNullOrBlank, isTrue);
    });
  });

  group('DateTimeX', () {
    final date = DateTime(2026, 11, 24);

    test('날짜를 한국식으로 표시한다', () {
      expect(date.toDotDate, '2026.11.24');
      expect(date.toKoreanDate, '11월 24일 (화)');
      expect(date.toKoreanFullDate, '2026년 11월 24일');
    });

    test('같은 날인지 비교한다', () => expect(date.isSameDay(DateTime(2026, 11, 24, 13)), isTrue));
  });
}
