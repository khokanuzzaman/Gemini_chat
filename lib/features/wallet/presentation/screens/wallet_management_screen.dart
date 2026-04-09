import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/widgets.dart';
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

    return AppPageScaffold(
      title: 'ওয়ালেট',
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddEditWalletSheet(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: walletsAsync.when(
        loading: () => const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(AppSpacing.screenPadding),
          child: AppLoadingState.list(),
        ),
        error: (error, _) => AppErrorState(
          message: _messageForError(error),
          onRetry: () => ref.read(walletProvider.notifier).refresh(),
        ),
        data: (wallets) {
          if (wallets.isEmpty) {
            return AppEmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'কোনো ওয়ালেট নেই',
              subtitle: 'নতুন ওয়ালেট যোগ করে ব্যালেন্স ট্র্যাক করুন',
              actionLabel: 'ওয়ালেট যোগ করুন',
              onAction: () => showAddEditWalletSheet(context),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.md,
              AppSpacing.screenPadding,
              100,
            ),
            children: [
              AppHeroCard(
                label: 'মোট ব্যালেন্স',
                amount: BanglaFormatters.currency(totalBalance),
                subtitle: '${wallets.length.toString()}টি সক্রিয় ওয়ালেট',
                icon: Icons.account_balance_wallet_outlined,
                gradient: AppGradients.primary,
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              ...wallets.map(
                (wallet) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
              AppActionButton(
                label: 'ঠিক আছে',
                onPressed: () => Navigator.of(dialogContext).pop(),
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
            AppActionButton(
              label: 'বাদ দিন',
              variant: AppActionButtonVariant.ghost,
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            AppActionButton(
              label: 'Archive করুন',
              variant: AppActionButtonVariant.danger,
              onPressed: () => Navigator.of(dialogContext).pop(true),
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

  static String _messageForError(Object error) {
    if (error is Failure) {
      return error.message;
    }
    if (error is StateError) {
      return error.message.toString();
    }
    return 'ওয়ালেট load করা যায়নি';
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
          gradient: AppGradients.warning,
          borderRadius: AppRadius.cardAll,
        ),
        child: const Icon(Icons.archive_outlined, color: Colors.white),
      ),
      child: AppCard(
        elevation: 2,
        gradient: _gradientForWalletType(wallet.type),
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(wallet.emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wallet.name,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    wallet.type.categoryLabelBn,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                  if ((wallet.accountNumber ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'শেষ ৪ ডিজিট: ${wallet.accountNumber}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                  if ((wallet.note ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      wallet.note!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  BanglaFormatters.currency(wallet.currentBalance),
                  style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  wallet.type.labelBn,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Gradient _gradientForWalletType(WalletType type) {
    return switch (type) {
      WalletType.cash => AppGradients.walletOrange,
      WalletType.bkash || WalletType.bank => AppGradients.walletBlue,
      WalletType.nagad || WalletType.card => AppGradients.walletPurple,
      WalletType.rocket || WalletType.other => AppGradients.walletTeal,
    };
  }
}
