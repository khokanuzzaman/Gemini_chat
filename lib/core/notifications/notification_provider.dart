import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/expense_local_datasource.dart';
import '../providers/database_providers.dart';
import '../providers/shared_preferences_provider.dart';
import 'budget_settings.dart';
import 'notification_service.dart';
import 'notification_settings.dart';

const _notificationSettingsKey = 'notification_settings';

final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationSettings>(
      NotificationNotifier.new,
    );

class NotificationNotifier extends Notifier<NotificationSettings> {
  @override
  NotificationSettings build() {
    final prefs = _prefsOrNull();
    if (prefs == null) {
      return NotificationSettings.defaults();
    }

    return NotificationSettings.fromJsonString(
          prefs.getString(_notificationSettingsKey),
        ) ??
        NotificationSettings.defaults();
  }

  Future<void> updateSettings(NotificationSettings settings) async {
    state = settings;
    final prefs = _prefsOrNull();
    if (prefs != null) {
      await prefs.setString(_notificationSettingsKey, settings.toJsonString());
    }
    await _applySettings(settings);
  }

  Future<void> reapplyCurrentSettings() async {
    await _applySettings(state);
  }

  Future<void> _applySettings(NotificationSettings settings) async {
    if (settings.dailyReminderEnabled) {
      await NotificationService.scheduleDailyReminder(
        time: settings.dailyReminderTime,
      );
    } else {
      await NotificationService.cancelDailyReminder();
    }

    if (settings.weeklyReportEnabled) {
      await NotificationService.scheduleWeeklyReport();
    } else {
      await NotificationService.cancelWeeklyReport();
    }
  }

  Future<void> checkBudgetAlert(String category) async {
    if (!state.budgetAlertEnabled) {
      return;
    }

    final expenseDataSource = _expenseDataSourceOrNull();
    if (expenseDataSource == null) {
      return;
    }

    final budget = ref.read(budgetProvider).categoryBudgets[category];
    if (budget == null || budget <= 0) {
      return;
    }

    final spent = await _getMonthlySpending(category, expenseDataSource);
    final percentage = (spent / budget) * 100;
    if (percentage < state.budgetAlertThreshold) {
      return;
    }

    await NotificationService.showBudgetAlert(
      category: category,
      spent: spent,
      budget: budget,
      percentage: percentage,
    );
  }

  Future<double> _getMonthlySpending(
    String category,
    ExpenseLocalDataSource expenseDataSource,
  ) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(
      now.year,
      now.month + 1,
      1,
    ).subtract(const Duration(milliseconds: 1));
    final totals = await expenseDataSource.getCategoryTotals(start, end);
    return totals[category] ?? 0;
  }

  SharedPreferences? _prefsOrNull() {
    try {
      return ref.read(sharedPreferencesProvider);
    } on UnimplementedError {
      return null;
    }
  }

  ExpenseLocalDataSource? _expenseDataSourceOrNull() {
    try {
      return ref.read(expenseLocalDataSourceProvider);
    } on UnimplementedError {
      return null;
    }
  }
}
