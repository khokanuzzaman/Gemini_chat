import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import 'package:gemini_chat/core/database/models/expense_record_model.dart';
import 'package:gemini_chat/core/database/models/wallet_model.dart';
import 'package:gemini_chat/core/ledger/wallet_ledger_service.dart';
import 'package:gemini_chat/features/debt/data/models/debt_payment_model.dart';
import 'package:gemini_chat/features/expense/domain/entities/expense_source.dart';
import 'package:gemini_chat/features/wallet/domain/entities/wallet_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Isar isar;
  late Directory tempDir;
  late WalletLedgerService ledger;

  setUp(() async {
    await Isar.initializeIsarCore(
      libraries: {
        Abi.current():
            '${Platform.environment['HOME']!}/.pub-cache/hosted/pub.dev/isar_community_flutter_libs-3.3.2/macos/libisar.dylib',
      },
    );
    tempDir = await Directory.systemTemp.createTemp('pocketpilot-ai-ledger-');
    isar = await Isar.open(
      [WalletModelSchema, ExpenseRecordModelSchema, DebtPaymentModelSchema],
      directory: tempDir.path,
      name: 'wallet_ledger_service_test',
    );
    ledger = WalletLedgerService(isar);
  });

  tearDown(() async {
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

  ExpenseRecordModel validRecord({
    int amount = 100,
    ExpenseSource source = ExpenseSource.debtPayment,
    int? sourceId = 1,
  }) {
    return ExpenseRecordModel()
      ..amount = amount
      ..category = 'EMI'
      ..description = 'ঋণ পরিশোধ'
      ..date = DateTime(2026, 7, 5)
      ..sourceType = source
      ..sourceId = sourceId;
  }

  DebtPaymentModel validPayment({double amount = 100}) {
    return DebtPaymentModel()
      ..debtId = 1
      ..amount = amount
      ..paidAt = DateTime(2026, 7, 5);
  }

  Future<double> walletBalance(int walletId) async {
    final wallet = await isar.walletModels.get(walletId);
    return wallet!.currentBalance;
  }

  // ---------------------------------------------------------------------------
  // Simple (single-record) convenience wrappers.
  // ---------------------------------------------------------------------------
  group('recordOutflow / recordInflow', () {
    test('apply the balance change exactly once (outflow then inflow)', () async {
      final walletId = await seedWallet(balance: 1000);

      final outflow = await ledger.recordOutflow(
        record: validRecord(amount: 100),
        walletId: walletId,
        amount: 100,
      );

      expect(await walletBalance(walletId), 900); // 1000 - 100, once
      expect(await isar.expenseRecordModels.count(), 1);
      expect(outflow.appliedDelta, -100);

      final saved =
          await isar.expenseRecordModels.get(outflow.recordIds.expenseRecordId!);
      expect(saved, isNotNull);
      expect(saved!.walletId, walletId); // ledger links record to the wallet
      expect(saved.sourceType, ExpenseSource.debtPayment);

      final inflow = await ledger.recordInflow(
        record: validRecord(amount: 250, source: ExpenseSource.expense),
        walletId: walletId,
        amount: 250,
      );

      expect(await walletBalance(walletId), 1150); // 900 + 250, once
      expect(inflow.appliedDelta, 250);
      expect(await isar.expenseRecordModels.count(), 2);
    });

    test('rolls back the balance change when the record write fails', () async {
      final walletId = await seedWallet(balance: 1000);
      final badRecord = ExpenseRecordModel()
        ..amount = 100
        ..description = 'broken' // `late category` unset -> serialization throws
        ..date = DateTime(2026, 7, 5);

      await expectLater(
        ledger.recordOutflow(record: badRecord, walletId: walletId, amount: 100),
        throwsA(anything),
      );

      expect(await walletBalance(walletId), 1000);
      expect(await isar.expenseRecordModels.count(), 0);
    });

    test('rolls back the record write when the balance change fails', () async {
      await expectLater(
        ledger.recordOutflow(
          record: validRecord(),
          walletId: 999999, // no such wallet
          amount: 100,
        ),
        throwsA(isA<WalletLedgerException>()),
      );
      expect(await isar.expenseRecordModels.count(), 0);
    });

    test('surfaces a typed error when the target wallet is missing', () async {
      await expectLater(
        ledger.recordOutflow(record: validRecord(), walletId: 424242, amount: 50),
        throwsA(
          isA<WalletLedgerException>().having(
            (e) => e.message,
            'message',
            contains('424242'),
          ),
        ),
      );
    });

    test('reverse() restores both the record and the balance exactly', () async {
      final walletId = await seedWallet(balance: 1000);
      final entry = await ledger.recordOutflow(
        record: validRecord(amount: 100),
        walletId: walletId,
        amount: 100,
      );
      expect(await walletBalance(walletId), 900);

      await ledger.reverse(
        entry: entry,
        deleteRecords: (txn) =>
            txn.expenseRecordModels.delete(entry.recordIds.expenseRecordId!),
      );

      expect(await walletBalance(walletId), 1000);
      expect(await isar.expenseRecordModels.count(), 0);
    });

    test('rejects a non-positive amount', () async {
      final walletId = await seedWallet(balance: 1000);
      await expectLater(
        ledger.recordOutflow(record: validRecord(), walletId: walletId, amount: 0),
        throwsArgumentError,
      );
      expect(await walletBalance(walletId), 1000);
      expect(await isar.expenseRecordModels.count(), 0);
    });
  });

  // ---------------------------------------------------------------------------
  // Generalized execute(): 3-write case = originating model (DebtPaymentModel)
  // + linked ExpenseRecordModel + wallet, all in one transaction.
  // ---------------------------------------------------------------------------
  group('execute (multi-record)', () {
    // Writes payment first, reads its id, links it onto the expense record.
    LedgerWriteRecords debtWrite({DebtPaymentModel? payment, ExpenseRecordModel? record}) {
      return (isar) async {
        final paymentId = await isar.debtPaymentModels.put(payment ?? validPayment());
        final expense = record ?? validRecord(source: ExpenseSource.debtPayment);
        expense.sourceId = paymentId; // link the expense record to the payment
        final recordId = await isar.expenseRecordModels.put(expense);
        return LedgerRecordIds(originatingId: paymentId, expenseRecordId: recordId);
      };
    }

    test('commits all three writes atomically and links the ids', () async {
      final walletId = await seedWallet(balance: 1000);

      final entry = await ledger.execute(
        walletId: walletId,
        delta: -100,
        writeRecords: debtWrite(),
      );

      expect(await walletBalance(walletId), 900);
      expect(await isar.debtPaymentModels.count(), 1);
      expect(await isar.expenseRecordModels.count(), 1);

      // ids correctly linked: expense.sourceId points at the payment row.
      final expense =
          await isar.expenseRecordModels.get(entry.recordIds.expenseRecordId!);
      expect(expense!.sourceId, entry.recordIds.originatingId);
      expect(expense.sourceType, ExpenseSource.debtPayment);
      final payment =
          await isar.debtPaymentModels.get(entry.recordIds.originatingId!);
      expect(payment, isNotNull);
    });

    test('failure in the linked expense record rolls back all three', () async {
      final walletId = await seedWallet(balance: 1000);
      final badExpense = ExpenseRecordModel()
        ..amount = 100
        ..description = 'broken' // `late category` unset
        ..date = DateTime(2026, 7, 5);

      await expectLater(
        ledger.execute(
          walletId: walletId,
          delta: -100,
          writeRecords: debtWrite(record: badExpense),
        ),
        throwsA(anything),
      );

      expect(await walletBalance(walletId), 1000);
      expect(await isar.debtPaymentModels.count(), 0);
      expect(await isar.expenseRecordModels.count(), 0);
    });

    test('failure in the originating model rolls back all three', () async {
      final walletId = await seedWallet(balance: 1000);
      final badPayment = DebtPaymentModel()
        ..debtId = 1
        ..paidAt = DateTime(2026, 7, 5); // `late amount` unset -> throws

      await expectLater(
        ledger.execute(
          walletId: walletId,
          delta: -100,
          writeRecords: debtWrite(payment: badPayment),
        ),
        throwsA(anything),
      );

      expect(await walletBalance(walletId), 1000);
      expect(await isar.debtPaymentModels.count(), 0);
      expect(await isar.expenseRecordModels.count(), 0);
    });

    test('failure applying the wallet delta rolls back all three', () async {
      await expectLater(
        ledger.execute(
          walletId: 999999, // missing wallet -> balance step throws
          delta: -100,
          writeRecords: debtWrite(),
        ),
        throwsA(isA<WalletLedgerException>()),
      );

      expect(await isar.debtPaymentModels.count(), 0);
      expect(await isar.expenseRecordModels.count(), 0);
    });

    test('reverse() of a 3-write case restores everything', () async {
      final walletId = await seedWallet(balance: 1000);
      final entry = await ledger.execute(
        walletId: walletId,
        delta: -100,
        writeRecords: debtWrite(),
      );
      expect(await walletBalance(walletId), 900);

      await ledger.reverse(
        entry: entry,
        deleteRecords: (txn) async {
          await txn.expenseRecordModels.delete(entry.recordIds.expenseRecordId!);
          await txn.debtPaymentModels.delete(entry.recordIds.originatingId!);
        },
      );

      expect(await walletBalance(walletId), 1000);
      expect(await isar.expenseRecordModels.count(), 0);
      expect(await isar.debtPaymentModels.count(), 0);
    });
  });

  // ---------------------------------------------------------------------------
  // amend(): edits update the record IN PLACE and move the wallet effect from
  // the old version to the new one, atomically.
  // ---------------------------------------------------------------------------
  group('amend (edit)', () {
    // Updates the existing expense's amount in place; keeps the same id.
    LedgerUpdateRecords updateAmount(int recordId, int newAmount, {int? newWalletId}) {
      return (isar) async {
        final existing = await isar.expenseRecordModels.get(recordId);
        existing!.amount = newAmount;
        if (newWalletId != null) existing.walletId = newWalletId;
        final id = await isar.expenseRecordModels.put(existing); // same id
        return LedgerRecordIds(expenseRecordId: id);
      };
    }

    test('same-wallet edit nets to one delta and preserves record identity', () async {
      final walletId = await seedWallet(balance: 1000);
      final entry = await ledger.recordOutflow(
        record: validRecord(amount: 100, source: ExpenseSource.expense),
        walletId: walletId,
        amount: 100,
      );
      final recordId = entry.recordIds.expenseRecordId!;
      expect(await walletBalance(walletId), 900);

      // Expense edited 100 -> 40 on the same wallet.
      final amended = await ledger.amend(
        updateRecords: updateAmount(recordId, 40),
        oldWalletId: walletId,
        oldAppliedDelta: -100,
        newWalletId: walletId,
        newAppliedDelta: -40,
      );

      expect(await walletBalance(walletId), 960); // 1000 - 40
      expect(amended.recordIds.expenseRecordId, recordId); // identity survives
      final saved = await isar.expenseRecordModels.get(recordId);
      expect(saved!.amount, 40);
      expect(await isar.expenseRecordModels.count(), 1);
    });

    test('cross-wallet edit refunds the old wallet and charges the new one', () async {
      final walletA = await seedWallet(balance: 1000);
      final walletB = await seedWallet(balance: 500);
      final entry = await ledger.recordOutflow(
        record: validRecord(amount: 100, source: ExpenseSource.expense),
        walletId: walletA,
        amount: 100,
      );
      final recordId = entry.recordIds.expenseRecordId!;
      expect(await walletBalance(walletA), 900);

      await ledger.amend(
        updateRecords: updateAmount(recordId, 40, newWalletId: walletB),
        oldWalletId: walletA,
        oldAppliedDelta: -100,
        newWalletId: walletB,
        newAppliedDelta: -40,
      );

      expect(await walletBalance(walletA), 1000); // refunded +100
      expect(await walletBalance(walletB), 460); // charged -40
      final saved = await isar.expenseRecordModels.get(recordId);
      expect(saved!.walletId, walletB);
      expect(saved.amount, 40);
    });

    test('rolls back the record update when a wallet delta fails', () async {
      final walletA = await seedWallet(balance: 1000);
      final entry = await ledger.recordOutflow(
        record: validRecord(amount: 100, source: ExpenseSource.expense),
        walletId: walletA,
        amount: 100,
      );
      final recordId = entry.recordIds.expenseRecordId!;
      expect(await walletBalance(walletA), 900);

      // New wallet is missing -> the apply step throws mid-amend.
      await expectLater(
        ledger.amend(
          updateRecords: updateAmount(recordId, 40, newWalletId: 999999),
          oldWalletId: walletA,
          oldAppliedDelta: -100,
          newWalletId: 999999,
          newAppliedDelta: -40,
        ),
        throwsA(isA<WalletLedgerException>()),
      );

      // Everything rolled back: old wallet not refunded, record unchanged.
      expect(await walletBalance(walletA), 900);
      final saved = await isar.expenseRecordModels.get(recordId);
      expect(saved!.amount, 100);
      expect(saved.walletId, walletA);
    });

    test('rolls back the wallet effect when the record update fails', () async {
      final walletId = await seedWallet(balance: 1000);
      await ledger.recordOutflow(
        record: validRecord(amount: 100, source: ExpenseSource.expense),
        walletId: walletId,
        amount: 100,
      );
      expect(await walletBalance(walletId), 900);

      await expectLater(
        ledger.amend(
          updateRecords: (isar) async => throw StateError('write failed'),
          oldWalletId: walletId,
          oldAppliedDelta: -100,
          newWalletId: walletId,
          newAppliedDelta: -40,
        ),
        throwsA(isA<StateError>()),
      );

      expect(await walletBalance(walletId), 900); // net delta not applied
    });
  });

  // ---------------------------------------------------------------------------
  // Batch capability the 3b migration relies on: N records + one summed delta as
  // a SINGLE atomic execute (deliberate C1 fix vs today's per-row swallowed loop).
  // ---------------------------------------------------------------------------
  group('execute (atomic batch)', () {
    LedgerWriteRecords writeN(int n, {bool poisonLast = false}) {
      return (isar) async {
        int? firstId;
        for (var i = 0; i < n; i++) {
          final record = (poisonLast && i == n - 1)
              ? (ExpenseRecordModel()
                ..amount = 100
                ..description = 'broken' // `late category` unset -> throws
                ..date = DateTime(2026, 7, 5))
              : validRecord(amount: 100, source: ExpenseSource.expense);
          final id = await isar.expenseRecordModels.put(record);
          firstId ??= id;
        }
        return LedgerRecordIds(expenseRecordId: firstId);
      };
    }

    test('N records + summed delta commit as one atomic op', () async {
      final walletId = await seedWallet(balance: 1000);
      await ledger.execute(
        walletId: walletId,
        delta: -300, // 3 x 100
        writeRecords: writeN(3),
      );
      expect(await walletBalance(walletId), 700);
      expect(await isar.expenseRecordModels.count(), 3);
    });

    test('a mid-batch failure rolls back ALL records and the balance', () async {
      final walletId = await seedWallet(balance: 1000);
      await expectLater(
        ledger.execute(
          walletId: walletId,
          delta: -300,
          writeRecords: writeN(3, poisonLast: true),
        ),
        throwsA(anything),
      );
      // Nothing half-applied: no records, balance untouched.
      expect(await isar.expenseRecordModels.count(), 0);
      expect(await walletBalance(walletId), 1000);
    });
  });
}
