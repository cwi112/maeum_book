import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:maeum_book/core/extensions/extensions.dart';
import 'package:maeum_book/core/theme/app_colors.dart';
import 'package:maeum_book/core/theme/app_dimens.dart';
import 'package:maeum_book/core/theme/app_text_styles.dart';
import 'package:material_ui/material_ui.dart';

/// 목록 화면의 공통 틀. 스크롤에 따라 **위쪽 그림자**와 **기록 버튼(FAB) 모양**이 바뀐다.
///
/// ```dart
/// AppListScaffold(
///   title: '보내요',
///   top: Column(children: [SummaryCard(...), SearchField(...)]),   // 고정되는 위쪽 (선택)
///   body: ListView(...),                                          // 스크롤되는 목록
///   fab: AppListFab(label: '보낸 마음 기록', icon: Icons.edit_outlined, onPressed: ...),
/// )
/// ```
///
/// ## 위쪽 그림자
/// - [top]이 있으면: 앱바+[top]을 하나의 고정 영역으로 보고, 목록이 조금이라도 내려가면 그 아래에 옅은 그림자를 띄운다.
///   (앱바 자체 그림자는 끈다. 그림자가 두 줄로 생기지 않게)
/// - [top]이 없으면: 앱바가 테마 설정대로 스크롤 시 그림자를 띄운다.
///
/// ## 기록 버튼(FAB)
/// | 상황 | 모양 |
/// |---|---|
/// | 맨 위에 있거나 위로 올릴 때 | 글자가 있는 버튼 (✏️ 보낸 마음 기록) |
/// | 아래로 내릴 때 | 작은 동그라미 (✏️) |
/// | 목록 맨 끝에 닿았을 때 | 아래로 숨김 → 마지막 줄을 가리지 않는다 |
///
/// 그래서 목록 아래에 버튼 크기만큼 큰 빈 공간을 두지 않아도 된다.
class AppListScaffold extends StatefulWidget {
  const AppListScaffold({super.key, required this.title, required this.body, this.top, this.fab, this.actions});

  final String title;

  /// 앱바 아래 고정 영역 (합계 카드, 검색창 등)
  final Widget? top;

  /// 스크롤되는 내용 (ListView 등). 빈 화면 안내처럼 스크롤이 없는 위젯이어도 된다.
  final Widget body;
  final AppListFab? fab;
  final List<Widget>? actions;

  @override
  State<AppListScaffold> createState() => _AppListScaffoldState();
}

/// 기록 버튼 상태
enum _FabMode { extended, collapsed, hidden }

class _AppListScaffoldState extends State<AppListScaffold> {
  bool _scrolled = false;
  _FabMode _fabMode = _FabMode.extended;

  /// 스크롤이 일어날 때마다 Flutter가 위로 올려 보내는 알림(ScrollNotification)을 받아 상태를 정한다.
  /// depth == 0: 이 화면의 바로 그 목록에서 온 알림만 본다. (목록 안의 가로 스크롤 등은 무시)
  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    final metrics = notification.metrics;

    final scrolled = metrics.pixels > 0;
    var mode = _fabMode;
    if (notification is UserScrollNotification) {
      // 사용자가 민 방향 알림. 손가락을 대는 순간(아직 위치가 바뀌기 전)에 먼저 오므로, 위치보다 방향을 먼저 본다.
      // reverse = 아래로 내림 → 접기, forward = 위로 올림 → 펼치기
      if (notification.direction == ScrollDirection.reverse) mode = _FabMode.collapsed;
      if (notification.direction == ScrollDirection.forward) mode = _FabMode.extended;
    } else if (notification is ScrollUpdateNotification) {
      // 위치가 실제로 바뀔 때: 맨 위/맨 끝인지 본다.
      if (metrics.pixels <= 0) {
        mode = _FabMode.extended; // 맨 위
      } else if (metrics.extentAfter < 8 && metrics.maxScrollExtent > 0) {
        mode = _FabMode.hidden; // 맨 끝
      } else if (mode == _FabMode.hidden) {
        mode = _FabMode.collapsed; // 끝에서 조금 올라오면 다시 보이게
      }
    }

    // 값이 바뀔 때만 다시 그린다. (스크롤 중 매 프레임 setState 하지 않도록)
    if (scrolled != _scrolled || mode != _fabMode) {
      setState(() {
        _scrolled = scrolled;
        _fabMode = mode;
      });
    }
    return false; // 알림을 위로 계속 전달 (앱바 등도 받을 수 있게)
  }

  /// 처음 상태(그림자 없음, 글자 버튼)로 되돌린다.
  void _reset() {
    if (!_scrolled && _fabMode == _FabMode.extended) return;
    setState(() {
      _scrolled = false;
      _fabMode = _FabMode.extended;
    });
  }

  /// 목록 내용의 크기가 바뀔 때(기록이 지워져 짧아질 때 등) 오는 알림.
  /// 스크롤할 거리가 없어졌으면 사용자가 스크롤하지 않아도 처음 상태로 되돌린다.
  bool _onMetricsChanged(ScrollMetricsNotification notification) {
    if (notification.depth != 0) return false;
    final metrics = notification.metrics;
    if (metrics.maxScrollExtent <= 0 || metrics.pixels <= 0) _reset();
    return false;
  }

  /// 목록이 빈 화면 안내로 바뀌면 스크롤 알림이 더 오지 않는다.
  /// 그래서 스크롤 중이던 상태(그림자 · 숨겨진 버튼)가 그대로 남지 않도록 body 종류가 바뀔 때 되돌린다.
  @override
  void didUpdateWidget(AppListScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.body.runtimeType != widget.body.runtimeType) {
      _scrolled = false;
      _fabMode = _FabMode.extended;
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = widget.top;
    final body = NotificationListener<ScrollMetricsNotification>(
      onNotification: _onMetricsChanged,
      child: NotificationListener<ScrollNotification>(onNotification: _onScroll, child: widget.body),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: widget.actions,
        // 위쪽 고정 영역이 있으면 그림자는 그 영역 아래에 그리므로 앱바 그림자는 끈다.
        notificationPredicate: top == null ? defaultScrollNotificationPredicate : (_) => false,
      ),
      body: top == null
          ? body
          // verticalDirection.up: 아래(목록)부터 배치하고 위쪽 영역을 **나중에 그린다**.
          // 그래야 위쪽 영역의 그림자가 목록 위에 덮여 보인다. (먼저 그리면 목록이 그림자를 가림)
          : Column(
              verticalDirection: VerticalDirection.up,
              children: [
                body.expanded(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    boxShadow: _scrolled
                        ? [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))]
                        : const [],
                  ),
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: top,
                ),
              ],
            ),
      floatingActionButton: widget.fab == null ? null : _AnimatedFab(fab: widget.fab!, mode: _fabMode),
    );
  }
}

/// 목록 화면의 기록 버튼 정보.
class AppListFab {
  const AppListFab({required this.label, required this.icon, required this.onPressed, this.testId});

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final String? testId;
}

/// 상태에 따라 글자 버튼 ↔ 동그라미 ↔ 숨김으로 부드럽게 바뀌는 버튼.
class _AnimatedFab extends StatelessWidget {
  const _AnimatedFab({required this.fab, required this.mode});

  final AppListFab fab;
  final _FabMode mode;

  static const double _size = 48;
  static const Duration _duration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final extended = mode == _FabMode.extended;
    final button = Material(
      color: AppColors.primary,
      elevation: 3,
      shadowColor: AppColors.shadow,
      shape: const StadiumBorder(), // 양끝이 둥근 알약 모양. 글자가 접히면 자연스럽게 동그라미가 된다.
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: fab.onPressed,
        splashColor: Colors.white24,
        highlightColor: Colors.white10,
        child: SizedBox(
          height: _size,
          // AnimatedSize: 글자가 접히고 펼쳐질 때 버튼 너비가 부드럽게 바뀐다.
          child: AnimatedSize(
            duration: _duration,
            curve: Curves.easeOutCubic,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: extended ? AppSpacing.md + 2 : (_size - 22) / 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(fab.icon, color: Colors.white, size: 22),
                  if (extended) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Text(fab.label, style: AppTextStyles.label.withColor(Colors.white)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // 맨 끝에 닿으면 아래로 미끄러지며 사라진다. 숨겨진 동안에는 눌리지 않게 막는다.
    final hidden = mode == _FabMode.hidden;
    return IgnorePointer(
      ignoring: hidden,
      child: AnimatedSlide(
        offset: hidden ? const Offset(0, 2) : Offset.zero,
        duration: _duration,
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: hidden ? 0 : 1,
          duration: _duration,
          child: Tooltip(message: fab.label, child: fab.testId == null ? button : button.testId(fab.testId!)),
        ),
      ),
    );
  }
}
