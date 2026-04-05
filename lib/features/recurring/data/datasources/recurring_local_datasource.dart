import 'package:isar/isar.dart';

import '../../../../core/database/models/recurring_expense_model.dart';

class RecurringLocalDataSource {
  const RecurringLocalDataSource(this._isar);

  final Isar _isar;

  Future<List<RecurringExpenseModel>> getAllPatterns() {
    return _isar.recurringExpenseModels.where().findAll();
  }

  Future<void> savePatterns(List<RecurringExpenseModel> models) async {
    await _isar.writeTxn(() async {
      await _isar.recurringExpenseModels.clear();
      if (models.isNotEmpty) {
        await _isar.recurringExpenseModels.putAll(models);
      }
    });
  }

  Future<void> updatePattern(RecurringExpenseModel model) async {
    await _isar.writeTxn(() async {
      await _isar.recurringExpenseModels.put(model);
    });
  }
}
