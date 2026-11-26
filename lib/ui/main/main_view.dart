import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';

/// 하단 탭(보내요 / 받아요 / 통계 / 설정)을 가진 메인 틀.
///
/// 어떤 탭이 선택됐는지는 go_router의 [StatefulNavigationShell]이 관리한다.
/// 그래서 이 화면에는 상태가 없고 ViewModel도 필요 없다. (탭 상태 = 현재 URL)
/// - [navigationShell]: 현재 탭의 화면. 탭마다 화면 상태(스크롤 위치 등)가 따로 유지된다.
class MainView extends StatelessWidget {
  const MainView({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// 탭을 누르면 해당 탭으로 이동한다. 이미 선택된 탭을 다시 누르면 그 탭의 첫 화면으로 돌아간다.
  void _onTap(int index) => navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      // 샘플 둘러보기 중이면 탭 바로 위에 안내 띠를 보여준다. (어느 탭에서든 지금 보는 게 샘플임을 알 수 있게)
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SampleTourBanner(),
          NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _onTap,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.outbox_outlined),
                selectedIcon: Icon(Icons.outbox),
                label: '보내요',
              ).testId(TestIds.tabSent),
              const NavigationDestination(
                icon: Icon(Icons.move_to_inbox_outlined),
                selectedIcon: Icon(Icons.move_to_inbox),
                label: '받아요',
              ).testId(TestIds.tabReceived),
              const NavigationDestination(
                icon: Icon(Icons.insert_chart_outlined),
                selectedIcon: Icon(Icons.insert_chart),
                label: '통계',
              ).testId(TestIds.tabStats),
              const NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: '설정',
              ).testId(TestIds.tabSettings),
            ],
          ),
        ],
      ),
    );
  }
}

/// "샘플 데이터로 둘러보는 중" 안내 띠 + [끝내기]. 샘플 모드가 아니면 아무것도 그리지 않는다.
class _SampleTourBanner extends ConsumerWidget {
  const _SampleTourBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(sampleModeProvider)) return const SizedBox.shrink();
    return Material(
      color: AppColors.primaryLight,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            const Icon(Icons.auto_awesome_outlined, size: 18, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(child: AppText.bodySmall('샘플 데이터로 둘러보는 중이에요 · 앱을 끄면 사라져요')),
            TextButton(
              onPressed: ref.read(sampleModeProvider.notifier).exit,
              child: const Text('끝내기'),
            ).testId(TestIds.sampleTourEnd),
          ],
        ).paddingSymmetric(horizontal: AppSpacing.md),
      ),
    );
  }
}
