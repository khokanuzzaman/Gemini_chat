import 'package:flutter/material.dart';

import 'app_tokens.dart';

// Re-export so every file that imports the theme also gets `context.tokens`.
export 'app_tokens.dart';

class AppColors {
  const AppColors._();

  // LEGACY NAMES, re-pointed at the indigo + brass tokens (see AppTokens).
  //
  // These are static consts, so they cannot follow dark mode. Use them ONLY
  // for fills, icons, brand art and gradients — never for TEXT. Text colour
  // must come from `context.tokens` (or the `context.*Color` accessors), which
  // switch with the theme and are checked for >= 4.5:1.
  static const primary = Color(0xFF5647C4);
  static const primaryDark = Color(0xFF3A2F86);
  static const primaryLight = Color(0xFFEEEBFB);
  static const darkPrimary = Color(0xFF9A8CF0);

  /// Indigo for FILL / ICON use from code that has no BuildContext (status and
  /// wallet-type colour maps). >= 3.78:1 on light and dark surfaces and canvas.
  /// Not for text, and not as a label-carrying button fill.
  static const primaryMid = Color(0xFF7A6ED0);

  // Fill / icon tones (>= 3:1 on light AND dark surfaces).
  static const success = Color(0xFF2E9E6B);
  static const warning = Color(0xFFD0721D);
  static const error = Color(0xFFD93F4B);
  static const info = Color(0xFF5647C4);

  static const lightBackground = Color(0xFFF3F1FA); // canvas
  static const lightSurface = Color(0xFFFAF9FE); // surface-2
  static const lightCard = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE7E3F3);
  static const lightText = Color(0xFF1B1733);
  static const lightTextSecondary = Color(0xFF6B6782);
  static const lightTextHint = Color(0xFF6B6782);

  static const darkBackground = Color(0xFF14121F); // canvas
  static const darkSurface = Color(0xFF1B1829); // surface-2
  static const darkCard = Color(0xFF221E33); // surface
  static const darkBorder = Color(0xFF312C46);
  static const darkText = Color(0xFFEFEDF7);
  static const darkTextSecondary = Color(0xFF9C97B4);
  static const darkTextHint = Color(0xFF9C97B4);

  static const userBubbleLight = Color(0xFF5647C4);
  static const aiBubbleLight = Color(0xFFEEEBFB);
  static const userBubbleTextLight = Color(0xFFFFFFFF);
  static const aiBubbleTextLight = Color(0xFF1B1733);

  static const userBubbleDark = Color(0xFF6D59E9);
  static const aiBubbleDark = Color(0xFF221E33);
  static const userBubbleTextDark = Color(0xFFFFFFFF);
  static const aiBubbleTextDark = Color(0xFFEFEDF7);

  static const grey50 = lightSurface;
  static const grey100 = Color(0xFFE7E3F3);
  static const grey200 = lightBorder;
  static const grey400 = Color(0xFFB8B3CC);
  static const grey600 = Color(0xFF6B6782);
  static const grey800 = Color(0xFF3F3A57);
  static const grey900 = lightText;

  // Category / wallet identity colours: user-facing DATA palette (stored per
  // category), deliberately NOT part of the brand tokens.
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

  /// Spec card shadow: `0 18px 40px -22px rgba(40,30,90,.45)`.
  static List<BoxShadow> get level2 => const [
    BoxShadow(
      color: Color(0x73281E5A),
      blurRadius: 40,
      spreadRadius: -22,
      offset: Offset(0, 18),
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

  /// Dark-mode card shadow: same geometry, deeper and darker.
  static List<BoxShadow> get darkLevel2 => const [
    BoxShadow(
      color: Color(0x99000000),
      blurRadius: 40,
      spreadRadius: -22,
      offset: Offset(0, 18),
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
    colors: [Color(0xFF5647C4), Color(0xFF3A2F86)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryDark = LinearGradient(
    colors: [Color(0xFF5647C4), Color(0xFF3A2F86)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient success = LinearGradient(
    colors: [Color(0xFF237852), Color(0xFF1B5F40)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warning = LinearGradient(
    colors: [Color(0xFF9F5716), Color(0xFF7C430F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient danger = LinearGradient(
    colors: [Color(0xFFCC2835), Color(0xFF9E1B27)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceLight = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFAF9FE)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient surfaceDark = LinearGradient(
    colors: [Color(0xFF221E33), Color(0xFF1B1829)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient income = LinearGradient(
    colors: [Color(0xFF237852), Color(0xFF1B5F40)],
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

  // Typefaces (bundled, see pubspec.yaml). Inter carries body text, Sora the
  // headings and big figures. Neither has Bengali glyphs, so every style falls
  // back to Noto Sans Bengali — which is what Bengali digits, ৳ and all Bengali
  // text actually render in. That makes the Bengali face the app's real
  // identity; weights below are chosen with it in mind.
  //
  // Weight is selected by `fontWeight` alone: the variable fonts' `wght` axis
  // follows it (verified by rendering 400/500/600/700 — see CONTRIBUTING.md).
  // Do NOT also pin a `FontVariation('wght')` here: a variation overrides
  // `fontWeight`, so every `.copyWith(fontWeight: …)` at a call site would
  // silently stop working.
  static const bodyFontFamily = 'Inter';
  static const displayFontFamily = 'Sora';
  static const bengaliFontFamily = 'NotoSansBengali';
  static const _bengaliFallback = <String>[bengaliFontFamily];

  // Line height: Noto Sans Bengali's natural height is ~1.32em and its tall
  // matras/conjuncts need air, so running text uses 1.5 (the spec's Bangla
  // target). Single-line display figures stay tighter, but never below 1.2.
  // Letter-spacing is 0 on every style that has Bengali glyphs: tracking
  // (especially negative) pulls conjunct components and matras into each other.

  static const displayLarge = TextStyle(
    fontFamily: displayFontFamily,
    fontFamilyFallback: _bengaliFallback,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  static const displayMedium = TextStyle(
    fontFamily: displayFontFamily,
    fontFamilyFallback: _bengaliFallback,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static const titleLarge = TextStyle(
    fontFamily: displayFontFamily,
    fontFamilyFallback: _bengaliFallback,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const titleMedium = TextStyle(
    fontFamily: displayFontFamily,
    fontFamilyFallback: _bengaliFallback,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const bodyLarge = TextStyle(
    fontFamily: bodyFontFamily,
    fontFamilyFallback: _bengaliFallback,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const bodyMedium = TextStyle(
    fontFamily: bodyFontFamily,
    fontFamilyFallback: _bengaliFallback,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const bodySmall = TextStyle(
    fontFamily: bodyFontFamily,
    fontFamilyFallback: _bengaliFallback,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const caption = TextStyle(
    fontFamily: bodyFontFamily,
    fontFamilyFallback: _bengaliFallback,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.45,
  );

  // The big money figures: Bengali digits + ৳ render in Noto Sans Bengali, whose
  // digits are tabular (identical advance at every weight), so 700 is enough —
  // 800 only clots the counters of ৯/৬/৪ at 36px.
  static const heroAmount = TextStyle(
    fontFamily: displayFontFamily,
    fontFamilyFallback: _bengaliFallback,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  static const heroLabel = TextStyle(
    fontFamily: bodyFontFamily,
    fontFamilyFallback: _bengaliFallback,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
  );

  static const statValue = TextStyle(
    fontFamily: displayFontFamily,
    fontFamilyFallback: _bengaliFallback,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static const statLabel = TextStyle(
    fontFamily: bodyFontFamily,
    fontFamilyFallback: _bengaliFallback,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    height: 1.4,
  );

  static const sectionTitle = TextStyle(
    fontFamily: displayFontFamily,
    fontFamilyFallback: _bengaliFallback,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );

  static const sectionSubtitle = TextStyle(
    fontFamily: bodyFontFamily,
    fontFamilyFallback: _bengaliFallback,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const chipLabel = TextStyle(
    fontFamily: bodyFontFamily,
    fontFamilyFallback: _bengaliFallback,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.4,
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

  // The spec's scale: 4 · 8 · 12 · 16 · 20 · 24 · 32.
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s20 = 20.0;
  static const s24 = 24.0;
  static const s32 = 32.0;

  static const cardPadding = 20.0;
  static const cardGap = 16.0;
  static const sectionGap = 24.0;
  static const screenPadding = 16.0; // spec: horizontal screen padding 16
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

  static const card = Radius.circular(18); // spec: cards ~18
  static const heroCard = Radius.circular(24);
  static const button = Radius.circular(16);
  static const chip = Radius.circular(100);
  static const sheet = Radius.circular(24); // spec: sheet top ~24
  static const input = Radius.circular(14);

  static const cardAll = BorderRadius.all(card);
  static const heroCardAll = BorderRadius.all(heroCard);
  static const buttonAll = BorderRadius.all(button);
  static const sheetAll = BorderRadius.all(sheet);
}

class AppTheme {
  const AppTheme._();

  static ThemeData lightTheme() => _build(Brightness.light, AppTokens.light);

  static ThemeData darkTheme() => _build(Brightness.dark, AppTokens.dark);

  static ThemeData _build(Brightness brightness, AppTokens t) {
    final isDark = brightness == Brightness.dark;

    // `primary` is the indigo for TEXT/ICONS (light on dark surfaces). Fills use
    // `t.primaryFill` + `t.onFill` explicitly in the component themes below; the
    // scheme's own onPrimary pairs with `primary` (system pickers etc.).
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: t.primary,
      onPrimary: isDark ? t.canvas : t.onFill,
      primaryContainer: t.primarySoft,
      onPrimaryContainer: t.primaryDeep,
      secondary: t.primarySoft,
      onSecondary: t.primaryDeep,
      error: t.dangerText,
      onError: isDark ? t.canvas : t.onFill,
      errorContainer: t.dangerSoft,
      onErrorContainer: t.dangerText,
      surface: t.surface,
      onSurface: t.ink,
      onSurfaceVariant: t.muted,
      outline: t.inputOutline,
      outlineVariant: t.line,
      surfaceTint: Colors.transparent,
      surfaceContainerLowest: isDark ? t.canvas : t.surface,
      surfaceContainerLow: t.surface2,
      surfaceContainer: isDark ? t.surface : t.canvas,
      surfaceContainerHigh: t.primarySoft,
      surfaceContainerHighest: t.line,
      inverseSurface: t.ink,
      onInverseSurface: t.surface,
      inversePrimary: t.primary,
    );

    final textTheme = TextTheme(
      displayLarge: AppTextStyles.displayLarge.copyWith(color: t.ink),
      displayMedium: AppTextStyles.displayMedium.copyWith(color: t.ink),
      titleLarge: AppTextStyles.titleLarge.copyWith(color: t.ink),
      titleMedium: AppTextStyles.titleMedium.copyWith(color: t.ink),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: t.ink),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(color: t.ink),
      bodySmall: AppTextStyles.bodySmall.copyWith(color: t.muted),
      labelSmall: AppTextStyles.caption.copyWith(color: t.muted),
    );

    OutlineInputBorder inputBorder(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      // Anything without an explicit AppTextStyles entry (Material defaults:
      // buttons, text-field input, list tiles…) gets Inter + Bengali fallback.
      fontFamily: AppTextStyles.bodyFontFamily,
      fontFamilyFallback: const [AppTextStyles.bengaliFontFamily],
      colorScheme: colorScheme,
      extensions: <ThemeExtension<dynamic>>[t],
      scaffoldBackgroundColor: t.canvas,
      canvasColor: t.canvas,
      cardColor: t.surface,
      dividerColor: t.line,
      shadowColor: isDark
          ? t.canvas.withValues(alpha: 0.36)
          : t.ink.withValues(alpha: 0.06),
      textTheme: textTheme,
      dividerTheme: DividerThemeData(color: t.line, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: t.canvas,
        foregroundColor: t.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: t.canvas,
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected) ? t.primary : t.muted,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return AppTextStyles.bodySmall.copyWith(
            color: states.contains(WidgetState.selected) ? t.primary : t.muted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          );
        }),
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: t.canvas,
        selectedItemColor: t.primary,
        unselectedItemColor: t.muted,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: t.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardAll,
          side: BorderSide(color: t.line),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: AppRadius.sheet),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surface2,
        // Text-field edges use inputOutline (>= 3:1); `line` is decorative.
        hintStyle: TextStyle(color: t.hint, fontSize: 14),
        labelStyle: TextStyle(color: t.muted),
        prefixIconColor: t.muted,
        suffixIconColor: t.muted,
        border: inputBorder(t.inputOutline),
        enabledBorder: inputBorder(t.inputOutline),
        focusedBorder: inputBorder(t.primary, 1.5),
        errorBorder: inputBorder(t.dangerText),
        focusedErrorBorder: inputBorder(t.dangerText, 1.5),
        errorStyle: TextStyle(color: t.dangerText),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: t.primaryFill,
          foregroundColor: t.onFill,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          textStyle: AppTextStyles.titleMedium.copyWith(color: t.onFill),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: t.primaryFill,
          foregroundColor: t.onFill,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.ink,
          side: BorderSide(color: t.inputOutline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: t.primary,
          textStyle: AppTextStyles.titleMedium.copyWith(color: t.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: t.surface2,
        selectedColor: t.primaryFill,
        disabledColor: t.line,
        side: BorderSide(color: t.line),
        labelStyle: AppTextStyles.bodySmall.copyWith(
          color: t.muted,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: AppTextStyles.bodySmall.copyWith(
          color: t.onFill,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: t.primaryFill,
        foregroundColor: t.onFill,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected) ? t.onFill : t.ink;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? t.primaryFill
                : t.surface2;
          }),
          side: WidgetStateProperty.all(BorderSide(color: t.inputOutline)),
        ),
      ),
      switchTheme: SwitchThemeData(
        // White thumb on a primaryFill track (>= 4.5:1); the off state is
        // outlined with inputOutline so the control edge stays >= 3:1.
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? t.onFill
              : t.inputOutline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? t.primaryFill
              : t.surface2;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? Colors.transparent
              : t.inputOutline;
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: t.surface,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: t.ink),
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

  Color get errorBubbleColor => tokens.dangerSoft;
  Color get errorBubbleTextColor => tokens.dangerText;
  Color get errorBubbleBorderColor => tokens.danger;

  Color get ragChipBackgroundColor => tokens.primarySoft;
  Color get ragChipTextColor => appColors.primary;

  Color get mutedSurfaceColor => tokens.surface2;

  /// The shell background: the flat canvas (spec), expressed as a gradient so
  /// existing `BoxDecoration(gradient: …)` call sites keep working.
  LinearGradient get shellBackgroundGradient => LinearGradient(
    colors: [tokens.canvas, tokens.canvas],
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

  /// The hero gradient — deep indigo with white text in BOTH modes.
  LinearGradient get primaryGradient => tokens.heroGradient;

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

  // Amount colours are TEXT colours: theme-aware and >= 4.5:1.
  Color get incomeColor => tokens.successText;
  Color get expenseColor => tokens.expenseText;
  Color get incomeBackgroundColor => tokens.successSoft;
  Color get expenseBackgroundColor => tokens.expenseSoft;

  Color ragCardBackground(Color tint) =>
      isDarkMode ? cardBackgroundColor : tint.withValues(alpha: 0.08);

  Color ragCardBorder(Color tint) =>
      tint.withValues(alpha: isDarkMode ? 0.42 : 0.24);

  Color progressBackground(Color tint) =>
      tint.withValues(alpha: isDarkMode ? 0.2 : 0.1);
}
