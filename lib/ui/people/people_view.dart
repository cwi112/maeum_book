import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/base/base_view.dart';
import '../../core/theme/app_colors.dart';
import 'people_view_model.dart';

/// 사람별 정리 탭.
class PeopleView extends BaseAsyncView<PeopleViewModel, List<String>> {
  const PeopleView({super.key});

  @override
  AsyncNotifierProvider<PeopleViewModel, List<String>> get provider => peopleViewModelProvider;

  @override
  Widget buildView(BuildContext context, WidgetRef ref, List<String> data, PeopleViewModel viewModel) {
    return Scaffold(
      appBar: AppBar(title: const Text('사람')),
      body: data.isEmpty
          ? const Center(
              child: Text('아직 등록된 사람이 없어요', style: TextStyle(color: AppColors.textSecondary)),
            )
          : ListView(children: [for (final name in data) ListTile(title: Text(name))]),
    );
  }
}
