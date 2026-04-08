import '../entities/expense_entity.dart';
import '../entities/expense_list_filter.dart';
import '../repositories/expense_repository.dart';

class GetExpenseListUseCase {
  const GetExpenseListUseCase(this._repository);

  final ExpenseRepository _repository;

  Future<List<ExpenseEntity>> call(ExpenseListFilter filter) async {
    var expenses = await _repository.getAllExpenses();

    if (filter.category != null && filter.category!.isNotEmpty) {
      expenses = expenses
          .where((expense) => expense.category == filter.category)
          .toList(growable: false);
    }

    if (filter.walletId != null) {
      expenses = expenses
          .where((expense) => expense.walletId == filter.walletId)
          .toList(growable: false);
    }

    if (filter.hasDateRange) {
      final start = DateTime(
        filter.startDate!.year,
        filter.startDate!.month,
        filter.startDate!.day,
      );
      final endExclusive = DateTime(
        filter.endDate!.year,
        filter.endDate!.month,
        filter.endDate!.day + 1,
      );
      expenses = expenses
          .where((expense) {
            return !expense.date.isBefore(start) &&
                expense.date.isBefore(endExclusive);
          })
          .toList(growable: false);
    }

    expenses = [...expenses]..sort((a, b) => b.date.compareTo(a.date));
    return expenses;
  }
}
