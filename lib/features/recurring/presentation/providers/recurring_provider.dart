import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/models/recurring_expense_model.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../expense/domain/entities/expense_entity.dart';
import '../../data/datasources/recurring_local_datasource.dart';
import '../../domain/entities/recurring_expense_entity.dart';
import '../../domain/recurring_schedule.dart';

/// Outcome of [RecurringNotifier.markExpenseAsRecurring].
enum MarkRecurringResult { added, alreadyExists }

final recurringLocalDataSourceProvider = Provider<RecurringLocalDataSource>((
  ref,
) {
  return RecurringLocalDataSource(ref.watch(isarProvider));
});

final recurringProvider =
    AsyncNotifierProvider<RecurringNotifier, List<RecurringExpenseEntity>>(
      RecurringNotifier.new,
    );

class RecurringNotifier extends AsyncNotifier<List<RecurringExpenseEntity>> {
  @override
  Future<List<RecurringExpenseEntity>> build() async {
    // Opt-in (Phase 1): recurring entries exist only when the user explicitly
    // marks an expense recurring. build() never auto-detects — it just loads
    // whatever the user has already marked. (The RecurringDetectionService is
    // kept but dead-ended; see CONTRIBUTING.)
    return _loadFromIsar();
  }

  Future<void> reload() async {
    state = AsyncData(await _loadFromIsar());
  }

  /// Marks [expense] as a recurring (monthly) expense. De-dupes: if an
  /// equivalent recurring entry already exists (same description, category and
  /// day-of-month), it is a no-op and returns [MarkRecurringResult.alreadyExists]
  /// so the caller can give clear feedback — no silent duplicate is created.
  Future<MarkRecurringResult> markExpenseAsRecurring(
    ExpenseEntity expense,
  ) async {
    final existing = await _loadFromIsar();
    final normalizedDescription = expense.description.trim().toLowerCase();
    final normalizedCategory = expense.category.trim().toLowerCase();
    final isDuplicate = existing.any(
      (item) =>
          item.frequency == RecurringFrequency.monthly &&
          item.dayOfMonth == expense.date.day &&
          item.description.trim().toLowerCase() == normalizedDescription &&
          item.category.trim().toLowerCase() == normalizedCategory,
    );
    if (isDuplicate) {
      return MarkRecurringResult.alreadyExists;
    }

    final entity = RecurringExpenseEntity(
      id: 0,
      description: expense.description,
      category: expense.category,
      averageAmount: expense.amount,
      confidenceScore: 1,
      frequency: RecurringFrequency.monthly,
      dayOfMonth: expense.date.day,
      dayOfWeek: expense.date.weekday,
      lastOccurrence: expense.date,
      nextExpected: _nextMonthSameDay(expense.date),
      isActive: true,
      reminderEnabled: false,
    );
    await ref
        .read(recurringLocalDataSourceProvider)
        .addPattern(RecurringExpenseModel.fromEntity(entity));
    state = AsyncData(await _loadFromIsar());
    return MarkRecurringResult.added;
  }

  Future<void> removePattern(int id) async {
    await ref.read(recurringLocalDataSourceProvider).deletePattern(id);
    state = AsyncData(await _loadFromIsar());
  }

  Future<void> toggleReminder(int id, bool enabled) async {
    final current = await _loadFromIsar();
    final target = current.where((item) => item.id == id).firstOrNull;
    if (target == null) {
      return;
    }
    final updated = target.copyWith(reminderEnabled: enabled);
    await ref
        .read(recurringLocalDataSourceProvider)
        .updatePattern(RecurringExpenseModel.fromEntity(updated));
    state = AsyncData(await _loadFromIsar());
  }

  DateTime _nextMonthSameDay(DateTime date) {
    final year = date.month == 12 ? date.year + 1 : date.year;
    final month = date.month == 12 ? 1 : date.month + 1;
    // Clamp the day to the target month's length (e.g. Jan 31 -> Feb 28/29).
    final lastDayOfMonth = DateTime(year, month + 1, 0).day;
    final day = date.day > lastDayOfMonth ? lastDayOfMonth : date.day;
    return DateTime(year, month, day);
  }

  Future<List<RecurringExpenseEntity>> _loadFromIsar() async {
    final patterns = await ref
        .read(recurringLocalDataSourceProvider)
        .getAllPatterns();
    final today = DateTime.now();
    final entities =
        patterns.map((pattern) => pattern.toEntity()).toList(growable: false)
          ..sort(
            (first, second) => nextDueDate(
              first,
              today: today,
            ).compareTo(nextDueDate(second, today: today)),
          );
    return entities;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
