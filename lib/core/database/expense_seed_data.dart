import 'package:shared_preferences/shared_preferences.dart';

import 'expense_local_datasource.dart';
import 'models/expense_record_model.dart';

class ExpenseSeedData {
  ExpenseSeedData._();

  static const _seededKey = 'seeded';

  static Future<void> seedIfNeeded(ExpenseLocalDataSource dataSource) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadySeeded = prefs.getBool(_seededKey) ?? false;
    final existingExpenses = await dataSource.getAllExpenses();
    if (alreadySeeded || existingExpenses.isNotEmpty) {
      if (!alreadySeeded) {
        await prefs.setBool(_seededKey, true);
      }
      return;
    }

    final now = DateTime.now();
    final expenses = <ExpenseRecordModel>[
      _expense(now, 1, 30, 'Food', 'নাস্তা'),
      _expense(now, 2, 150, 'Food', 'লাঞ্চ'),
      _expense(now, 3, 200, 'Food', 'ডিনার'),
      _expense(now, 4, 20, 'Food', 'চা'),
      _expense(now, 5, 60, 'Transport', 'রিকশা'),
      _expense(now, 6, 30, 'Transport', 'বাস ভাড়া'),
      _expense(now, 7, 150, 'Transport', 'উবার'),
      _expense(now, 8, 500, 'Shopping', 'বাজার'),
      _expense(now, 9, 800, 'Shopping', 'কাপড়'),
      _expense(now, 10, 1200, 'Bill', 'বিদ্যুৎ বিল'),
      _expense(now, 11, 500, 'Bill', 'ইন্টারনেট বিল'),
      _expense(now, 12, 200, 'Healthcare', 'ওষুধ'),
      _expense(now, 13, 500, 'Healthcare', 'ডাক্তার ফি'),
      _expense(now, 14, 90, 'Entertainment', 'সিনেমা'),
      _expense(now, 15, 120, 'Food', 'বিকেলের নাস্তা'),
      _expense(now, 16, 45, 'Transport', 'সিএনজি শেয়ার'),
      _expense(now, 18, 350, 'Shopping', 'মুদিখানা'),
      _expense(now, 20, 220, 'Food', 'রাতের খাবার'),
      _expense(now, 23, 650, 'Shopping', 'মাছ'),
      _expense(now, 26, 300, 'Food', 'বিরিয়ানি'),
    ];

    await dataSource.saveExpenses(expenses);
    await prefs.setBool(_seededKey, true);
  }

  static Future<void> forceSeed(ExpenseLocalDataSource dataSource) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final expenses = <ExpenseRecordModel>[
      _expense(now, 1, 30, 'Food', 'নাস্তা'),
      _expense(now, 2, 150, 'Food', 'লাঞ্চ'),
      _expense(now, 3, 200, 'Food', 'ডিনার'),
      _expense(now, 4, 20, 'Food', 'চা'),
      _expense(now, 5, 60, 'Transport', 'রিকশা'),
      _expense(now, 6, 30, 'Transport', 'বাস ভাড়া'),
      _expense(now, 7, 150, 'Transport', 'উবার'),
      _expense(now, 8, 500, 'Shopping', 'বাজার'),
      _expense(now, 9, 800, 'Shopping', 'কাপড়'),
      _expense(now, 10, 1200, 'Bill', 'বিদ্যুৎ বিল'),
      _expense(now, 11, 500, 'Bill', 'ইন্টারনেট বিল'),
      _expense(now, 12, 200, 'Healthcare', 'ওষুধ'),
      _expense(now, 13, 500, 'Healthcare', 'ডাক্তার ফি'),
      _expense(now, 14, 90, 'Entertainment', 'সিনেমা'),
      _expense(now, 15, 120, 'Food', 'বিকেলের নাস্তা'),
      _expense(now, 16, 45, 'Transport', 'সিএনজি শেয়ার'),
      _expense(now, 18, 350, 'Shopping', 'মুদিখানা'),
      _expense(now, 20, 220, 'Food', 'রাতের খাবার'),
      _expense(now, 23, 650, 'Shopping', 'মাছ'),
      _expense(now, 26, 300, 'Food', 'বিরিয়ানি'),
    ];
    await dataSource.saveExpenses(expenses);
    await prefs.setBool(_seededKey, true);
  }

  static ExpenseRecordModel _expense(
    DateTime now,
    int day,
    int amount,
    String category,
    String description,
  ) {
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final safeDay = day.clamp(1, lastDay);
    return ExpenseRecordModel()
      ..amount = amount
      ..category = category
      ..description = description
      ..date = DateTime(now.year, now.month, safeDay, 12);
  }
}
