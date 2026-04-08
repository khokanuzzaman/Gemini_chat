import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const primary = Color(0xFF1A73E8);
  static const primaryDark = Color(0xFF1557B0);
  static const primaryLight = Color(0xFFE8F0FE);
  static const darkPrimary = Color(0xFF4A9EFF);

  static const success = Color(0xFF34A853);
  static const warning = Color(0xFFFBBC04);
  static const error = Color(0xFFEA4335);
  static const info = Color(0xFF1A73E8);

  static const lightBackground = Color(0xFFFFFFFF);
  static const lightSurface = Color(0xFFF8F9FA);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE8EAED);
  static const lightText = Color(0xFF202124);
  static const lightTextSecondary = Color(0xFF5F6368);
  static const lightTextHint = Color(0xFF9AA0A6);

  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);
  static const darkCard = Color(0xFF2D2D2D);
  static const darkBorder = Color(0xFF3C3C3C);
  static const darkText = Color(0xFFE8EAED);
  static const darkTextSecondary = Color(0xFF9AA0A6);
  static const darkTextHint = Color(0xFF5F6368);

  static const userBubbleLight = Color(0xFF1A73E8);
  static const aiBubbleLight = Color(0xFFF1F3F4);
  static const userBubbleTextLight = Color(0xFFFFFFFF);
  static const aiBubbleTextLight = Color(0xFF202124);

  static const userBubbleDark = Color(0xFF1557B0);
  static const aiBubbleDark = Color(0xFF2D2D2D);
  static const userBubbleTextDark = Color(0xFFFFFFFF);
  static const aiBubbleTextDark = Color(0xFFE8EAED);

  static const grey50 = lightSurface;
  static const grey100 = Color(0xFFF1F3F4);
  static const grey200 = lightBorder;
  static const grey400 = Color(0xFFBDC1C6);
  static const grey600 = Color(0xFF80868B);
  static const grey800 = Color(0xFF3C4043);
  static const grey900 = lightText;

  static const food = Color(0xFFFF6D00);
  static const transport = Color(0xFF1A73E8);
  static const healthcare = Color(0xFFEA4335);
  static const shopping = Color(0xFF9334E6);
  static const bill = Color(0xFF00897B);
  static const entertainment = Color(0xFFE91E63);
  static const other = Color(0xFF80868B);
}

class AppElevation {
  const AppElevation._();

  static List<BoxShadow> get level1 => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get level2 => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get level3 => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get level4 => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get darkLevel1 => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get darkLevel2 => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get darkLevel3 => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.32),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get darkLevel4 => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ];
}

class AppGradients {
  const AppGradients._();

  static const LinearGradient primary = LinearGradient(
    colors: [Color(0xFF1A73E8), Color(0xFF1557B0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryDark = LinearGradient(
    colors: [Color(0xFF4A9EFF), Color(0xFF1557B0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient success = LinearGradient(
    colors: [Color(0xFF34A853), Color(0xFF1B7A33)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warning = LinearGradient(
    colors: [Color(0xFFFBBC04), Color(0xFFE89800)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient danger = LinearGradient(
    colors: [Color(0xFFEA4335), Color(0xFFB31412)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceLight = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient surfaceDark = LinearGradient(
    colors: [Color(0xFF1E1E1E), Color(0xFF171C26)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient income = LinearGradient(
    colors: [Color(0xFF00C853), Color(0xFF00897B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient expense = LinearGradient(
    colors: [Color(0xFFFF5252), Color(0xFFC62828)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient walletBlue = LinearGradient(
    colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient walletPurple = LinearGradient(
    colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient walletTeal = LinearGradient(
    colors: [Color(0xFF00897B), Color(0xFF004D40)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient walletOrange = LinearGradient(
    colors: [Color(0xFFFF6D00), Color(0xFFBF360C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppMotion {
  const AppMotion._();

  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutQuart;
  static const Curve bounce = Curves.elasticOut;
  static const Curve smooth = Curves.fastOutSlowIn;

  static const Duration staggerDelay = Duration(milliseconds: 50);
}

class AppTextStyles {
  const AppTextStyles._();

  static const displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static const displayMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );

  static const bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
  );

  static const caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.2,
  );

  static const heroAmount = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.0,
    height: 1.1,
  );

  static const heroLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  static const statValue = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  static const statLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );

  static const sectionTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  static const sectionSubtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const chipLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );
}

class AppSpacing {
  const AppSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;

  static const cardPadding = 20.0;
  static const cardGap = 16.0;
  static const sectionGap = 24.0;
  static const screenPadding = 20.0;
  static const tightGap = 12.0;
  static const looseGap = 32.0;
}

class AppRadius {
  const AppRadius._();

  static const sm = Radius.circular(8);
  static const md = Radius.circular(12);
  static const lg = Radius.circular(16);
  static const xl = Radius.circular(24);
  static const full = Radius.circular(100);

  static const card = Radius.circular(20);
  static const heroCard = Radius.circular(24);
  static const button = Radius.circular(16);
  static const chip = Radius.circular(100);
  static const sheet = Radius.circular(28);
  static const input = Radius.circular(14);

  static const cardAll = BorderRadius.all(card);
  static const heroCardAll = BorderRadius.all(heroCard);
  static const buttonAll = BorderRadius.all(button);
  static const sheetAll = BorderRadius.all(sheet);
}

class AppTheme {
  const AppTheme._();

  static ThemeData lightTheme() {
    const colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.primaryLight,
      error: AppColors.error,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightText,
      onPrimary: AppColors.userBubbleTextLight,
      outline: AppColors.lightBorder,
    );

    return _themeData(
      brightness: Brightness.light,
      colorScheme: colorScheme,
      background: AppColors.lightBackground,
      card: AppColors.lightCard,
      divider: AppColors.lightBorder,
      shadow: AppColors.lightText.withValues(alpha: 0.06),
      text: AppColors.lightText,
      secondaryText: AppColors.lightTextSecondary,
      hintText: AppColors.lightTextHint,
      navSelected: AppColors.primary,
      navUnselected: AppColors.lightTextSecondary,
      inputFill: AppColors.lightSurface,
    );
  }

  static ThemeData darkTheme() {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.darkPrimary,
      secondary: AppColors.primaryLight,
      error: AppColors.error,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkText,
      onPrimary: AppColors.userBubbleTextDark,
      outline: AppColors.darkBorder,
    );

    return _themeData(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      background: AppColors.darkBackground,
      card: AppColors.darkCard,
      divider: AppColors.darkBorder,
      shadow: AppColors.darkBackground.withValues(alpha: 0.36),
      text: AppColors.darkText,
      secondaryText: AppColors.darkTextSecondary,
      hintText: AppColors.darkTextHint,
      navSelected: AppColors.darkPrimary,
      navUnselected: AppColors.darkTextSecondary,
      inputFill: AppColors.darkSurface,
    );
  }

  static ThemeData _themeData({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required Color background,
    required Color card,
    required Color divider,
    required Color shadow,
    required Color text,
    required Color secondaryText,
    required Color hintText,
    required Color navSelected,
    required Color navUnselected,
    required Color inputFill,
  }) {
    final textTheme = TextTheme(
      displayLarge: AppTextStyles.displayLarge.copyWith(color: text),
      displayMedium: AppTextStyles.displayMedium.copyWith(color: text),
      titleLarge: AppTextStyles.titleLarge.copyWith(color: text),
      titleMedium: AppTextStyles.titleMedium.copyWith(color: text),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: text),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(color: text),
      bodySmall: AppTextStyles.bodySmall.copyWith(color: secondaryText),
      labelSmall: AppTextStyles.caption.copyWith(color: secondaryText),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      cardColor: card,
      dividerColor: divider,
      shadowColor: shadow,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: background,
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? navSelected
                : navUnselected,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return AppTextStyles.bodySmall.copyWith(
            color: states.contains(WidgetState.selected)
                ? navSelected
                : navUnselected,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          );
        }),
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: background,
        selectedItemColor: navSelected,
        unselectedItemColor: navUnselected,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: divider),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        hintStyle: TextStyle(color: hintText, fontSize: 14),
        labelStyle: TextStyle(color: secondaryText),
        prefixIconColor: secondaryText,
        suffixIconColor: secondaryText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.3),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          textStyle: AppTextStyles.titleMedium.copyWith(
            color: colorScheme.onPrimary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: BorderSide(color: divider),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: AppTextStyles.titleMedium.copyWith(
            color: colorScheme.primary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: inputFill,
        selectedColor: colorScheme.primary,
        disabledColor: divider,
        side: BorderSide(color: divider),
        labelStyle: AppTextStyles.bodySmall.copyWith(
          color: secondaryText,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: AppTextStyles.bodySmall.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? colorScheme.onPrimary
                : text;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? colorScheme.primary
                : inputFill;
          }),
          side: WidgetStateProperty.all(BorderSide(color: divider)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: card,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

extension AppThemeContext on BuildContext {
  ThemeData get appTheme => Theme.of(this);
  ColorScheme get appColors => appTheme.colorScheme;
  bool get isDarkMode => appTheme.brightness == Brightness.dark;

  Color get surfaceColor => appColors.surface;
  Color get backgroundColor => appTheme.scaffoldBackgroundColor;
  Color get cardBackgroundColor => appTheme.cardColor;
  Color get borderColor => appTheme.dividerColor;
  Color get primaryTextColor => appColors.onSurface;
  Color get secondaryTextColor =>
      appTheme.textTheme.bodySmall?.color ??
      appColors.onSurface.withValues(alpha: 0.7);
  Color get hintTextColor =>
      appTheme.inputDecorationTheme.hintStyle?.color ??
      appColors.onSurface.withValues(alpha: 0.45);

  Color get userBubbleColor =>
      isDarkMode ? AppColors.userBubbleDark : AppColors.userBubbleLight;
  Color get aiBubbleColor =>
      isDarkMode ? AppColors.aiBubbleDark : AppColors.aiBubbleLight;
  Color get userBubbleTextColor =>
      isDarkMode ? AppColors.userBubbleTextDark : AppColors.userBubbleTextLight;
  Color get aiBubbleTextColor =>
      isDarkMode ? AppColors.aiBubbleTextDark : AppColors.aiBubbleTextLight;

  Color get errorBubbleColor =>
      isDarkMode ? const Color(0xFF3D1515) : const Color(0xFFFFEBEE);
  Color get errorBubbleTextColor =>
      isDarkMode ? const Color(0xFFFFDAD4) : const Color(0xFF8B1E14);
  Color get errorBubbleBorderColor => AppColors.error;

  Color get ragChipBackgroundColor => isDarkMode
      ? AppColors.darkPrimary.withValues(alpha: 0.18)
      : AppColors.primaryLight;
  Color get ragChipTextColor => appColors.primary;

  Color get mutedSurfaceColor =>
      isDarkMode ? AppColors.darkSurface : AppColors.lightSurface;

  LinearGradient get shellBackgroundGradient => LinearGradient(
    colors: isDarkMode
        ? [AppColors.darkBackground, const Color(0xFF171C26)]
        : [const Color(0xFFFDFEFF), const Color(0xFFF7FAFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  List<BoxShadow> elevationLevel(int level) {
    if (isDarkMode) {
      return switch (level) {
        1 => AppElevation.darkLevel1,
        2 => AppElevation.darkLevel2,
        3 => AppElevation.darkLevel3,
        4 => AppElevation.darkLevel4,
        _ => AppElevation.darkLevel2,
      };
    }
    return switch (level) {
      1 => AppElevation.level1,
      2 => AppElevation.level2,
      3 => AppElevation.level3,
      4 => AppElevation.level4,
      _ => AppElevation.level2,
    };
  }

  LinearGradient get primaryGradient =>
      isDarkMode ? AppGradients.primaryDark : AppGradients.primary;

  LinearGradient get surfaceGradient =>
      isDarkMode ? AppGradients.surfaceDark : AppGradients.surfaceLight;

  BoxDecoration cardDecoration({int elevation = 2}) {
    return BoxDecoration(
      color: cardBackgroundColor,
      borderRadius: AppRadius.cardAll,
      boxShadow: elevationLevel(elevation),
      border: Border.all(
        color: borderColor.withValues(alpha: isDarkMode ? 0.4 : 0.6),
        width: 0.5,
      ),
    );
  }

  BoxDecoration heroCardDecoration({Gradient? gradient}) {
    return BoxDecoration(
      gradient: gradient ?? primaryGradient,
      borderRadius: AppRadius.heroCardAll,
      boxShadow: elevationLevel(3),
    );
  }

  BoxDecoration glassDecoration() {
    return BoxDecoration(
      color: cardBackgroundColor.withValues(alpha: isDarkMode ? 0.6 : 0.7),
      borderRadius: AppRadius.cardAll,
      border: Border.all(
        color: Colors.white.withValues(alpha: isDarkMode ? 0.1 : 0.5),
        width: 1,
      ),
      boxShadow: elevationLevel(2),
    );
  }

  Color get incomeColor => AppColors.success;
  Color get expenseColor => AppColors.error;
  Color get incomeBackgroundColor =>
      AppColors.success.withValues(alpha: isDarkMode ? 0.15 : 0.08);
  Color get expenseBackgroundColor =>
      AppColors.error.withValues(alpha: isDarkMode ? 0.15 : 0.08);

  Color ragCardBackground(Color tint) =>
      isDarkMode ? cardBackgroundColor : tint.withValues(alpha: 0.08);

  Color ragCardBorder(Color tint) =>
      tint.withValues(alpha: isDarkMode ? 0.42 : 0.24);

  Color progressBackground(Color tint) =>
      tint.withValues(alpha: isDarkMode ? 0.2 : 0.1);
}
