import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/backup/backup_providers.dart';
import '../../core/database/clear_all_data.dart';
import '../../core/notifications/budget_settings.dart';
import '../../core/preferences/app_preferences.dart';
import '../../core/providers/database_providers.dart';
import '../anomaly/presentation/providers/anomaly_provider.dart';
import '../budget/presentation/providers/budget_provider.dart';
import '../debt/presentation/providers/debt_providers.dart';
import '../expense/presentation/providers/expense_providers.dart';
import '../goals/presentation/providers/goal_provider.dart';
import '../income/presentation/providers/income_providers.dart';
import '../prediction/presentation/providers/prediction_provider.dart';
import '../sms_import/presentation/providers/sms_import_provider.dart';
import '../wallet/presentation/providers/wallet_provider.dart';

/// Everything "সব ডেটা মুছুন" does on the device: sign out of Google, forget the
/// backup bookkeeping, clear every user collection and reset the dependent
/// providers. Shared with "অ্যাকাউন্ট মুছুন", which runs it after the cloud side.
Future<void> wipeAllLocalData(WidgetRef ref) async {
  await ref.read(smsAutoImportProvider.notifier).disable();
  await ref.read(backupStateProvider.notifier).signOut();
  await ref.read(backupStateProvider.notifier).resetLocalState();
  await clearAllUserCollections(ref.read(isarProvider));

  await ref.read(predictionProvider.notifier).reset();
  await ref.read(anomalyProvider.notifier).clear();
  await AppPreferences.setActiveWalletId(0);
  await ref.read(smsSettingsProvider).resetAll();
  await ref.read(budgetSettingsProvider.notifier).clearBudgets();
  ref.read(expenseRefreshTokenProvider.notifier).state++;
  ref.read(incomeRefreshTokenProvider.notifier).state++;
  ref.read(debtRefreshTokenProvider.notifier).state++;
  ref.read(anomalyForceRedetectTokenProvider.notifier).state++;
  ref.read(predictionRefreshTokenProvider.notifier).state++;
  ref.invalidate(budgetProvider);
  ref.invalidate(goalsProvider);
  ref.invalidate(walletProvider);
  ref.invalidate(dashboardControllerProvider);
  ref.invalidate(expenseListControllerProvider);
  ref.invalidate(analyticsControllerProvider);
  ref.invalidate(incomeListControllerProvider);
  ref.invalidate(debtListProvider);
  ref.invalidate(cashFlowProvider);
  ref.invalidate(thisMonthIncomeProvider);
  ref.invalidate(lastMonthIncomeProvider);
}
