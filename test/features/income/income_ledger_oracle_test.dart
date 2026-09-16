// Regression ORACLE for the income ledger migration (task 3c). Income writes an
// IncomeRecordModel + wallet only (NO expense record), sign opposite to expense
// (+amount on create). Each test asserts BOTH the income total via the existing
// read path (thisMonthIncomeProvider) AND the wallet balance — proving the
// aggregation still sees the migrated writes. Must be GREEN on the unmigrated
// code first, then remain green after the migration.

import 'dart:ffi';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gemini_chat/core/database/models/expense_record_model.dart';
import 'package:gemini_chat/core/database/models/income_record_model.dart';
import 'package:gemini_chat/core/database/models/wallet_model.dart';
import 'package:gemini_chat/core/providers/database_providers.dart';
import 'package:gemini_chat/core/providers/shared_preferences_provider.dart';
import 'package:gemini_chat/features/income/domain/entities/income_entity.dart';
import 'package:gemini_chat/features/income/presentation/providers/income_providers.dart';
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
    tempDir = await Directory.systemTemp.createTemp('pocketpilot-ai-income-');
    isar = await Isar.open(
      [WalletModelSchema, IncomeRecordModelSchema, ExpenseRecordModelSchema],
      directory: tempDir.path,
      name: 'income_ledger_oracle_test',
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

  Future<int> seedWallet({double balance = 1000, WalletType type = WalletType.cash}) {
    final wallet = WalletModel()
      ..name = 'W'
      ..type = type
      ..emoji = '💵'
      ..initialBalance = balance
      ..currentBalance = balance
      ..sortOrder = 0
      ..createdAt = now
      ..updatedAt = now;
    return isar.writeTxn(() => isar.walletModels.put(wallet));
  }

  // Arranges the POST-create state directly (an income row + a wallet already
  // credited), so edit/delete tests exercise the real update/deleteIncome path.
  Future<IncomeEntity> seedIncome({required int walletId, int amount = 500}) async {
    await isar.writeTxn(
      () => isar.incomeRecordModels.put(
        IncomeRecordModel()
          ..amount = amount
          ..source = 'Salary'
          ..description = 'বেতন'
          ..walletId = walletId
          ..date = now
          ..createdAt = now,
      ),
    );
    return (await container.read(incomeRepositoryProvider).getAllIncome()).single;
  }

  IncomeMutationController mutations() =>
      container.read(incomeMutationControllerProvider);

  Future<double> balance(int walletId) async =>
      (await isar.walletModels.get(walletId))!.currentBalance;

  // The existing read path — proves the aggregation sees the migrated writes.
  Future<double> thisMonthIncome() =>
      container.read(thisMonthIncomeProvider.future);

  IncomeEntity income({double amount = 500}) => IncomeEntity(
        amount: amount,
        source: 'Salary',
        description: 'বেতন',
        date: now,
        createdAt: now,
      );

  test('create: saveManualIncome credits the wallet once and writes one income record (no expense record)', () async {
    final w = await seedWallet(balance: 1000);

    final err = await mutations().saveManualIncome(income(amount: 500), walletId: w);

    expect(err, isNull);
    expect(await balance(w), 1500); // +500
    expect(await isar.incomeRecordModels.count(), 1);
    expect(await isar.expenseRecordModels.count(), 0); // income has no expense record
    expect(await thisMonthIncome(), 500); // read path sees it
  });

  test('edit same-wallet: applies (new - old) and keeps the income record id', () async {
    final w = await seedWallet(balance: 1500); // as if 500 already credited
    final saved = await seedIncome(walletId: w, amount: 500);

    final err = await mutations().updateIncome(saved.copyWith(amount: 300), saved);

    expect(err, isNull);
    expect(await balance(w), 1300); // 1500 + (300 - 500)
    final after = (await container.read(incomeRepositoryProvider).getAllIncome()).single;
    expect(after.id, saved.id); // record identity survives
    expect(after.amount, 300);
    expect(await thisMonthIncome(), 300);
  });

  test('edit cross-wallet: debits old wallet and credits new wallet', () async {
    final wa = await seedWallet(balance: 1500); // as if 500 credited on wa
    final wb = await seedWallet(balance: 500);
    final saved = await seedIncome(walletId: wa, amount: 500);

    final err = await mutations()
        .updateIncome(saved.copyWith(amount: 300, walletId: wb), saved);

    expect(err, isNull);
    expect(await balance(wa), 1000); // 1500 - 500 (old income removed)
    expect(await balance(wb), 800); // 500 + 300 (new income)
    final after = (await container.read(incomeRepositoryProvider).getAllIncome()).single;
    expect(after.walletId, wb);
    expect(after.amount, 300);
    expect(await thisMonthIncome(), 300);
  });

  test('delete: debits the wallet and removes the income record', () async {
    final w = await seedWallet(balance: 1500);
    final saved = await seedIncome(walletId: w, amount: 500);

    final err = await mutations().deleteIncome(saved);

    expect(err, isNull);
    expect(await balance(w), 1000); // -500
    expect(await isar.incomeRecordModels.count(), 0);
    expect(await thisMonthIncome(), 0);
  });

  test('batch: saveDetectedIncomeBatch writes all rows and credits the summed total', () async {
    final w = await seedWallet(balance: 1000);

    final err = await mutations().saveDetectedIncomeBatch(
      [income(amount: 500), income(amount: 300)],
      walletId: w,
    );

    expect(err, isNull);
    expect(await balance(w), 1800); // +800
    expect(await isar.incomeRecordModels.count(), 2);
    expect(await thisMonthIncome(), 800);
  });

  test('detailed: saveDetectedIncomeDetailed returns the saved income and credits once', () async {
    final w = await seedWallet(balance: 1000);

    final result =
        await mutations().saveDetectedIncomeDetailed(income(amount: 250), walletId: w);

    expect(result.error, isNull);
    expect(result.income, isNotNull);
    expect(await balance(w), 1250);
    expect(await thisMonthIncome(), 250);
  });
}
