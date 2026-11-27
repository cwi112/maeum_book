import 'package:maeum_book/core/define/test_ids.dart';
import 'package:maeum_book/core/extensions/widget_extension.dart';
import 'package:maeum_book/core/theme/app_colors.dart';
import 'package:maeum_book/core/theme/app_dimens.dart';
import 'package:maeum_book/core/widgets/app_text.dart';
import 'package:maeum_book/core/widgets/form/clear_text_button.dart';
import 'package:material_ui/material_ui.dart';

/// 앱 공통 확인·입력 창.
abstract final class AppDialog {
  /// "정말 할까요?" 확인 창을 띄우고, 확인을 누르면 true를 돌려준다. (취소·바깥 누름은 false)
  ///
  /// ```dart
  /// if (await AppDialog.confirm(context, title: '모두 지울까요?', confirmLabel: '지우기', isDestructive: true)) { ... }
  /// ```
  /// [isDestructive]: 되돌릴 수 없는 작업이면 true. 확인 버튼이 빨간색이 된다.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    String? message,
    String confirmLabel = '확인',
    String cancelLabel = '취소',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _AppAlertDialog(
        title: title,
        content: message == null ? null : AppText.body(message, color: AppColors.textSecondary),
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
    return result ?? false;
  }

  /// 글자 하나를 입력받는 창. 확인을 누르면 입력한 글자(앞뒤 공백 제거), 취소하면 null.
  ///
  /// ```dart
  /// final name = await AppDialog.prompt(context, title: '종류 추가', hint: '예) 환갑', maxLength: 10);
  /// ```
  static Future<String?> prompt(
    BuildContext context, {
    required String title,
    String initialValue = '',
    String? hint,
    int? maxLength,
    String confirmLabel = '확인',
  }) => showDialog<String>(
    context: context,
    builder: (_) => _PromptDialog(
      title: title,
      initialValue: initialValue,
      hint: hint,
      maxLength: maxLength,
      confirmLabel: confirmLabel,
    ),
  );
}

/// 확인 창 공통 모양 (흰 배경, 둥근 모서리, 취소/확인 버튼)
class _AppAlertDialog extends StatelessWidget {
  const _AppAlertDialog({
    required this.title,
    required this.content,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.isDestructive,
    required this.onConfirm,
  });

  final String title;
  final Widget? content;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      title: AppText.title(title),
      content: content,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          child: Text(cancelLabel),
        ).testId(TestIds.dialogCancel),
        FilledButton(
          onPressed: onConfirm,
          style: isDestructive ? FilledButton.styleFrom(backgroundColor: AppColors.error) : null,
          child: Text(confirmLabel),
        ).testId(TestIds.dialogConfirm),
      ],
    );
  }
}

/// 입력 창. 입력칸 컨트롤러를 창이 열려 있는 동안 유지·정리해야 해서 StatefulWidget으로 만들었다.
class _PromptDialog extends StatefulWidget {
  const _PromptDialog({
    required this.title,
    required this.initialValue,
    required this.hint,
    required this.maxLength,
    required this.confirmLabel,
  });

  final String title;
  final String initialValue;
  final String? hint;
  final int? maxLength;
  final String confirmLabel;

  @override
  State<_PromptDialog> createState() => _PromptDialogState();
}

class _PromptDialogState extends State<_PromptDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => _AppAlertDialog(
        title: widget.title,
        confirmLabel: widget.confirmLabel,
        cancelLabel: '취소',
        isDestructive: false,
        // 비어 있으면 확인 버튼을 막는다.
        onConfirm: _controller.text.trim().isEmpty ? null : _submit,
        content: TextField(
          controller: _controller,
          autofocus: true,
          maxLength: widget.maxLength,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            hintText: widget.hint,
            counterText: '',
            suffixIcon: ClearTextButton(controller: _controller, onCleared: () {}),
          ),
        ).testId(TestIds.dialogInput),
      ),
    );
  }
}
