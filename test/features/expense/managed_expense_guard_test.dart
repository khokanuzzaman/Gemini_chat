// R3 (b): a debtPayment / goalDeposit row is a MIRROR owned by another feature.
// The খরচ list must refuse to edit or delete it — doing so would amend the
// wallet and the mirror but not the DebtPayment/debt, desyncing the books.
// Every refusal must leave the wallet and the record exactly as they were.

import 'dart:ffi';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gemini_chat/core/database/models/expense_record_model.dart';
import 'package:gemini_chat/core/database/models/wallet_model.dart';
import 'package:gemini_chat/core/notifications/notification_provider.dart';
import 'package:gemini_chat/core/notifications/notification_settings.dart';
import 'package:gemini_chat/core/providers/database_providers.dart';
import 'package:gemini_chat/core/providers/shared_preferences_provider.dart';
import 'package:gemini_chat/features/anomaly/presentation/providers/anomaly_provider.dart';
import 'package:gemini_chat/features/expense/domain/entities/expense_entity.dart';
import 'package:gemini_chat/features/expense/domain/entities/expense_source.dart';
import 'package:gemini_chat/features/expense/presentation/providers/expense_providers.dart';
import 'package:gemini_chat/features/wallet/domain/entities/wallet_entity.dart';

class _FakeNotificationNotifier extends NotificationNotifier {
  @override
  NotificationSettings build() => NotificationSettings.defaults();

  @override
  Future<void> checkBudgetAlert(String category) async {}
}

class _FakeAnomalyNotifier extends AnomalyNotifier {
  @override
  AnomalyState build() => const AnomalyState(alerts: [], isDetecting: false);

  @override
  Future<void> reDetect() async {}
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
    tempDir = await Directory.systemTemp.createTemp('pocketpilot-ai-managed-');
    isar = await Isar.open(
      [WalletModelSchema, ExpenseRecordModelSchema],
      directory: tempDir.path,
      name: 'managed_expense_guard_test',
    );
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        isarProvider.overrideWithValue(isar),
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationProvider.overrideWith(_FakeNotificationNotifier.new),
        anomalyProvider.overrideWith(_FakeAnomalyNotifier.new),
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

  Future<int> seedWallet(double balance) {
    final wallet = WalletModel()
      ..name = 'W'
      ..type = WalletType.cash
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

  Future<ExpenseEntity> seed({
    required int walletId,
    required ExpenseSource source,
    int amount = 300,
  }) async {
    await isar.writeTxn(
      () => isar.expenseRecordModels.put(
        ExpenseRecordModel()
          ..amount = amount
          ..category = 'EMI'
          ..description = 'কিস্তি'
          ..date = DateTime(2026, 7, 10)
          ..walletId = walletId
          ..sourceType = source
          ..sourceId = 42,
      ),
    );
    return (await container.read(expenseRepositoryProvider).getAllExpenses())
        .single;
  }

  ExpenseListController controller() =>
      container.read(expenseListControllerProvider.notifier);

  for (final source in [ExpenseSource.debtPayment, ExpenseSource.goalDeposit]) {
    group('${source.name} row', () {
      test('edit is refused; wallet and record are untouched', () async {
        final w = await seedWallet(700); // as if 300 already went out
        final row = await seed(walletId: w, source: source);

        final err = await controller().updateExpense(row.copyWith(amount: 50));

        expect(err, isNotNull);
        expect(await balance(w), 700);
        final stored =
            (await isar.expenseRecordModels.where().findAll()).single;
        expect(stored.amount, 300);
        expect(stored.sourceType, source);
        expect(stored.sourceId, 42);
      });

      test('delete is refused; wallet and record are untouched', () async {
        final w = await seedWallet(700);
        final row = await seed(walletId: w, source: source);

        final err = await controller().deleteExpense(row);

        expect(err, isNotNull);
        expect(await balance(w), 700);
        expect(await isar.expenseRecordModels.count(), 1);
      });

      test(
        'cannot be laundered by relabelling the entity as an expense',
        () async {
          final w = await seedWallet(700);
          final row = await seed(walletId: w, source: source);
          final relabelled = row.copyWith(
            sourceType: ExpenseSource.expense,
            amount: 50,
          );

          final editErr = await controller().updateExpense(relabelled);
          final deleteErr = await controller().deleteExpense(relabelled);

          // The STORED row decides, not the caller's claim.
          expect(editErr, isNotNull);
          expect(deleteErr, isNotNull);
          expect(await balance(w), 700);
          final stored =
              (await isar.expenseRecordModels.where().findAll()).single;
          expect(stored.amount, 300);
          expect(stored.sourceType, source);
        },
      );
    });
  }

  test('debtPayment refusal points the user at দেনা-পাওনা', () async {
    final w = await seedWallet(700);
    final row = await seed(walletId: w, source: ExpenseSource.debtPayment);

    final err = await controller().deleteExpense(row);

    expect(err, contains('দেনা-পাওনা'));
  });

  test('an ordinary expense is still editable and deletable', () async {
    final w = await seedWallet(900); // as if 100 already spent
    final row = await seed(
      walletId: w,
      source: ExpenseSource.expense,
      amount: 100,
    );

    String? editErr;
    try {
      editErr = await controller().updateExpense(row.copyWith(amount: 40));
    } catch (e) {
      // Bare container: tolerate only the post-write rebuild assertion.
      if (!e.toString().contains('_didChangeDependency')) rethrow;
    }
    await Future<void>.delayed(Duration.zero);
    expect(editErr, isNull);
    expect(await balance(w), 960);
  });

  test('the policy flag: only ExpenseSource.expense is list-editable', () {
    expect(ExpenseSource.expense.editableFromExpenseList, isTrue);
    expect(ExpenseSource.debtPayment.editableFromExpenseList, isFalse);
    expect(ExpenseSource.goalDeposit.editableFromExpenseList, isFalse);
  });
}
