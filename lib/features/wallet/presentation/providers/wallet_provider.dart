import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_providers.dart';
import '../../../expense/data/repositories/expense_repository_impl.dart';
import '../../../expense/presentation/providers/expense_refresh_provider.dart';
import '../../data/datasources/wallet_local_datasource.dart';
import '../../data/repositories/wallet_repository_impl.dart';
import '../../domain/entities/wallet_entity.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../domain/usecases/archive_wallet_usecase.dart';
import '../../domain/usecases/delete_wallet_usecase.dart';
import '../../domain/usecases/get_wallets_usecase.dart';
import '../../domain/usecases/save_wallet_usecase.dart';

final walletLocalDataSourceProvider = Provider<WalletLocalDataSource>((ref) {
  return WalletLocalDataSource(ref.watch(isarProvider));
});

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepositoryImpl(
    localDataSource: ref.watch(walletLocalDataSourceProvider),
  );
});

final getWalletsUseCaseProvider = Provider<GetWalletsUseCase>((ref) {
  return GetWalletsUseCase(ref.watch(walletRepositoryProvider));
});

final saveWalletUseCaseProvider = Provider<SaveWalletUseCase>((ref) {
  return SaveWalletUseCase(ref.watch(walletRepositoryProvider));
});

final deleteWalletUseCaseProvider = Provider<DeleteWalletUseCase>((ref) {
  return DeleteWalletUseCase(ref.watch(walletRepositoryProvider));
});

final archiveWalletUseCaseProvider = Provider<ArchiveWalletUseCase>((ref) {
  return ArchiveWalletUseCase(ref.watch(walletRepositoryProvider));
});

final walletProvider =
    AsyncNotifierProvider<WalletNotifier, List<WalletEntity>>(
      WalletNotifier.new,
    );

final activeWalletIdProvider = StateProvider<int?>((ref) => null);

final activeWalletProvider = Provider<WalletEntity?>((ref) {
  final activeId = ref.watch(activeWalletIdProvider);
  final walletsAsync = ref.watch(walletProvider);

  return walletsAsync.maybeWhen(
    data: (wallets) {
      if (wallets.isEmpty) {
        return null;
      }

      if (activeId == null) {
        for (final wallet in wallets) {
          if (wallet.type == WalletType.cash) {
            return wallet;
          }
        }
        return wallets.first;
      }

      for (final wallet in wallets) {
        if (wallet.id == activeId) {
          return wallet;
        }
      }
      return wallets.first;
    },
    orElse: () => null,
  );
});

final walletByIdProvider = Provider.family<WalletEntity?, int>((ref, id) {
  final wallets =
      ref.watch(walletProvider).valueOrNull ?? const <WalletEntity>[];
  for (final wallet in wallets) {
    if (wallet.id == id) {
      return wallet;
    }
  }
  return null;
});

final totalBalanceProvider = Provider<double>((ref) {
  final wallets = ref.watch(walletProvider).valueOrNull;
  if (wallets == null) {
    return 0;
  }
  return wallets
      .where((wallet) => !wallet.isArchived)
      .fold<double>(0, (sum, wallet) => sum + wallet.currentBalance);
});

final walletMonthlySpentProvider = FutureProvider.family<double, int>((
  ref,
  walletId,
) async {
  ref.watch(expenseRefreshTokenProvider);
  final repository = ExpenseRepositoryImpl(
    localDataSource: ref.watch(expenseLocalDataSourceProvider),
  );
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final expenses = await repository.getExpensesByWallet(walletId);
  final thisMonth = expenses.where(
    (expense) => !expense.date.isBefore(startOfMonth),
  );
  return thisMonth.fold<double>(0, (sum, expense) => sum + expense.amount);
});

final walletBreakdownForMonthProvider =
    FutureProvider.family<Map<int, double>, DateTime>((ref, month) async {
      ref.watch(expenseRefreshTokenProvider);
      final repository = ExpenseRepositoryImpl(
        localDataSource: ref.watch(expenseLocalDataSourceProvider),
      );
      final start = DateTime(month.year, month.month, 1);
      final end = month.month == 12
          ? DateTime(
              month.year + 1,
              1,
              1,
            ).subtract(const Duration(milliseconds: 1))
          : DateTime(
              month.year,
              month.month + 1,
              1,
            ).subtract(const Duration(milliseconds: 1));
      final expenses = await repository.getExpensesByDateRange(start, end);

      final totals = <int, double>{};
      for (final expense in expenses) {
        final walletId = expense.walletId;
        if (walletId == null) {
          continue;
        }
        totals.update(
          walletId,
          (value) => value + expense.amount,
          ifAbsent: () => expense.amount,
        );
      }
      return totals;
    });

class WalletNotifier extends AsyncNotifier<List<WalletEntity>> {
  @override
  Future<List<WalletEntity>> build() {
    return _loadWallets();
  }

  Future<void> addWallet(WalletEntity wallet) async {
    await ref.read(saveWalletUseCaseProvider).call(wallet);
    state = AsyncData(await _loadWallets());
  }

  Future<void> updateWallet(WalletEntity wallet) async {
    await ref.read(saveWalletUseCaseProvider).call(wallet);
    state = AsyncData(await _loadWallets());
  }

  Future<void> archiveWallet(int id) async {
    await ref.read(archiveWalletUseCaseProvider).call(id);
    state = AsyncData(await _loadWallets());
  }

  Future<void> deleteWallet(int id) async {
    await ref.read(deleteWalletUseCaseProvider).call(id);
    state = AsyncData(await _loadWallets());
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadWallets);
  }

  Future<List<WalletEntity>> _loadWallets() async {
    final wallets = await ref.read(getWalletsUseCaseProvider).call();
    final sorted = [...wallets]
      ..sort((first, second) => first.sortOrder.compareTo(second.sortOrder));
    return sorted;
  }
}
