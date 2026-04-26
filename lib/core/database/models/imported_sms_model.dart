import 'package:isar_community/isar.dart';

part 'imported_sms_model.g.dart';

@collection
class ImportedSmsModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String signature;

  late String sender;

  @Index()
  late DateTime smsDate;

  @Index()
  late DateTime importedAt;

  int? expenseId;
  int? incomeId;
}
