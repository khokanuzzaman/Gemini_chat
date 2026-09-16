// NEW-behavior oracle for task 4c — the numbers-changing slice. Proves the
// DESYNC-1 fix (iOwe debt payments become spending), the exclusions (anomaly,
// theyOwe), the correctness invariants (wallet moves exactly once, no
// double-deduct), and forward-only / legacy safety on delete.

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
import 'package:gemini_chat/features/anomaly/data/services/anomaly_detection_service.dart';
import 'package:gemini_chat/features/debt/data/datasources/debt_local_datasource.dart';
import 'package:gemini_chat/features/debt/data/models/debt_model.dart';
import 'package:gemini_chat/features/debt/data/models/debt_payment_model.dart';
import 'package:gemini_chat/features/debt/domain/entities/debt_entity.dart';
import 'package:gemini_chat/features/debt/presentation/providers/debt_providers.dart';
import 'package:gemini_chat/features/expense/domain/entities/expense_entity.dart';
import 'package:gemini_chat/features/expense/domain/entities/expense_source.dart';
import 'package:gemini_chat/features/expense/presentation/providers/expense_providers.dart';
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
    tempDir = await Directory.systemTemp.createTemp('pocketpilot-ai-debt4c-');
    isar = await Isar.open(
      [
        WalletModelSchema,
        DebtModelSchema,
        DebtPaymentModelSchema,
        ExpenseRecordModelSchema,
        IncomeRecordModelSchema,
      ],
      directory: tempDir.path,
      name: 'debt_ledger_new_behavior_test',
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

  // Seeds a debt directly (bypassing the provider's create path so its own
  // wallet effect doesn't muddy the payment assertions).
  Future<int> seedDebt({
    required int walletId,
    required DebtType type,
    String personName = 'Rahim',
    double original = 1000,
    double remaining = 1000,
  }) async {
    final debt = DebtModel()
      ..personName = personName
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

  DebtMutationController mutations() =>
      container.read(debtMutationControllerProvider);

  Future<double> walletBalance(int walletId) async =>
      (await isar.walletModels.get(walletId))!.currentBalance;

  test('iOwe payment: one payment, one linked EMI record, wallet debited once, '
      'and this month\'s spending total goes up by the payment amount', () async {
    final w = await seedWallet(balance: 1000);
    final debtId = await seedDebt(
      walletId: w,
      type: DebtType.iOwe,
      personName: 'Rahim',
    );

    final result = await mutations().addPayment(debtId, 300);
    expect(result.isSuccess, isTrue);

    // Points 1 + 2: exactly one payment; wallet moved exactly once by 300
    // (not 600 — no double-deduct).
    expect(await isar.debtPaymentModels.count(), 1);
    expect(await walletBalance(w), 700);

    // Point 4: the linked record's shape.
    final payment = (await isar.debtPaymentModels.where().findAll()).single;
    final expenses = await isar.expenseRecordModels.where().findAll();
    expect(expenses, hasLength(1));
    final expense = expenses.single;
    expect(expense.sourceType, ExpenseSource.debtPayment);
    expect(expense.category, 'EMI');
    expect(expense.sourceId, payment.id);
    expect(expense.description, 'Rahim'); // debt name
    expect(expense.amount, 300);

    // Point 3 (the user-visible fix): dashboard this-month spending includes it.
    final dashboard = await container.read(getDashboardDataUseCaseProvider).call();
    expect(dashboard.thisMonthTotal, 300);
    expect(dashboard.categoryTotals['EMI'], 300);
  });

  test('untitled debt: linked record description falls back to EMI', () async {
    final w = await seedWallet(balance: 1000);
    final debtId = await seedDebt(walletId: w, type: DebtType.iOwe, personName: '');

    await mutations().addPayment(debtId, 200);

    final expense = (await isar.expenseRecordModels.where().findAll()).single;
    expect(expense.description, 'EMI');
  });

  test('theyOwe receipt: NO expense record, NO income record, wallet up once', () async {
    final w = await seedWallet(balance: 1000);
    final debtId = await seedDebt(walletId: w, type: DebtType.theyOwe);

    final result = await mutations().addPayment(debtId, 300);
    expect(result.isSuccess, isTrue);

    expect(await walletBalance(w), 1300); // +300, once
    expect(await isar.debtPaymentModels.count(), 1);
    expect(await isar.expenseRecordModels.count(), 0); // not spending
    expect(await isar.incomeRecordModels.count(), 0); // not income either
  });

  test('anomaly detection EXCLUDES debtPayment rows', () async {
    // A big EMI that WOULD spike if it were treated as ordinary spending.
    final emi = ExpenseEntity(
      amount: 5000,
      category: 'EMI',
      description: 'Rahim',
      date: now,
      sourceType: ExpenseSource.debtPayment,
    );
    final food = ExpenseEntity(
      amount: 100,
      category: 'Food',
      description: 'lunch',
      date: now,
      sourceType: ExpenseSource.expense,
    );

    final alerts = const AnomalyDetectionService().detect(
      last30Days: [emi, food],
      previous90Days: const [],
    );

    // The debt payment never surfaces as an anomaly.
    expect(alerts.where((a) => a.category == 'EMI'), isEmpty);
  });

  test('delete payment: removes both rows, reverses wallet once, rolls back debt', () async {
    final w = await seedWallet(balance: 1000);
    final debtId = await seedDebt(walletId: w, type: DebtType.iOwe, remaining: 1000);
    await mutations().addPayment(debtId, 300);
    final paymentId = (await isar.debtPaymentModels.where().findAll()).single.id;

    final result = await mutations().deletePayment(paymentId);
    expect(result.isSuccess, isTrue);

    expect(await walletBalance(w), 1000); // refunded once
    expect(await isar.debtPaymentModels.count(), 0);
    expect(await isar.expenseRecordModels.count(), 0); // linked expense gone
    expect((await isar.debtModels.get(debtId))!.remainingAmount, 1000); // rollback
  });

  test('legacy payment (no linked expense) deletes cleanly', () async {
    final w = await seedWallet(balance: 700); // as if 300 already paid
    final debtId = await seedDebt(
      walletId: w,
      type: DebtType.iOwe,
      original: 1000,
      remaining: 700,
    );
    // A payment written before the linked-record feature existed: no expense.
    final paymentId = await isar.writeTxn(
      () => isar.debtPaymentModels.put(
        DebtPaymentModel()
          ..debtId = debtId
          ..amount = 300
          ..walletId = w
          ..paidAt = DateTime(2026, 1, 1),
      ),
    );

    final result = await mutations().deletePayment(paymentId);
    expect(result.isSuccess, isTrue); // no failure despite absent expense

    expect(await walletBalance(w), 1000); // 700 + 300 reversed
    expect(await isar.debtPaymentModels.count(), 0);
    expect((await isar.debtModels.get(debtId))!.remainingAmount, 1000);
  });

  test('creation is wallet-only: moves the principal, writes NO expense record', () async {
    final w = await seedWallet(balance: 1000);

    final result = await mutations().saveDebt(
      DebtEntity(
        id: 0,
        personName: 'Karim',
        type: DebtType.iOwe,
        originalAmount: 500,
        remainingAmount: 500,
        status: DebtStatus.active,
        createdAt: now,
        walletId: w,
      ),
    );
    expect(result.isSuccess, isTrue);

    expect(await walletBalance(w), 1500); // +500 principal (iOwe borrow)
    expect(await isar.debtModels.count(), 1);
    expect(await isar.expenseRecordModels.count(), 0); // creation is a transfer
  });
}
