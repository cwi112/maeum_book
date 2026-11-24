/// 날짜 표시용 확장.
///
/// ```dart
/// date.toDotDate        // '2026.11.24'
/// date.toKoreanDate     // '11월 24일 (화)'
/// date.isSameDay(other)
/// ```
extension DateTimeX on DateTime {
  static const List<String> _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  String get _mm => month.toString().padLeft(2, '0');
  String get _dd => day.toString().padLeft(2, '0');

  /// '2026.11.24'
  String get toDotDate => '$year.$_mm.$_dd';

  /// 요일 한 글자 ('월' ~ '일')
  String get koreanWeekday => _weekdays[weekday - 1];

  /// '11월 24일 (화)'
  String get toKoreanDate => '$month월 $day일 ($koreanWeekday)';

  /// '2026년 11월 24일'
  String get toKoreanFullDate => '$year년 $month월 $day일';

  bool isSameDay(DateTime other) => year == other.year && month == other.month && day == other.day;

  /// 시·분·초를 뺀 날짜
  DateTime get dateOnly => DateTime(year, month, day);
}
