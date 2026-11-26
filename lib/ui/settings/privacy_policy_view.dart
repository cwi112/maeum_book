import 'package:flutter/services.dart' show rootBundle;
import 'package:maeum_book/core/core.dart';
import 'package:url_launcher/url_launcher.dart';

/// 개인정보 처리방침 글 (앱에 함께 들어 있는 docs/PRIVACY_POLICY.md). 인터넷 없이도 읽힌다.
final privacyPolicyTextProvider = FutureProvider<String>((ref) => rootBundle.loadString('docs/PRIVACY_POLICY.md'));

/// 개인정보 처리방침 화면. 경로 `/settings/privacy`
///
/// - 글은 **앱 안에 들어 있는 문서**를 보여 준다. 그래서 인터넷이 없거나 웹 페이지가 열리지 않아도 항상 볼 수 있다.
///   (스토어 규정: 앱 안에서 쉽게 볼 수 있어야 함)
/// - 오른쪽 위 버튼: 같은 내용의 웹 페이지(스토어에 등록한 주소)를 브라우저로 연다.
/// - 문서를 고치면 다음 앱 업데이트부터 앱 안 글도 바뀐다. 웹 페이지는 저장소에 병합하는 즉시 바뀐다.
class PrivacyPolicyView extends ConsumerWidget {
  const PrivacyPolicyView({super.key});

  Future<void> _openWeb(BuildContext context) async {
    final opened = await InAppHandoff.run(
      () => launchUrl(Uri.parse(AppDefine.privacyPolicyUrl), mode: LaunchMode.externalApplication),
    );
    if (!opened && context.mounted) context.showToast('웹 페이지를 열지 못했어요', type: ToastType.error);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = ref.watch(privacyPolicyTextProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('개인정보 처리방침'),
        actions: [
          IconButton(
            onPressed: () => _openWeb(context),
            icon: const Icon(Icons.open_in_new_rounded),
            tooltip: '웹에서 보기',
          ),
        ],
      ),
      body: switch (text) {
        AsyncData(:final value) => ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.xl),
          children: [SimpleMarkdown(text: value)],
        ),
        AsyncError() => const EmptyView(
          icon: Icons.error_outline,
          title: '내용을 불러오지 못했어요',
          message: '오른쪽 위 버튼으로 웹에서 볼 수 있어요',
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
