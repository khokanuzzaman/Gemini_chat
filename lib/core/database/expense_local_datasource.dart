import 'package:isar/isar.dart';

import 'models/expense_record_model.dart';

class ExpenseLocalDataSource {
  const ExpenseLocalDataSource(this._isar);

  final Isar _isar;

  Future<void> seedIfNeeded() async {
    final existingCount = await _isar.expenseRecordModels.count();
    if (existingCount > 0) {
      return;
    }

    final now = DateTime.now();
    final expenses = <ExpenseRecordModel>[
      _buildExpense(
        amount: 180,
        category: 'Food',
        description: 'সকালের নাস্তা',
        date: _dateForDay(now, 1),
      ),
      _buildExpense(
        amount: 60,
        category: 'Transport',
        description: 'রিকশা ভাড়া',
        date: _dateForDay(now, 3),
      ),
      _buildExpense(
        amount: 250,
        category: 'Food',
        description: 'দুপুরের খাবার',
        date: _dateForDay(now, 5),
      ),
      _buildExpense(
        amount: 850,
        category: 'Shopping',
        description: 'শার্ট কিনেছি',
        date: _dateForDay(now, 7),
      ),
      _buildExpense(
        amount: 45,
        category: 'Transport',
        description: 'বাস ভাড়া',
        date: _dateForDay(now, 9),
      ),
      _buildExpense(
        amount: 500,
        category: 'Healthcare',
        description: 'ডাক্তার ফি',
        date: _dateForDay(now, 11),
      ),
      _buildExpense(
        amount: 320,
        category: 'Entertainment',
        description: 'সিনেমা দেখা',
        date: _dateForDay(now, 12),
      ),
      _buildExpense(
        amount: 140,
        category: 'Food',
        description: 'চা নাস্তা',
        date: _dateForDay(now, 13),
      ),
      _buildExpense(
        amount: 120,
        category: 'Transport',
        description: 'সিএনজি ভাড়া',
        date: _dateForDay(now, 15),
      ),
      _buildExpense(
        amount: 420,
        category: 'Shopping',
        description: 'বাজারের ব্যাগ',
        date: _dateForDay(now, 17),
      ),
      _buildExpense(
        amount: 1350,
        category: 'Bill',
        description: 'বিদ্যুৎ বিল',
        date: _dateForDay(now, 19),
      ),
      _buildExpense(
        amount: 320,
        category: 'Food',
        description: 'রাতের খাবার',
        date: _dateForDay(now, 21),
      ),
      _buildExpense(
        amount: 80,
        category: 'Transport',
        description: 'মেট্রোরেল ভাড়া',
        date: _dateForDay(now, 23),
      ),
      _buildExpense(
        amount: 180,
        category: 'Healthcare',
        description: 'ওষুধ কিনেছি',
        date: _dateForDay(now, 25),
      ),
      _buildExpense(
        amount: 210,
        category: 'Food',
        description: 'অফিস ক্যান্টিন',
        date: _dateForDay(now, 27),
      ),
      _buildExpense(
        amount: 1200,
        category: 'Shopping',
        description: 'জুতা কিনেছি',
        date: _dateForDay(now, 28),
      ),
    ];

    await _isar.writeTxn(() async {
      await _isar.expenseRecordModels.putAll(expenses);
    });
  }

  Future<List<ExpenseRecordModel>> getCurrentMonthExpenses() {
    return getThisMonthExpenses();
  }

  Future<List<ExpenseRecordModel>> getThisMonthExpenses() {
    final now = DateTime.now();
    return _getExpensesInRange(
      DateTime(now.year, now.month, 1),
      _endOfDay(now),
    );
  }

  Future<List<ExpenseRecordModel>> getLastMonthExpenses() {
    final now = DateTime.now();
    final startOfThisMonth = DateTime(now.year, now.month, 1);
    final start = now.month == 1
        ? DateTime(now.year - 1, 12, 1)
        : DateTime(now.year, now.month - 1, 1);
    return _getExpensesInRange(
      start,
      startOfThisMonth.subtract(const Duration(milliseconds: 1)),
    );
  }

  Future<List<ExpenseRecordModel>> getTodayExpenses() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return _getExpensesInRange(start, _endOfDay(start));
  }

  Future<List<ExpenseRecordModel>> getExpensesByCategory(
    String category,
  ) async {
    final expenses = await _loadAllSortedExpenses();
    return expenses
        .where((expense) => expense.category == category)
        .toList(growable: false);
  }

  Future<List<ExpenseRecordModel>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) {
    final normalizedStart = DateTime(start.year, start.month, start.day);
    return _getExpensesInRange(normalizedStart, _endOfDay(end));
  }

  Future<List<ExpenseRecordModel>> getAllExpenses() {
    return _loadAllSortedExpenses();
  }

  Future<List<ExpenseRecordModel>> getExpensesForMonth(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    return _getExpensesInRange(
      start,
      _startOfNextMonth(start).subtract(const Duration(milliseconds: 1)),
    );
  }

  Future<ExpenseRecordModel> saveExpense(ExpenseRecordModel expense) async {
    await _isar.writeTxn(() async {
      await _isar.expenseRecordModels.put(expense);
    });
    return expense;
  }

  Future<List<ExpenseRecordModel>> saveExpenses(
    List<ExpenseRecordModel> expenses,
  ) async {
    await _isar.writeTxn(() async {
      await _isar.expenseRecordModels.putAll(expenses);
    });
    return expenses;
  }

  Future<bool> deleteExpense(int id) async {
    late bool deleted;
    await _isar.writeTxn(() async {
      deleted = await _isar.expenseRecordModels.delete(id);
    });
    return deleted;
  }

  Future<bool> updateExpense(ExpenseRecordModel expense) async {
    final existingExpense = await _isar.expenseRecordModels.get(expense.id);
    if (existingExpense == null) {
      return false;
    }

    await _isar.writeTxn(() async {
      await _isar.expenseRecordModels.put(expense);
    });
    return true;
  }

  Future<Map<DateTime, double>> getDailyTotals(int days) async {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));
    final expenses = await _getExpensesInRange(start, _endOfDay(now));

    final totals = <DateTime, double>{};
    for (var index = 0; index < days; index++) {
      final day = DateTime(start.year, start.month, start.day + index);
      totals[day] = 0;
    }

    for (final expense in expenses) {
      final day = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      totals.update(
        day,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount.toDouble(),
      );
    }

    return totals;
  }

  Future<Map<String, double>> getCategoryTotals(
    DateTime start,
    DateTime end,
  ) async {
    final expenses = await getExpensesByDateRange(start, end);
    final totals = <String, double>{};

    for (final expense in expenses) {
      totals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount.toDouble(),
      );
    }

    return totals;
  }

  Future<List<ExpenseRecordModel>> _getExpensesInRange(
    DateTime startInclusive,
    DateTime endInclusive,
  ) async {
    final expenses = await _loadAllSortedExpenses();
    return expenses
        .where((expense) {
          return !expense.date.isBefore(startInclusive) &&
              !expense.date.isAfter(endInclusive);
        })
        .toList(growable: false);
  }

  Future<List<ExpenseRecordModel>> _loadAllSortedExpenses() async {
    final expenses = await _isar.expenseRecordModels.where().findAll();
    expenses.sort((first, second) => second.date.compareTo(first.date));
    return expenses;
  }

  ExpenseRecordModel _buildExpense({
    required int amount,
    required String category,
    required String description,
    required DateTime date,
  }) {
    return ExpenseRecordModel()
      ..amount = amount
      ..category = category
      ..description = description
      ..date = date;
  }

  DateTime _dateForDay(DateTime month, int day) {
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0).day;
    final safeDay = day.clamp(1, lastDayOfMonth);
    return DateTime(month.year, month.month, safeDay, 12);
  }

  DateTime _startOfNextMonth(DateTime month) {
    return month.month == 12
        ? DateTime(month.year + 1, 1, 1)
        : DateTime(month.year, month.month + 1, 1);
  }

  DateTime _endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }
}
