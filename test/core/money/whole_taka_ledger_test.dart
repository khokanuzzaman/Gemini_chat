// The record/wallet invariant: for EVERY money path, with fractional input, the
// wallet moves by exactly the signed sum of the integer record amounts. Records
// store ints (`amount.round()`); the ledger applies a double — so each controller
// must round ONCE and give both the same number.
import 'dart:ffi';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gemini_chat/core/ai/expense_result.dart';
import 'package:gemini_chat/core/database/models/expense_record_model.dart';
import 'package:gemini_chat/core/database/models/income_record_model.dart';
import 'package:gemini_chat/core/database/models/split_bill_model.dart';
import 'package:gemini_chat/core/database/models/wallet_model.dart';
import 'package:gemini_chat/core/notifications/notification_provider.dart';
import 'package:gemini_chat/core/notifications/notification_settings.dart';
import 'package:gemini_chat/core/providers/database_providers.dart';
import 'package:gemini_chat/core/providers/shared_preferences_provider.dart';
import 'package:gemini_chat/features/anomaly/presentation/providers/anomaly_provider.dart';
import 'package:gemini_chat/features/debt/data/datasources/debt_local_datasource.dart';
import 'package:gemini_chat/features/debt/data/models/debt_model.dart';
import 'package:gemini_chat/features/debt/data/models/debt_payment_model.dart';
import 'package:gemini_chat/features/debt/domain/entities/debt_entity.dart';
import 'package:gemini_chat/features/debt/presentation/providers/debt_providers.dart';
import 'package:gemini_chat/features/expense/domain/entities/expense_entity.dart';
import 'package:gemini_chat/features/expense/domain/entities/expense_source.dart';
import 'package:gemini_chat/features/expense/presentation/providers/expense_providers.dart';
import 'package:gemini_chat/features/income/domain/entities/income_entity.dart';
import 'package:gemini_chat/features/income/presentation/providers/income_providers.dart';
import 'package:gemini_chat/features/prediction/presentation/providers/prediction_provider.dart';
import 'package:gemini_chat/features/wallet/domain/entities/wallet_entity.dart';

class _Notifications extends NotificationNotifier {
  @override
  NotificationSettings build() => NotificationSettings.defaults();
  @override
  Future<void> checkBudgetAlert(String category) async {}
}

class _Anomaly extends AnomalyNotifier {
  @override
  AnomalyState build() => const AnomalyState(alerts: [], isDetecting: false);
  @override
  Future<void> reDetect() async {}
}

class _Prediction extends PredictionNotifier {
  @override
  PredictionState build() => const PredictionState();
  @override
  Future<void> registerExpenseSaves(int count) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Isar isar;
  late Directory dir;
  late ProviderContainer container;

  setUp(() async {
    await Isar.initializeIsarCore(
      libraries: {
        Abi.current():
            '${Platform.environment['HOME']!}/.pub-cache/hosted/pub.dev/isar_community_flutter_libs-3.3.2/macos/libisar.dylib',
      },
    );
    dir = await Directory.systemTemp.createTemp('pocketpilot-wholetaka-');
    isar = await Isar.open(
      [
        WalletModelSchema,
        ExpenseRecordModelSchema,
        IncomeRecordModelSchema,
        SplitBillModelSchema,
        DebtModelSchema,
        DebtPaymentModelSchema,
      ],
      directory: dir.path,
      name: 'whole_taka_${DateTime.now().microsecondsSinceEpoch}',
    );
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer(
      overrides: [
        isarProvider.overrideWithValue(isar),
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
        notificationProvider.overrideWith(_Notifications.new),
        anomalyProvider.overrideWith(_Anomaly.new),
        predictionProvider.overrideWith(_Prediction.new),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await isar.close(deleteFromDisk: true);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  });

  final date = DateTime(2026, 7, 10);

  Future<int> seedWallet({double balance = 1000}) => isar.writeTxn(
    () => isar.walletModels.put(
      WalletModel()
        ..name = 'W'
        ..type = WalletType.cash
        ..emoji = 'x'
        ..initialBalance = balance
        ..currentBalance = balance
        ..sortOrder = 0
        ..createdAt = DateTime(2026, 1, 1)
        ..updatedAt = DateTime(2026, 1, 1),
    ),
  );

  Future<double> balance(int id) async =>
      (await isar.walletModels.get(id))!.currentBalance;
  Future<int> expenseSum() async =>
      (await isar.expenseRecordModels.where().findAll()).fold<int>(
        0,
        (s, e) => s + e.amount,
      );
  Future<int> incomeSum() async =>
      (await isar.incomeRecordModels.where().findAll()).fold<int>(
        0,
        (s, e) => s + e.amount,
      );

  /// THE invariant, for a wallet that started at [start].
  Future<void> expectAgrees(int wallet, double start) async {
    final expected = start - await expenseSum() + await incomeSum();
    expect(
      await balance(wallet),
      expected,
      reason: 'wallet must equal start − Σexpense + Σincome (records are ints)',
    );
  }

  ExpenseMutationController expenses() =>
      container.read(expenseMutationControllerProvider);
  IncomeMutationController incomes() =>
      container.read(incomeMutationControllerProvider);

  // The post-write re-read in a bare ProviderContainer can trip riverpod's
  // "_didChangeDependency" assertion; the money movement has already committed.
  Future<String?> tolerant(Future<String?> Function() op) async {
    try {
      return await op();
    } catch (e) {
      if ('$e'.contains('_didChangeDependency')) return null;
      rethrow;
    }
  }

  group('expense paths', () {
    test('manual: 120.50 -> record 121, wallet −121', () async {
      final w = await seedWallet();
      expect(
        await expenses().saveManualExpense(
          ExpenseEntity(
            amount: 120.5,
            category: 'Food',
            description: 'a',
            date: date,
          ),
          walletId: w,
        ),
        isNull,
      );
      expect(await expenseSum(), 121);
      expect(await balance(w), 879);
      await expectAgrees(w, 1000);
    });

    test(
      'an amount that rounds to ৳0 is rejected and writes nothing',
      () async {
        final w = await seedWallet();
        final err = await expenses().saveManualExpense(
          ExpenseEntity(
            amount: 0.4,
            category: 'Food',
            description: 'x',
            date: date,
          ),
          walletId: w,
        );
        expect(err, isNotNull);
        expect(await isar.expenseRecordModels.count(), 0);
        expect(await balance(w), 1000);
      },
    );

    test('detected (SMS-style) single: 1250.40 -> 1250 both sides', () async {
      final w = await seedWallet(balance: 5000);
      final r = await expenses().saveDetectedExpenseDetailed(
        const ExpenseData(
          amount: 1250.4,
          category: 'Food',
          description: 'bKash',
          date: '2026-07-11',
        ),
        walletId: w,
      );
      expect(r.isSuccess, isTrue);
      expect(await expenseSum(), 1250);
      await expectAgrees(w, 5000);
    });

    test(
      'dedupe: a re-saved fractional expense is recognised as a duplicate',
      () async {
        final w = await seedWallet(balance: 5000);
        const item = ExpenseData(
          amount: 1250.4,
          category: 'Food',
          description: 'bKash',
          date: '2026-07-11',
        );
        expect(
          (await expenses().saveDetectedExpenseDetailed(
            item,
            walletId: w,
          )).isSuccess,
          isTrue,
        );

        final again = await expenses().saveDetectedExpenseDetailed(
          item,
          walletId: w,
        );
        expect(again.isSuccess, isFalse);
        expect(again.error, contains('একই খরচ'));
        expect(await isar.expenseRecordModels.count(), 1);
        await expectAgrees(w, 5000);
      },
    );

    test(
      'batch: each item rounded BEFORE summing; batch delta == Σ records',
      () async {
        final w = await seedWallet(balance: 5000);
        await expenses().saveDetectedExpenses(const [
          ExpenseData(
            amount: 1250.4,
            category: 'Food',
            description: 'b1',
            date: '2026-07-11',
          ),
          ExpenseData(
            amount: 99.6,
            category: 'Food',
            description: 'b2',
            date: '2026-07-11',
          ),
          ExpenseData(
            amount: 300.5,
            category: 'Food',
            description: 'b3',
            date: '2026-07-11',
          ),
          ExpenseData(
            amount: 0.3,
            category: 'Food',
            description: 'dust',
            date: '2026-07-11',
          ),
        ], walletId: w);
        expect(
          await isar.expenseRecordModels.count(),
          3,
          reason: 'the ৳0.30 item is skipped',
        );
        expect(await expenseSum(), 1250 + 100 + 301);
        await expectAgrees(w, 5000);
      },
    );

    test('receipt/AI total 99.60 -> 100 both sides, and dedupes', () async {
      final w = await seedWallet();
      final receipt = {
        'total': 99.6,
        'merchant': 'Shwapno',
        'category': 'Food',
        'date': '2026-07-11',
      };
      expect(await expenses().saveReceiptExpense(receipt, walletId: w), isNull);
      expect(await expenseSum(), 100);
      await expectAgrees(w, 1000);

      expect(
        await expenses().saveReceiptExpense(receipt, walletId: w),
        contains('একই খরচ'),
      );
      expect(await isar.expenseRecordModels.count(), 1);
    });

    test(
      'delete reverses exactly: save 120.50 then delete -> wallet back to 1000',
      () async {
        final w = await seedWallet();
        await expenses().saveManualExpense(
          ExpenseEntity(
            amount: 120.5,
            category: 'Food',
            description: 'a',
            date: date,
          ),
          walletId: w,
        );
        final saved =
            (await container.read(expenseRepositoryProvider).getAllExpenses())
                .single;
        expect(saved.amount, 121);

        await tolerant(
          () => container
              .read(expenseListControllerProvider.notifier)
              .deleteExpense(saved),
        );
        expect(await isar.expenseRecordModels.count(), 0);
        expect(await balance(w), 1000, reason: 'no phantom ৳0.50');
      },
    );

    test('edit: 120.50 -> 200.40 leaves wallet == start − 200', () async {
      final w = await seedWallet();
      await expenses().saveManualExpense(
        ExpenseEntity(
          amount: 120.5,
          category: 'Food',
          description: 'a',
          date: date,
        ),
        walletId: w,
      );
      final saved =
          (await container.read(expenseRepositoryProvider).getAllExpenses())
              .single;

      await tolerant(
        () => container
            .read(expenseListControllerProvider.notifier)
            .updateExpense(saved.copyWith(amount: 200.4)),
      );
      expect(await expenseSum(), 200);
      await expectAgrees(w, 1000);
    });
  });

  group('income paths', () {
    test('manual: 500.40 -> record 500, wallet +500', () async {
      final w = await seedWallet();
      expect(
        await incomes().saveManualIncome(
          IncomeEntity(
            amount: 500.4,
            source: 'Salary',
            description: 'i',
            date: date,
            createdAt: date,
          ),
          walletId: w,
        ),
        isNull,
      );
      expect(await incomeSum(), 500);
      await expectAgrees(w, 1000);
    });

    test('detected income 2000.60 -> 2001 both sides', () async {
      final w = await seedWallet();
      final r = await incomes().saveDetectedIncomeDetailed(
        IncomeEntity(
          amount: 2000.6,
          source: 'Salary',
          description: 's',
          date: date,
          createdAt: date,
        ),
        walletId: w,
      );
      expect(r.income, isNotNull);
      expect(await incomeSum(), 2001);
      await expectAgrees(w, 1000);
    });

    test(
      'batch: rounded per item, credit == Σ records; dust skipped',
      () async {
        final w = await seedWallet();
        expect(
          await incomes().saveDetectedIncomeBatch([
            IncomeEntity(
              amount: 100.4,
              source: 'Salary',
              description: 'a',
              date: date,
              createdAt: date,
            ),
            IncomeEntity(
              amount: 200.5,
              source: 'Salary',
              description: 'b',
              date: date,
              createdAt: date,
            ),
            IncomeEntity(
              amount: 0.2,
              source: 'Salary',
              description: 'dust',
              date: date,
              createdAt: date,
            ),
          ], walletId: w),
          isNull,
        );
        expect(await isar.incomeRecordModels.count(), 2);
        expect(await incomeSum(), 100 + 201);
        await expectAgrees(w, 1000);
      },
    );

    test('delete and edit reverse exactly', () async {
      final w = await seedWallet();
      await incomes().saveManualIncome(
        IncomeEntity(
          amount: 500.4,
          source: 'Salary',
          description: 'i',
          date: date,
          createdAt: date,
        ),
        walletId: w,
      );
      final saved =
          (await container.read(getAllIncomeUseCaseProvider).call()).single;
      expect(saved.amount, 500);

      expect(
        await incomes().updateIncome(saved.copyWith(amount: 750.7), saved),
        isNull,
      );
      expect(await incomeSum(), 751);
      await expectAgrees(w, 1000);

      final edited =
          (await container.read(getAllIncomeUseCaseProvider).call()).single;
      expect(await incomes().deleteIncome(edited), isNull);
      expect(await balance(w), 1000);
    });
  });

  group('debt paths (whole taka)', () {
    Future<int> seedDebt({
      required int walletId,
      DebtType type = DebtType.iOwe,
      double original = 1250.4,
      double remaining = 1250.4,
      bool emi = false,
      double emiAmount = 0,
    }) async {
      final debt = DebtModel()
        ..personName = 'Rahim'
        ..type = type
        ..originalAmount = original
        ..remainingAmount = remaining
        ..status = DebtStatus.active
        ..createdAt = DateTime(2026, 7, 1)
        ..walletId = walletId
        ..reminderEnabled = false
        ..isEMI = emi
        ..emiAmount = emiAmount
        ..totalInstallments = emi ? 3 : 0;
      return (await DebtLocalDataSource(isar).saveDebt(debt)).id;
    }

    Future<DebtModel> debtOf(int id) async => (await isar.debtModels.get(id))!;

    DebtMutationController debts() =>
        container.read(debtMutationControllerProvider);

    test(
      'an existing ৳1,250.40 debt settles with a ৳1,250 payment (0.40 is dust)',
      () async {
        final w = await seedWallet();
        final id = await seedDebt(walletId: w);

        final result = await debts().addPayment(id, 1250);
        expect(result.isSuccess, isTrue);

        final debt = await debtOf(id);
        expect(debt.remainingAmount, 0);
        expect(debt.status, DebtStatus.settled);
        expect(await balance(w), -250, reason: '1000 − 1250');
        expect(await expenseSum(), 1250, reason: 'mirror == wallet movement');
        await expectAgrees(w, 1000);
      },
    );

    test('paying more than the whole-taka maximum is refused', () async {
      final w = await seedWallet();
      final id = await seedDebt(walletId: w);
      final result = await debts().addPayment(id, 1251);
      expect(result.isSuccess, isFalse);
      expect(await balance(w), 1000);
    });

    test(
      'a fractional payment is rounded once: 250.60 -> 251 everywhere',
      () async {
        final w = await seedWallet();
        final id = await seedDebt(walletId: w, original: 5000, remaining: 5000);

        expect((await debts().addPayment(id, 250.6)).isSuccess, isTrue);

        final payment = (await isar.debtPaymentModels.where().findAll()).single;
        expect(payment.amount, 251);
        expect((await debtOf(id)).remainingAmount, 4749);
        expect(await expenseSum(), 251);
        await expectAgrees(w, 1000);
      },
    );

    test('a debt already below ৳1 can still be closed with ৳1', () async {
      final w = await seedWallet();
      final id = await seedDebt(walletId: w, original: 1000, remaining: 0.4);
      expect((await debts().addPayment(id, 1)).isSuccess, isTrue);
      final debt = await debtOf(id);
      expect(debt.remainingAmount, 0);
      expect(debt.status, DebtStatus.settled);
    });

    test(
      'an EMI whose last instalment is fractional (৳1,250.40) pays 1250 and settles',
      () async {
        final w = await seedWallet();
        final id = await seedDebt(
          walletId: w,
          original: 12000,
          remaining: 1250.4,
          emi: true,
          emiAmount: 5000,
        );
        expect((await debts().recordInstallmentPaid(id)).isSuccess, isTrue);
        expect((await debtOf(id)).remainingAmount, 0);
        expect(await balance(w), -250);
        expect(await expenseSum(), 1250);
      },
    );

    test(
      'deleting a payment restores the wallet and the mirror exactly',
      () async {
        final w = await seedWallet();
        final id = await seedDebt(walletId: w, original: 5000, remaining: 5000);
        await debts().addPayment(id, 250.6);
        final paymentId =
            (await isar.debtPaymentModels.where().findAll()).single.id;

        expect((await debts().deletePayment(paymentId)).isSuccess, isTrue);
        expect(await balance(w), 1000);
        expect(await isar.expenseRecordModels.count(), 0);
      },
    );

    test(
      'a NEW debt principal is whole taka and credits the wallet by that',
      () async {
        final w = await seedWallet();
        final result = await debts().saveDebt(
          DebtEntity(
            id: 0,
            personName: 'Karim',
            type: DebtType.theyOwe,
            originalAmount: 800.6,
            remainingAmount: 800.6,
            status: DebtStatus.active,
            createdAt: DateTime(2026, 7, 1),
          ),
          walletId: w,
        );
        expect(result.isSuccess, isTrue);
        final saved = (await isar.debtModels.where().findAll()).single;
        expect(saved.originalAmount, 801);
        expect(saved.remainingAmount, 801);
        expect(
          await balance(w),
          1000 - 801,
          reason: 'lent ৳801 out of the wallet',
        );
      },
    );
  });

  test(
    'ExpenseSource.debtPayment mirror carries the same whole amount',
    () async {
      final w = await seedWallet();
      final id = await DebtLocalDataSource(isar)
          .saveDebt(
            DebtModel()
              ..personName = 'R'
              ..type = DebtType.iOwe
              ..originalAmount = 3000
              ..remainingAmount = 3000
              ..status = DebtStatus.active
              ..createdAt = DateTime(2026, 7, 1)
              ..walletId = w
              ..reminderEnabled = false,
          )
          .then((d) => d.id);
      await container.read(debtMutationControllerProvider).addPayment(id, 99.5);
      final mirror = (await isar.expenseRecordModels.where().findAll()).single;
      expect(mirror.sourceType, ExpenseSource.debtPayment);
      expect(mirror.amount, 100);
      expect(await balance(w), 900);
    },
  );
}
