// INVARIANT oracle for the debt ledger migration (task 4). Unlike 3b/3c, task 4
// CHANGES user-visible numbers (a linked expense record appears in spending).
// This file pins only what must NOT change across the migration: a payment moves
// the wallet exactly once, the debt outstanding math is correct, the DebtPayment
// row is written, and the debt-position summary reflects it. It must be GREEN on
// the CURRENT (unmigrated) code and stay green after 4c. (The NEW behavior — the
// linked debtPayment expense record — is asserted by a separate 4c oracle.)

import 'dart:ffi';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gemini_chat/core/database/models/expense_record_model.dart';
import 'package:gemini_chat/core/database/models/wallet_model.dart';
import 'package:gemini_chat/core/providers/database_providers.dart';
import 'package:gemini_chat/core/providers/shared_preferences_provider.dart';
import 'package:gemini_chat/features/debt/data/datasources/debt_local_datasource.dart';
import 'package:gemini_chat/features/debt/data/models/debt_model.dart';
import 'package:gemini_chat/features/debt/data/models/debt_payment_model.dart';
import 'package:gemini_chat/features/debt/domain/entities/debt_entity.dart';
import 'package:gemini_chat/features/debt/presentation/providers/debt_providers.dart';
import 'package:gemini_chat/features/wallet/domain/entities/wallet_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Isar isar;
  late Directory tempDir;
  late ProviderContainer container;

  setUp(() async {
    await Isar.initializeIsarCore(
      libraries: {
        Abi.current():
            '${Platform.environment['HOME']!}/.pub-cache/hosted/pub.dev/isar_community_flutter_libs-3.3.2/macos/libisar.dylib',
      },
    );
    tempDir = await Directory.systemTemp.createTemp('pocketpilot-ai-debt-oracle-');
    isar = await Isar.open(
      // ExpenseRecordModelSchema: iOwe payments now write a linked expense record.
      [
        WalletModelSchema,
        DebtModelSchema,
        DebtPaymentModelSchema,
        ExpenseRecordModelSchema,
      ],
      directory: tempDir.path,
      name: 'debt_ledger_oracle_test',
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
      ..createdAt = DateTime(2026, 1, 1)
      ..updatedAt = DateTime(2026, 1, 1);
    return isar.writeTxn(() => isar.walletModels.put(wallet));
  }

  // Seeds a debt directly (bypassing the provider's create path so its own
  // wallet effect doesn't muddy the payment assertion).
  Future<int> seedDebt({
    required int walletId,
    required DebtType type,
    double original = 1000,
    double remaining = 1000,
  }) async {
    final debt = DebtModel()
      ..personName = 'Rahim'
      ..type = type
      ..originalAmount = original
      ..remainingAmount = remaining
      ..status = DebtStatus.active
      ..createdAt = DateTime(2026, 7, 1)
      ..walletId = walletId
      ..reminderEnabled = false;
    final saved = await DebtLocalDataSource(isar).saveDebt(debt);
    return saved.id;
  }

  Future<double> walletBalance(int walletId) async =>
      (await isar.walletModels.get(walletId))!.currentBalance;

  Future<double> outstanding(int debtId) async =>
      (await isar.debtModels.get(debtId))!.remainingAmount;

  test('iOwe payment: wallet debited once, outstanding + position reflect it', () async {
    final w = await seedWallet(balance: 1000);
    final debtId = await seedDebt(walletId: w, type: DebtType.iOwe, remaining: 1000);

    final result = await container
        .read(debtMutationControllerProvider)
        .addPayment(debtId, 300);

    expect(result.isSuccess, isTrue);
    expect(await walletBalance(w), 700); // 1000 - 300, exactly once
    expect(await isar.debtPaymentModels.count(), 1);
    expect(await outstanding(debtId), 700); // 1000 - 300

    // Debt-position summary (reads DebtModel outstanding, not expenses).
    await container.read(debtListProvider.future);
    expect(container.read(debtSummaryProvider).totalIOwe, 700);
  });

  test('theyOwe receipt: wallet credited once, outstanding reflects it', () async {
    final w = await seedWallet(balance: 1000);
    final debtId =
        await seedDebt(walletId: w, type: DebtType.theyOwe, remaining: 1000);

    final result = await container
        .read(debtMutationControllerProvider)
        .addPayment(debtId, 300);

    expect(result.isSuccess, isTrue);
    expect(await walletBalance(w), 1300); // +300 (they repaid you), once
    expect(await isar.debtPaymentModels.count(), 1);
    expect(await outstanding(debtId), 700);
    await container.read(debtListProvider.future);
    expect(container.read(debtSummaryProvider).totalOwedToMe, 700);
  });
}
