import 'package:flutter/material.dart';

import '../../../../../core/navigation/app_page_route.dart';
import '../../../../../core/navigation/app_shell_navigation.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../wallet/presentation/screens/wallet_management_screen.dart';
import '../../screens/manual_add_screen.dart';

/// First run (zero expenses AND zero income): never a blank page. A welcome hero
/// with the app mark, three guided first steps, and one primary action.
class HomeWelcome extends StatelessWidget {
  const HomeWelcome({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: context.heroCardDecoration(),
          child: Column(
            children: [
              // Placeholder mark — the real logo lands in its own slice.
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: tokens.onHero.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: tokens.onHero,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'PocketPilot-এ স্বাগতম',
                textAlign: TextAlign.center,
                style: AppTextStyles.displayMedium.copyWith(
                  color: tokens.onHero,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'আপনার খরচ, আয় আর সম্পদ — এক জায়গায়, ফোনেই থাকে।',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: tokens.onHeroMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.cardGap),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              _GuidedStep(
                number: '১',
                icon: Icons.add_circle_outline_rounded,
                title: 'প্রথম খরচ যোগ করুন',
                subtitle: 'কয়েক সেকেন্ডেই হয়ে যায়',
                onTap: () => showManualAddSheet(context),
              ),
              Divider(height: 1, indent: 16, endIndent: 16, color: tokens.line),
              _GuidedStep(
                number: '২',
                icon: Icons.sms_outlined,
                title: 'SMS থেকে লেনদেন আনুন',
                subtitle: 'bKash, নগদ, ব্যাংকের মেসেজ নিজে নিজে',
                onTap: AppShellNavigation.openSmsImport,
              ),
              Divider(height: 1, indent: 16, endIndent: 16, color: tokens.line),
              _GuidedStep(
                number: '৩',
                icon: Icons.account_balance_wallet_outlined,
                title: 'ওয়ালেট সেট করুন',
                subtitle: 'ক্যাশ, বিকাশ, ব্যাংকের ব্যালেন্স',
                onTap: () => Navigator.of(context).push(
                  AppSlideRoute(builder: (_) => const WalletManagementScreen()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.cardGap),
        AppActionButton(
          label: 'খরচ যোগ করুন',
          icon: Icons.add_rounded,
          fullWidth: true,
          onPressed: () => showManualAddSheet(context),
        ),
      ],
    );
  }
}

class _GuidedStep extends StatelessWidget {
  const _GuidedStep({
    required this.number,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String number;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tokens.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: tokens.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$number. $title',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: tokens.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: tokens.muted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: tokens.muted),
          ],
        ),
      ),
    );
  }
}
