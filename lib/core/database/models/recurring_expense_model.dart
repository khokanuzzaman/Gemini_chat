import 'package:isar/isar.dart';

import '../../../features/recurring/domain/entities/recurring_expense_entity.dart';

part 'recurring_expense_model.g.dart';

@collection
class RecurringExpenseModel {
  Id id = Isar.autoIncrement;

  late String description;
  late String category;
  late double averageAmount;
  @enumerated
  late RecurringFrequency frequency;
  late int dayOfMonth;
  late int dayOfWeek;
  late DateTime lastOccurrence;
  DateTime? nextExpected;
  late bool isActive;
  late bool reminderEnabled;

  RecurringExpenseEntity toEntity() {
    return RecurringExpenseEntity(
      id: id,
      description: description,
      category: category,
      averageAmount: averageAmount,
      frequency: frequency,
      dayOfMonth: dayOfMonth,
      dayOfWeek: dayOfWeek,
      lastOccurrence: lastOccurrence,
      nextExpected: nextExpected,
      isActive: isActive,
      reminderEnabled: reminderEnabled,
    );
  }

  static RecurringExpenseModel fromEntity(RecurringExpenseEntity entity) {
    return RecurringExpenseModel()
      ..id = entity.id > 0 ? entity.id : Isar.autoIncrement
      ..description = entity.description
      ..category = entity.category
      ..averageAmount = entity.averageAmount
      ..frequency = entity.frequency
      ..dayOfMonth = entity.dayOfMonth
      ..dayOfWeek = entity.dayOfWeek
      ..lastOccurrence = entity.lastOccurrence
      ..nextExpected = entity.nextExpected
      ..isActive = entity.isActive
      ..reminderEnabled = entity.reminderEnabled;
  }
}
