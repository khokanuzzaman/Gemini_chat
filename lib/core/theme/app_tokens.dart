import 'package:flutter/material.dart';

/// Design tokens for the indigo + brass design system.
///
/// This is a RE-SKIN of the previous Google-blue palette. Screens must consume
/// these tokens (directly via `context.tokens`, or through the legacy accessors
/// in `app_theme.dart` that now read from here) and never hard-code colours —
/// `test/core/theme/no_hardcoded_colors_test.dart` ratchets that.
///
/// Rules baked into the values (checked by `app_tokens_contrast_test.dart`):
/// - Every TEXT token is >= 4.5:1 on every surface it can sit on.
/// - Fills that carry a label ([primaryFill], [successFill], [dangerFill]) are
///   >= 4.5:1 against a white [onFill] label in BOTH modes, and >= 3:1 against
///   the surfaces they sit on.
/// - Text-field edges use [inputOutline] (>= 3:1); [line]/[outline] are decorative.
/// - Brass is a jewel — see [brass].
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.canvas,
    required this.surface,
    required this.surface2,
    required this.ink,
    required this.muted,
    required this.line,
    required this.outline,
    required this.inputOutline,
    required this.primary,
    required this.primaryFill,
    required this.primaryDeep,
    required this.primarySoft,
    required this.heroStart,
    required this.heroEnd,
    required this.onHero,
    required this.onHeroMuted,
    required this.onFill,
    required this.brass,
    required this.brassSoft,
    required this.onBrass,
    required this.success,
    required this.successText,
    required this.successSoft,
    required this.successFill,
    required this.danger,
    required this.dangerText,
    required this.dangerSoft,
    required this.dangerFill,
    required this.warning,
    required this.warningText,
    required this.warningSoft,
    required this.expenseText,
    required this.expenseSoft,
  });

  /// App background (scaffold).
  final Color canvas;

  /// Cards, sheets, dialogs.
  final Color surface;

  /// Inputs, segmented-control track, muted panels.
  final Color surface2;

  /// Primary text.
  final Color ink;

  /// Secondary text AND hint/placeholder text (hint == muted: nothing lighter
  /// passes 4.5:1 on canvas). >= 4.5:1 on every surface incl.
  /// primarySoft/brassSoft.
  final Color muted;

  /// DECORATIVE dividers and card borders. Not for text-field edges — use
  /// [inputOutline].
  final Color line;

  /// DECORATIVE outlines. Not for text-field edges — use [inputOutline].
  final Color outline;

  /// Text-field / control border. >= 3:1 against surface, canvas and surface2
  /// in both modes (WCAG 1.4.11).
  final Color inputOutline;

  /// Indigo for TEXT, ICONS and links on surfaces. Do NOT use as a button fill
  /// in dark mode — use [primaryFill].
  final Color primary;

  /// Indigo for FILLS (buttons, FAB, selected chips) carrying a white [onFill]
  /// label: >= 4.5:1 label, >= 3:1 vs surface/canvas.
  final Color primaryFill;

  /// Emphasis (e.g. headline numbers). In dark mode this is a LIGHT tint for
  /// text — the hero uses [heroStart]/[heroEnd], not this.
  final Color primaryDeep;

  /// Icon-chip and selected-state backgrounds.
  final Color primarySoft;

  /// Hero card gradient start. Mode-independent: the hero is deep indigo with
  /// white text in both modes.
  final Color heroStart;

  /// Hero card gradient end.
  final Color heroEnd;

  /// Text/icons on the hero gradient (>= 6.79:1).
  final Color onHero;

  /// Secondary text on the hero gradient (>= 5.38:1).
  final Color onHeroMuted;

  /// Label/icon colour ON every *Fill token (primaryFill, successFill,
  /// dangerFill).
  final Color onFill;

  /// BRASS RULE — brass is a jewel: money / security / premium accents, EMI-
  /// and-debt markers, and the SMS auto-import (moat) card ONLY. Everything
  /// else is indigo. LIGHT MODE: brass is a FILL (with [onBrass] text) or a
  /// [brassSoft] background — NEVER text or an icon on white/canvas (2.14:1,
  /// fails). Dark mode: brass text/icons are fine (9.37:1).
  final Color brass;

  /// Background for brass cards (e.g. the SMS card). Text on it: [ink] or
  /// [muted]; light mode may also use [onBrass], dark mode may use [brass].
  final Color brassSoft;

  /// Text on a brass FILL (7.64:1 light, 9.49:1 dark).
  final Color onBrass;

  /// Success as a FILL / ICON / progress tone (>= 3:1). For TEXT use
  /// [successText].
  final Color success;

  /// Success TEXT (>= 4.5:1 incl. on its own tint).
  final Color successText;

  /// Success tint background.
  final Color successSoft;

  /// Success button fill with a white [onFill] label (>= 4.5:1).
  final Color successFill;

  /// Danger as a FILL / ICON tone (>= 3:1). For TEXT use [dangerText].
  final Color danger;

  /// Danger/error TEXT (>= 4.5:1 incl. on its own tint).
  final Color dangerText;

  /// Danger tint background.
  final Color dangerSoft;

  /// Destructive button fill with a white [onFill] label (>= 4.5:1).
  final Color dangerFill;

  /// Warning as a FILL / ICON tone (>= 3:1). Orange hue — kept apart from brass
  /// amber. For TEXT use [warningText].
  final Color warning;

  /// Warning TEXT (>= 4.5:1). Also usable as a banner fill with white text.
  final Color warningText;

  /// Warning tint background.
  final Color warningSoft;

  /// Expense amounts: a subtle desaturated rose, deliberately not alarm-red.
  final Color expenseText;

  /// Expense tint background.
  final Color expenseSoft;

  /// Hint/placeholder text. Same colour as [muted] — nothing lighter clears
  /// 4.5:1 on the canvas — so placeholders are told apart by size and weight.
  Color get hint => muted;

  /// Informational accent. Alias of [primary] (no separate info hue).
  Color get info => primary;

  /// The hero card gradient (identical in light and dark).
  LinearGradient get heroGradient => LinearGradient(
    colors: [heroStart, heroEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const AppTokens light = AppTokens(
    canvas: Color(0xFFF3F1FA),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFFAF9FE),
    ink: Color(0xFF1B1733),
    muted: Color(0xFF6B6782),
    line: Color(0xFFE7E3F3),
    outline: Color(0xFFD9D3EE),
    inputOutline: Color(0xFF8E86A8),
    primary: Color(0xFF5647C4),
    primaryFill: Color(0xFF5647C4),
    primaryDeep: Color(0xFF3A2F86),
    primarySoft: Color(0xFFEEEBFB),
    heroStart: Color(0xFF5647C4),
    heroEnd: Color(0xFF3A2F86),
    onHero: Color(0xFFFFFFFF),
    onHeroMuted: Color(0xFFE6E3F2),
    onFill: Color(0xFFFFFFFF),
    brass: Color(0xFFE0A83B),
    brassSoft: Color(0xFFFBF0D8),
    onBrass: Color(0xFF2A1E05),
    success: Color(0xFF2E9E6B),
    successText: Color(0xFF237852),
    successSoft: Color(0xFFE6F3ED),
    successFill: Color(0xFF237852),
    danger: Color(0xFFD93F4B),
    dangerText: Color(0xFFCC2835),
    dangerSoft: Color(0xFFFBECED),
    dangerFill: Color(0xFFCC2835),
    warning: Color(0xFFD0721D),
    warningText: Color(0xFF9F5716),
    warningSoft: Color(0xFFFBEFE4),
    expenseText: Color(0xFFAD4A54),
    expenseSoft: Color(0xFFF8EEEF),
  );

  static const AppTokens dark = AppTokens(
    canvas: Color(0xFF14121F),
    surface: Color(0xFF221E33),
    surface2: Color(0xFF1B1829),
    ink: Color(0xFFEFEDF7),
    muted: Color(0xFF9C97B4),
    line: Color(0xFF312C46),
    outline: Color(0xFF3E3757),
    inputOutline: Color(0xFF6F678E),
    primary: Color(0xFF9A8CF0),
    primaryFill: Color(0xFF6D59E9),
    primaryDeep: Color(0xFFB7AEF6),
    primarySoft: Color(0xFF2A2547),
    heroStart: Color(0xFF5647C4),
    heroEnd: Color(0xFF3A2F86),
    onHero: Color(0xFFFFFFFF),
    onHeroMuted: Color(0xFFE6E3F2),
    onFill: Color(0xFFFFFFFF),
    brass: Color(0xFFF0BE55),
    brassSoft: Color(0xFF3A2F18),
    onBrass: Color(0xFF2A1E05),
    success: Color(0xFF57C795),
    successText: Color(0xFF57C795),
    successSoft: Color(0xFF2A3943),
    successFill: Color(0xFF2A7F59),
    danger: Color(0xFFF27A84),
    dangerText: Color(0xFFF27A84),
    dangerSoft: Color(0xFF432D40),
    dangerFill: Color(0xFFE01627),
    warning: Color(0xFFF2A359),
    warningText: Color(0xFFF2A359),
    warningSoft: Color(0xFF433339),
    expenseText: Color(0xFFE58D95),
    expenseSoft: Color(0xFF3D2E41),
  );

  @override
  AppTokens copyWith({
    Color? canvas,
    Color? surface,
    Color? surface2,
    Color? ink,
    Color? muted,
    Color? line,
    Color? outline,
    Color? inputOutline,
    Color? primary,
    Color? primaryFill,
    Color? primaryDeep,
    Color? primarySoft,
    Color? heroStart,
    Color? heroEnd,
    Color? onHero,
    Color? onHeroMuted,
    Color? onFill,
    Color? brass,
    Color? brassSoft,
    Color? onBrass,
    Color? success,
    Color? successText,
    Color? successSoft,
    Color? successFill,
    Color? danger,
    Color? dangerText,
    Color? dangerSoft,
    Color? dangerFill,
    Color? warning,
    Color? warningText,
    Color? warningSoft,
    Color? expenseText,
    Color? expenseSoft,
  }) {
    return AppTokens(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      line: line ?? this.line,
      outline: outline ?? this.outline,
      inputOutline: inputOutline ?? this.inputOutline,
      primary: primary ?? this.primary,
      primaryFill: primaryFill ?? this.primaryFill,
      primaryDeep: primaryDeep ?? this.primaryDeep,
      primarySoft: primarySoft ?? this.primarySoft,
      heroStart: heroStart ?? this.heroStart,
      heroEnd: heroEnd ?? this.heroEnd,
      onHero: onHero ?? this.onHero,
      onHeroMuted: onHeroMuted ?? this.onHeroMuted,
      onFill: onFill ?? this.onFill,
      brass: brass ?? this.brass,
      brassSoft: brassSoft ?? this.brassSoft,
      onBrass: onBrass ?? this.onBrass,
      success: success ?? this.success,
      successText: successText ?? this.successText,
      successSoft: successSoft ?? this.successSoft,
      successFill: successFill ?? this.successFill,
      danger: danger ?? this.danger,
      dangerText: dangerText ?? this.dangerText,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      dangerFill: dangerFill ?? this.dangerFill,
      warning: warning ?? this.warning,
      warningText: warningText ?? this.warningText,
      warningSoft: warningSoft ?? this.warningSoft,
      expenseText: expenseText ?? this.expenseText,
      expenseSoft: expenseSoft ?? this.expenseSoft,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) {
      return this;
    }
    return AppTokens(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      line: Color.lerp(line, other.line, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      inputOutline: Color.lerp(inputOutline, other.inputOutline, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryFill: Color.lerp(primaryFill, other.primaryFill, t)!,
      primaryDeep: Color.lerp(primaryDeep, other.primaryDeep, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      heroStart: Color.lerp(heroStart, other.heroStart, t)!,
      heroEnd: Color.lerp(heroEnd, other.heroEnd, t)!,
      onHero: Color.lerp(onHero, other.onHero, t)!,
      onHeroMuted: Color.lerp(onHeroMuted, other.onHeroMuted, t)!,
      onFill: Color.lerp(onFill, other.onFill, t)!,
      brass: Color.lerp(brass, other.brass, t)!,
      brassSoft: Color.lerp(brassSoft, other.brassSoft, t)!,
      onBrass: Color.lerp(onBrass, other.onBrass, t)!,
      success: Color.lerp(success, other.success, t)!,
      successText: Color.lerp(successText, other.successText, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      successFill: Color.lerp(successFill, other.successFill, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerText: Color.lerp(dangerText, other.dangerText, t)!,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
      dangerFill: Color.lerp(dangerFill, other.dangerFill, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningText: Color.lerp(warningText, other.warningText, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      expenseText: Color.lerp(expenseText, other.expenseText, t)!,
      expenseSoft: Color.lerp(expenseSoft, other.expenseSoft, t)!,
    );
  }
}

/// `context.tokens` — the active [AppTokens]. Falls back to the light/dark set
/// by brightness when a test pumps a bare `MaterialApp` without [AppTheme].
extension AppTokensContext on BuildContext {
  AppTokens get tokens {
    final theme = Theme.of(this);
    return theme.extension<AppTokens>() ??
        (theme.brightness == Brightness.dark
            ? AppTokens.dark
            : AppTokens.light);
  }
}
