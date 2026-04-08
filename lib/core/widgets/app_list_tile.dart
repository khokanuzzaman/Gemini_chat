import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_amount_text.dart';

/// A premium list tile for settings, transactions, and wallet rows.
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.leadingEmoji,
    this.leadingIcon,
    this.leadingColor,
    this.trailing,
    this.trailingAmount,
    this.trailingAmountIsIncome = false,
    this.trailingAmountIsExpense = false,
    this.trailingSubtitle,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.dense = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final String? leadingEmoji;
  final IconData? leadingIcon;
  final Color? leadingColor;
  final Widget? trailing;
  final double? trailingAmount;
  final bool trailingAmountIsIncome;
  final bool trailingAmountIsExpense;
  final String? trailingSubtitle;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final leadingWidget = _buildLeading(context);
    final trailingWidget = _buildTrailing(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: AppRadius.cardAll,
        child: Padding(
          padding: padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leadingWidget != null) ...[
                leadingWidget,
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: (dense
                              ? AppTextStyles.bodyMedium
                              : AppTextStyles.titleMedium)
                          .copyWith(color: context.primaryTextColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.secondaryTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailingWidget != null) ...[
                const SizedBox(width: 12),
                trailingWidget,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (leading != null) {
      return leading;
    }

    if (leadingEmoji != null) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: (leadingColor ?? context.appColors.primary)
              .withValues(alpha: context.isDarkMode ? 0.18 : 0.1),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(leadingEmoji!, style: const TextStyle(fontSize: 20)),
      );
    }

    if (leadingIcon != null) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: (leadingColor ?? context.appColors.primary)
              .withValues(alpha: context.isDarkMode ? 0.18 : 0.1),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          leadingIcon,
          size: 20,
          color: leadingColor ?? context.appColors.primary,
        ),
      );
    }

    return null;
  }

  Widget? _buildTrailing(BuildContext context) {
    if (trailing != null) {
      return trailing;
    }

    if (trailingAmount != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppAmountText(
            amount: trailingAmount!,
            isIncome: trailingAmountIsIncome,
            isExpense: trailingAmountIsExpense,
            showSign: trailingAmountIsIncome || trailingAmountIsExpense,
            style: AppTextStyles.titleMedium,
          ),
          if (trailingSubtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              trailingSubtitle!,
              style: AppTextStyles.caption.copyWith(
                color: context.secondaryTextColor,
              ),
            ),
          ],
        ],
      );
    }

    return null;
  }
}
