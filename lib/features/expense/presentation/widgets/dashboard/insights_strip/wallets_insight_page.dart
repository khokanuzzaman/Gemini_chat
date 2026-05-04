import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/navigation/app_page_route.dart';
import '../../../../../../core/navigation/app_shell_navigation.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/utils/bangla_formatters.dart';
import '../../../../../../core/widgets/widgets.dart';
import '../../../../../wallet/domain/entities/wallet_entity.dart';
import '../../../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../../../wallet/presentation/screens/wallet_management_screen.dart';
import '../../../providers/expense_providers.dart';

class WalletsInsightPage extends ConsumerWidget {
  const WalletsInsightPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletProvider);
    final totalBalance = ref.watch(totalBalanceProvider);

    return walletsAsync.when(
      loading: () => const SizedBox(
        height: 224,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'ওয়ালেট লোড করা যায়নি',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.secondaryTextColor,
                ),
              ),
            ),
            AppActionButton(
              label: 'আবার চেষ্টা',
              onPressed: () => ref.read(walletProvider.notifier).refresh(),
              size: AppActionButtonSize.small,
              variant: AppActionButtonVariant.ghost,
            ),
          ],
        ),
      ),
      data: (wallets) {
        final activeWallets = wallets
            .where((wallet) => !wallet.isArchived)
            .toList(growable: false);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionHeader(
              title: 'আমার ওয়ালেট',
              subtitle:
                  'মোট ব্যালেন্স ${BanglaFormatters.currency(totalBalance)}',
            ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                        maxHeight: constraints.maxHeight,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ...activeWallets.map(
                            (wallet) => Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: _DashboardWalletCard(
                                walletId: wallet.id,
                                emoji: wallet.emoji,
                                name: wallet.name,
                                walletType: wallet.type,
                                balance: wallet.currentBalance,
                                onTap: () async {
                                  final controller = ref.read(
                                    expenseListControllerProvider.notifier,
                                  );
                                  await controller.clearFilters();
                                  await controller.setWallet(wallet.id);
                                  AppShellNavigation.openExpenses();
                                },
                              ),
                            ),
                          ),
                          _AddWalletCard(
                            onTap: () {
                              Navigator.of(context).push(
                                AppSlideRoute(
                                  builder: (_) => const WalletManagementScreen(),
                                ),
                              );
                            },
                          ),
                          const _ActionTrailingSpacer(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DashboardWalletCard extends ConsumerWidget {
  const _DashboardWalletCard({
    required this.walletId,
    required this.emoji,
    required this.name,
    required this.walletType,
    required this.balance,
    required this.onTap,
  });

  final int walletId;
  final String emoji;
  final String name;
  final WalletType walletType;
  final double balance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlySpent = ref.watch(walletMonthlySpentProvider(walletId));
    final gradient = _walletGradient(walletType);

    return SizedBox(
      width: 160,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        gradient: gradient,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 10),
                Text(
                  name,
                  style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: AppAmountText(
                    amount: balance,
                    style: AppTextStyles.statValue.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
            monthlySpent.when(
              data: (spent) => Text(
                'এই মাসে খরচ: ${BanglaFormatters.currency(spent)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              loading: () =>
                  const ShimmerBox(height: 14, width: 96, radius: 999),
              error: (_, _) => Text(
                'খরচ জানা যায়নি',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient _walletGradient(WalletType type) {
    return switch (type) {
      WalletType.cash => AppGradients.walletTeal,
      WalletType.bkash => AppGradients.walletOrange,
      WalletType.nagad => AppGradients.walletPurple,
      WalletType.rocket => AppGradients.walletBlue,
      WalletType.bank => AppGradients.walletBlue,
      WalletType.card => AppGradients.walletPurple,
      WalletType.other => AppGradients.walletTeal,
    };
  }
}

class _AddWalletCard extends StatelessWidget {
  const _AddWalletCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: context.mutedSurfaceColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'নতুন\nওয়ালেট',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(
                color: context.primaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTrailingSpacer extends StatelessWidget {
  const _ActionTrailingSpacer();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width < 430 ? 88 : 56,
      height: 1,
    );
  }
}
