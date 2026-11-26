import 'package:flutter_test/flutter_test.dart';
import 'package:maeum_book/core/core.dart';

/// 도넛 그래프: 조각을 누르면 범례가 굵게, 그래프 밖을 누르면 풀린다.
void main() {
  FontWeight? weightOf(WidgetTester tester, String label) {
    final text = tester.widget<Text>(find.text(label));
    return text.style?.fontWeight;
  }

  testWidgets('조각을 누르면 범례가 굵어지고, 그래프 밖을 누르면 원래대로 돌아온다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const DonutChart(
                slices: [
                  ChartSlice(label: '보낸 마음', value: 100, color: Colors.red),
                  ChartSlice(label: '받은 마음', value: 100, color: Colors.teal),
                ],
              ),
              const SizedBox(height: 40),
              TextButton(onPressed: () {}, child: const Text('바깥')),
            ],
          ),
        ),
      ),
    );
    final normal = weightOf(tester, '보낸 마음');

    // 오른쪽 반 = 첫 조각(12시부터 시계 방향). 그래프 중심에서 오른쪽으로 조금 떨어진 곳을 누른다.
    final chart = tester.getRect(find.byType(DonutChart).first);
    final center = Offset(chart.center.dx, chart.top + 100);
    await tester.tapAt(center + const Offset(80, 0));
    await tester.pump();
    expect(weightOf(tester, '보낸 마음'), isNot(normal));

    await tester.tap(find.text('바깥'));
    await tester.pump();
    expect(weightOf(tester, '보낸 마음'), normal);
  });
}
