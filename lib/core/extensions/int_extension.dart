/// 금액 표시용 정수 확장.
///
/// ```dart
/// 50000.comma     // '50,000'
/// 50000.won       // '50,000원'
/// 150000.manWon   // '15만원'
/// 55000.manWon    // '5만 5,000원'
/// ```
extension IntX on int {
  static final RegExp _thousands = RegExp(r'\B(?=(\d{3})+(?!\d))');

  /// 세 자리마다 쉼표
  String get comma => toString().replaceAll(_thousands, ',');

  /// 쉼표 + '원'
  String get won => '$comma원';

  /// 만 원 단위로 읽기 쉽게 (경조사 금액 표시용)
  String get manWon {
    if (abs() < 10000) return won;
    final sign = isNegative ? '-' : '';
    final man = abs() ~/ 10000;
    final rest = abs() % 10000;
    return rest == 0 ? '$sign${man.comma}만원' : '$sign${man.comma}만 ${rest.comma}원';
  }
}
