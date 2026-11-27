import 'dart:async';

import 'package:maeum_book/core/theme/app_colors.dart';
import 'package:maeum_book/core/theme/app_dimens.dart';
import 'package:maeum_book/core/widgets/app_text.dart';
import 'package:material_ui/material_ui.dart';

/// 로딩 모양 두 가지
enum LoadingStyle {
  /// 버튼 안에 스피너가 도는 작업 (저장하기 · 로그인 · 엑셀 등). 화면은 그대로 보이고 **터치만 막는다.**
  /// 스피너는 버튼이 직접 그린다. (예: `state.isSaving ? 스피너 : 글자`)
  button,

  /// 따로 누른 버튼이 없는 작업 (밀어서 삭제 · 행사 삭제 · 로그아웃 등).
  /// 화면을 어둡게 덮고 가운데에 흰 스피너 + 흰 글자로 알려 준다.
  screen,
}

/// 앱 전체 로딩 막. 서버를 거치는 작업이 끝날 때까지 **어떤 동작도 못 하게** 막는다.
///
/// ```dart
/// await context.withLoading(() => viewModel.deleteEvent(), message: '행사를 지우는 중이에요');
/// await context.withLoading(() => viewModel.save(), style: LoadingStyle.button);
/// ```
///
/// ## 막는 것
/// - 화면 터치 (버튼 · 칸 · 탭 · 밀기 · 아이폰 옆에서 밀어 뒤로 가기)
/// - 안드로이드 뒤로 버튼
///
/// ## 보이는 것
/// | 시간 | [LoadingStyle.button] | [LoadingStyle.screen] |
/// |---|---|---|
/// | 0.3초까지 | 버튼 스피너만 | 아무것도 (금방 끝나는 비회원 작업이 깜빡이지 않게) · 터치는 이미 막힘 |
/// | 0.3초부터 | 버튼 스피너만 | 어두운 막 + 흰 스피너 + 문구 |
/// | 10초부터 | 버튼 스피너만 | + "연결이 느려요" |
///
/// 여러 작업이 겹치면 모두 끝날 때까지 막고, 하나라도 [LoadingStyle.screen]이면 어두운 막을 보여 준다.
/// 앱을 강제로 끄면 진행 중이던 통신은 휴대폰이 끊는다. (서버 통신 자체의 시간 제한은 TimeoutHttpClient)
class AppLoading extends StatefulWidget {
  const AppLoading({super.key, required this.child});

  final Widget child;

  /// 화면을 덮기 전에 기다리는 시간
  static const showDelay = Duration(milliseconds: 300);

  /// "연결이 느려요"를 덧붙이는 시간
  static const slowAfter = Duration(seconds: 10);

  static _AppLoadingState? _of(BuildContext context) => context.findAncestorStateOfType<_AppLoadingState>();

  @override
  State<AppLoading> createState() => _AppLoadingState();
}

class _Task {
  _Task(this.style, this.message);

  final LoadingStyle style;
  final String? message;
}

class _AppLoadingState extends State<AppLoading> with WidgetsBindingObserver {
  final List<_Task> _tasks = [];
  bool _showDim = false;
  bool _slow = false;
  Timer? _showTimer;
  Timer? _slowTimer;

  bool get _busy => _tasks.isNotEmpty;

  /// 지금 보여 줄 문구: 가장 최근에 시작한 어두운 막 작업의 문구
  _Task? get _screenTask => _tasks.lastWhereOrNull((task) => task.style == LoadingStyle.screen);

  @override
  void initState() {
    super.initState();
    // 이 위젯은 화면 이동(Router)보다 먼저 만들어져서, 뒤로 버튼 신호를 Router보다 먼저 받는다.
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _showTimer?.cancel();
    _slowTimer?.cancel();
    super.dispose();
  }

  /// 안드로이드 뒤로 버튼: 작업 중이면 "처리했다"고 답해서 화면이 닫히지 않게 한다.
  @override
  Future<bool> didPopRoute() async => _busy;

  Future<T> run<T>(Future<T> Function() task, LoadingStyle style, String? message) async {
    final entry = _Task(style, message);
    setState(() => _tasks.add(entry));
    _restartTimers();
    try {
      return await task();
    } finally {
      if (mounted) {
        setState(() => _tasks.remove(entry));
        _restartTimers();
      }
    }
  }

  void _restartTimers() {
    if (!_busy) {
      _showTimer?.cancel();
      _slowTimer?.cancel();
      _showTimer = _slowTimer = null;
      if (_showDim || _slow) setState(() => _showDim = _slow = false);
      return;
    }
    _showTimer ??= Timer(AppLoading.showDelay, () {
      if (mounted) setState(() => _showDim = true);
    });
    _slowTimer ??= Timer(AppLoading.slowAfter, () {
      if (mounted) setState(() => _slow = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenTask = _screenTask;
    final dim = _busy && _showDim && screenTask != null;
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        if (_busy)
          // 투명해도 모든 터치를 받아서 아래 화면에 전달하지 않는다.
          Positioned.fill(
            child: Semantics(
              label: screenTask?.message ?? '처리하는 중이에요',
              liveRegion: true,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                color: dim ? AppColors.loadingDim : Colors.transparent,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  onHorizontalDragStart: (_) {},
                  onVerticalDragStart: (_) {},
                  child: dim ? _DimContent(message: screenTask.message, slow: _slow) : const SizedBox.expand(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 어두운 막 가운데: 흰 스피너 + 흰 문구 (+ 오래 걸리면 안내)
class _DimContent extends StatelessWidget {
  const _DimContent({required this.message, required this.slow});

  final String? message;
  final bool slow;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox.square(dimension: 36, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)),
            const SizedBox(height: AppSpacing.lg),
            AppText.subtitle(message ?? '처리하는 중이에요', color: Colors.white, align: TextAlign.center),
            if (slow) ...[
              const SizedBox(height: AppSpacing.xs),
              AppText.caption('연결이 느려요. 조금만 기다려 주세요', color: AppColors.loadingDimSubtext, align: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}

/// 어디서든 `context.withLoading(...)`으로 쓴다.
extension AppLoadingContext on BuildContext {
  /// [task]가 끝날 때까지 앱 전체를 막고 결과를 돌려준다. 실패해도 막은 풀린다. (예외는 그대로 전달)
  ///
  /// [AppLoading]이 없는 곳(일부 테스트)에서는 막 없이 그냥 실행한다.
  Future<T> withLoading<T>(Future<T> Function() task, {LoadingStyle style = LoadingStyle.screen, String? message}) {
    final state = AppLoading._of(this);
    return state == null ? task() : state.run(task, style, message);
  }

  /// 나중에 쓸 로딩 막을 지금 잡아 둔다. 이 위젯이 화면에서 사라진 뒤에 실행될 작업에 쓴다.
  /// (예: 지운 줄은 사라졌는데 토스트의 "되돌리기"를 누를 때)
  LoadingRunner get loadingRunner {
    final state = AppLoading._of(this);
    return <T>(task, {style = LoadingStyle.screen, message}) =>
        state == null || !state.mounted ? task() : state.run(task, style, message);
  }
}

/// [AppLoadingContext.loadingRunner]가 돌려주는 함수
typedef LoadingRunner = Future<T> Function<T>(Future<T> Function() task, {LoadingStyle style, String? message});

extension<T> on List<T> {
  T? lastWhereOrNull(bool Function(T) test) {
    for (var i = length - 1; i >= 0; i--) {
      if (test(this[i])) return this[i];
    }
    return null;
  }
}
