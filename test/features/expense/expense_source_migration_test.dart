import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import 'package:gemini_chat/core/database/models/expense_record_model.dart';
import 'package:gemini_chat/features/expense/domain/entities/expense_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // Pure-Dart guards. These lock the two invariants the migration relies on and
  // need no Isar instance.
  // ---------------------------------------------------------------------------
  group('ExpenseSource invariants', () {
    test('ordinals are locked — APPEND ONLY (Isar persists the index)', () {
      // Isar stores @enumerated as the ordinal index. Reordering or inserting a
      // value would silently re-class existing rows on disk (e.g. debtPayment ->
      // goalDeposit). These assertions force any such change to be deliberate.
      expect(ExpenseSource.expense.index, 0); // legacy rows default here
      expect(ExpenseSource.debtPayment.index, 1);
      expect(ExpenseSource.goalDeposit.index, 2);
      expect(ExpenseSource.values.first, ExpenseSource.expense);
      // Adding a value must fail this until the test (and migration reasoning)
      // is updated on purpose.
      expect(ExpenseSource.values.length, 3);
    });

    test('per-surface policy matrix matches the approved decision', () {
      //                 spending  budget  prediction  anomaly  cashFlow
      // expense            ✅        ✅        ✅          ✅        ✅
      // debtPayment        ✅        ✅        ✅          ❌        ✅
      // goalDeposit        ❌        ❌        ❌          ❌        ✅
      const e = ExpenseSource.expense;
      expect(
        [
          e.countsInSpendingTotals,
          e.countsInCategoryBudget,
          e.countsInPrediction,
          e.countsInAnomaly,
          e.countsInCashFlow,
        ],
        [true, true, true, true, true],
      );

      const d = ExpenseSource.debtPayment;
      expect(
        [
          d.countsInSpendingTotals,
          d.countsInCategoryBudget,
          d.countsInPrediction,
          d.countsInAnomaly,
          d.countsInCashFlow,
        ],
        [true, true, true, false, true],
      );

      const g = ExpenseSource.goalDeposit;
      expect(
        [
          g.countsInSpendingTotals,
          g.countsInCategoryBudget,
          g.countsInPrediction,
          g.countsInAnomaly,
          g.countsInCashFlow,
        ],
        [false, false, false, false, true],
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Isar round-trip: upgrade-in-place for existing users. A record written the
  // way legacy call sites build it (no sourceType/sourceId) must read back as an
  // ordinary consumption expense; new source types must persist faithfully.
  // ---------------------------------------------------------------------------
  group('ExpenseRecordModel Isar round-trip', () {
    late Isar isar;
    late Directory tempDir;

    setUp(() async {
      await Isar.initializeIsarCore(
        libraries: {
          Abi.current():
              '${Platform.environment['HOME']!}/.pub-cache/hosted/pub.dev/isar_community_flutter_libs-3.3.2/macos/libisar.dylib',
        },
      );
      tempDir = await Directory.systemTemp.createTemp('pocketpilot-ai-source-');
      isar = await Isar.open(
        [ExpenseRecordModelSchema],
        directory: tempDir.path,
        name: 'expense_source_migration_test',
      );
    });

    tearDown(() async {
      await isar.close(deleteFromDisk: true);
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('legacy-style record (no sourceType set) reads back as expense/null', () async {
      // Mirrors how existing code builds a record today — it never sets
      // sourceType/sourceId.
      final legacy = ExpenseRecordModel()
        ..amount = 250
        ..category = 'Food'
        ..description = 'নাস্তা'
        ..date = DateTime(2026, 7, 1);

      final id = await isar.writeTxn(
        () => isar.expenseRecordModels.put(legacy),
      );
      final loaded = await isar.expenseRecordModels.get(id);

      expect(loaded, isNotNull);
      expect(loaded!.sourceType, ExpenseSource.expense);
      expect(loaded.sourceId, isNull);
    });

    test('debtPayment and goalDeposit round-trip with their sourceId', () async {
      final debt = ExpenseRecordModel()
        ..amount = 5000
        ..category = 'EMI'
        ..description = 'ঋণ পরিশোধ'
        ..date = DateTime(2026, 7, 5)
        ..sourceType = ExpenseSource.debtPayment
        ..sourceId = 42;

      final goal = ExpenseRecordModel()
        ..amount = 2000
        ..category = 'Savings'
        ..description = 'লক্ষ্য সঞ্চয়'
        ..date = DateTime(2026, 7, 6)
        ..sourceType = ExpenseSource.goalDeposit
        ..sourceId = 7;

      final ids = await isar.writeTxn(
        () => isar.expenseRecordModels.putAll([debt, goal]),
      );

      final loadedDebt = await isar.expenseRecordModels.get(ids[0]);
      final loadedGoal = await isar.expenseRecordModels.get(ids[1]);

      expect(loadedDebt!.sourceType, ExpenseSource.debtPayment);
      expect(loadedDebt.sourceId, 42);
      expect(loadedGoal!.sourceType, ExpenseSource.goalDeposit);
      expect(loadedGoal.sourceId, 7);
    });

    test('sourceType is queryable via the generated index', () async {
      await isar.writeTxn(() async {
        await isar.expenseRecordModels.putAll([
          ExpenseRecordModel()
            ..amount = 100
            ..category = 'Food'
            ..description = 'a'
            ..date = DateTime(2026, 7, 1),
          ExpenseRecordModel()
            ..amount = 100
            ..category = 'EMI'
            ..description = 'b'
            ..date = DateTime(2026, 7, 2)
            ..sourceType = ExpenseSource.debtPayment
            ..sourceId = 1,
        ]);
      });

      final debts = await isar.expenseRecordModels
          .filter()
          .sourceTypeEqualTo(ExpenseSource.debtPayment)
          .findAll();

      expect(debts, hasLength(1));
      expect(debts.single.category, 'EMI');
    });
  });
}
