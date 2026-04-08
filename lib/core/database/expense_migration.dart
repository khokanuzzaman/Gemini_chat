import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/expense_record_model.dart';
import 'models/wallet_model.dart';
import '../../features/wallet/domain/entities/wallet_entity.dart';

class ExpenseMigration {
  ExpenseMigration._();

  static const _walletMigrationKey = 'expense_wallet_migration_v1';

  static Future<void> migrateExpensesToDefaultWallet({
    required Isar isar,
    required SharedPreferences prefs,
  }) async {
    final alreadyMigrated = prefs.getBool(_walletMigrationKey) ?? false;
    if (alreadyMigrated) {
      return;
    }

    final wallets = await isar.walletModels.where().findAll();
    WalletModel? cashWallet;
    for (final wallet in wallets) {
      if (wallet.type == WalletType.cash) {
        cashWallet = wallet;
        break;
      }
    }
    if (cashWallet == null) {
      return;
    }

    final expenses = await isar.expenseRecordModels.where().findAll();
    final missingWalletExpenses = expenses
        .where((expense) => expense.walletId == null)
        .toList(growable: false);

    if (missingWalletExpenses.isNotEmpty) {
      await isar.writeTxn(() async {
        for (final expense in missingWalletExpenses) {
          expense.walletId = cashWallet!.id;
        }
        await isar.expenseRecordModels.putAll(missingWalletExpenses);
      });
    }

    await prefs.setBool(_walletMigrationKey, true);
  }
}
