/// 문자열 확장.
///
/// ```dart
/// '  '.isBlank            // true
/// '50,000원'.digitsOnly   // '50000'
/// '50,000'.toAmount       // 50000
/// ```
extension StringX on String {
  /// 공백만 있거나 비어 있으면 true
  bool get isBlank => trim().isEmpty;

  bool get isNotBlank => !isBlank;

  /// 숫자만 남긴다 (금액 입력값 정리용)
  String get digitsOnly => replaceAll(RegExp(r'[^0-9]'), '');

  /// 금액 문자열을 정수로. 숫자가 없으면 null
  int? get toAmount => int.tryParse(digitsOnly);
}

extension NullableStringX on String? {
  /// null이거나 공백뿐이면 true
  bool get isNullOrBlank => this == null || this!.trim().isEmpty;
}
