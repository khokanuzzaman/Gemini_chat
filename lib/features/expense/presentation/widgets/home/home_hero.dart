import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/navigation/app_page_route.dart';
import '../../../../../core/navigation/app_shell_navigation.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/bangla_formatters.dart';
import '../../../../wallet/domain/entities/net_worth.dart';
import '../../../../wallet/domain/entities/wallet_entity.dart';
import '../../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../../wallet/presentation/screens/wallet_management_screen.dart';
import '../../providers/expense_providers.dart';

/// মোট সম্পদ — cumulative, never resets — with a chip per wallet.
class HomeHero extends ConsumerWidget {
  const HomeHero({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets =
        (ref.watch(walletProvider).valueOrNull ?? const <WalletEntity>[])
            .where((wallet) => !wallet.isArchived)
            .toList(growable: false);
    // Same definition (and ordering) as totalBalanceProvider.
    final total = netWorthOf(sortedBySortOrder(wallets));
    final tokens = context.tokens;

    return Semantics(
      container: true,
      label: 'মোট সম্পদ ${BanglaFormatters.currency(total)}',
      child: GestureDetector(
        onTap: () => Navigator.of(
          context,
        ).push(AppSlideRoute(builder: (_) => const WalletManagementScreen())),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: context.heroCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'মোট সম্পদ',
                style: AppTextStyles.heroLabel.copyWith(
                  color: tokens.onHeroMuted,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  BanglaFormatters.currency(total),
                  style: AppTextStyles.heroAmount.copyWith(
                    color: tokens.onHero,
                  ),
                ),
              ),
              Text(
                'সব ওয়ালেট মিলিয়ে',
                style: AppTextStyles.bodySmall.copyWith(
                  color: tokens.onHeroMuted,
                ),
              ),
              if (wallets.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final wallet in wallets) ...[
                        _WalletChip(wallet: wallet),
                        if (wallet != wallets.last) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletChip extends ConsumerWidget {
  const _WalletChip({required this.wallet});

  final WalletEntity wallet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    return Material(
      color: tokens.onHero.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final controller = ref.read(expenseListControllerProvider.notifier);
          await controller.clearFilters();
          await controller.setWallet(wallet.id);
          AppShellNavigation.openExpenses();
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 72, maxWidth: 148),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${wallet.emoji} ${wallet.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: tokens.onHeroMuted,
                  ),
                ),
                Text(
                  BanglaFormatters.currency(wallet.currentBalance),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.chipLabel.copyWith(
                    color: tokens.onHero,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
