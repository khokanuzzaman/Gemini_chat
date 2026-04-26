import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/preferences/app_preferences.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../wallet/domain/entities/wallet_entity.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../data/datasources/debt_local_datasource.dart';
import '../../data/repositories/debt_repository_impl.dart';
import '../../domain/entities/debt_entity.dart';
import '../../domain/entities/debt_payment_entity.dart';
import '../../domain/repositories/debt_repository.dart';
import '../../domain/usecases/add_debt_payment_usecase.dart';
import '../../domain/usecases/delete_debt_usecase.dart';
import '../../domain/usecases/get_all_debts_usecase.dart';
import '../../domain/usecases/get_debt_by_id_usecase.dart';
import '../../domain/usecases/get_debt_payments_usecase.dart';
import '../../domain/usecases/record_installment_paid_usecase.dart';
import '../../domain/usecases/save_debt_usecase.dart';
import '../../domain/usecases/settle_debt_usecase.dart';
import '../../domain/usecases/update_debt_usecase.dart';
import '../../domain/utils/emi_calculator.dart';
import '../models/mutation_result.dart';

final debtRefreshTokenProvider = StateProvider<int>((ref) => 0);

final debtLocalDataSourceProvider = Provider<DebtLocalDataSource>((ref) {
  return DebtLocalDataSource(ref.watch(isarProvider));
});

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  return DebtRepositoryImpl(
    localDataSource: ref.watch(debtLocalDataSourceProvider),
  );
});

final getAllDebtsUseCaseProvider = Provider<GetAllDebtsUseCase>((ref) {
  return GetAllDebtsUseCase(ref.watch(debtRepositoryProvider));
});

final getDebtByIdUseCaseProvider = Provider<GetDebtByIdUseCase>((ref) {
  return GetDebtByIdUseCase(ref.watch(debtRepositoryProvider));
});

final saveDebtUseCaseProvider = Provider<SaveDebtUseCase>((ref) {
  return SaveDebtUseCase(ref.watch(debtRepositoryProvider));
});

final updateDebtUseCaseProvider = Provider<UpdateDebtUseCase>((ref) {
  return UpdateDebtUseCase(ref.watch(debtRepositoryProvider));
});

final deleteDebtUseCaseProvider = Provider<DeleteDebtUseCase>((ref) {
  return DeleteDebtUseCase(ref.watch(debtRepositoryProvider));
});

final addDebtPaymentUseCaseProvider = Provider<AddDebtPaymentUseCase>((ref) {
  return AddDebtPaymentUseCase(ref.watch(debtRepositoryProvider));
});

final getDebtPaymentsUseCaseProvider = Provider<GetDebtPaymentsUseCase>((ref) {
  return GetDebtPaymentsUseCase(ref.watch(debtRepositoryProvider));
});

final recordInstallmentPaidUseCaseProvider =
    Provider<RecordInstallmentPaidUseCase>((ref) {
      return RecordInstallmentPaidUseCase(ref.watch(debtRepositoryProvider));
    });

final settleDebtUseCaseProvider = Provider<SettleDebtUseCase>((ref) {
  return SettleDebtUseCase(ref.watch(debtRepositoryProvider));
});

final debtMutationControllerProvider = Provider<DebtMutationController>((ref) {
  return DebtMutationController(ref);
});

enum DebtFilterType {
  all,
  iOwe,
  theyOwe,
  active,
  settled,
  overdue,
  emiOnly,
  regularOnly,
}

DebtStatus resolveDebtStatus(DebtEntity debt) {
  return debt.isOverdue ? DebtStatus.overdue : debt.status;
}

bool isOpenDebtStatus(DebtStatus status) {
  return status == DebtStatus.active || status == DebtStatus.overdue;
}

List<DebtEntity> sortDebtsForDisplay(Iterable<DebtEntity> debts) {
  final sorted = debts.toList();
  sorted.sort((first, second) {
    final rankDiff = _displayRank(first) - _displayRank(second);
    if (rankDiff != 0) {
      return rankDiff;
    }

    final firstDueDate = first.effectiveDueDate;
    final secondDueDate = second.effectiveDueDate;
    if (firstDueDate != null && secondDueDate != null) {
      final dueDiff = firstDueDate.compareTo(secondDueDate);
      if (dueDiff != 0) {
        return dueDiff;
      }
    } else if (firstDueDate != null) {
      return -1;
    } else if (secondDueDate != null) {
      return 1;
    }

    if (resolveDebtStatus(first) == DebtStatus.settled) {
      final firstSettledAt = first.settledAt;
      final secondSettledAt = second.settledAt;
      if (firstSettledAt != null && secondSettledAt != null) {
        final settledDiff = secondSettledAt.compareTo(firstSettledAt);
        if (settledDiff != 0) {
          return settledDiff;
        }
      }
    }

    return second.createdAt.compareTo(first.createdAt);
  });
  return sorted;
}

int _displayRank(DebtEntity debt) {
  final status = resolveDebtStatus(debt);
  if (status == DebtStatus.overdue) {
    return 0;
  }
  if (status == DebtStatus.active && debt.isEMI) {
    return 1;
  }
  if (status == DebtStatus.active) {
    return 2;
  }
  if (status == DebtStatus.settled) {
    return 3;
  }
  return 4;
}

class DebtListState {
  const DebtListState({required this.debts, required this.filter});

  final List<DebtEntity> debts;
  final DebtFilterType filter;

  List<DebtEntity> get activeDebts => sortDebtsForDisplay(
    debts.where((debt) => isOpenDebtStatus(resolveDebtStatus(debt))),
  );

  List<DebtEntity> get settledDebts => sortDebtsForDisplay(
    debts.where((debt) => resolveDebtStatus(debt) == DebtStatus.settled),
  );

  List<DebtEntity> get emiDebts =>
      sortDebtsForDisplay(debts.where((debt) => debt.isEMI));

  List<DebtEntity> get regularDebts =>
      sortDebtsForDisplay(debts.where((debt) => !debt.isEMI));

  double get totalOwedToMe => activeDebts
      .where((debt) => debt.type == DebtType.theyOwe)
      .fold<double>(0, (sum, debt) => sum + debt.remainingAmount);

  double get totalIOwe => activeDebts
      .where((debt) => debt.type == DebtType.iOwe)
      .fold<double>(0, (sum, debt) => sum + debt.remainingAmount);

  double get netPosition => totalOwedToMe - totalIOwe;

  int get overdueCount => debts
      .where((debt) => resolveDebtStatus(debt) == DebtStatus.overdue)
      .length;

  List<DebtEntity> get upcomingInstallmentsThisWeek {
    final today = _stripTime(DateTime.now());
    final end = today.add(const Duration(days: 7));
    return sortDebtsForDisplay(
      debts.where(
        (debt) =>
            debt.isEMI &&
            resolveDebtStatus(debt) == DebtStatus.active &&
            debt.nextInstallmentDate != null &&
            !_stripTime(debt.nextInstallmentDate!).isBefore(today) &&
            !_stripTime(debt.nextInstallmentDate!).isAfter(end),
      ),
    );
  }

  List<DebtEntity> get filteredDebts {
    final source = sortDebtsForDisplay(debts);
    return switch (filter) {
      DebtFilterType.all => source,
      DebtFilterType.iOwe =>
        source
            .where((debt) => debt.type == DebtType.iOwe)
            .toList(growable: false),
      DebtFilterType.theyOwe =>
        source
            .where((debt) => debt.type == DebtType.theyOwe)
            .toList(growable: false),
      DebtFilterType.active =>
        source
            .where((debt) => resolveDebtStatus(debt) == DebtStatus.active)
            .toList(growable: false),
      DebtFilterType.settled =>
        source
            .where((debt) => resolveDebtStatus(debt) == DebtStatus.settled)
            .toList(growable: false),
      DebtFilterType.overdue =>
        source
            .where((debt) => resolveDebtStatus(debt) == DebtStatus.overdue)
            .toList(growable: false),
      DebtFilterType.emiOnly =>
        source.where((debt) => debt.isEMI).toList(growable: false),
      DebtFilterType.regularOnly =>
        source.where((debt) => !debt.isEMI).toList(growable: false),
    };
  }

  DebtListState copyWith({List<DebtEntity>? debts, DebtFilterType? filter}) {
    return DebtListState(
      debts: debts ?? this.debts,
      filter: filter ?? this.filter,
    );
  }
}

final debtListProvider = AsyncNotifierProvider<DebtListNotifier, DebtListState>(
  DebtListNotifier.new,
);

class DebtListNotifier extends AsyncNotifier<DebtListState> {
  DebtFilterType _filter = DebtFilterType.all;

  @override
  Future<DebtListState> build() async {
    ref.watch(debtRefreshTokenProvider);
    await ref.read(debtRepositoryProvider).updateOverdueStatuses();
    return _loadState();
  }

  void setFilter(DebtFilterType filter) {
    _filter = filter;
    final currentState = state.valueOrNull;
    if (currentState == null) {
      return;
    }
    state = AsyncData(currentState.copyWith(filter: filter));
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    await ref.read(debtRepositoryProvider).updateOverdueStatuses();
    state = await AsyncValue.guard(_loadState);
  }

  Future<DebtListState> _loadState() async {
    final debts = await ref.read(getAllDebtsUseCaseProvider).call();
    return DebtListState(debts: sortDebtsForDisplay(debts), filter: _filter);
  }
}

class DebtDetailData {
  const DebtDetailData({required this.debt, required this.payments});

  final DebtEntity debt;
  final List<DebtPaymentEntity> payments;
}

final debtDetailProvider = FutureProvider.family<DebtDetailData, int>((
  ref,
  debtId,
) async {
  ref.watch(debtRefreshTokenProvider);
  final debt = await ref.read(getDebtByIdUseCaseProvider).call(debtId);
  if (debt == null) {
    throw const StorageFailure('ধার-দেনার রেকর্ডটি খুঁজে পাওয়া যায়নি');
  }
  final payments = await ref.read(getDebtPaymentsUseCaseProvider).call(debtId);
  return DebtDetailData(debt: debt, payments: payments);
});

class DebtSummaryData {
  const DebtSummaryData({
    required this.totalOwedToMe,
    required this.totalIOwe,
    required this.netPosition,
    required this.activeCount,
    required this.overdueCount,
    required this.upcomingEMICount,
    required this.upcomingEMITotal,
  });

  final double totalOwedToMe;
  final double totalIOwe;
  final double netPosition;
  final int activeCount;
  final int overdueCount;
  final int upcomingEMICount;
  final double upcomingEMITotal;

  bool get hasActiveDebts => activeCount > 0;
  bool get hasUpcomingEMI => upcomingEMICount > 0;
}

final debtSummaryProvider = Provider<DebtSummaryData>((ref) {
  final debtState = ref.watch(debtListProvider).valueOrNull;
  if (debtState == null) {
    return const DebtSummaryData(
      totalOwedToMe: 0,
      totalIOwe: 0,
      netPosition: 0,
      activeCount: 0,
      overdueCount: 0,
      upcomingEMICount: 0,
      upcomingEMITotal: 0,
    );
  }

  final upcomingInstallments = debtState.upcomingInstallmentsThisWeek;
  return DebtSummaryData(
    totalOwedToMe: debtState.totalOwedToMe,
    totalIOwe: debtState.totalIOwe,
    netPosition: debtState.netPosition,
    activeCount: debtState.activeDebts.length,
    overdueCount: debtState.overdueCount,
    upcomingEMICount: upcomingInstallments.length,
    upcomingEMITotal: upcomingInstallments.fold<double>(
      0,
      (sum, debt) => sum + debt.nextInstallmentAmount,
    ),
  );
});

class DebtMutationController {
  const DebtMutationController(this._ref);

  final Ref _ref;

  Future<MutationResult> saveDebt(DebtEntity debt, {int? walletId}) async {
    if (debt.id > 0) {
      return updateDebt(debt);
    }

    final validationError = _validateDebt(debt);
    if (validationError != null) {
      return MutationResult.failure(validationError);
    }

    try {
      final warnings = <String>[];

      final resolvedWalletId =
          walletId ?? debt.walletId ?? await _resolveWalletId();
      final preparedDebt = _prepareNewDebt(
        debt: debt,
        resolvedWalletId: resolvedWalletId,
      );

      final savedDebt = await _ref
          .read(saveDebtUseCaseProvider)
          .call(preparedDebt);

      await _runWalletSideEffect(
        walletId: savedDebt.walletId,
        delta: _originalWalletDelta(savedDebt.type, savedDebt.originalAmount),
        warnings: warnings,
      );
      await _syncDebtReminder(savedDebt, warnings);

      _notifyDebtChanged();
      return MutationResult.success(
        'ধার-দেনা সংরক্ষণ হয়েছে',
        warnings: warnings,
      );
    } on Failure catch (failure) {
      return MutationResult.failure(failure.message);
    } catch (error) {
      return MutationResult.failure('$error');
    }
  }

  Future<MutationResult> updateDebt(DebtEntity debt) async {
    if (debt.id <= 0) {
      return MutationResult.failure(
        'এই ধার-দেনার রেকর্ডটি আপডেট করা যাচ্ছে না',
      );
    }

    final validationError = _validateDebt(debt);
    if (validationError != null) {
      return MutationResult.failure(validationError);
    }

    try {
      final warnings = <String>[];
      final existingDebt = await _ref
          .read(getDebtByIdUseCaseProvider)
          .call(debt.id);
      if (existingDebt == null) {
        return MutationResult.failure('ধার-দেনার রেকর্ডটি খুঁজে পাওয়া যায়নি');
      }

      final payments = await _ref
          .read(getDebtPaymentsUseCaseProvider)
          .call(debt.id);
      final resolvedWalletId =
          debt.walletId ?? existingDebt.walletId ?? await _resolveWalletId();
      final preparedDebt = _prepareExistingDebt(
        debt: debt,
        existingDebt: existingDebt,
        payments: payments,
        resolvedWalletId: resolvedWalletId,
      );

      await _ref.read(updateDebtUseCaseProvider).call(preparedDebt);
      final refreshedDebt = await _loadDebt(debt.id);
      if (refreshedDebt != null) {
        await _syncDebtReminder(refreshedDebt, warnings);
      }

      _notifyDebtChanged();
      return MutationResult.success(
        'ধার-দেনার তথ্য আপডেট হয়েছে',
        warnings: warnings,
      );
    } on Failure catch (failure) {
      return MutationResult.failure(failure.message);
    } catch (error) {
      return MutationResult.failure('$error');
    }
  }

  Future<MutationResult> deleteDebt(int id) async {
    final debt = await _ref.read(getDebtByIdUseCaseProvider).call(id);
    if (debt == null) {
      return MutationResult.failure('ধার-দেনার রেকর্ডটি খুঁজে পাওয়া যায়নি');
    }

    try {
      final warnings = <String>[];

      await _ref.read(deleteDebtUseCaseProvider).call(id);

      if (debt.walletId != null && isOpenDebtStatus(resolveDebtStatus(debt))) {
        await _runWalletSideEffect(
          walletId: debt.walletId,
          delta: -_originalWalletDelta(debt.type, debt.originalAmount),
          warnings: warnings,
        );
      }
      await _cancelDebtReminder(id, warnings);

      _notifyDebtChanged();
      return MutationResult.success(
        'ধার-দেনার রেকর্ডটি মুছে গেছে',
        warnings: warnings,
      );
    } on Failure catch (failure) {
      return MutationResult.failure(failure.message);
    } catch (error) {
      return MutationResult.failure('$error');
    }
  }

  Future<MutationResult> addPayment(
    int debtId,
    double amount, {
    int? walletId,
    String? note,
  }) async {
    final debt = await _ref.read(getDebtByIdUseCaseProvider).call(debtId);
    if (debt == null) {
      return MutationResult.failure('ধার-দেনার রেকর্ডটি খুঁজে পাওয়া যায়নি');
    }

    final currentStatus = resolveDebtStatus(debt);
    if (currentStatus == DebtStatus.settled ||
        currentStatus == DebtStatus.cancelled) {
      return MutationResult.failure('এই রেকর্ডে আর পরিশোধ যোগ করা যাবে না');
    }
    if (amount <= 0) {
      return MutationResult.failure('সঠিক পরিশোধের পরিমাণ দিন');
    }
    if (amount > debt.remainingAmount) {
      return MutationResult.failure(
        'পরিশোধের পরিমাণ বাকি টাকার চেয়ে বেশি হতে পারবে না',
      );
    }

    final resolvedWalletId =
        walletId ?? debt.walletId ?? await _resolveWalletId();

    try {
      final warnings = <String>[];
      await _ref
          .read(addDebtPaymentUseCaseProvider)
          .call(
            debtId: debtId,
            amount: amount,
            walletId: resolvedWalletId,
            note: _normalizeText(note),
          );

      await _runWalletSideEffect(
        walletId: resolvedWalletId,
        delta: _paymentWalletDelta(debt.type, amount),
        warnings: warnings,
      );

      final refreshedDebt = await _loadDebt(debtId);
      if (refreshedDebt != null) {
        await _syncDebtReminder(refreshedDebt, warnings);
      }

      _notifyDebtChanged();
      return MutationResult.success('পরিশোধ যোগ হয়েছে', warnings: warnings);
    } on Failure catch (failure) {
      return MutationResult.failure(failure.message);
    } catch (error) {
      return MutationResult.failure('$error');
    }
  }

  Future<MutationResult> recordInstallmentPaid(
    int debtId, {
    int? walletId,
  }) async {
    final debt = await _ref.read(getDebtByIdUseCaseProvider).call(debtId);
    if (debt == null) {
      return MutationResult.failure('ধার-দেনার রেকর্ডটি খুঁজে পাওয়া যায়নি');
    }
    if (!debt.isEMI) {
      return MutationResult.failure('এই রেকর্ডটি কিস্তির নয়');
    }

    final currentStatus = resolveDebtStatus(debt);
    if (currentStatus == DebtStatus.settled ||
        currentStatus == DebtStatus.cancelled) {
      return MutationResult.failure('এই কিস্তিতে আর পরিশোধ যোগ করা যাবে না');
    }
    if (debt.totalInstallments > 0 &&
        debt.paidInstallments >= debt.totalInstallments) {
      return MutationResult.failure('সব কিস্তি ইতিমধ্যে পরিশোধিত');
    }

    final resolvedWalletId =
        walletId ?? debt.walletId ?? await _resolveWalletId();
    final installmentAmount = debt.nextInstallmentAmount;

    try {
      final warnings = <String>[];
      await _ref
          .read(recordInstallmentPaidUseCaseProvider)
          .call(debtId, walletId: resolvedWalletId);

      await _runWalletSideEffect(
        walletId: resolvedWalletId,
        delta: _paymentWalletDelta(debt.type, installmentAmount),
        warnings: warnings,
      );

      final refreshedDebt = await _loadDebt(debtId);
      if (refreshedDebt != null) {
        await _syncDebtReminder(refreshedDebt, warnings);
      }

      _notifyDebtChanged();
      return MutationResult.success('কিস্তি পরিশোধ হয়েছে', warnings: warnings);
    } on Failure catch (failure) {
      return MutationResult.failure(failure.message);
    } catch (error) {
      return MutationResult.failure('$error');
    }
  }

  Future<MutationResult> settleDebt(int debtId) async {
    final debt = await _ref.read(getDebtByIdUseCaseProvider).call(debtId);
    if (debt == null) {
      return MutationResult.failure('ধার-দেনার রেকর্ডটি খুঁজে পাওয়া যায়নি');
    }

    if (resolveDebtStatus(debt) == DebtStatus.settled || debt.isFullyPaid) {
      return MutationResult.success('এই ধার-দেনা আগেই পরিশোধিত');
    }

    try {
      final warnings = <String>[];
      await _ref.read(settleDebtUseCaseProvider).call(debtId);
      await _cancelDebtReminder(debtId, warnings);
      _notifyDebtChanged();
      return MutationResult.success(
        'ধার-দেনা সম্পূর্ণ পরিশোধিত',
        warnings: warnings,
      );
    } on Failure catch (failure) {
      return MutationResult.failure(failure.message);
    } catch (error) {
      return MutationResult.failure('$error');
    }
  }

  String? _validateDebt(DebtEntity debt) {
    if (debt.personName.trim().isEmpty) {
      return debt.isEMI
          ? 'প্রতিষ্ঠান বা ব্যক্তির নাম দিন'
          : 'কার সাথে ধার-দেনা হয়েছে, নাম দিন';
    }
    if (debt.originalAmount <= 0) {
      return 'সঠিক টাকার পরিমাণ দিন';
    }
    if (debt.remainingAmount < 0) {
      return 'বাকি টাকার পরিমাণ সঠিক নয়';
    }
    if (debt.isEMI) {
      if (debt.totalInstallments <= 0) {
        return 'কত মাসে কিস্তি হবে, সেটি দিন';
      }
      if (debt.installmentDayOfMonth == null) {
        return 'মাসের কোন তারিখে কিস্তি হবে, সেটি দিন';
      }
      if (debt.installmentDayOfMonth! < 1 || debt.installmentDayOfMonth! > 31) {
        return 'কিস্তির তারিখ ১ থেকে ৩১ এর মধ্যে হতে হবে';
      }
      if (debt.annualInterestRate < 0) {
        return 'সুদের হার ঋণাত্মক হতে পারবে না';
      }
    }
    return null;
  }

  DebtEntity _prepareNewDebt({
    required DebtEntity debt,
    required int? resolvedWalletId,
  }) {
    final normalizedDebt = debt.copyWith(
      personName: debt.personName.trim(),
      walletId: resolvedWalletId,
      createdAt: debt.createdAt,
    );

    if (!normalizedDebt.isEMI) {
      return normalizedDebt.copyWith(
        remainingAmount: normalizedDebt.originalAmount,
        paidInstallments: 0,
        totalInstallments: 0,
        annualInterestRate: 0,
        emiAmount: 0,
        nextInstallmentDate: null,
        installmentDayOfMonth: null,
      );
    }

    final emiAmount = _resolveEmiAmount(normalizedDebt);
    final nextInstallmentDate = _resolveInitialInstallmentDate(normalizedDebt);
    return normalizedDebt.copyWith(
      personPhone: null,
      dueDate: null,
      emiAmount: emiAmount,
      paidInstallments: 0,
      remainingAmount: emiAmount * normalizedDebt.totalInstallments,
      nextInstallmentDate: nextInstallmentDate,
    );
  }

  DebtEntity _prepareExistingDebt({
    required DebtEntity debt,
    required DebtEntity existingDebt,
    required List<DebtPaymentEntity> payments,
    required int? resolvedWalletId,
  }) {
    final totalPaid = payments.fold<double>(
      0,
      (sum, payment) => sum + payment.amount,
    );
    final installmentCount = payments
        .where((payment) => payment.isInstallment)
        .length;
    final normalizedDebt = debt.copyWith(
      personName: debt.personName.trim(),
      walletId: resolvedWalletId,
      createdAt: existingDebt.createdAt,
    );

    if (!normalizedDebt.isEMI) {
      return normalizedDebt.copyWith(
        remainingAmount: math.max(0, normalizedDebt.originalAmount - totalPaid),
        paidInstallments: 0,
        totalInstallments: 0,
        annualInterestRate: 0,
        emiAmount: 0,
        nextInstallmentDate: null,
        installmentDayOfMonth: null,
      );
    }

    final emiAmount = _resolveEmiAmount(normalizedDebt);
    final totalPayable = emiAmount * normalizedDebt.totalInstallments;
    final paidInstallments = math.min(
      normalizedDebt.totalInstallments,
      installmentCount,
    );
    final remainingAmount = math.max(0, totalPayable - totalPaid).toDouble();
    final nextInstallmentDate =
        remainingAmount <= 0 ||
            paidInstallments >= normalizedDebt.totalInstallments
        ? null
        : _resolveUpdatedInstallmentDate(
            updatedDebt: normalizedDebt,
            existingDebt: existingDebt,
          );

    return normalizedDebt.copyWith(
      personPhone: null,
      dueDate: null,
      emiAmount: emiAmount,
      paidInstallments: paidInstallments,
      remainingAmount: remainingAmount,
      nextInstallmentDate: nextInstallmentDate,
    );
  }

  double _resolveEmiAmount(DebtEntity debt) {
    if (debt.emiAmount > 0) {
      return debt.emiAmount;
    }
    return EmiCalculator.calculateEMI(
      principal: debt.originalAmount,
      annualRate: debt.annualInterestRate,
      months: debt.totalInstallments,
    );
  }

  DateTime? _resolveInitialInstallmentDate(DebtEntity debt) {
    final day = debt.installmentDayOfMonth;
    if (!debt.isEMI || day == null) {
      return null;
    }
    return _nextInstallmentFromReference(DateTime.now(), day);
  }

  DateTime? _resolveUpdatedInstallmentDate({
    required DebtEntity updatedDebt,
    required DebtEntity existingDebt,
  }) {
    final day = updatedDebt.installmentDayOfMonth;
    if (!updatedDebt.isEMI || day == null) {
      return null;
    }

    if (existingDebt.isEMI && existingDebt.nextInstallmentDate != null) {
      final existingDate = existingDebt.nextInstallmentDate!;
      if (existingDebt.installmentDayOfMonth == day) {
        return existingDate;
      }
      return _safeInstallmentDate(existingDate.year, existingDate.month, day);
    }

    return _nextInstallmentFromReference(DateTime.now(), day);
  }

  String? _normalizeText(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<int?> _resolveWalletId() async {
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

  double _originalWalletDelta(DebtType type, double amount) {
    return type == DebtType.iOwe ? amount : -amount;
  }

  double _paymentWalletDelta(DebtType type, double amount) {
    return type == DebtType.theyOwe ? amount : -amount;
  }

  Future<void> _runWalletSideEffect({
    required int? walletId,
    required double delta,
    required List<String> warnings,
  }) async {
    if (walletId == null || delta == 0) {
      return;
    }

    try {
      await _ref
          .read(walletLocalDataSourceProvider)
          .adjustBalance(walletId, delta);
      _ref.invalidate(walletProvider);
    } catch (error, stackTrace) {
      debugPrint('Debt wallet side effect failed: $error\n$stackTrace');
      warnings.add('ওয়ালেটের ব্যালেন্স ঠিকভাবে সমন্বয় করা যায়নি');
    }
  }

  Future<void> _syncDebtReminder(DebtEntity debt, List<String> warnings) async {
    try {
      if (!debt.reminderEnabled ||
          resolveDebtStatus(debt) == DebtStatus.settled ||
          resolveDebtStatus(debt) == DebtStatus.cancelled) {
        await NotificationService.cancelDebtReminder(_debtReminderId(debt.id));
        return;
      }

      final dueDate = debt.effectiveDueDate;
      if (dueDate == null) {
        await NotificationService.cancelDebtReminder(_debtReminderId(debt.id));
        return;
      }

      final today = _stripTime(DateTime.now());
      if (_stripTime(dueDate).isBefore(today)) {
        await NotificationService.cancelDebtReminder(_debtReminderId(debt.id));
        return;
      }

      final scheduledFor = _stripTime(
        dueDate,
      ).subtract(const Duration(days: 1));
      final title = debt.isEMI ? 'কিস্তি আগামীকাল' : 'পরিশোধের সময় হয়েছে';
      final body = debt.isEMI
          ? '${debt.personName} এর ${BanglaFormatters.currency(debt.nextInstallmentAmount)} কিস্তি আগামীকাল ${BanglaFormatters.count(debt.installmentDayOfMonth ?? dueDate.day)} তারিখে'
          : '${debt.personName} এর ${BanglaFormatters.currency(debt.remainingAmount)} আগামীকাল পরিশোধ করতে হবে';

      await NotificationService.scheduleDebtReminder(
        notificationId: _debtReminderId(debt.id),
        title: title,
        body: body,
        scheduledFor: scheduledFor,
        payload: 'debt:${debt.id}',
      );
    } catch (error, stackTrace) {
      debugPrint('Debt reminder side effect failed: $error\n$stackTrace');
      warnings.add('রিমাইন্ডার ঠিকভাবে সেট করা যায়নি');
    }
  }

  Future<void> _cancelDebtReminder(int debtId, List<String> warnings) async {
    try {
      await NotificationService.cancelDebtReminder(_debtReminderId(debtId));
    } catch (error, stackTrace) {
      debugPrint('Debt reminder cancel failed: $error\n$stackTrace');
      warnings.add('রিমাইন্ডার বন্ধ করা যায়নি');
    }
  }

  Future<DebtEntity?> _loadDebt(int debtId) {
    return _ref.read(getDebtByIdUseCaseProvider).call(debtId);
  }

  void _notifyDebtChanged() {
    _ref.read(debtRefreshTokenProvider.notifier).state++;
  }
}

DateTime _stripTime(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime _nextInstallmentFromReference(DateTime referenceDate, int dayOfMonth) {
  final today = _stripTime(referenceDate);
  var candidate = _safeInstallmentDate(today.year, today.month, dayOfMonth);
  if (candidate.isBefore(today)) {
    candidate = _safeInstallmentDate(today.year, today.month + 1, dayOfMonth);
  }
  return candidate;
}

DateTime _safeInstallmentDate(int year, int month, int dayOfMonth) {
  final normalizedYear = year + ((month - 1) ~/ 12);
  final normalizedMonth = ((month - 1) % 12 + 12) % 12 + 1;
  final maxDay = DateTime(normalizedYear, normalizedMonth + 1, 0).day;
  final safeDay = dayOfMonth.clamp(1, maxDay);
  return DateTime(normalizedYear, normalizedMonth, safeDay);
}

int _debtReminderId(int debtId) => 100000 + debtId;
