import '../entities/expense_entity.dart';
import '../repositories/expense_repository.dart';

class SaveExpenseUseCase {
  const SaveExpenseUseCase(this._repository);

  final ExpenseRepository _repository;

  Future<ExpenseEntity> call(ExpenseEntity expense) {
    return _repository.saveExpense(expense);
  }

  Future<List<ExpenseEntity>> saveMany(List<ExpenseEntity> expenses) {
    return _repository.saveExpenses(expenses);
  }
}
