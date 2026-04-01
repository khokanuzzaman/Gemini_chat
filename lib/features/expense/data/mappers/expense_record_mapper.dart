import 'package:isar/isar.dart';

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
    );
  }
}

extension ExpenseEntityMapper on ExpenseEntity {
  ExpenseRecordModel toModel() {
    return ExpenseRecordModel()
      ..id = id ?? Isar.autoIncrement
      ..amount = amount.round()
      ..category = category
      ..description = description
      ..date = date;
  }
}
