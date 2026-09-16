// 5c oracle — goal DELETION refunds its deposits back to the source wallets via
// the ledger (the last money-path slice). Money conservation is the only real
// risk, so every case asserts EXACT wallet balances restored.
//
// Guardrails asserted here:
//   PER-WALLET REFUND: each source wallet gets back exactly the sum of ITS
//     deposits — refunded exactly once, never double (single-wallet common case;
//     multi-wallet happy path).
//   LEGACY SKIP: walletId==null savings (pre-fix, wallet never debited) are
//     deleted but NOT refunded — a mixed goal refunds only the new sum.
//   ACHIEVED path: an achieved goal deletes via the same path — refund applies
//     regardless of status.
//   ROLLUP: after deletion the goal + all its savings are gone (no orphans) and
//     goalSavingsProvider reflects it.

import 'dart:ffi';
import 'dart:io';

import 'package:flutter/services.dart';
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
import 'package:gemini_chat/features/goals/domain/entities/goal_entity.dart';
import 'package:gemini_chat/features/goals/presentation/providers/goal_provider.dart';
import 'package:gemini_chat/features/wallet/domain/entities/wallet_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Isar isar;
  late Directory tempDir;
  late ProviderContainer container;
  final now = DateTime.now();

  // Goal deletion cancels the goal's reminder; stub the notifications channel so
  // the RED here is about the refund, not a missing platform plugin.
  const notificationsChannel =
      MethodChannel('dexterous.com/flutter/local_notifications');

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notificationsChannel, (_) async => null);
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notificationsChannel, null);
  });

  setUp(() async {
    await Isar.initializeIsarCore(
      libraries: {
        Abi.current():
            '${Platform.environment['HOME']!}/.pub-cache/hosted/pub.dev/isar_community_flutter_libs-3.3.2/macos/libisar.dylib',
      },
    );
    tempDir = await Directory.systemTemp.createTemp('pocketpilot-ai-goaldel-');
    isar = await Isar.open(
      [
        WalletModelSchema,
        GoalModelSchema,
        GoalSavingModelSchema,
        ExpenseRecordModelSchema,
        IncomeRecordModelSchema,
      ],
      directory: tempDir.path,
      name: 'goal_deletion_refund_ledger_test',
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

  Future<int> seedWallet({required String name, double balance = 1000}) {
    final wallet = WalletModel()
      ..name = name
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

  // Seed a LEGACY saving directly: walletId stays null and NO wallet is debited
  // — exactly the pre-fix state. Bumps savedAmount to stay realistic.
  Future<void> seedLegacySaving(int goalId, double amount) async {
    final model = GoalSavingModel()
      ..goalId = goalId
      ..amount = amount
      ..date = now
      ..walletId = null;
    await isar.writeTxn(() async {
      await isar.goalSavingModels.put(model);
      final goal = await isar.goalModels.get(goalId);
      goal!.savedAmount += amount;
      await isar.goalModels.put(goal);
    });
  }

  // GoalNotifier loads goals into state via a microtask; wait for it so
  // addSaving/deleteGoal can find the goal.
  Future<void> loadGoals() async {
    container.read(goalProvider.notifier);
    for (var i = 0; i < 100; i++) {
      if (container.read(goalProvider).goals.isNotEmpty) return;
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  Future<double> walletBalance(int walletId) async =>
      (await isar.walletModels.get(walletId))!.currentBalance;

  test('single-wallet goal deletion refunds the deposit exactly once and '
      'removes the goal + its savings', () async {
    final w = await seedWallet(name: 'Cash', balance: 1000);
    final goalId = await seedGoal();
    await loadGoals();

    await container
        .read(goalProvider.notifier)
        .addSaving(goalId: goalId, amount: 300, walletId: w);
    expect(await walletBalance(w), 700); // debited by the deposit

    await container.read(goalProvider.notifier).deleteGoal(goalId);

    // Refund: wallet restored to exactly its pre-deposit balance, once.
    expect(await walletBalance(w), 1000);
    // Goal + savings gone (no orphans).
    expect(await isar.goalModels.get(goalId), isNull);
    expect(await isar.goalSavingModels.count(), 0);
    // Rollup provider reflects the deletion.
    final savings = await container.read(goalSavingsProvider(goalId).future);
    expect(savings, isEmpty);
  });

  test('multi-wallet goal deletion refunds each source wallet its own sum',
      () async {
    final w1 = await seedWallet(name: 'Cash', balance: 1000);
    final w2 = await seedWallet(name: 'Bank', balance: 500);
    final goalId = await seedGoal();
    await loadGoals();

    final notifier = container.read(goalProvider.notifier);
    await notifier.addSaving(goalId: goalId, amount: 200, walletId: w1);
    await notifier.addSaving(goalId: goalId, amount: 150, walletId: w2);
    await notifier.addSaving(goalId: goalId, amount: 50, walletId: w1);
    expect(await walletBalance(w1), 750); // 1000 - 200 - 50
    expect(await walletBalance(w2), 350); // 500 - 150

    await notifier.deleteGoal(goalId);

    // Each wallet gets back exactly ITS deposits — no cross-contamination.
    expect(await walletBalance(w1), 1000);
    expect(await walletBalance(w2), 500);
    expect(await isar.goalModels.get(goalId), isNull);
    expect(await isar.goalSavingModels.count(), 0);
  });

  test('mixed new+legacy goal deletion refunds only the new sum; legacy '
      'savings are deleted but not refunded', () async {
    final w = await seedWallet(name: 'Cash', balance: 1000);
    final goalId = await seedGoal();
    await loadGoals();

    // New (wallet-linked) deposit debits the wallet.
    await container
        .read(goalProvider.notifier)
        .addSaving(goalId: goalId, amount: 300, walletId: w);
    expect(await walletBalance(w), 700);
    // Legacy deposit: seeded directly, wallet NOT debited.
    await seedLegacySaving(goalId, 200);
    expect(await walletBalance(w), 700); // legacy never touched the wallet
    expect(await isar.goalSavingModels.count(), 2);

    await container.read(goalProvider.notifier).deleteGoal(goalId);

    // Only the new 300 comes back; the legacy 200 does NOT (wallet delta == new
    // sum only).
    expect(await walletBalance(w), 1000);
    // Both saving rows deleted; goal gone.
    expect(await isar.goalModels.get(goalId), isNull);
    expect(await isar.goalSavingModels.count(), 0);
  });

  test('achieved goal deletes via the same path and refunds', () async {
    final w = await seedWallet(name: 'Cash', balance: 1000);
    final goalId = await seedGoal(target: 300);
    await loadGoals();

    // Deposit meets the target -> goal becomes achieved.
    await container
        .read(goalProvider.notifier)
        .addSaving(goalId: goalId, amount: 300, walletId: w);
    expect(await walletBalance(w), 700);
    expect((await isar.goalModels.get(goalId))!.status, GoalStatus.achieved);

    await container.read(goalProvider.notifier).deleteGoal(goalId);

    // Refund applies regardless of status.
    expect(await walletBalance(w), 1000);
    expect(await isar.goalModels.get(goalId), isNull);
    expect(await isar.goalSavingModels.count(), 0);
  });
}
