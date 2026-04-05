import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/models/recurring_expense_model.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../expense/presentation/providers/expense_providers.dart';
import '../../data/datasources/recurring_local_datasource.dart';
import '../../data/services/recurring_detection_service.dart';
import '../../domain/entities/recurring_expense_entity.dart';

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
    ref.watch(expenseRefreshTokenProvider);
    await _detectAndSave();
    return _loadFromIsar();
  }

  Future<void> reDetect() async {
    await _detectAndSave();
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

  Future<void> _detectAndSave() async {
    final expenses = await ref.read(expenseRepositoryProvider).getAllExpenses();
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    final last90Days = expenses
        .where((expense) => expense.date.isAfter(cutoff))
        .toList(growable: false);
    final detected = await const RecurringDetectionService().detectPatterns(
      last90Days,
    );
    await ref
        .read(recurringLocalDataSourceProvider)
        .savePatterns(
          detected
              .map(RecurringExpenseModel.fromEntity)
              .toList(growable: false),
        );
  }

  Future<List<RecurringExpenseEntity>> _loadFromIsar() async {
    final patterns = await ref
        .read(recurringLocalDataSourceProvider)
        .getAllPatterns();
    final entities =
        patterns.map((pattern) => pattern.toEntity()).toList(growable: false)
          ..sort((first, second) {
            final firstDate = first.nextExpected ?? first.lastOccurrence;
            final secondDate = second.nextExpected ?? second.lastOccurrence;
            return firstDate.compareTo(secondDate);
          });
    return entities;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
