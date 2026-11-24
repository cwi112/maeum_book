/// 자주 쓰는 함수 타입 별칭 모음.
///
/// `void Function(int value)`처럼 긴 함수 타입을 매번 쓰는 대신 짧은 이름을 붙여 둔다.
/// 위젯 파라미터로 콜백을 받을 때 이 이름을 쓰면 읽기 쉽고 형태가 통일된다.
///
/// ```dart
/// class AmountInput extends StatelessWidget {
///   const AmountInput({super.key, required this.onChanged});
///   final IntCallback onChanged;               // void Function(int value)
/// }
///
/// Future<bool> save({ErrorCallback? onError}); // void Function(Object error)
/// ```
///
/// Flutter에 이미 있는 콜백 타입도 같이 내보내서, 이 파일 하나로 모두 쓸 수 있다.
/// - `VoidCallback` : `void Function()` — 값 없이 눌렀을 때
/// - `ValueChanged<T>` : `void Function(T value)` — 값이 바뀔 때
/// - `AsyncCallback` : `Future<void> Function()` — 값 없이 비동기 작업
library;

export 'package:flutter/foundation.dart' show AsyncCallback, ValueChanged, ValueGetter, ValueSetter, VoidCallback;

// ── 값 하나를 받는 콜백 ──────────────────
/// 어떤 타입이든 값 하나를 받는 콜백
typedef ValueCallback<T> = void Function(T value);

typedef IntCallback = void Function(int value);
typedef DoubleCallback = void Function(double value);
typedef StringCallback = void Function(String value);
typedef BoolCallback = void Function(bool value);
typedef DateTimeCallback = void Function(DateTime value);

/// 값이 없을 수도 있는 콜백 (예: 선택을 취소하면 null)
typedef NullableCallback<T> = void Function(T? value);

// ── 비동기·오류 ──────────────────────────
/// 값 하나를 받아 비동기 작업을 하는 콜백 (예: 저장)
typedef AsyncValueCallback<T> = Future<void> Function(T value);

/// 오류를 받는 콜백 (예: 저장 실패 시 스낵바 띄우기)
typedef ErrorCallback = void Function(Object error);

// ── 목록 ────────────────────────────────
/// 목록에서 몇 번째인지와 그 값을 함께 받는 콜백
typedef IndexedValueCallback<T> = void Function(int index, T value);
