import '../../../../core/database/expense_local_datasource.dart';
import '../../../../core/errors/failures.dart';
import '../mappers/expense_record_mapper.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/repositories/expense_repository.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  const ExpenseRepositoryImpl({required ExpenseLocalDataSource localDataSource})
    : _localDataSource = localDataSource;

  final ExpenseLocalDataSource _localDataSource;

  @override
  Future<List<ExpenseEntity>> getAllExpenses() async {
    try {
      final expenses = await _localDataSource.getAllExpenses();
      return expenses
          .map((expense) => expense.toEntity())
          .toList(growable: false);
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<List<ExpenseEntity>> getThisMonthExpenses() async {
    try {
      final expenses = await _localDataSource.getThisMonthExpenses();
      return expenses
          .map((expense) => expense.toEntity())
          .toList(growable: false);
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<List<ExpenseEntity>> getLastMonthExpenses() async {
    try {
      final expenses = await _localDataSource.getLastMonthExpenses();
      return expenses
          .map((expense) => expense.toEntity())
          .toList(growable: false);
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<List<ExpenseEntity>> getTodayExpenses() async {
    try {
      final expenses = await _localDataSource.getTodayExpenses();
      return expenses
          .map((expense) => expense.toEntity())
          .toList(growable: false);
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<List<ExpenseEntity>> getExpensesForMonth(DateTime month) async {
    try {
      final expenses = await _localDataSource.getExpensesForMonth(month);
      return expenses
          .map((expense) => expense.toEntity())
          .toList(growable: false);
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<List<ExpenseEntity>> getExpensesByCategory(String category) async {
    try {
      final expenses = await _localDataSource.getExpensesByCategory(category);
      return expenses
          .map((expense) => expense.toEntity())
          .toList(growable: false);
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<List<ExpenseEntity>> getExpensesByWallet(int walletId) async {
    try {
      final expenses = await _localDataSource.getExpensesByWallet(walletId);
      return expenses
          .map((expense) => expense.toEntity())
          .toList(growable: false);
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<List<ExpenseEntity>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final expenses = await _localDataSource.getExpensesByDateRange(
        start,
        end,
      );
      return expenses
          .map((expense) => expense.toEntity())
          .toList(growable: false);
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<ExpenseEntity> saveExpense(ExpenseEntity expense) async {
    try {
      final savedExpense = await _localDataSource.saveExpense(
        expense.toModel(),
      );
      return savedExpense.toEntity();
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<List<ExpenseEntity>> saveExpenses(List<ExpenseEntity> expenses) async {
    try {
      final savedExpenses = await _localDataSource.saveExpenses(
        expenses.map((expense) => expense.toModel()).toList(growable: false),
      );
      return savedExpenses
          .map((expense) => expense.toEntity())
          .toList(growable: false);
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<void> deleteExpense(int id) async {
    try {
      final deleted = await _localDataSource.deleteExpense(id);
      if (!deleted) {
        throw const StorageFailure('খরচটি খুঁজে পাওয়া যায়নি');
      }
    } catch (error) {
      if (error is Failure) {
        rethrow;
      }
      throw const StorageFailure();
    }
  }

  @override
  Future<void> updateExpense(ExpenseEntity expense) async {
    try {
      final updated = await _localDataSource.updateExpense(expense.toModel());
      if (!updated) {
        throw const StorageFailure('খরচটি খুঁজে পাওয়া যায়নি');
      }
    } catch (error) {
      if (error is Failure) {
        rethrow;
      }
      throw const StorageFailure();
    }
  }

  @override
  Future<Map<DateTime, double>> getDailyTotals(int days) async {
    try {
      return _localDataSource.getDailyTotals(days);
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<Map<String, double>> getCategoryTotals(
    DateTime start,
    DateTime end,
  ) async {
    try {
      return _localDataSource.getCategoryTotals(start, end);
    } catch (_) {
      throw const StorageFailure();
    }
  }
}
