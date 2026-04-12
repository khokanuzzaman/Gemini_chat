import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';

class ChatConfirmationCardShell extends StatelessWidget {
  const ChatConfirmationCardShell({
    super.key,
    required this.accentColor,
    required this.child,
    this.maxWidthFactor = 0.84,
  });

  final Color accentColor;
  final Widget child;
  final double maxWidthFactor;

  @override
  Widget build(BuildContext context) {
    return AppFadeSlideIn(
      duration: AppMotion.normal,
      offset: const Offset(0, 0.05),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * maxWidthFactor,
          ),
          child: AppCard(
            padding: EdgeInsets.zero,
            elevation: 2,
            borderRadius: AppRadius.cardAll,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(height: 4, color: accentColor),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChatConfirmationIconCircle extends StatelessWidget {
  const ChatConfirmationIconCircle({
    super.key,
    this.emoji,
    this.icon,
    this.tintColor,
    this.gradient,
    this.iconColor,
    this.size = 44,
  }) : assert(emoji != null || icon != null);

  final String? emoji;
  final IconData? icon;
  final Color? tintColor;
  final Gradient? gradient;
  final Color? iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final accentColor = tintColor ?? context.appColors.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        color: gradient == null
            ? accentColor.withValues(alpha: context.isDarkMode ? 0.18 : 0.10)
            : null,
      ),
      alignment: Alignment.center,
      child: emoji != null
          ? Text(emoji!, style: TextStyle(fontSize: size * 0.45))
          : Icon(icon, size: size * 0.45, color: iconColor ?? accentColor),
    );
  }
}

class ChatConfirmationNoteChip extends StatelessWidget {
  const ChatConfirmationNoteChip({
    super.key,
    required this.note,
    this.tintColor = AppColors.warning,
    this.icon = Icons.info_outline_rounded,
  });

  final String note;
  final Color tintColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tintColor.withValues(alpha: context.isDarkMode ? 0.20 : 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: tintColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              note,
              style: AppTextStyles.caption.copyWith(color: tintColor),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatConfirmationBanner extends StatelessWidget {
  const ChatConfirmationBanner({
    super.key,
    required this.icon,
    required this.text,
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final String text;
  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: foregroundColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatConfirmationMutedBox extends StatelessWidget {
  const ChatConfirmationMutedBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: context.mutedSurfaceColor,
        borderRadius: AppRadius.cardAll,
      ),
      child: child,
    );
  }
}

class ChatConfirmationSavedChip extends StatelessWidget {
  const ChatConfirmationSavedChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('saved'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: AppRadius.cardAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.check_circle_rounded, size: 18, color: AppColors.success),
          SizedBox(width: 8),
          Text(
            'সংরক্ষিত',
            style: TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class ChatConfirmationActionSwitcher extends StatelessWidget {
  const ChatConfirmationActionSwitcher({
    super.key,
    required this.isSaved,
    required this.unsavedChild,
  });

  final bool isSaved;
  final Widget unsavedChild;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.fast,
      child: isSaved
          ? const ChatConfirmationSavedChip()
          : KeyedSubtree(key: const ValueKey('unsaved'), child: unsavedChild),
    );
  }
}

class ChatActionButton extends StatelessWidget {
  const ChatActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.variant,
    required this.onPressed,
    this.size = AppActionButtonSize.medium,
    this.fullWidth = false,
    this.enabled = true,
    this.isLoading = false,
  });

  final String label;
  final IconData icon;
  final AppActionButtonVariant variant;
  final VoidCallback? onPressed;
  final AppActionButtonSize size;
  final bool fullWidth;
  final bool enabled;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final interactive = enabled && !isLoading;

    return Opacity(
      opacity: interactive ? 1 : 0.5,
      child: IgnorePointer(
        ignoring: !interactive,
        child: AppActionButton(
          label: label,
          icon: icon,
          variant: variant,
          size: size,
          fullWidth: fullWidth,
          isLoading: isLoading,
          onPressed: interactive ? onPressed : null,
        ),
      ),
    );
  }
}

class ChatSelectionCheckbox extends StatelessWidget {
  const ChatSelectionCheckbox({
    super.key,
    required this.checked,
    required this.color,
  });

  final bool checked;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.fast,
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: checked ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: checked ? color : context.borderColor,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: checked
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : null,
    );
  }
}
