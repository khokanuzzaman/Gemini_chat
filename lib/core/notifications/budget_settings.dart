import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/shared_preferences_provider.dart';

const _budgetSettingsKey = 'budget_settings';

class BudgetSettings {
  const BudgetSettings({required this.categoryBudgets});

  final Map<String, double> categoryBudgets;

  factory BudgetSettings.defaults() {
    return const BudgetSettings(
      categoryBudgets: {
        'Food': 5000,
        'Transport': 3000,
        'Shopping': 4000,
        'Healthcare': 2000,
        'Bill': 3000,
        'Entertainment': 2000,
        'Other': 1000,
      },
    );
  }

  factory BudgetSettings.fromJson(Map<String, dynamic> json) {
    final decodedMap = <String, double>{};
    for (final entry in json.entries) {
      final value = entry.value;
      if (value is num) {
        decodedMap[entry.key] = value.toDouble();
      }
    }

    return BudgetSettings(
      categoryBudgets: decodedMap.isEmpty
          ? BudgetSettings.defaults().categoryBudgets
          : decodedMap,
    );
  }

  static BudgetSettings? fromJsonString(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return BudgetSettings.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  BudgetSettings copyWith({Map<String, double>? categoryBudgets}) {
    return BudgetSettings(
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
    );
  }

  double get totalBudget {
    return categoryBudgets.values.fold<double>(0, (sum, value) => sum + value);
  }

  Map<String, dynamic> toJson() {
    return categoryBudgets.map((key, value) => MapEntry(key, value));
  }

  String toJsonString() => jsonEncode(toJson());
}

final budgetProvider = NotifierProvider<BudgetNotifier, BudgetSettings>(
  BudgetNotifier.new,
);

class BudgetNotifier extends Notifier<BudgetSettings> {
  @override
  BudgetSettings build() {
    final prefs = _prefsOrNull();
    if (prefs == null) {
      return BudgetSettings.defaults();
    }

    return BudgetSettings.fromJsonString(prefs.getString(_budgetSettingsKey)) ??
        BudgetSettings.defaults();
  }

  Future<void> updateBudget(String category, double amount) async {
    final sanitizedAmount = amount.isNaN || amount.isNegative ? 0.0 : amount;
    final updatedBudgets = Map<String, double>.from(state.categoryBudgets)
      ..[category] = sanitizedAmount;
    final updatedSettings = state.copyWith(categoryBudgets: updatedBudgets);
    state = updatedSettings;
    await _save(updatedSettings);
  }

  Future<void> saveBudgets(Map<String, double> budgets) async {
    final sanitized = budgets.map(
      (key, value) => MapEntry(key, value.isNegative ? 0.0 : value),
    );
    final updatedSettings = state.copyWith(categoryBudgets: sanitized);
    state = updatedSettings;
    await _save(updatedSettings);
  }

  Future<void> resetDefaults() async {
    final defaults = BudgetSettings.defaults();
    state = defaults;
    await _save(defaults);
  }

  Future<void> _save(BudgetSettings settings) async {
    final prefs = _prefsOrNull();
    if (prefs == null) {
      return;
    }

    await prefs.setString(_budgetSettingsKey, settings.toJsonString());
  }

  SharedPreferences? _prefsOrNull() {
    try {
      return ref.read(sharedPreferencesProvider);
    } on UnimplementedError {
      return null;
    }
  }
}
