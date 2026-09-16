import 'package:isar_community/isar.dart';

import '../../../features/expense/domain/entities/expense_source.dart';

part 'expense_record_model.g.dart';

@collection
class ExpenseRecordModel {
  Id id = Isar.autoIncrement;

  late int amount;
  late String category;
  late String description;
  int? walletId;
  bool isManual = false;

  @Index()
  late DateTime date;

  /// Origin/kind of this record. Legacy rows (written before this field existed)
  /// deserialize to index 0 = [ExpenseSource.expense]. See ExpenseSource.
  @enumerated
  ExpenseSource sourceType = ExpenseSource.expense;

  /// Back-link to the originating row when [sourceType] is not `expense`
  /// (e.g. DebtPaymentModel.id / GoalSavingModel.id). Null for ordinary expenses.
  int? sourceId;
}
