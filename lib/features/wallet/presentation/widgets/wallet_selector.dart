import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../providers/wallet_provider.dart';

class WalletSelectorWidget extends ConsumerWidget {
  const WalletSelectorWidget({
    super.key,
    required this.selectedWalletId,
    required this.onChanged,
    this.label = 'ওয়ালেট',
  });

  final int? selectedWalletId;
  final ValueChanged<int> onChanged;
  final String? label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 8),
        ],
        walletsAsync.when(
          data: (wallets) {
            if (wallets.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.mutedSurfaceColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.borderColor),
                ),
                child: Text(
                  'কোনো ওয়ালেট পাওয়া যায়নি',
                  style: TextStyle(
                    color: context.secondaryTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }

            if (wallets.length == 1 && selectedWalletId != wallets.first.id) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                onChanged(wallets.first.id);
              });
            }

            final fallbackWallet = selectedWalletId == null
                ? ref.watch(activeWalletProvider)
                : null;
            final effectiveSelectedId = selectedWalletId ?? fallbackWallet?.id;
            final isSingleWallet = wallets.length == 1;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: wallets
                    .map((wallet) {
                      final isSelected = wallet.id == effectiveSelectedId;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: isSingleWallet
                              ? null
                              : () => onChanged(wallet.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : context.mutedSurfaceColor,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : context.borderColor,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  wallet.emoji,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  wallet.name,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.onPrimary
                                        : context.primaryTextColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
            );
          },
          loading: () => SizedBox(
            height: 42,
            child: AppShimmer(
              child: Row(
                children: const [
                  _WalletChipPlaceholder(width: 96),
                  SizedBox(width: 8),
                  _WalletChipPlaceholder(width: 104),
                  SizedBox(width: 8),
                  _WalletChipPlaceholder(width: 92),
                ],
              ),
            ),
          ),
          error: (_, _) => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.mutedSurfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.borderColor),
            ),
            child: Text(
              'ওয়ালেট লোড করা যায়নি',
              style: TextStyle(
                color: context.secondaryTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WalletChipPlaceholder extends StatelessWidget {
  const _WalletChipPlaceholder({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: width,
      decoration: BoxDecoration(
        color: context.isDarkMode ? AppColors.darkSurface : AppColors.grey100,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
