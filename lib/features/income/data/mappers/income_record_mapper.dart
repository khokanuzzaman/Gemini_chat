import '../../../../core/database/models/income_record_model.dart';
import '../../domain/entities/income_entity.dart';

extension IncomeEntityMapper on IncomeEntity {
  IncomeRecordModel toModel() {
    final model = IncomeRecordModel()
      ..amount = amount.round()
      ..source = source
      ..description = description
      ..walletId = walletId
      ..isRecurring = isRecurring
      ..isManual = isManual
      ..note = note
      ..date = date
      ..createdAt = createdAt;
    if (id != null && id! > 0) {
      model.id = id!;
    }
    return model;
  }
}
