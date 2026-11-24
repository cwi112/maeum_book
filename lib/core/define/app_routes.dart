/// 화면 이동 경로(URL) 모음. go_router가 이 경로로 화면을 찾는다.
///
/// 경로 문자열을 화면마다 직접 쓰지 않고 여기 이름으로 쓴다. 오타로 이동이 안 되는 실수를 막기 위함이다.
///
/// ```dart
/// context.go(AppRoutes.stats);                         // 탭 전환 (기록이 쌓이지 않음)
/// context.push(AppRoutes.entryNew(RecordDirection.sent)); // 화면 위에 새 화면을 쌓음 (뒤로 가기 가능)
/// ```
abstract final class AppRoutes {
  // ── 하단 탭 ────────────────────────────
  static const String sent = '/sent';
  static const String received = '/received';
  static const String stats = '/stats';
  static const String settings = '/settings';

  /// 앱을 켰을 때 처음 보여줄 화면
  static const String initial = sent;

  // ── 깊이(depth)가 있는 화면 ────────────
  /// 기록 입력 화면 경로 패턴. `:direction` 자리에 'sent' 또는 'received'가 들어간다.
  static const String entryNewPattern = '/entry/new/:direction';

  /// 기록 입력 화면으로 갈 실제 경로를 만든다. 예) `/entry/new/sent`
  static String entryNew(Enum direction) => '/entry/new/${direction.name}';

  /// 기록 수정 화면 경로 패턴. `:id` 자리에 기록 번호가 들어간다.
  static const String entryEditPattern = '/entry/:id/edit';

  /// 기록 수정 화면으로 갈 실제 경로. 예) `/entry/12/edit`
  static String entryEdit(int id) => '/entry/$id/edit';
}
