import 'package:maeum_book/core/core.dart';

/// 보내요 탭의 ViewModel. 상태(state) = 보낸 내역 목록.
class SentViewModel extends BaseAsyncViewModel<List<String>> {
  // TODO: 내역 모델(models/)과 저장소(data/)를 만든 뒤 실제 데이터로 바꾼다.
  @override
  Future<List<String>> load() async => [];
}

final sentViewModelProvider = AsyncNotifierProvider.autoDispose<SentViewModel, List<String>>(SentViewModel.new);
