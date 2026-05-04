import 'package:flutter/material.dart';

import '../../../../../core/navigation/app_shell_navigation.dart';
import '../../../../../core/navigation/app_page_route.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../budget/presentation/screens/budget_planner_screen.dart';
import '../../../../export/presentation/screens/export_screen.dart';
import '../../../../goals/presentation/screens/goals_screen.dart';
import '../../../../sms_import/presentation/screens/sms_import_screen.dart';
import '../../screens/manual_add_screen.dart';

class PrimaryQuickActions extends StatelessWidget {
  const PrimaryQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _PrimaryAction(
        label: 'খরচ যোগ',
        icon: Icons.add_rounded,
        onTap: () => showManualAddSheet(context),
      ),
      _PrimaryAction(
        label: 'আয় যোগ',
        icon: Icons.trending_up_rounded,
        color: AppColors.success,
        onTap: AppShellNavigation.openIncome,
      ),
      _PrimaryAction(
        label: 'রিসিট স্ক্যান',
        icon: Icons.camera_alt_rounded,
        onTap: AppShellNavigation.openChat,
      ),
      _PrimaryAction(
        label: 'স্প্লিট বিল',
        icon: Icons.call_split_rounded,
        onTap: AppShellNavigation.openSplit,
      ),
      _PrimaryAction(
        label: 'আরও',
        icon: Icons.more_horiz_rounded,
        onTap: () => _openMoreActionsSheet(context),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnCountForWidth(constraints.maxWidth);
        final spacing = AppSpacing.tightGap;
        final actionWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        final compact = columns >= 3;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: actions.map((action) {
            return SizedBox(
              width: actionWidth,
              child: AppChip(
                label: action.label,
                icon: action.icon,
                color: action.color,
                compact: compact,
                fullWidth: true,
                onTap: action.onTap,
              ),
            );
          }).toList(growable: false),
        );
      },
    );
  }

  void _openMoreActionsSheet(BuildContext context) {
    AppBottomSheet.show<void>(
      context: context,
      title: 'আরও',
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.tightGap,
        mainAxisSpacing: AppSpacing.tightGap,
        childAspectRatio: 1.6,
        children: [
          _MoreActionTile(
            icon: Icons.pie_chart_rounded,
            label: 'বাজেট',
            color: context.appColors.primary,
            onTap: () {
              Navigator.of(context).maybePop();
              Navigator.of(context).push(
                AppSlideRoute(builder: (_) => const BudgetPlannerScreen()),
              );
            },
          ),
          _MoreActionTile(
            icon: Icons.flag_outlined,
            label: 'লক্ষ্য',
            color: AppColors.warning,
            onTap: () {
              Navigator.of(context).maybePop();
              Navigator.of(context).push(buildAppRoute(const GoalsScreen()));
            },
          ),
          _MoreActionTile(
            icon: Icons.sms_rounded,
            label: 'SMS আমদানি',
            color: AppColors.success,
            onTap: () {
              Navigator.of(context).maybePop();
              SmsImportScreen.push(context);
            },
          ),
          _MoreActionTile(
            icon: Icons.ios_share_rounded,
            label: 'এক্সপোর্ট',
            color: context.appColors.primary,
            onTap: () {
              Navigator.of(context).maybePop();
              Navigator.of(context).push(buildAppRoute(const ExportScreen()));
            },
          ),
        ],
      ),
    );
  }

  int _columnCountForWidth(double width) {
    if (width >= 720) return 5;
    if (width >= 540) return 4;
    if (width >= 400) return 3;
    return 2;
  }
}

class _PrimaryAction {
  const _PrimaryAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
}

class _MoreActionTile extends StatelessWidget {
  const _MoreActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.titleMedium.copyWith(
              color: context.primaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
