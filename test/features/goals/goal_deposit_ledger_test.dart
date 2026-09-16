// 5b oracle — goal deposit via the ledger (DESYNC-2 fix). Explicit about which
// assertions PIN old behavior vs assert NEW behavior:
//   NEW: after a deposit the wallet DROPS by exactly the amount (today addSaving
//        doesn't touch the wallet — this is the fix).
//   PIN: goal.savedAmount still increments; expense/spending totals UNCHANGED
//        (a deposit isn't consumption).
//   NEW: CashFlowData.savings reflects the deposit; wallet_change = netFlow − savings.

import 'dart:ffi';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gemini_chat/core/database/models/expense_record_model.dart';
import 'package:gemini_chat/core/database/models/goal_model.dart';
import 'package:gemini_chat/core/database/models/goal_saving_model.dart';
import 'package:gemini_chat/core/database/models/income_record_model.dart';
import 'package:gemini_chat/core/database/models/wallet_model.dart';
import 'package:gemini_chat/core/providers/database_providers.dart';
import 'package:gemini_chat/core/providers/shared_preferences_provider.dart';
import 'package:gemini_chat/features/expense/presentation/providers/expense_providers.dart';
import 'package:gemini_chat/features/goals/domain/entities/goal_entity.dart';
import 'package:gemini_chat/features/goals/presentation/providers/goal_provider.dart';
import 'package:gemini_chat/features/wallet/domain/entities/wallet_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Isar isar;
  late Directory tempDir;
  late ProviderContainer container;
  final now = DateTime.now();

  setUp(() async {
    await Isar.initializeIsarCore(
      libraries: {
        Abi.current():
            '${Platform.environment['HOME']!}/.pub-cache/hosted/pub.dev/isar_community_flutter_libs-3.3.2/macos/libisar.dylib',
      },
    );
    tempDir = await Directory.systemTemp.createTemp('pocketpilot-ai-goaldep-');
    isar = await Isar.open(
      [
        WalletModelSchema,
        GoalModelSchema,
        GoalSavingModelSchema,
        ExpenseRecordModelSchema,
        IncomeRecordModelSchema,
      ],
      directory: tempDir.path,
      name: 'goal_deposit_ledger_test',
    );
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        isarProvider.overrideWithValue(isar),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await isar.close(deleteFromDisk: true);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<int> seedWallet({double balance = 1000}) {
    final wallet = WalletModel()
      ..name = 'Cash'
      ..type = WalletType.cash
      ..emoji = '💵'
      ..initialBalance = balance
      ..currentBalance = balance
      ..sortOrder = 0
      ..createdAt = now
      ..updatedAt = now;
    return isar.writeTxn(() => isar.walletModels.put(wallet));
  }

  Future<int> seedGoal({double target = 5000}) {
    final goal = GoalModel()
      ..title = 'Laptop'
      ..emoji = '💻'
      ..targetAmount = target
      ..savedAmount = 0
      ..targetDate = DateTime(2026, 12, 1)
      ..createdAt = now
      ..status = GoalStatus.active;
    return isar.writeTxn(() => isar.goalModels.put(goal));
  }

  // GoalNotifier loads goals into state via a microtask; wait for it so
  // addSaving can find the goal.
  Future<void> loadGoals() async {
    container.read(goalProvider.notifier);
    for (var i = 0; i < 100; i++) {
      if (container.read(goalProvider).goals.isNotEmpty) return;
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  Future<double> walletBalance(int walletId) async =>
      (await isar.walletModels.get(walletId))!.currentBalance;

  Future<double> savedAmount(int goalId) async =>
      (await isar.goalModels.get(goalId))!.savedAmount;

  test('deposit debits the wallet once, bumps savedAmount, writes a wallet-linked '
      'GoalSaving, and NO expense record', () async {
    final w = await seedWallet(balance: 1000);
    final goalId = await seedGoal();
    await loadGoals();

    final err = await container
        .read(goalProvider.notifier)
        .addSaving(goalId: goalId, amount: 300);
    expect(err, isNull);

    // NEW: wallet dropped by exactly 300 (the DESYNC-2 fix), once.
    expect(await walletBalance(w), 700);
    // PIN: savedAmount incremented.
    expect(await savedAmount(goalId), 300);
    // Saving carries its source wallet (so 5c can refund it).
    final savings = await isar.goalSavingModels.where().findAll();
    expect(savings, hasLength(1));
    expect(savings.single.walletId, w);
    expect(savings.single.amount, 300);
    // PIN: a deposit is a transfer — no expense record.
    expect(await isar.expenseRecordModels.count(), 0);
  });

  test('deposit is excluded from spending, appears in cash flow as savings, and '
      'wallet_change = netFlow - savings', () async {
    final w = await seedWallet(balance: 1000);
    final goalId = await seedGoal();
    await loadGoals();

    final dashBefore = await container.read(getDashboardDataUseCaseProvider).call();
    final cashBefore = await container.read(cashFlowProvider.future);
    final walletBefore = await walletBalance(w);

    await container.read(goalProvider.notifier).addSaving(goalId: goalId, amount: 300);

    container.invalidate(cashFlowProvider);
    final dashAfter = await container.read(getDashboardDataUseCaseProvider).call();
    final cashAfter = await container.read(cashFlowProvider.future);
    final walletAfter = await walletBalance(w);

    // Excluded from spending: dashboard total + cash-flow expense unchanged.
    expect(dashAfter.thisMonthTotal, dashBefore.thisMonthTotal);
    expect(cashAfter.expense, cashBefore.expense);
    // Appears in cash flow as savings.
    expect(cashAfter.savings - cashBefore.savings, 300);
    // Wallet dropped by the deposit.
    expect(walletAfter, walletBefore - 300);
    // The identity: wallet_change == netFlow_change - savings_change.
    final walletChange = walletAfter - walletBefore;
    final netFlowChange = cashAfter.netFlow - cashBefore.netFlow;
    final savingsChange = cashAfter.savings - cashBefore.savings;
    expect(walletChange, netFlowChange - savingsChange);
  });

  test('deposit with no resolvable wallet hard-fails atomically (nothing persists)', () async {
    // No wallet seeded -> _resolveWalletId returns null.
    final goalId = await seedGoal();
    await loadGoals();

    final err = await container
        .read(goalProvider.notifier)
        .addSaving(goalId: goalId, amount: 300);

    expect(err, isNotNull); // hard failure
    expect(await isar.goalSavingModels.count(), 0); // no saving
    expect(await savedAmount(goalId), 0); // savedAmount not bumped
  });
}
