import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Polished action button with consistent variants and sizing.
class AppActionButton extends StatelessWidget {
  const AppActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppActionButtonVariant.primary,
    this.size = AppActionButtonSize.medium,
    this.fullWidth = false,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppActionButtonVariant variant;
  final AppActionButtonSize size;
  final bool fullWidth;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = _resolveColors(context);
    final padding = _resolvePadding();
    final textStyle = _resolveTextStyle();
    final labelText = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      style: textStyle.copyWith(color: colors.foreground),
    );

    final content = isLoading
        ? SizedBox(
            height: textStyle.fontSize,
            width: textStyle.fontSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(colors.foreground),
            ),
          )
        : Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: textStyle.fontSize, color: colors.foreground),
                const SizedBox(width: 8),
              ],
              if (fullWidth) Flexible(child: labelText) else labelText,
            ],
          );

    return Material(
      color: colors.background,
      borderRadius: AppRadius.buttonAll,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: AppRadius.buttonAll,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: AppRadius.buttonAll,
            border: colors.border != null
                ? Border.all(color: colors.border!, width: 1.2)
                : null,
          ),
          width: fullWidth ? double.infinity : null,
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );
  }

  _ButtonColors _resolveColors(BuildContext context) {
    return switch (variant) {
      AppActionButtonVariant.primary => _ButtonColors(
        background: context.appColors.primary,
        foreground: Colors.white,
      ),
      AppActionButtonVariant.success => _ButtonColors(
        background: AppColors.success,
        foreground: Colors.white,
      ),
      AppActionButtonVariant.danger => _ButtonColors(
        background: AppColors.error,
        foreground: Colors.white,
      ),
      AppActionButtonVariant.secondary => _ButtonColors(
        background: context.appColors.primary.withValues(
          alpha: context.isDarkMode ? 0.18 : 0.1,
        ),
        foreground: context.appColors.primary,
      ),
      AppActionButtonVariant.ghost => _ButtonColors(
        background: Colors.transparent,
        foreground: context.appColors.primary,
        border: context.borderColor,
      ),
    };
  }

  EdgeInsetsGeometry _resolvePadding() {
    return switch (size) {
      AppActionButtonSize.small => const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),
      AppActionButtonSize.medium => const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 14,
      ),
      AppActionButtonSize.large => const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 18,
      ),
    };
  }

  TextStyle _resolveTextStyle() {
    return switch (size) {
      AppActionButtonSize.small => AppTextStyles.chipLabel,
      AppActionButtonSize.medium => AppTextStyles.titleMedium,
      AppActionButtonSize.large => AppTextStyles.titleLarge,
    };
  }
}

enum AppActionButtonVariant { primary, secondary, danger, ghost, success }

enum AppActionButtonSize { small, medium, large }

class _ButtonColors {
  const _ButtonColors({
    required this.background,
    required this.foreground,
    this.border,
  });

  final Color background;
  final Color foreground;
  final Color? border;
}
