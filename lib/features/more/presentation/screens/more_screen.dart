import 'package:flutter/material.dart';

import '../../../../core/navigation/app_page_route.dart';
import '../../../../core/navigation/app_shell_navigation.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../category/presentation/screens/category_management_screen.dart';
import '../../../export/presentation/screens/export_screen.dart';
import '../../../settings/settings_screen.dart';
import '../../../sms_import/presentation/screens/sms_import_screen.dart';
import '../../../wallet/presentation/screens/wallet_management_screen.dart';

/// আরও tab — the catch-all hub. SMS import (the moat) is promoted to the top.
/// Analytics and Split live here now that they are no longer bottom-nav tabs.
/// Security, backup, premium and theme remain inside the full Settings screen.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'আরও',
      showBackButton: false,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  AppListTile(
                    leadingIcon: Icons.sms_rounded,
                    leadingColor: AppColors.success,
                    title: 'SMS আমদানি',
                    subtitle: 'বিকাশ, নগদ ও ব্যাংক SMS থেকে খরচ ধরুন',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => SmsImportScreen.push(context),
                  ),
                  AppListTile(
                    leadingIcon: Icons.bar_chart_rounded,
                    leadingColor: context.appColors.primary,
                    title: 'বিশ্লেষণ',
                    subtitle: 'বিস্তারিত চার্ট ও অ্যানোমালি',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: AppShellNavigation.openAnalytics,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  AppListTile(
                    leadingIcon: Icons.account_balance_wallet_rounded,
                    leadingColor: context.appColors.primary,
                    title: 'ওয়ালেট',
                    subtitle: 'ক্যাশ, বিকাশ, নগদ ও ব্যাংক',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(
                      context,
                    ).push(buildAppRoute(const WalletManagementScreen())),
                  ),
                  AppListTile(
                    leadingIcon: Icons.category_rounded,
                    leadingColor: context.appColors.primary,
                    title: 'ক্যাটাগরি',
                    subtitle: 'খরচের ক্যাটাগরি গুছিয়ে রাখুন',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(
                      context,
                    ).push(buildAppRoute(const CategoryManagementScreen())),
                  ),
                  AppListTile(
                    leadingIcon: Icons.trending_up_rounded,
                    leadingColor: AppColors.success,
                    title: 'আয়',
                    subtitle: 'আয়ের তালিকা ও ব্যবস্থাপনা',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: AppShellNavigation.openIncome,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  AppListTile(
                    leadingIcon: Icons.ios_share_rounded,
                    leadingColor: context.appColors.primary,
                    title: 'এক্সপোর্ট',
                    subtitle: 'CSV ফাইলে ডেটা রপ্তানি',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(
                      context,
                    ).push(buildAppRoute(const ExportScreen())),
                  ),
                  AppListTile(
                    leadingIcon: Icons.call_split_rounded,
                    leadingColor: context.appColors.primary,
                    title: 'স্প্লিট বিল',
                    subtitle: 'বিল ভাগ করুন',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: AppShellNavigation.openSplit,
                  ),
                  AppListTile(
                    leadingIcon: Icons.settings_rounded,
                    leadingColor: context.appColors.primary,
                    title: 'সেটিংস',
                    subtitle: 'নিরাপত্তা, ব্যাকআপ, থিম ও আরও',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                      AppSlideRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
