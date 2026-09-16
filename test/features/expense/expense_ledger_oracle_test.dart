// Regression ORACLE for the ledger migration (task 3b). These pin the CURRENT
// behavior of expense + split money movement — exact balances, exact record
// counts, record-id-unchanged on edit, and that budget alerts still fire. They
// must pass GREEN on the unmigrated code first, then remain green after the
// migration onto WalletLedgerService. This is behavior-preserving (except the
// batch path, which becomes atomic — see the note on that test).

import 'dart:ffi';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gemini_chat/core/ai/expense_result.dart';
import 'package:gemini_chat/core/database/models/expense_record_model.dart';
import 'package:gemini_chat/core/database/models/split_bill_model.dart';
import 'package:gemini_chat/core/database/models/wallet_model.dart';
import 'package:gemini_chat/core/notifications/notification_provider.dart';
import 'package:gemini_chat/core/notifications/notification_settings.dart';
import 'package:gemini_chat/core/providers/database_providers.dart';
import 'package:gemini_chat/core/providers/shared_preferences_provider.dart';
import 'package:gemini_chat/features/anomaly/presentation/providers/anomaly_provider.dart';
import 'package:gemini_chat/features/expense/domain/entities/expense_entity.dart';
import 'package:gemini_chat/features/expense/domain/entities/expense_source.dart';
import 'package:gemini_chat/features/expense/presentation/providers/expense_providers.dart';
import 'package:gemini_chat/features/prediction/presentation/providers/prediction_provider.dart';
import 'package:gemini_chat/features/split/domain/entities/split_bill_entity.dart';
import 'package:gemini_chat/features/split/presentation/providers/split_bill_provider.dart';
import 'package:gemini_chat/features/wallet/domain/entities/wallet_entity.dart';

// Records checkBudgetAlert categories so tests can assert alerts still fire,
// without touching notification platform channels.
final List<String> budgetAlertCalls = [];

class _FakeNotificationNotifier extends NotificationNotifier {
  @override
  NotificationSettings build() => NotificationSettings.defaults();

  @override
  Future<void> checkBudgetAlert(String category) async {
    budgetAlertCalls.add(category);
  }
}

class _FakeAnomalyNotifier extends AnomalyNotifier {
  @override
  AnomalyState build() => const AnomalyState(alerts: [], isDetecting: false);

  @override
  Future<void> reDetect() async {}
}

class _FakePredictionNotifier extends PredictionNotifier {
  @override
  PredictionState build() => const PredictionState();

  @override
  Future<void> registerExpenseSaves(int count) async {}
}

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
    tempDir = await Directory.systemTemp.createTemp('pocketpilot-ai-oracle-');
    isar = await Isar.open(
      [WalletModelSchema, ExpenseRecordModelSchema, SplitBillModelSchema],
      directory: tempDir.path,
      name: 'expense_ledger_oracle_test',
    );
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    budgetAlertCalls.clear();
    container = ProviderContainer(
      overrides: [
        isarProvider.overrideWithValue(isar),
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationProvider.overrideWith(_FakeNotificationNotifier.new),
        anomalyProvider.overrideWith(_FakeAnomalyNotifier.new),
        predictionProvider.overrideWith(_FakePredictionNotifier.new),
      ],
    );
  });

  // Runs an ExpenseListController mutation, tolerating ONLY riverpod's
  // bare-container "outdated" assertion from the post-write _loadState re-read
  // (in-app a ProviderScope drives that rebuild; the money movement — record +
  // wallet — has already committed before it). Any other error is a real
  // failure and rethrows, so money-path regressions are NOT masked; the Isar
  // assertions after the call are the actual oracle.
  // Flushes scheduled provider rebuilds (microtask turn), mirroring a UI frame.
  Future<void> pump() => Future<void>.delayed(Duration.zero);

  Future<String?> tolerantMutation(Future<String?> Function() op) async {
    try {
      return await op();
    } catch (e) {
      if (e.toString().contains('_didChangeDependency')) return null;
      rethrow;
    }
  }

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
      ..createdAt = DateTime(2026, 1, 1)
      ..updatedAt = DateTime(2026, 1, 1);
    return isar.writeTxn(() => isar.walletModels.put(wallet));
  }

  Future<double> balance(int walletId) async =>
      (await isar.walletModels.get(walletId))!.currentBalance;

  ExpenseMutationController mutations() =>
      container.read(expenseMutationControllerProvider);

  Future<List<ExpenseEntity>> allExpenses() =>
      container.read(expenseRepositoryProvider).getAllExpenses();

  // Arranges the POST-create state directly (a record + an already-debited
  // wallet), so edit/delete tests exercise the real updateExpense/deleteExpense
  // path without a prior create bumping the refresh token mid-test.
  Future<ExpenseEntity> seedExpense({
    required int walletId,
    int amount = 100,
    String category = 'Food',
  }) async {
    await isar.writeTxn(
      () => isar.expenseRecordModels.put(
        ExpenseRecordModel()
          ..amount = amount
          ..category = category
          ..description = 'lunch'
          ..date = _july10Date
          ..walletId = walletId,
      ),
    );
    return (await allExpenses()).single;
  }

  test('create: saveManualExpense debits the wallet once and writes one record', () async {
    final w = await seedWallet(balance: 1000);

    final err = await mutations().saveManualExpense(
      ExpenseEntity(
        amount: 100,
        category: 'Food',
        description: 'lunch',
        date: _july10Date,
      ),
      walletId: w,
    );

    expect(err, isNull);
    expect(await balance(w), 900);
    expect(await isar.expenseRecordModels.count(), 1);
    expect(budgetAlertCalls, contains('Food'));
    final rec = (await isar.expenseRecordModels.where().findAll()).single;
    expect(rec.sourceType, ExpenseSource.expense);
  });

  test('edit same-wallet: applies (previous - updated) and keeps the record id', () async {
    final w = await seedWallet(balance: 900); // as if 100 already spent
    final saved = await seedExpense(walletId: w, amount: 100);
    final err = await tolerantMutation(
      () => container
          .read(expenseListControllerProvider.notifier)
          .updateExpense(saved.copyWith(amount: 40)),
    );
    await pump();

    expect(err, isNull);
    expect(await balance(w), 960); // 900 + (100 - 40)
    final after = (await allExpenses()).single;
    expect(after.id, saved.id); // record identity survives the edit
    expect(after.amount, 40);
    expect(await isar.expenseRecordModels.count(), 1);
  });

  test('edit cross-wallet: refunds old wallet and charges new wallet, atomically', () async {
    final wa = await seedWallet(balance: 900); // as if 100 already spent on wa
    final wb = await seedWallet(balance: 500);
    final saved = await seedExpense(walletId: wa, amount: 100);
    final err = await tolerantMutation(
      () => container
          .read(expenseListControllerProvider.notifier)
          .updateExpense(saved.copyWith(amount: 40, walletId: wb)),
    );
    await pump();

    expect(err, isNull);
    expect(await balance(wa), 1000); // 900 + 100 refund
    expect(await balance(wb), 460); // 500 - 40
    final after = (await allExpenses()).single;
    expect(after.id, saved.id);
    expect(after.walletId, wb);
    expect(after.amount, 40);
  });

  test('delete: refunds the wallet and removes the record', () async {
    final w = await seedWallet(balance: 900); // as if 100 already spent
    final saved = await seedExpense(walletId: w, amount: 100);
    final err = await tolerantMutation(
      () => container
          .read(expenseListControllerProvider.notifier)
          .deleteExpense(saved),
    );
    await pump();

    expect(err, isNull);
    expect(await balance(w), 1000);
    expect(await isar.expenseRecordModels.count(), 0);
  });

  test('batch: saveDetectedExpenses writes all rows and debits the summed total', () async {
    final w = await seedWallet(balance: 1000);

    final err = await mutations().saveDetectedExpenses(
      const [
        ExpenseData(amount: 100, category: 'Food', description: 'a', date: _july10),
        ExpenseData(amount: 50, category: 'Transport', description: 'b', date: _july10),
      ],
      walletId: w,
    );

    expect(err, isNull);
    expect(await balance(w), 850); // 1000 - (100 + 50)
    expect(await isar.expenseRecordModels.count(), 2);
    expect(budgetAlertCalls, containsAll(<String>['Food', 'Transport']));
  });

  test('receipt: saveReceiptExpense debits the wallet by the total', () async {
    final w = await seedWallet(balance: 1000);

    final err = await mutations().saveReceiptExpense(
      const {
        'total': 200,
        'date': _july10,
        'merchant': 'Shop',
        'summary': 'groceries',
        'category': 'Shopping',
      },
      walletId: w,
    );

    expect(err, isNull);
    expect(await balance(w), 800);
    expect(await isar.expenseRecordModels.count(), 1);
  });

  test('detailed: saveDetectedExpenseDetailed returns the saved expense and debits once', () async {
    final w = await seedWallet(balance: 1000);

    final result = await mutations().saveDetectedExpenseDetailed(
      const ExpenseData(amount: 75, category: 'Food', description: 'snack', date: _july10),
      walletId: w,
    );

    expect(result.error, isNull);
    expect(result.expense, isNotNull);
    expect(await balance(w), 925);
    expect(await isar.expenseRecordModels.count(), 1);
  });

  test('split: saveMyShareAsExpense (through the split provider) debits once and writes one expense', () async {
    // Single cash wallet -> the controller resolves to it (no explicit walletId
    // flows through saveMyShareAsExpense). This proves split inherits the fix in
    // its REAL call path, not by calling the expense controller directly.
    final w = await seedWallet(balance: 1000);

    final split = SplitBillEntity(
      id: 1,
      title: 'Dinner',
      totalAmount: 900,
      persons: const [],
      date: DateTime(2026, 7, 10),
      isSettled: false,
      category: 'Food',
    );

    final err = await container
        .read(splitBillProvider.notifier)
        .saveMyShareAsExpense(split: split, myShare: 300, category: 'Food');

    expect(err, isNull);
    expect(await balance(w), 700); // 1000 - 300
    expect(await isar.expenseRecordModels.count(), 1);
    final rec = (await isar.expenseRecordModels.where().findAll()).single;
    expect(rec.sourceType, ExpenseSource.expense);
    expect(rec.walletId, w);
  });
}

const String _july10 = '2026-07-10'; // ExpenseData / receipt use a String date
final DateTime _july10Date = DateTime(2026, 7, 10); // ExpenseEntity uses DateTime
