import 'package:maeum_book/core/core.dart';

/// 받아요 탭의 ViewModel. 상태(state) = 받은 내역 목록.
class ReceivedViewModel extends BaseAsyncViewModel<List<String>> {
  // TODO: 내역 모델(models/)과 저장소(data/)를 만든 뒤 실제 데이터로 바꾼다.
  @override
  Future<List<String>> load() async => [];
}

final receivedViewModelProvider = AsyncNotifierProvider.autoDispose<ReceivedViewModel, List<String>>(
  ReceivedViewModel.new,
);
