import 'package:maeum_book/core/theme/app_colors.dart';
import 'package:maeum_book/core/theme/app_dimens.dart';
import 'package:maeum_book/core/widgets/app_text.dart';
import 'package:material_ui/material_ui.dart';

/// 입력 폼의 항목 하나. "제목 + 필수/선택 표시 + 입력 위젯 + 오류 문구" 묶음이다.
///
/// ```dart
/// FormSection(label: '금액', isRequired: true, child: AmountField(...))
/// FormSection(label: '메모', child: AppTextField(...))   // isRequired 기본값 false = 선택
/// ```
/// [errorText]는 칩처럼 자체 오류 표시가 없는 입력 위젯 아래에 문구를 띄울 때 쓴다.
///
/// ## 오류 칸으로 이동 ([revealFirstError])
/// 저장을 눌렀는데 빠진 칸이 화면 밖(위쪽 · 키보드 뒤)에 있으면 아무 반응이 없는 것처럼 보인다.
/// 그래서 저장에 실패하면 **오류가 있는 첫 번째 항목으로 스크롤**하고, 글자 입력칸이면 커서를 놓아 키보드를 띄운다.
/// - 칩처럼 [errorText]를 여기서 보여주는 항목은 자동으로 대상이 된다.
/// - 입력칸이 오류를 직접 보여주는 항목(이름 · 금액 등)은 [hasError]를 true로 넘긴다.
///
/// ```dart
/// FormSection(label: '이름', hasError: state.nameError != null, child: AppTextField(errorText: state.nameError))
///
/// final saved = await viewModel.save();
/// if (!saved && context.mounted) FormSection.revealFirstError(context);
/// ```
class FormSection extends StatelessWidget {
  const FormSection({
    super.key,
    required this.label,
    required this.child,
    this.isRequired = false,
    this.errorText,
    this.hasError = false,
  });

  final String label;
  final Widget child;

  /// 필수 입력이면 true (제목 옆에 "필수" 배지)
  final bool isRequired;

  final String? errorText;

  /// 안쪽 입력칸이 오류를 보여주고 있는지. ([errorText]가 있으면 따로 넘기지 않아도 오류로 본다)
  final bool hasError;

  bool get _invalid => hasError || errorText != null;

  /// [context] 아래에서 오류가 있는 첫 번째(화면 위쪽부터) 항목으로 스크롤하고, 그 안의 글자 입력칸에 커서를 놓는다.
  /// 오류 항목이 없으면 아무것도 하지 않고 false.
  ///
  /// 오류 문구가 화면에 그려진 다음 찾아야 하므로 한 프레임을 기다린다.
  static Future<bool> revealFirstError(BuildContext context) async {
    await WidgetsBinding.instance.endOfFrame;
    if (!context.mounted) return false;

    // 위젯 트리를 위에서부터 차례로 훑으면 화면에 놓인 순서(위 → 아래)와 같다.
    Element? section;
    void findSection(Element element) {
      if (section != null) return;
      final widget = element.widget;
      if (widget is FormSection && widget._invalid) {
        section = element;
        return;
      }
      element.visitChildren(findSection);
    }

    context.visitChildElements(findSection);
    final target = section;
    if (target == null) return false;

    await Scrollable.ensureVisible(
      target,
      alignment: 0.1, // 항목 제목이 화면 위쪽에서 조금 여유를 두고 보이게
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
    if (!target.mounted) return true;

    // 글자 입력칸이 있으면 커서를 놓고 키보드를 띄운다. (칩 · 날짜 항목은 스크롤만)
    EditableTextState? editable;
    void findEditable(Element element) {
      if (editable != null) return;
      if (element is StatefulElement && element.state is EditableTextState) {
        editable = element.state as EditableTextState;
        return;
      }
      element.visitChildren(findEditable);
    }

    target.visitChildren(findEditable);
    editable?.requestKeyboard();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppText.label(label),
            const SizedBox(width: AppSpacing.xs + 2),
            _RequiredBadge(isRequired: isRequired),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.xs + 2),
          AppText.caption(errorText!, color: AppColors.error),
        ],
      ],
    );
  }
}

/// "필수"(테라코타) / "선택"(회색) 작은 배지
class _RequiredBadge extends StatelessWidget {
  const _RequiredBadge({required this.isRequired});

  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isRequired ? AppColors.primaryLight : AppColors.divider,
        borderRadius: BorderRadius.circular(6),
      ),
      child: AppText.caption(isRequired ? '필수' : '선택', color: isRequired ? AppColors.primary : AppColors.textSecondary),
    );
  }
}
