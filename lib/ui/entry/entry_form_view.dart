import 'package:maeum_book/core/core.dart';
import 'package:maeum_book/data/data.dart';

/// 기록 입력 화면 (보낸 마음 / 받은 마음).
///
/// 탭 화면 위에 "한 단계 깊이" 쌓이는 화면이라, 하단 탭 없이 전체 화면으로 열리고 뒤로 가기로 돌아간다.
/// 경로: `/entry/new/sent`, `/entry/new/received` ([AppRoutes.entryNew])
// TODO: 다음 작업에서 입력 폼(날짜, 종류, 상대방, 금액, 메모)과 저장 기능을 구현한다.
class EntryFormView extends StatelessWidget {
  const EntryFormView({super.key, required this.direction});

  final RecordDirection direction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${direction == RecordDirection.sent ? '보낸' : '받은'} 마음 기록')),
      body: const EmptyView(icon: Icons.edit_outlined, title: '입력 화면 준비 중이에요'),
    );
  }
}
