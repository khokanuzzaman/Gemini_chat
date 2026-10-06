import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/debt/data/models/debt_model.dart';
import '../analytics/analytics_providers.dart';
import '../analytics/usage_analytics.dart';
import '../database/models/expense_record_model.dart';
import '../database/models/goal_model.dart';
import '../database/models/income_record_model.dart';
import '../providers/database_providers.dart';
import '../providers/shared_preferences_provider.dart';
import 'auto_backup_coordinator.dart';
import 'backup_reminder_policy.dart';

const backupReminderSnoozedUntilKey = 'backup_reminder_snoozed_until';

/// Non-null (show the Home card) when the user has data but no recent backup.
/// Invalidated after every backup, snooze and delete-all.
final backupReminderProvider =
    FutureProvider.autoDispose<BackupReminderDecision?>((ref) async {
      final prefs = ref.read(sharedPreferencesProvider);
      final isar = ref.read(isarProvider);

      DateTime? readDate(String key) {
        final millis = prefs.getInt(key);
        return millis == null || millis <= 0
            ? null
            : DateTime.fromMillisecondsSinceEpoch(millis);
      }

      final recordCount =
          await isar.expenseRecordModels.count() +
          await isar.incomeRecordModels.count();
      final hasDebtOrGoal =
          await isar.debtModels.count() > 0 ||
          await isar.goalModels.count() > 0;

      final decision = evaluateBackupReminder(
        BackupReminderInput(
          now: DateTime.now(),
          lastBackup: readDate(AutoBackupKeys.lastSuccessAt),
          firstSeen: readDate(AutoBackupKeys.firstSeenAt),
          recordCount: recordCount,
          hasDebtOrGoal: hasDebtOrGoal,
          snoozedUntil: readDate(backupReminderSnoozedUntilKey),
        ),
      );
      return decision.show ? decision : null;
    });

/// Hide the card for a week.
Future<void> snoozeBackupReminder(WidgetRef ref) async {
  final until = DateTime.now().add(BackupReminderPolicy.snoozeFor);
  await ref
      .read(sharedPreferencesProvider)
      .setInt(backupReminderSnoozedUntilKey, until.millisecondsSinceEpoch);
  ref
      .read(usageAnalyticsProvider)
      .backupReminder(BackupReminderAction.dismissed);
  ref.invalidate(backupReminderProvider);
}
