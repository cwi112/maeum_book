import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoDatePicker, CupertinoDatePickerMode;
import 'package:maeum_book/core/define/test_ids.dart';
import 'package:maeum_book/core/define/typedefs.dart';
import 'package:maeum_book/core/extensions/extensions.dart';
import 'package:maeum_book/core/theme/app_colors.dart';
import 'package:maeum_book/core/theme/app_dimens.dart';
import 'package:maeum_book/core/widgets/app_text.dart';
import 'package:material_ui/material_ui.dart';

/// 날짜 선택칸. 누르면 날짜를 고르는 창이 뜨고, 고른 날짜를 '2026년 11월 24일 (화)' 형태로 보여준다.
///
/// ```dart
/// DateField(value: state.date, onChanged: viewModel.setDate)
/// ```
/// - **아이폰**: 아래에서 올라오는 돌림판(년 · 월 · 일). 아이폰 기본 앱과 같은 방식이라 익숙하고, 지난 날짜도 빨리 고른다.
/// - **안드로이드**: 안드로이드 기본 달력 창.
///
/// 경조사는 미리 기록해 둘 수도 있어서 앞으로 5년까지 고를 수 있게 했다.
class DateField extends StatelessWidget {
  const DateField({super.key, required this.value, required this.onChanged});

  final DateTime value;
  final DateTimeCallback onChanged;

  static final DateTime _first = DateTime(1950);
  static DateTime get _last => DateTime(DateTime.now().year + 5, 12, 31);

  Future<void> _pick(BuildContext context) async {
    final isIOS = switch (Theme.of(context).platform) {
      TargetPlatform.iOS || TargetPlatform.macOS => true,
      _ => false,
    };
    final picked = isIOS
        ? await _DateWheelSheet.show(context, initial: value, first: _first, last: _last)
        : await showDatePicker(context: context, initialDate: value, firstDate: _first, lastDate: _last);
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

/// 아이폰용 날짜 돌림판 창: [취소] 날짜 [완료]
///
/// 돌리는 동안은 위에 고른 날짜(요일 포함)를 보여 주고, [완료]를 눌러야 반영한다. (내리거나 취소하면 그대로)
class _DateWheelSheet extends StatefulWidget {
  const _DateWheelSheet({required this.initial, required this.first, required this.last});

  final DateTime initial;
  final DateTime first;
  final DateTime last;

  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initial,
    required DateTime first,
    required DateTime last,
  }) => showModalBottomSheet<DateTime>(
    context: context,
    builder: (_) => _DateWheelSheet(initial: initial, first: first, last: last),
  );

  @override
  State<_DateWheelSheet> createState() => _DateWheelSheetState();
}

class _DateWheelSheetState extends State<_DateWheelSheet> {
  late DateTime _date = DateUtils.dateOnly(widget.initial);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: AppText.body('취소', color: AppColors.textSecondary),
                ),
                AppText.subtitle(
                  '${_date.toKoreanFullDate} (${_date.koreanWeekday})',
                  align: TextAlign.center,
                ).expanded(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(_date),
                  child: const Text('완료'),
                ).testId(TestIds.datePickerDone),
              ],
            ),
          ),
          const Divider(),
          SizedBox(
            height: 216, // 아이폰 기본 돌림판 높이
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: _date,
              minimumDate: widget.first,
              maximumDate: widget.last,
              onDateTimeChanged: (date) => setState(() => _date = DateUtils.dateOnly(date)),
            ),
          ),
        ],
      ),
    );
  }
}
