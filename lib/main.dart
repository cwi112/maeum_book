import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';

void main() {
  // ProviderScope: Riverpod의 모든 provider(ViewModel)가 이 안에서 동작한다.
  runApp(const ProviderScope(child: App()));
}
