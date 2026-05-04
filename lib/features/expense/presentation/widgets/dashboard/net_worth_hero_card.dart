import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/navigation/app_shell_navigation.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/bangla_formatters.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../wallet/presentation/providers/wallet_provider.dart';
import '../../providers/expense_providers.dart';

class NetWorthHeroCard extends ConsumerWidget {
  const NetWorthHeroCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletProvider);
    return walletsAsync.when(
      loading: () => const AppLoadingState.heroCard(),
      error: (error, _) => AppErrorState(
        title: 'মোট সম্পদ লোড করা যায়নি',
        onRetry: () => ref.invalidate(walletProvider),
        compact: true,
      ),
      data: (wallets) {
        final activeWallets = wallets
            .where((wallet) => !wallet.isArchived)
            .toList();
        if (activeWallets.isEmpty) {
          return AppEmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'কোনো ওয়ালেট নেই',
            subtitle: 'প্রথমে একটি ওয়ালেট যোগ করুন',
            actionLabel: 'ওয়ালেট যোগ করুন',
            onAction: onTap,
            compact: true,
          );
        }

        final netWorth = ref.watch(totalBalanceProvider);
        final cashFlowAsync = ref.watch(cashFlowProvider);
        final pills = cashFlowAsync.maybeWhen(
          data: (cashFlow) => _CashFlowTrailingPills(
            income: cashFlow.income,
            expense: cashFlow.expense,
          ),
          orElse: () => null,
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 400;

            return AppCard(
              onTap: onTap,
              elevation: 3,
              gradient: context.primaryGradient,
              borderRadius: AppRadius.heroCardAll,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Stack(
                children: [
                  Positioned(
                    right: -30,
                    top: -30,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: isCompact ? 138 : 108,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'মোট সম্পদ',
                              style: AppTextStyles.heroLabel.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white.withValues(alpha: 0.7),
                              size: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (isCompact) ...[
                          _HeroAmountBlock(
                            amount: BanglaFormatters.currency(netWorth),
                            subtitle:
                                '${BanglaFormatters.count(activeWallets.length)} টি ওয়ালেট থেকে',
                          ),
                          if (pills != null) ...[
                            const SizedBox(height: 16),
                            pills,
                          ],
                        ] else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: _HeroAmountBlock(
                                  amount: BanglaFormatters.currency(netWorth),
                                  subtitle:
                                      '${BanglaFormatters.count(activeWallets.length)} টি ওয়ালেট থেকে',
                                ),
                              ),
                              if (pills != null) ...[
                                const SizedBox(width: 16),
                                Flexible(
                                  child: Align(
                                    alignment: Alignment.bottomRight,
                                    child: pills,
                                  ),
                                ),
                              ],
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _HeroAmountBlock extends StatelessWidget {
  const _HeroAmountBlock({required this.amount, required this.subtitle});

  final String amount;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            amount,
            style: AppTextStyles.heroAmount.copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

class _CashFlowTrailingPills extends StatelessWidget {
  const _CashFlowTrailingPills({required this.income, required this.expense});

  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Pill(
          icon: Icons.arrow_upward_rounded,
          color: AppColors.success,
          text: BanglaFormatters.currency(income),
          onTap: AppShellNavigation.openIncome,
        ),
        _Pill(
          icon: Icons.arrow_downward_rounded,
          color: AppColors.error,
          text: BanglaFormatters.currency(expense),
          onTap: AppShellNavigation.openExpenses,
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.color,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                text,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
