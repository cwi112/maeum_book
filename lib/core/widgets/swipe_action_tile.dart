import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:maeum_book/core/extensions/widget_extension.dart';
import 'package:maeum_book/core/theme/app_colors.dart';
import 'package:maeum_book/core/theme/app_dimens.dart';
import 'package:maeum_book/core/widgets/app_text.dart';
import 'package:material_ui/material_ui.dart';

/// 밀었을 때 나오는 버튼 하나의 정보.
class SwipeAction {
  const SwipeAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.pressedColor,
    required this.onPressed,
    this.testId,
  });

  /// 삭제 버튼 기본 모양 (장밋빛, 누르면 진하게)
  const SwipeAction.delete({required VoidCallback onPressed, String? testId})
    : this(
        label: '삭제',
        icon: Icons.delete_outline_rounded,
        color: AppColors.deleteAction,
        pressedColor: AppColors.deleteActionPressed,
        onPressed: onPressed,
        testId: testId,
      );

  /// 수정 버튼 기본 모양 (꿀색, 누르면 진하게)
  const SwipeAction.edit({required VoidCallback onPressed, String? testId})
    : this(
        label: '수정',
        icon: Icons.edit_outlined,
        color: AppColors.editAction,
        pressedColor: AppColors.editActionPressed,
        onPressed: onPressed,
        testId: testId,
      );

  final String label;
  final IconData icon;

  /// 평소 배경색 / 누르고 있을 때 배경색
  final Color color;
  final Color pressedColor;
  final VoidCallback onPressed;
  final String? testId;
}

/// 아이폰처럼 **왼쪽으로 밀면 오른쪽에서 버튼이 나오는** 목록 한 줄.
///
/// ```dart
/// SwipeActionTile(
///   key: ValueKey(entry.id),   // 꼭 넣는다. (아래 설명)
///   actions: [SwipeAction.edit(onPressed: ...), SwipeAction.delete(onPressed: ...)],
///   child: LedgerEntryTile(entry: entry),
/// )
/// ```
///
/// ## key가 꼭 필요한 이유
/// 목록에서 한 줄이 지워지면 Flutter는 위치(순서)로 위젯을 다시 짝지으려 한다.
/// key가 없으면 "열려 있던 상태"가 지워진 줄의 다음 줄로 옮겨 붙는 문제가 생긴다.
///
/// ## 동작
/// - 버튼을 누르면 먼저 열린 줄을 닫고 [SwipeAction.onPressed]를 실행한다.
/// - 한 줄을 열면 다른 열린 줄은 자동으로 닫힌다. (목록을 `SlidableAutoCloseBehavior`로 감싼 경우)
class SwipeActionTile extends StatelessWidget {
  const SwipeActionTile({super.key, required this.actions, required this.child});

  final List<SwipeAction> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Slidable(
      // 이 묶음(group) 안에서는 한 번에 한 줄만 열린다.
      groupTag: 'swipe_action_tile',
      endActionPane: ActionPane(
        motion: const DrawerMotion(), // 버튼이 서랍처럼 함께 밀려 나오는 효과
        extentRatio: 0.18 * actions.length, // 버튼 하나당 화면 너비의 18%
        children: [for (final action in actions) _SwipeActionButton(action: action)],
      ),
      child: child,
    );
  }
}

/// 밀어서 나온 버튼. 누르고 있는 동안 배경이 [SwipeAction.pressedColor]로 바뀐다.
class _SwipeActionButton extends StatelessWidget {
  const _SwipeActionButton({required this.action});

  final SwipeAction action;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: action.color,
      child: InkWell(
        // 누르는 동안의 색(highlight)과 물결(splash)을 버튼 색에 맞춘다.
        highlightColor: action.pressedColor,
        splashColor: action.pressedColor,
        onTap: () {
          Slidable.of(context)?.close();
          action.onPressed();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, color: Colors.white, size: 22),
            const SizedBox(height: AppSpacing.xs),
            AppText.caption(action.label, color: Colors.white),
          ],
        ),
      ),
    );
    return Expanded(child: action.testId == null ? button : button.testId(action.testId!));
  }
}
