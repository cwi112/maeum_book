import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/base/base_view_model.dart';

/// 경조사 내역 탭의 ViewModel. 상태(state) = 내역 목록.
class HistoryViewModel extends BaseAsyncViewModel<List<String>> {
  // TODO: 내역 모델(models/)과 저장소(data/)를 만든 뒤 실제 데이터로 바꾼다.
  @override
  Future<List<String>> load() async => [];
}

final historyViewModelProvider =
    AsyncNotifierProvider.autoDispose<HistoryViewModel, List<String>>(HistoryViewModel.new);
