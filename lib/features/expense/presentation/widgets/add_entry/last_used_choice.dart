import 'package:shared_preferences/shared_preferences.dart';

import 'entry_type.dart';

/// Remembers the last category (খরচ) and last source (আয়) the user saved, so the
/// next entry starts where they usually are. Preferences only, one key per type.
class LastUsedEntryChoice {
  const LastUsedEntryChoice._();

  static const expenseCategoryKey = 'add_entry_last_expense_category';
  static const incomeSourceKey = 'add_entry_last_income_source';

  static String _key(EntryType type) => switch (type) {
    EntryType.expense => expenseCategoryKey,
    EntryType.income => incomeSourceKey,
  };

  static String? read(SharedPreferences prefs, EntryType type) {
    final value = prefs.getString(_key(type));
    return (value == null || value.trim().isEmpty) ? null : value;
  }

  static Future<void> write(
    SharedPreferences prefs,
    EntryType type,
    String value,
  ) async {
    await prefs.setString(_key(type), value);
  }

  /// The remembered choice if it still exists, otherwise [fallback].
  /// (A deleted custom category must not leave the sheet with nothing valid.)
  static String? resolve({
    required String? stored,
    required List<String> available,
    required String? fallback,
  }) {
    if (stored != null && available.contains(stored)) {
      return stored;
    }
    return fallback;
  }

  /// The pre-existing default for খরচ, used when nothing is remembered: Food, else
  /// Other, else the first category.
  static String? defaultExpenseCategory(List<String> names) {
    if (names.isEmpty) {
      return null;
    }
    if (names.contains('Food')) {
      return 'Food';
    }
    return names.contains('Other') ? 'Other' : names.first;
  }
}
