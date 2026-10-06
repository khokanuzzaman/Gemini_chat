import 'package:isar_community/isar.dart';

import '../../features/chat/data/models/message_model.dart';
import '../../features/debt/data/models/debt_model.dart';
import '../../features/debt/data/models/debt_payment_model.dart';
import '../../features/net_worth/data/models/net_worth_snapshot_model.dart';
import '../../features/prediction/data/models/prediction_cache_model.dart';
import 'models/budget_plan_model.dart';
import 'models/expense_record_model.dart';
import 'models/goal_model.dart';
import 'models/goal_saving_model.dart';
import 'models/imported_sms_model.dart';
import 'models/income_record_model.dart';
import 'models/recurring_expense_model.dart';
import 'models/sms_ledger_entry_model.dart';
import 'models/sms_ledger_sync_state_model.dart';
import 'models/split_bill_model.dart';
import 'models/wallet_model.dart';

/// "সব ডেটা মুছুন": clears every user-data collection in one transaction.
///
/// A new collection MUST be added here (and to `IsarExportService`), or delete-all
/// silently leaves it behind. Categories are deliberately NOT cleared (existing
/// behaviour — see CONTRIBUTING "Known issues").
Future<void> clearAllUserCollections(Isar isar) {
  return isar.writeTxn(() async {
    await isar.expenseRecordModels.clear();
    await isar.incomeRecordModels.clear();
    await isar.messageModels.clear();
    await isar.walletModels.clear();
    await isar.budgetPlanModels.clear();
    await isar.goalModels.clear();
    await isar.goalSavingModels.clear();
    await isar.predictionCacheModels.clear();
    await isar.recurringExpenseModels.clear();
    await isar.splitBillModels.clear();
    await isar.debtModels.clear();
    await isar.debtPaymentModels.clear();
    await isar.importedSmsModels.clear();
    await isar.smsLedgerEntryModels.clear();
    await isar.smsLedgerSyncStateModels.clear();
    await isar.netWorthSnapshotModels.clear();
  });
}
