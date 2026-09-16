import '../../../../core/database/models/expense_record_model.dart';
import '../../domain/entities/expense_entity.dart';

extension ExpenseRecordModelMapper on ExpenseRecordModel {
  ExpenseEntity toEntity() {
    return ExpenseEntity(
      id: id,
      amount: amount.toDouble(),
      category: category,
      description: description,
      date: date,
      walletId: walletId,
      isManual: isManual,
      sourceType: sourceType,
      sourceId: sourceId,
    );
  }
}

extension ExpenseEntityMapper on ExpenseEntity {
  ExpenseRecordModel toModel() {
    final model = ExpenseRecordModel()
      ..amount = amount.round()
      ..category = category
      ..description = description
      ..walletId = walletId
      ..isManual = isManual
      ..date = date
      ..sourceType = sourceType
      ..sourceId = sourceId;
    if (id != null && id! > 0) {
      model.id = id!;
    }
    return model;
  }
}
