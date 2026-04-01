import '../repositories/expense_repository.dart';

class DeleteExpenseUseCase {
  const DeleteExpenseUseCase(this._repository);

  final ExpenseRepository _repository;

  Future<void> call(int id) {
    return _repository.deleteExpense(id);
  }
}
