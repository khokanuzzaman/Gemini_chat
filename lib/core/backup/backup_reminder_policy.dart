/// When to nudge "you have data but no recent backup" (free for everyone —
/// losing a year of data is a trust problem, not an upsell).
///
/// Pure: all inputs are passed in, so the thresholds are unit-testable.
class BackupReminderPolicy {
  const BackupReminderPolicy._();

  /// Fewer records than this = nothing much to lose yet.
  static const minRecordsForReminder = 10;

  /// Existing heavy users who have NEVER backed up are nudged sooner.
  static const heavyUserRecords = 30;

  static const staleAfter = Duration(days: 30);
  static const heavyNeverBackedUpAfter = Duration(days: 7);
  static const snoozeFor = Duration(days: 7);
}

class BackupReminderInput {
  const BackupReminderInput({
    required this.now,
    required this.lastBackup,
    required this.firstSeen,
    required this.recordCount,
    required this.hasDebtOrGoal,
    required this.snoozedUntil,
  });

  final DateTime now;

  /// Last SUCCESSFUL backup (manual or auto), null if never.
  final DateTime? lastBackup;

  /// First run of a G2+ build; null if unknown yet.
  final DateTime? firstSeen;

  /// Expense + income records.
  final int recordCount;
  final bool hasDebtOrGoal;
  final DateTime? snoozedUntil;
}

class BackupReminderDecision {
  const BackupReminderDecision({required this.show, this.daysSinceBackup});

  const BackupReminderDecision.hidden() : show = false, daysSinceBackup = null;

  final bool show;

  /// Null when there has never been a backup.
  final int? daysSinceBackup;
}

BackupReminderDecision evaluateBackupReminder(BackupReminderInput input) {
  final hasData =
      input.recordCount >= BackupReminderPolicy.minRecordsForReminder ||
      input.hasDebtOrGoal;
  if (!hasData) {
    return const BackupReminderDecision.hidden();
  }
  final snoozedUntil = input.snoozedUntil;
  if (snoozedUntil != null && input.now.isBefore(snoozedUntil)) {
    return const BackupReminderDecision.hidden();
  }

  final lastBackup = input.lastBackup;
  if (lastBackup != null) {
    // A real backup exists: its true age is what matters, even if it predates
    // the first G2 run.
    final age = input.now.difference(lastBackup);
    return age >= BackupReminderPolicy.staleAfter
        ? BackupReminderDecision(show: true, daysSinceBackup: age.inDays)
        : const BackupReminderDecision.hidden();
  }

  // Never backed up: count from the first time we saw this install.
  final firstSeen = input.firstSeen;
  if (firstSeen == null) {
    return const BackupReminderDecision.hidden();
  }
  final heavy = input.recordCount >= BackupReminderPolicy.heavyUserRecords;
  final threshold = heavy
      ? BackupReminderPolicy.heavyNeverBackedUpAfter
      : BackupReminderPolicy.staleAfter;
  return input.now.difference(firstSeen) >= threshold
      ? const BackupReminderDecision(show: true)
      : const BackupReminderDecision.hidden();
}
