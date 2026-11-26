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

  /// 하단 탭 4개: (아이콘, 선택됐을 때 아이콘, 이름, 자동화 테스트 이름)
  static const _tabs = [
    (Icons.outbox_outlined, Icons.outbox, '보내요', TestIds.tabSent),
    (Icons.move_to_inbox_outlined, Icons.move_to_inbox, '받아요', TestIds.tabReceived),
    (Icons.insert_chart_outlined, Icons.insert_chart, '통계', TestIds.tabStats),
    (Icons.settings_outlined, Icons.settings, '설정', TestIds.tabSettings),
  ];

  /// 탭을 누르면 해당 탭으로 이동한다. 이미 선택된 탭을 다시 누르면 아무것도 하지 않는다.
  void _onTap(int index) {
    if (index == navigationShell.currentIndex) return;
    navigationShell.goBranch(index);
  }

  /// 탭 하나.
  /// - `tooltip: ''`: 길게 눌렀을 때 뜨는 툴팁 끄기 (빈 문자열이면 Flutter가 툴팁을 그리지 않음)
  /// - 이미 선택된 탭은 눌러도 물결(splash) · 눌림 색(highlight)이 보이지 않게 효과 색을 투명으로 한다.
  ///   탭 바는 "선택됨" 상태로 효과 색을 고를 수 없지만, 각 탭이 바로 위의 [NavigationBarTheme]에서 효과 색을 읽기 때문에
  ///   선택된 탭만 테마로 감싸 투명색을 준다. (물결 · 눌림 색 모두 이 overlayColor를 쓴다)
  Widget _destination(BuildContext context, int index) {
    final (icon, selectedIcon, label, testId) = _tabs[index];
    final destination = NavigationDestination(
      icon: Icon(icon),
      selectedIcon: Icon(selectedIcon),
      label: label,
      tooltip: '',
    ).testId(testId);
    if (index != navigationShell.currentIndex) return destination;
    return NavigationBarTheme(
      data: NavigationBarTheme.of(context).copyWith(overlayColor: const WidgetStatePropertyAll(Colors.transparent)),
      child: destination,
    );
  }

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
            destinations: [for (var i = 0; i < _tabs.length; i++) _destination(context, i)],
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
