import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import 'package:gemini_chat/features/debt/data/datasources/debt_local_datasource.dart';
import 'package:gemini_chat/features/debt/data/models/debt_model.dart';
import 'package:gemini_chat/features/debt/data/models/debt_payment_model.dart';
import 'package:gemini_chat/features/debt/domain/entities/debt_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'deletePayment rolls back EMI progress and next installment date',
    () async {
      await Isar.initializeIsarCore(
        libraries: {
          Abi.current():
              '${Platform.environment['HOME']!}/.pub-cache/hosted/pub.dev/isar_community_flutter_libs-3.3.2/macos/libisar.dylib',
        },
      );
      final tempDir = await Directory.systemTemp.createTemp(
        'pocketpilot-ai-debt-',
      );
      final isar = await Isar.open(
        [DebtModelSchema, DebtPaymentModelSchema],
        directory: tempDir.path,
        name: 'debt_local_datasource_test',
      );
      addTearDown(() async {
        await isar.close(deleteFromDisk: true);
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final dataSource = DebtLocalDataSource(isar);
      final nextInstallmentDate = DateTime(2026, 6, 15);
      final debt = DebtModel()
        ..personName = 'Laptop EMI'
        ..type = DebtType.iOwe
        ..originalAmount = 1000
        ..remainingAmount = 800
        ..status = DebtStatus.active
        ..createdAt = DateTime(2026, 4, 1)
        ..isEMI = true
        ..totalInstallments = 5
        ..paidInstallments = 1
        ..emiAmount = 200
        ..installmentDayOfMonth = 15
        ..nextInstallmentDate = nextInstallmentDate;

      final savedDebt = await dataSource.saveDebt(debt);
      final payment = DebtPaymentModel()
        ..debtId = savedDebt.id
        ..amount = 200
        ..paidAt = DateTime(2026, 4, 15)
        ..isInstallment = true
        ..installmentNumber = 1;

      await isar.writeTxn(() async {
        await isar.debtPaymentModels.put(payment);
      });

      final deleted = await dataSource.deletePayment(payment.id);
      final updatedDebt = await isar.debtModels.get(savedDebt.id);
      final payments = await dataSource.getPaymentsForDebt(savedDebt.id);

      expect(deleted, isTrue);
      expect(updatedDebt, isNotNull);
      expect(updatedDebt!.remainingAmount, 1000);
      expect(updatedDebt.paidInstallments, 0);
      expect(updatedDebt.nextInstallmentDate, DateTime(2026, 5, 15));
      expect(payments, isEmpty);
    },
  );
}
