import 'package:isar/isar.dart';

import '../../../features/income/domain/entities/income_entity.dart';

part 'income_record_model.g.dart';

@collection
class IncomeRecordModel {
  Id id = Isar.autoIncrement;

  late int amount;
  late String source;
  late String description;
  int? walletId;
  bool isRecurring = false;
  bool isManual = false;
  String? note;

  @Index()
  late DateTime date;

  late DateTime createdAt;

  IncomeEntity toEntity() {
    return IncomeEntity(
      id: id,
      amount: amount.toDouble(),
      source: source,
      description: description,
      date: date,
      walletId: walletId,
      isRecurring: isRecurring,
      isManual: isManual,
      note: note,
      createdAt: createdAt,
    );
  }
}
