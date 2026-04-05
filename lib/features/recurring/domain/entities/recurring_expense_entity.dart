// Feature: Recurring
// Layer: Domain

enum RecurringFrequency { daily, weekly, monthly }

class RecurringExpenseEntity {
  const RecurringExpenseEntity({
    required this.id,
    required this.description,
    required this.category,
    required this.averageAmount,
    required this.frequency,
    required this.dayOfMonth,
    required this.dayOfWeek,
    required this.lastOccurrence,
    required this.nextExpected,
    required this.isActive,
    required this.reminderEnabled,
  });

  final int id;
  final String description;
  final String category;
  final double averageAmount;
  final RecurringFrequency frequency;
  final int dayOfMonth;
  final int dayOfWeek;
  final DateTime lastOccurrence;
  final DateTime? nextExpected;
  final bool isActive;
  final bool reminderEnabled;

  RecurringExpenseEntity copyWith({
    int? id,
    String? description,
    String? category,
    double? averageAmount,
    RecurringFrequency? frequency,
    int? dayOfMonth,
    int? dayOfWeek,
    DateTime? lastOccurrence,
    DateTime? nextExpected,
    bool? isActive,
    bool? reminderEnabled,
  }) {
    return RecurringExpenseEntity(
      id: id ?? this.id,
      description: description ?? this.description,
      category: category ?? this.category,
      averageAmount: averageAmount ?? this.averageAmount,
      frequency: frequency ?? this.frequency,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      lastOccurrence: lastOccurrence ?? this.lastOccurrence,
      nextExpected: nextExpected ?? this.nextExpected,
      isActive: isActive ?? this.isActive,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    );
  }
}
