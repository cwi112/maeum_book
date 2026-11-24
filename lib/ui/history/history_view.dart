import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/base/base_view.dart';
import '../../core/theme/app_colors.dart';
import 'history_view_model.dart';

/// 경조사 내역 탭.
class HistoryView extends BaseAsyncView<HistoryViewModel, List<String>> {
  const HistoryView({super.key});

  @override
  AsyncNotifierProvider<HistoryViewModel, List<String>> get provider => historyViewModelProvider;

  @override
  Widget buildView(BuildContext context, WidgetRef ref, List<String> data, HistoryViewModel viewModel) {
    return Scaffold(
      appBar: AppBar(title: const Text('내역')),
      body: data.isEmpty
          ? const Center(
              child: Text('아직 기록된 내역이 없어요', style: TextStyle(color: AppColors.textSecondary)),
            )
          : ListView(children: [for (final item in data) ListTile(title: Text(item))]),
    );
  }
}
