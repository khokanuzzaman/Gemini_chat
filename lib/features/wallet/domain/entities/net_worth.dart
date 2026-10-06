import 'wallet_entity.dart';

/// Wallets in display/summing order — the single ordering every net-worth
/// consumer uses (see [netWorthOf]).
List<WalletEntity> sortedBySortOrder(Iterable<WalletEntity> wallets) {
  return [...wallets]
    ..sort((first, second) => first.sortOrder.compareTo(second.sortOrder));
}

/// মোট সম্পদ: the sum of every non-archived wallet's `currentBalance`.
///
/// The ONE definition of net worth. `totalBalanceProvider` and the net-worth
/// snapshots both call it with a [sortedBySortOrder] list, so they agree to the
/// last bit (floating-point addition is order-dependent).
double netWorthOf(Iterable<WalletEntity> wallets) {
  return wallets
      .where((wallet) => !wallet.isArchived)
      .fold<double>(0, (sum, wallet) => sum + wallet.currentBalance);
}
