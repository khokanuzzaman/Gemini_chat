import 'dart:ffi';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gemini_chat/core/ai/expense_result.dart';
import 'package:gemini_chat/core/database/models/expense_record_model.dart';
import 'package:gemini_chat/core/database/models/wallet_model.dart';
import 'package:gemini_chat/core/providers/database_providers.dart';
import 'package:gemini_chat/core/providers/shared_preferences_provider.dart';
import 'package:gemini_chat/features/expense/presentation/providers/expense_providers.dart';
import 'package:gemini_chat/features/wallet/domain/entities/wallet_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'chat-style expense save refreshes dashboard, expense list, and analytics providers',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await Isar.initializeIsarCore(
        libraries: {
          Abi.current():
              '${Platform.environment['HOME']!}/.pub-cache/hosted/pub.dev/isar_community_flutter_libs-3.3.2/macos/libisar.dylib',
        },
      );
      final tempDir = await Directory.systemTemp.createTemp(
        'pocketpilot-ai-wallet-refresh-',
      );
      // Real Isar end to end: the ledger write path and the dashboard/list/
      // analytics read path share one store, so a save is actually observable.
      final isar = await Isar.open(
        [WalletModelSchema, ExpenseRecordModelSchema],
        directory: tempDir.path,
        name: 'wallet_refresh_test',
      );
      final now = DateTime.now();
      final walletId = await isar.writeTxn(() async {
        await isar.expenseRecordModels.put(
          ExpenseRecordModel()
            ..amount = 120
            ..category = 'Food'
            ..description = 'নাস্তা'
            ..date = DateTime(now.year, now.month, now.day, 9, 0),
        );
        final wallet = WalletModel()
          ..name = 'Cash'
          ..type = WalletType.cash
          ..emoji = '💵'
          ..initialBalance = 0
          ..currentBalance = 1000
          ..sortOrder = 1
          ..isArchived = false
          ..createdAt = now
          ..updatedAt = now;
        return isar.walletModels.put(wallet);
      });
      addTearDown(() async {
        await isar.close(deleteFromDisk: true);
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWithValue(isar),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final initialDashboard = await container.read(
        dashboardControllerProvider.future,
      );
      final initialList = await container.read(
        expenseListControllerProvider.future,
      );
      final initialAnalytics = await container.read(
        analyticsControllerProvider.future,
      );

      expect(initialDashboard.thisMonthTotal, 120);
      expect(initialList.expenses, hasLength(1));
      expect(initialAnalytics.data.totalSpent, 120);

      final error = await container
          .read(expenseMutationControllerProvider)
          .saveDetectedExpense(
            ExpenseData(
              amount: 60,
              category: 'Transport',
              description: 'রিকশা',
              date: DateTime(
                now.year,
                now.month,
                now.day,
              ).toIso8601String().split('T').first,
            ),
            walletId: walletId,
          );

      expect(error, isNull);

      final updatedDashboard = await container.read(
        dashboardControllerProvider.future,
      );
      final updatedList = await container.read(
        expenseListControllerProvider.future,
      );
      final updatedAnalytics = await container.read(
        analyticsControllerProvider.future,
      );

      expect(updatedDashboard.thisMonthTotal, 180);
      expect(updatedDashboard.todayExpenses, hasLength(2));
      expect(updatedList.expenses, hasLength(2));
      expect(updatedAnalytics.data.totalSpent, 180);
      expect(container.read(expenseRefreshTokenProvider), 1);
      // The ledger actually moved the wallet, too: 1000 - 60.
      expect((await isar.walletModels.get(walletId))!.currentBalance, 940);
    },
  );
}
