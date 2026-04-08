import '../entities/income_entity.dart';

abstract class IncomeRepository {
  Future<List<IncomeEntity>> getAllIncome();

  Future<List<IncomeEntity>> getThisMonthIncome();

  Future<List<IncomeEntity>> getLastMonthIncome();

  Future<List<IncomeEntity>> getIncomeForMonth(DateTime month);

  Future<List<IncomeEntity>> getIncomeByDateRange(
    DateTime start,
    DateTime end,
  );

  Future<List<IncomeEntity>> getIncomeByWallet(int walletId);

  Future<List<IncomeEntity>> getIncomeBySource(String source);

  Future<IncomeEntity?> getIncomeById(int id);

  Future<IncomeEntity> saveIncome(IncomeEntity income);

  Future<List<IncomeEntity>> saveIncomeBatch(List<IncomeEntity> incomes);

  Future<void> deleteIncome(int id);

  Future<void> updateIncome(IncomeEntity income);

  Future<double> getTotalIncomeForRange(DateTime start, DateTime end);

  Future<Map<String, double>> getIncomeBySourceTotals(
    DateTime start,
    DateTime end,
  );
}
