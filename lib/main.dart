import 'package:maeum_book/app.dart';
import 'package:maeum_book/core/core.dart';

void main() {
  // ProviderScope: Riverpod의 모든 provider(ViewModel)가 이 안에서 동작한다.
  runApp(const ProviderScope(child: App()));
}
