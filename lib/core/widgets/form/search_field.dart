import 'package:maeum_book/core/define/typedefs.dart';
import 'package:maeum_book/core/theme/app_colors.dart';
import 'package:maeum_book/core/widgets/form/clear_text_button.dart';
import 'package:material_ui/material_ui.dart';

/// 검색창. 왼쪽에 돋보기, 글자가 있으면 오른쪽에 지우기(X) 버튼이 나온다.
///
/// ```dart
/// SearchField(value: state.filter.query, hint: '이름, 메모 검색', onChanged: viewModel.setQuery)
/// ```
///
/// ## 왜 StatefulWidget인가
/// 다른 탭에 갔다 와도 검색어가 남아 있어야 하므로, 처음 글자는 ViewModel 값([value])으로 채운다.
/// "필터 초기화"처럼 바깥에서 값이 비워지면 입력칸 글자도 같이 비워야 해서 컨트롤러를 직접 관리한다.
class SearchField extends StatefulWidget {
  const SearchField({super.key, required this.value, required this.onChanged, this.hint});

  final String value;
  final StringCallback onChanged;
  final String? hint;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);

  /// 바깥에서 값이 바뀌었는데(예: 초기화) 입력칸 글자와 다르면 맞춘다. 직접 입력 중일 때는 같으므로 건드리지 않는다.
  @override
  void didUpdateWidget(SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text != widget.value) _controller.text = widget.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary),
        // 글자가 있을 때만 지우기 버튼을 보여준다. (컨트롤러 값이 바뀔 때마다 이 부분만 다시 그림)
        suffixIcon: ClearTextButton(controller: _controller, onCleared: () => widget.onChanged('')),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}
