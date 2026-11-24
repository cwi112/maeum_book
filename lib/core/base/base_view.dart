import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maeum_book/core/base/base_view_model.dart';
import 'package:maeum_book/core/theme/app_colors.dart';
import 'package:material_ui/material_ui.dart';

/// 일반 화면(View)의 부모 클래스. [BaseViewModel]과 짝을 이룬다.
///
/// ```dart
/// class CounterView extends BaseView<CounterViewModel, int> {
///   const CounterView({super.key});
///
///   @override
///   NotifierProvider<CounterViewModel, int> get provider => counterViewModelProvider;
///
///   @override
///   Widget buildView(BuildContext context, WidgetRef ref, int state, CounterViewModel viewModel) {
///     return TextButton(onPressed: viewModel.increment, child: Text('$state'));
///   }
/// }
/// ```
///
/// - [provider]의 상태가 바뀌면 [buildView]가 자동으로 다시 실행된다.
/// - 버튼 등에서 동작을 실행할 때는 `viewModel.메서드()`를 부른다.
abstract class BaseView<VM extends BaseViewModel<S>, S> extends ConsumerWidget {
  const BaseView({super.key});

  /// 이 화면이 사용할 ViewModel의 provider.
  NotifierProvider<VM, S> get provider;

  /// 화면을 그린다. [state]가 바뀔 때마다 다시 호출된다.
  Widget buildView(BuildContext context, WidgetRef ref, S state, VM viewModel);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(provider);
    final viewModel = ref.read(provider.notifier);
    return buildView(context, ref, state, viewModel);
  }
}

/// 데이터를 불러오는 화면(View)의 부모 클래스. [BaseAsyncViewModel]과 짝을 이룬다.
///
/// - 불러오는 중이면 [buildLoading], 실패하면 [buildError], 성공하면 [buildView]를 그린다.
/// - 로딩·오류 화면을 바꾸고 싶으면 하위 클래스에서 [buildLoading]/[buildError]를 다시 정의한다.
abstract class BaseAsyncView<VM extends BaseAsyncViewModel<S>, S> extends ConsumerWidget {
  const BaseAsyncView({super.key});

  /// 이 화면이 사용할 ViewModel의 provider.
  AsyncNotifierProvider<VM, S> get provider;

  /// 데이터를 불러온 뒤의 화면을 그린다.
  Widget buildView(BuildContext context, WidgetRef ref, S data, VM viewModel);

  /// 로딩 중 화면.
  Widget buildLoading(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }

  /// 오류 화면. 기본으로 오류 문구와 "다시 시도" 버튼을 보여준다.
  Widget buildError(BuildContext context, Object error, VoidCallback retry) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('문제가 발생했어요', style: TextStyle(color: AppColors.error)),
          const SizedBox(height: 4),
          Text('$error', style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          FilledButton(onPressed: retry, child: const Text('다시 시도')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(provider);
    final viewModel = ref.read(provider.notifier);
    return asyncState.when(
      data: (data) => buildView(context, ref, data, viewModel),
      loading: () => buildLoading(context),
      error: (error, _) => buildError(context, error, viewModel.reload),
    );
  }
}
