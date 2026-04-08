import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../domain/entities/wallet_entity.dart';
import '../providers/wallet_provider.dart';
import '../widgets/add_edit_wallet_sheet.dart';

class WalletManagementScreen extends ConsumerStatefulWidget {
  const WalletManagementScreen({super.key});

  @override
  ConsumerState<WalletManagementScreen> createState() =>
      _WalletManagementScreenState();
}

class _WalletManagementScreenState
    extends ConsumerState<WalletManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletProvider);
    final totalBalance = ref.watch(totalBalanceProvider);

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('ওয়ালেট')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddEditWalletSheet(context),
        child: const Icon(Icons.add),
      ),
      body: walletsAsync.when(
        loading: () => const _WalletLoadingState(),
        error: (error, _) => _WalletErrorState(
          message: _messageForError(error),
          onRetry: () => ref.read(walletProvider.notifier).refresh(),
        ),
        data: (wallets) {
          if (wallets.isEmpty) {
            return _WalletEmptyState(
              onAdd: () => showAddEditWalletSheet(context),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _WalletSummaryCard(totalBalance: totalBalance),
              const SizedBox(height: 16),
              ...wallets.map(
                (wallet) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _WalletCard(
                    wallet: wallet,
                    walletCount: wallets.length,
                    onTap: () =>
                        showAddEditWalletSheet(context, existingWallet: wallet),
                    onArchive: () => _confirmArchive(wallet, wallets.length),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<bool> _confirmArchive(WalletEntity wallet, int walletCount) async {
    if (walletCount <= 1) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('শেষ ওয়ালেট'),
            content: const Text('কমপক্ষে একটি সক্রিয় ওয়ালেট রাখতে হবে।'),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('ঠিক আছে'),
              ),
            ],
          );
        },
      );
      return false;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ওয়ালেট archive করবেন?'),
          content: Text('"${wallet.displayName}" আপাতত লুকিয়ে রাখা হবে।'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('বাদ দিন'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Archive করুন'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return false;
    }

    try {
      await ref.read(walletProvider.notifier).archiveWallet(wallet.id);
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ওয়ালেট archive করা হয়েছে')),
      );
      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_messageForError(error))));
      return false;
    }
  }

  String _messageForError(Object error) {
    if (error is Failure) {
      return error.message;
    }
    if (error is StateError) {
      return error.message.toString();
    }
    return 'ওয়ালেট load করা যায়নি';
  }
}

class _WalletSummaryCard extends StatelessWidget {
  const _WalletSummaryCard({required this.totalBalance});

  final double totalBalance;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [context.appColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'মোট ব্যালেন্স',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              BanglaFormatters.currency(totalBalance),
              style: AppTextStyles.displayMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.wallet,
    required this.walletCount,
    required this.onTap,
    required this.onArchive,
  });

  final WalletEntity wallet;
  final int walletCount;
  final VoidCallback onTap;
  final Future<bool> Function() onArchive;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('wallet-${wallet.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => onArchive(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.warning,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.archive_outlined, color: Colors.white),
      ),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(wallet.emoji, style: const TextStyle(fontSize: 30)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${wallet.name} — ${wallet.type.categoryLabelBn}',
                        style: AppTextStyles.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      if ((wallet.accountNumber ?? '').isNotEmpty)
                        Text(
                          'শেষ ৪ ডিজিট: ${wallet.accountNumber}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.secondaryTextColor,
                          ),
                        ),
                      if ((wallet.note ?? '').isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          wallet.note!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.secondaryTextColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      BanglaFormatters.currency(wallet.currentBalance),
                      style: AppTextStyles.titleMedium.copyWith(
                        color: context.appColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      wallet.type.labelBn,
                      style: AppTextStyles.caption.copyWith(
                        color: context.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WalletLoadingState extends StatelessWidget {
  const _WalletLoadingState();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: const [
          ShimmerBox(height: 110, radius: 16),
          SizedBox(height: 16),
          ShimmerBox(height: 86, radius: 16),
          SizedBox(height: 12),
          ShimmerBox(height: 86, radius: 16),
          SizedBox(height: 12),
          ShimmerBox(height: 86, radius: 16),
        ],
      ),
    );
  }
}

class _WalletErrorState extends StatelessWidget {
  const _WalletErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: context.secondaryTextColor,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('আবার চেষ্টা করুন'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletEmptyState extends StatelessWidget {
  const _WalletEmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 52,
              color: context.secondaryTextColor,
            ),
            const SizedBox(height: 12),
            const Text(
              'কোনো ওয়ালেট নেই। নতুন ওয়ালেট যোগ করুন।',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('ওয়ালেট যোগ করুন'),
            ),
          ],
        ),
      ),
    );
  }
}
