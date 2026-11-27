import 'package:maeum_book/core/theme/app_colors.dart';
import 'package:maeum_book/core/theme/app_dimens.dart';
import 'package:maeum_book/core/theme/app_text_styles.dart';
import 'package:material_ui/material_ui.dart';

/// 앱 전체 테마. 색은 [AppColors], 글꼴은 [AppTextStyles], 크기는 [AppSpacing]/[AppRadius]에서 가져온다.
///
/// 버튼·카드·입력창 등 기본 위젯의 모양을 여기서 한 번에 정하므로,
/// 화면에서는 `FilledButton(...)`처럼 그냥 쓰면 자동으로 이 디자인이 적용된다.
class AppTheme {
  AppTheme._();

  static ThemeData get light => of(AppPalette.light);
  static ThemeData get dark => of(AppPalette.dark);

  /// 화면 모드 [p]의 색으로 테마를 만든다.
  static ThemeData of(AppPalette p) {
    final colorScheme = ColorScheme.fromSeed(
      brightness: p.brightness,
      seedColor: p.primary,
      primary: p.primary,
      onPrimary: Colors.white,
      primaryContainer: p.primaryLight,
      secondary: p.secondary,
      surface: p.surface,
      onSurface: p.textPrimary,
      error: p.error,
    );

    final textTheme = AppTextStyles.textThemeFor(p);

    return ThemeData(
      brightness: p.brightness,
      colorScheme: colorScheme,
      fontFamily: AppTextStyles.bodyFont,
      textTheme: textTheme,
      scaffoldBackgroundColor: p.background,
      dividerColor: p.divider,

      // 상단 바: 배경과 같은 크림색, 그림자 없음, 제목은 고운바탕
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        // 목록을 내리면(앱바 아래로 내용이 지나가면) 아주 옅은 그림자가 생겨 앱바와 내용이 구분된다.
        scrolledUnderElevation: 1.5,
        shadowColor: p.shadow,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall,
      ),

      // 하단 탭: 흰 배경, 선택 시 옅은 테라코타 알약
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.primaryLight,
        height: 68,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(color: states.contains(WidgetState.selected) ? p.primary : p.textHint),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium!.copyWith(
            color: states.contains(WidgetState.selected) ? p.primary : p.textHint,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),

      // 카드: 흰 바탕, 둥근 모서리, 그림자 대신 옅은 테두리
      cardTheme: CardThemeData(
        color: p.surface,
        // 카드 안의 목록 줄 · 버튼을 누를 때 물결(splash) · 눌림 색(highlight)이 카드의 둥근 모서리 밖으로
        // 네모나게 삐져나오지 않도록, 카드 모양대로 잘라서 그린다. (설정 · 경조사 종류 관리 등 모든 Card)
        clipBehavior: Clip.antiAlias,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: p.divider),
        ),
      ),

      // 버튼
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          foregroundColor: p.primary,
          side: BorderSide(color: p.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: p.primary, textStyle: textTheme.labelLarge),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),

      // 입력창: 흰 바탕을 채운 둥근 칸
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
        hintStyle: textTheme.bodyLarge!.copyWith(color: p.textHint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: p.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: p.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: p.primary, width: 1.5),
        ),
      ),

      // 칩, 목록, 구분선, 바텀시트
      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: p.primaryLight,
        side: BorderSide(color: p.divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        // 칩 글자는 색을 꼭 지정해야 한다. 지정하지 않으면 기본 색 계산 때문에 흰 배경에 흰 글자가 될 수 있다.
        labelStyle: AppTextStyles.bodySmallBase.copyWith(fontWeight: FontWeight.w500, color: p.textPrimary),
        secondaryLabelStyle: AppTextStyles.bodySmallBase.copyWith(fontWeight: FontWeight.w600, color: p.primary),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: p.primaryLight,
          selectedForegroundColor: p.primary,
          foregroundColor: p.textSecondary,
          side: BorderSide(color: p.divider),
          textStyle: AppTextStyles.labelBase,
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        titleTextStyle: textTheme.bodyLarge,
        subtitleTextStyle: textTheme.bodySmall,
        iconColor: p.textSecondary,
      ),
      dividerTheme: DividerThemeData(color: p.divider, thickness: 1, space: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.primary),
      // 눌렀을 때 효과(물결·강조) 색. 앱 전체 InkWell·ListTile·버튼에 공통으로 적용된다.
      splashColor: p.pressedOverlay,
      highlightColor: p.pressedOverlay,
    );
  }
}
