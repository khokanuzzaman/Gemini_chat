import 'dart:ffi';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import 'package:gemini_chat/core/database/models/expense_record_model.dart';
import 'package:gemini_chat/core/database/models/wallet_model.dart';
import 'package:gemini_chat/core/providers/database_providers.dart';
import 'package:gemini_chat/features/debt/data/datasources/debt_local_datasource.dart';
import 'package:gemini_chat/features/debt/data/models/debt_model.dart';
import 'package:gemini_chat/features/debt/data/models/debt_payment_model.dart';
import 'package:gemini_chat/features/debt/domain/entities/debt_entity.dart';
import 'package:gemini_chat/features/debt/presentation/providers/debt_providers.dart';

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
    tempDir = await Directory.systemTemp.createTemp('pocketpilot-ai-debtpay-');
    isar = await Isar.open(
      [
        WalletModelSchema,
        DebtModelSchema,
        DebtPaymentModelSchema,
        ExpenseRecordModelSchema,
      ],
      directory: tempDir.path,
      name: 'debt_add_payment_missing_wallet_test',
    );
    container = ProviderContainer(
      overrides: [isarProvider.overrideWithValue(isar)],
    );
  });

  tearDown(() async {
    container.dispose();
    await isar.close(deleteFromDisk: true);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'addPayment to a MISSING wallet now fails atomically — nothing persists '
    '(the ledger replaces the old swallow-and-warn behavior)',
    () async {
      // Debt points at a wallet id that does not exist. Under the ledger, the
      // whole payment is one transaction: writing the payment/linked expense and
      // moving the wallet commit together or not at all. A missing wallet makes
      // the ledger throw, so NOTHING persists — no false success for money that
      // never moved (audit C1), and no orphan payment.
      final debt = DebtModel()
        ..personName = 'Rahim'
        ..type = DebtType.iOwe
        ..originalAmount = 1000
        ..remainingAmount = 1000
        ..status = DebtStatus.active
        ..createdAt = DateTime(2026, 7, 1)
        ..walletId = 999999 // no such wallet
        ..reminderEnabled = false;

      final saved = await DebtLocalDataSource(isar).saveDebt(debt);

      final result = await container
          .read(debtMutationControllerProvider)
          .addPayment(saved.id, 100);

      expect(result.isSuccess, isFalse); // hard failure, not success-with-warning
      expect(await isar.debtPaymentModels.count(), 0); // payment rolled back
      expect(await isar.expenseRecordModels.count(), 0); // linked expense rolled back
      // Debt math untouched (the addPaymentInTxn ran in the same rolled-back txn).
      expect((await isar.debtModels.get(saved.id))!.remainingAmount, 1000);
    },
  );
}
