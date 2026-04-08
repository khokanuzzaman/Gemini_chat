import '../../../../core/errors/failures.dart';
import '../datasources/income_local_datasource.dart';
import '../mappers/income_record_mapper.dart';
import '../../domain/entities/income_entity.dart';
import '../../domain/repositories/income_repository.dart';

class IncomeRepositoryImpl implements IncomeRepository {
  const IncomeRepositoryImpl({required IncomeLocalDataSource localDataSource})
    : _localDataSource = localDataSource;

  final IncomeLocalDataSource _localDataSource;

  @override
  Future<List<IncomeEntity>> getAllIncome() async {
    try {
      final income = await _localDataSource.getAllIncome();
      return income
          .map((entry) => entry.toEntity())
          .toList(growable: false);
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<List<IncomeEntity>> getThisMonthIncome() async {
    try {
      final income = await _localDataSource.getThisMonthIncome();
      return income
          .map((entry) => entry.toEntity())
          .toList(growable: false);
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<List<IncomeEntity>> getLastMonthIncome() async {
    try {
      final income = await _localDataSource.getLastMonthIncome();
      return income
          .map((entry) => entry.toEntity())
          .toList(growable: false);
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<List<IncomeEntity>> getIncomeForMonth(DateTime month) async {
    try {
      final income = await _localDataSource.getIncomeForMonth(month);
      return income
          .map((entry) => entry.toEntity())
          .toList(growable: false);
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<List<IncomeEntity>> getIncomeByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final income = await _localDataSource.getIncomeByDateRange(start, end);
      return income
          .map((entry) => entry.toEntity())
          .toList(growable: false);
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<List<IncomeEntity>> getIncomeByWallet(int walletId) async {
    try {
      final income = await _localDataSource.getIncomeByWallet(walletId);
      return income
          .map((entry) => entry.toEntity())
          .toList(growable: false);
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<List<IncomeEntity>> getIncomeBySource(String source) async {
    try {
      final income = await _localDataSource.getIncomeBySource(source);
      return income
          .map((entry) => entry.toEntity())
          .toList(growable: false);
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<IncomeEntity?> getIncomeById(int id) async {
    try {
      final income = await _localDataSource.getIncomeById(id);
      return income?.toEntity();
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<IncomeEntity> saveIncome(IncomeEntity income) async {
    try {
      final savedIncome = await _localDataSource.saveIncome(income.toModel());
      return savedIncome.toEntity();
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<List<IncomeEntity>> saveIncomeBatch(
    List<IncomeEntity> incomes,
  ) async {
    try {
      final savedIncome = await _localDataSource.saveIncomeBatch(
        incomes.map((entry) => entry.toModel()).toList(growable: false),
      );
      return savedIncome
          .map((entry) => entry.toEntity())
          .toList(growable: false);
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<void> deleteIncome(int id) async {
    try {
      final deleted = await _localDataSource.deleteIncome(id);
      if (!deleted) {
        throw const StorageFailure('আয়টি খুঁজে পাওয়া যায়নি');
      }
    } catch (error) {
      if (error is Failure) {
        rethrow;
      }
      throw const StorageFailure();
    }
  }

  @override
  Future<void> updateIncome(IncomeEntity income) async {
    try {
      final updated = await _localDataSource.updateIncome(income.toModel());
      if (!updated) {
        throw const StorageFailure('আয়টি খুঁজে পাওয়া যায়নি');
      }
    } catch (error) {
      if (error is Failure) {
        rethrow;
      }
      throw const StorageFailure();
    }
  }

  @override
  Future<double> getTotalIncomeForRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      return _localDataSource.getTotalIncomeForRange(start, end);
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<Map<String, double>> getIncomeBySourceTotals(
    DateTime start,
    DateTime end,
  ) async {
    try {
      return _localDataSource.getIncomeBySourceTotals(start, end);
    } catch (_) {
      throw const StorageFailure();
    }
  }
}
