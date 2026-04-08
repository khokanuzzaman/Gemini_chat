import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/preferences/app_preferences.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../wallet/domain/entities/wallet_entity.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../data/datasources/income_local_datasource.dart';
import '../../data/repositories/income_repository_impl.dart';
import '../../domain/entities/income_entity.dart';
import '../../domain/repositories/income_repository.dart';
import '../../domain/usecases/delete_income_usecase.dart';
import '../../domain/usecases/get_all_income_usecase.dart';
import '../../domain/usecases/get_income_for_month_usecase.dart';
import '../../domain/usecases/get_income_totals_usecase.dart';
import '../../domain/usecases/save_income_usecase.dart';
import '../../domain/usecases/update_income_usecase.dart';

final incomeRefreshTokenProvider = StateProvider<int>((ref) => 0);

final incomeLocalDataSourceProvider = Provider<IncomeLocalDataSource>((ref) {
  final isar = ref.watch(isarProvider);
  return IncomeLocalDataSource(isar);
});

final incomeRepositoryProvider = Provider<IncomeRepository>((ref) {
  final local = ref.watch(incomeLocalDataSourceProvider);
  return IncomeRepositoryImpl(localDataSource: local);
});

final getAllIncomeUseCaseProvider = Provider<GetAllIncomeUseCase>((ref) {
  return GetAllIncomeUseCase(ref.watch(incomeRepositoryProvider));
});

final getIncomeForMonthUseCaseProvider =
    Provider<GetIncomeForMonthUseCase>((ref) {
      return GetIncomeForMonthUseCase(ref.watch(incomeRepositoryProvider));
    });

final saveIncomeUseCaseProvider = Provider<SaveIncomeUseCase>((ref) {
  return SaveIncomeUseCase(ref.watch(incomeRepositoryProvider));
});

final deleteIncomeUseCaseProvider = Provider<DeleteIncomeUseCase>((ref) {
  return DeleteIncomeUseCase(ref.watch(incomeRepositoryProvider));
});

final updateIncomeUseCaseProvider = Provider<UpdateIncomeUseCase>((ref) {
  return UpdateIncomeUseCase(ref.watch(incomeRepositoryProvider));
});

final getIncomeTotalsUseCaseProvider = Provider<GetIncomeTotalsUseCase>((ref) {
  return GetIncomeTotalsUseCase(ref.watch(incomeRepositoryProvider));
});

final incomeListControllerProvider =
    AsyncNotifierProvider<IncomeListController, List<IncomeEntity>>(
      IncomeListController.new,
    );

final thisMonthIncomeProvider = FutureProvider<double>((ref) async {
  ref.watch(incomeRefreshTokenProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  final end = DateTime(now.year, now.month + 1, 1)
      .subtract(const Duration(milliseconds: 1));
  return ref.read(getIncomeTotalsUseCaseProvider).forRange(start, end);
});

final lastMonthIncomeProvider = FutureProvider<double>((ref) async {
  ref.watch(incomeRefreshTokenProvider);
  final now = DateTime.now();
  final start = now.month == 1
      ? DateTime(now.year - 1, 12, 1)
      : DateTime(now.year, now.month - 1, 1);
  final end = DateTime(now.year, now.month, 1)
      .subtract(const Duration(milliseconds: 1));
  return ref.read(getIncomeTotalsUseCaseProvider).forRange(start, end);
});

final incomeBySourceThisMonthProvider =
    FutureProvider<Map<String, double>>((ref) async {
  ref.watch(incomeRefreshTokenProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  final end = DateTime(now.year, now.month + 1, 1)
      .subtract(const Duration(milliseconds: 1));
  return ref.read(getIncomeTotalsUseCaseProvider).bySourceForRange(start, end);
});

final incomeMutationControllerProvider = Provider<IncomeMutationController>(
  (ref) => IncomeMutationController(ref),
);

class IncomeListController extends AsyncNotifier<List<IncomeEntity>> {
  @override
  Future<List<IncomeEntity>> build() async {
    ref.watch(incomeRefreshTokenProvider);
    return _load();
  }

  Future<List<IncomeEntity>> _load() async {
    return ref.read(getAllIncomeUseCaseProvider).call();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _load());
  }

  Future<String?> deleteIncome(IncomeEntity income) async {
    if (income.id == null) {
      return 'এই আয়টি মুছা যাচ্ছে না';
    }

    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(
        current.where((entry) => entry.id != income.id).toList(growable: false),
      );
    }

    final error = await ref
        .read(incomeMutationControllerProvider)
        .deleteIncome(income);

    state = AsyncData(await _load());
    return error;
  }
}

class IncomeMutationController {
  IncomeMutationController(this._ref);

  final Ref _ref;

  Future<String?> saveManualIncome(
    IncomeEntity income, {
    int? walletId,
  }) async {
    try {
      final resolvedWalletId = await _resolveWalletId(walletId);
      if (resolvedWalletId == null) {
        return 'কোনো ওয়ালেট পাওয়া যায়নি';
      }

      final normalized = income.copyWith(
        walletId: resolvedWalletId,
        isManual: true,
      );
      await _ref.read(saveIncomeUseCaseProvider).call(normalized);
      await _adjustWalletBalance(
        walletId: resolvedWalletId,
        delta: normalized.amount,
      );
      await _rememberActiveWallet(resolvedWalletId);
      await _notifyIncomeChanged();
      return null;
    } on Failure catch (failure) {
      return failure.message;
    } catch (error) {
      return '$error';
    }
  }

  Future<String?> saveDetectedIncome(
    IncomeEntity income, {
    int? walletId,
  }) async {
    try {
      final resolvedWalletId = await _resolveWalletId(walletId);
      if (resolvedWalletId == null) {
        return 'কোনো ওয়ালেট পাওয়া যায়নি';
      }

      final normalized = income.copyWith(
        walletId: resolvedWalletId,
        isManual: false,
      );
      await _ref.read(saveIncomeUseCaseProvider).call(normalized);
      await _adjustWalletBalance(
        walletId: resolvedWalletId,
        delta: normalized.amount,
      );
      await _rememberActiveWallet(resolvedWalletId);
      await _notifyIncomeChanged();
      return null;
    } on Failure catch (failure) {
      return failure.message;
    } catch (error) {
      return '$error';
    }
  }

  Future<String?> saveDetectedIncomeBatch(
    List<IncomeEntity> incomes, {
    int? walletId,
  }) async {
    try {
      final resolvedWalletId = await _resolveWalletId(walletId);
      if (resolvedWalletId == null) {
        return 'কোনো ওয়ালেট পাওয়া যায়নি';
      }

      final normalized = incomes
          .map(
            (entry) => entry.copyWith(
              walletId: resolvedWalletId,
              isManual: false,
            ),
          )
          .toList(growable: false);

      await _ref.read(saveIncomeUseCaseProvider).saveMany(normalized);
      for (final entry in normalized) {
        await _adjustWalletBalance(
          walletId: resolvedWalletId,
          delta: entry.amount,
        );
      }
      await _rememberActiveWallet(resolvedWalletId);
      await _notifyIncomeChanged();
      return null;
    } on Failure catch (failure) {
      return failure.message;
    } catch (error) {
      return '$error';
    }
  }

  Future<String?> deleteIncome(IncomeEntity income) async {
    if (income.id == null) {
      return 'এই আয়টি মুছা যাচ্ছে না';
    }

    try {
      final refundWalletId = income.walletId;
      final refundAmount = income.amount;
      await _ref.read(deleteIncomeUseCaseProvider).call(income.id!);
      if (refundWalletId != null) {
        await _adjustWalletBalance(
          walletId: refundWalletId,
          delta: -refundAmount,
        );
      }
      await _notifyIncomeChanged();
      return null;
    } on Failure catch (failure) {
      return failure.message;
    } catch (error) {
      return '$error';
    }
  }

  Future<String?> updateIncome(
    IncomeEntity newIncome,
    IncomeEntity oldIncome,
  ) async {
    if (newIncome.id == null) {
      return 'এই আয়টি আপডেট করা যাচ্ছে না';
    }

    try {
      await _ref.read(updateIncomeUseCaseProvider).call(newIncome);

      final oldWalletId = oldIncome.walletId;
      final newWalletId = newIncome.walletId;
      if (oldWalletId != null && newWalletId != null) {
        if (oldWalletId == newWalletId) {
          final delta = newIncome.amount - oldIncome.amount;
          if (delta != 0) {
            await _adjustWalletBalance(walletId: newWalletId, delta: delta);
          }
        } else {
          await _adjustWalletBalance(
            walletId: oldWalletId,
            delta: -oldIncome.amount,
          );
          await _adjustWalletBalance(
            walletId: newWalletId,
            delta: newIncome.amount,
          );
        }
      } else if (oldWalletId != null) {
        await _adjustWalletBalance(
          walletId: oldWalletId,
          delta: -oldIncome.amount,
        );
      } else if (newWalletId != null) {
        await _adjustWalletBalance(
          walletId: newWalletId,
          delta: newIncome.amount,
        );
      }

      await _notifyIncomeChanged();
      return null;
    } on Failure catch (failure) {
      return failure.message;
    } catch (error) {
      return '$error';
    }
  }

  Future<void> _notifyIncomeChanged() async {
    _ref.read(incomeRefreshTokenProvider.notifier).state++;
    _ref.invalidate(incomeListControllerProvider);
    _ref.invalidate(thisMonthIncomeProvider);
    _ref.invalidate(lastMonthIncomeProvider);
    _ref.invalidate(incomeBySourceThisMonthProvider);
  }

  Future<int?> _resolveWalletId(int? explicitWalletId) async {
    if (explicitWalletId != null) {
      return explicitWalletId;
    }

    final activeWallet = _ref.read(activeWalletProvider);
    if (activeWallet != null) {
      return activeWallet.id;
    }

    final savedWalletId = await AppPreferences.activeWalletId();
    final wallets = await _ref.read(walletProvider.future);
    if (wallets.isEmpty) {
      return null;
    }

    if (savedWalletId != null) {
      for (final wallet in wallets) {
        if (wallet.id == savedWalletId) {
          return wallet.id;
        }
      }
    }

    for (final wallet in wallets) {
      if (wallet.type == WalletType.cash) {
        return wallet.id;
      }
    }

    return wallets.first.id;
  }

  Future<void> _rememberActiveWallet(int walletId) async {
    _ref.read(activeWalletIdProvider.notifier).state = walletId;
    await AppPreferences.setActiveWalletId(walletId);
  }

  Future<void> _adjustWalletBalance({
    required int walletId,
    required double delta,
  }) async {
    try {
      await _ref
          .read(walletLocalDataSourceProvider)
          .adjustBalance(walletId, delta);
      _ref.invalidate(walletProvider);
    } catch (error, stackTrace) {
      debugPrint('Wallet balance sync failed: $error\n$stackTrace');
    }
  }
}
