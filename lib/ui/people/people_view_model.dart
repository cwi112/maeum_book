import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/base/base_view_model.dart';

/// 사람별 정리 탭의 ViewModel. 상태(state) = 사람 목록.
class PeopleViewModel extends BaseAsyncViewModel<List<String>> {
  // TODO: 사람 모델과 저장소를 만든 뒤 실제 데이터로 바꾼다.
  @override
  Future<List<String>> load() async => [];
}

final peopleViewModelProvider =
    AsyncNotifierProvider.autoDispose<PeopleViewModel, List<String>>(PeopleViewModel.new);
