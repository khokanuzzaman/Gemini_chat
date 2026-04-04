import 'package:isar/isar.dart';

part 'expense_record_model.g.dart';

@collection
class ExpenseRecordModel {
  Id id = Isar.autoIncrement;

  late int amount;
  late String category;
  late String description;
  bool isManual = false;

  @Index()
  late DateTime date;
}
