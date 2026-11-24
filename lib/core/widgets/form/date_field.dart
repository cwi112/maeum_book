import 'package:maeum_book/core/define/typedefs.dart';
import 'package:maeum_book/core/extensions/extensions.dart';
import 'package:maeum_book/core/theme/app_dimens.dart';
import 'package:maeum_book/core/widgets/app_text.dart';
import 'package:material_ui/material_ui.dart';

/// 날짜 선택칸. 누르면 달력이 뜨고, 고른 날짜를 '2026년 11월 24일 (화)' 형태로 보여준다.
///
/// ```dart
/// DateField(value: state.date, onChanged: viewModel.setDate)
/// ```
/// 경조사는 미리 기록해 둘 수도 있어서 앞으로 5년까지 고를 수 있게 했다.
class DateField extends StatelessWidget {
  const DateField({super.key, required this.value, required this.onChanged});

  final DateTime value;
  final DateTimeCallback onChanged;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year + 5, 12, 31),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _pick(context),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InputDecorator(
        decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_today_outlined, size: 20)),
        child: AppText.body('${value.toKoreanFullDate} (${value.koreanWeekday})'),
      ),
    );
  }
}
