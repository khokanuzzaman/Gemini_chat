import 'package:isar/isar.dart';

import '../../../../core/database/models/income_record_model.dart';

class IncomeLocalDataSource {
  const IncomeLocalDataSource(this._isar);

  final Isar _isar;

  Future<List<IncomeRecordModel>> getAllIncome() {
    return _loadAllSortedIncome();
  }

  Future<List<IncomeRecordModel>> getThisMonthIncome() {
    final now = DateTime.now();
    return _getIncomeInRange(
      DateTime(now.year, now.month, 1),
      _endOfDay(now),
    );
  }

  Future<List<IncomeRecordModel>> getLastMonthIncome() {
    final now = DateTime.now();
    final startOfThisMonth = DateTime(now.year, now.month, 1);
    final start = now.month == 1
        ? DateTime(now.year - 1, 12, 1)
        : DateTime(now.year, now.month - 1, 1);
    return _getIncomeInRange(
      start,
      startOfThisMonth.subtract(const Duration(milliseconds: 1)),
    );
  }

  Future<List<IncomeRecordModel>> getIncomeForMonth(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    return _getIncomeInRange(
      start,
      _startOfNextMonth(start).subtract(const Duration(milliseconds: 1)),
    );
  }

  Future<List<IncomeRecordModel>> getIncomeByDateRange(
    DateTime start,
    DateTime end,
  ) {
    final normalizedStart = DateTime(start.year, start.month, start.day);
    return _getIncomeInRange(normalizedStart, _endOfDay(end));
  }

  Future<List<IncomeRecordModel>> getIncomeByWallet(int walletId) async {
    final income = await _loadAllSortedIncome();
    return income
        .where((entry) => entry.walletId == walletId)
        .toList(growable: false);
  }

  Future<List<IncomeRecordModel>> getIncomeBySource(String source) async {
    final income = await _loadAllSortedIncome();
    return income
        .where((entry) => entry.source == source)
        .toList(growable: false);
  }

  Future<IncomeRecordModel?> getIncomeById(int id) {
    return _isar.incomeRecordModels.get(id);
  }

  Future<IncomeRecordModel> saveIncome(IncomeRecordModel income) async {
    await _isar.writeTxn(() async {
      await _isar.incomeRecordModels.put(income);
    });
    return income;
  }

  Future<List<IncomeRecordModel>> saveIncomeBatch(
    List<IncomeRecordModel> incomes,
  ) async {
    await _isar.writeTxn(() async {
      await _isar.incomeRecordModels.putAll(incomes);
    });
    return incomes;
  }

  Future<bool> deleteIncome(int id) async {
    late bool deleted;
    await _isar.writeTxn(() async {
      deleted = await _isar.incomeRecordModels.delete(id);
    });
    return deleted;
  }

  Future<bool> updateIncome(IncomeRecordModel income) async {
    final existing = await _isar.incomeRecordModels.get(income.id);
    if (existing == null) {
      return false;
    }

    await _isar.writeTxn(() async {
      await _isar.incomeRecordModels.put(income);
    });
    return true;
  }

  Future<double> getTotalIncomeForRange(
    DateTime start,
    DateTime end,
  ) async {
    final income = await getIncomeByDateRange(start, end);
    return income.fold<double>(
      0,
      (sum, entry) => sum + entry.amount,
    );
  }

  Future<Map<String, double>> getIncomeBySourceTotals(
    DateTime start,
    DateTime end,
  ) async {
    final income = await getIncomeByDateRange(start, end);
    final totals = <String, double>{};
    for (final entry in income) {
      totals.update(
        entry.source,
        (value) => value + entry.amount,
        ifAbsent: () => entry.amount.toDouble(),
      );
    }
    return totals;
  }

  Future<List<IncomeRecordModel>> _getIncomeInRange(
    DateTime startInclusive,
    DateTime endInclusive,
  ) async {
    final income = await _loadAllSortedIncome();
    return income
        .where((entry) {
          return !entry.date.isBefore(startInclusive) &&
              !entry.date.isAfter(endInclusive);
        })
        .toList(growable: false);
  }

  Future<List<IncomeRecordModel>> _loadAllSortedIncome() async {
    final income = await _isar.incomeRecordModels.where().findAll();
    income.sort((first, second) => second.date.compareTo(first.date));
    return income;
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
