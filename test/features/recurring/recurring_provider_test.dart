import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/core/database/models/recurring_expense_model.dart';
import 'package:gemini_chat/features/expense/domain/entities/expense_entity.dart';
import 'package:gemini_chat/features/recurring/data/datasources/recurring_local_datasource.dart';
import 'package:gemini_chat/features/recurring/domain/entities/recurring_expense_entity.dart';
import 'package:gemini_chat/features/recurring/presentation/providers/recurring_provider.dart';

/// In-memory stand-in that records whether the (now-dead) auto-detection path
/// ever runs — savePatterns is only called by detection.
class _FakeRecurringDataSource implements RecurringLocalDataSource {
  final List<RecurringExpenseModel> store = [];
  int savePatternsCalls = 0;
  int _nextId = 1;

  @override
  Future<List<RecurringExpenseModel>> getAllPatterns() async => List.of(store);

  @override
  Future<void> savePatterns(List<RecurringExpenseModel> models) async {
    savePatternsCalls++;
    store
      ..clear()
      ..addAll(models);
  }

  @override
  Future<void> updatePattern(RecurringExpenseModel model) async {
    final index = store.indexWhere((item) => item.id == model.id);
    if (index >= 0) {
      store[index] = model;
    } else {
      store.add(model);
    }
  }

  @override
  Future<int> addPattern(RecurringExpenseModel model) async {
    model.id = _nextId++;
    store.add(model);
    return model.id;
  }

  @override
  Future<void> deletePattern(int id) async {
    store.removeWhere((item) => item.id == id);
  }
}

ExpenseEntity _expense({
  String description = 'Netflix',
  String category = 'Bill',
  double amount = 500,
  DateTime? date,
}) {
  return ExpenseEntity(
    amount: amount,
    category: category,
    description: description,
    date: date ?? DateTime(2026, 5, 10),
  );
}

RecurringExpenseModel _existingMarkedEntry() {
  return RecurringExpenseModel.fromEntity(
    RecurringExpenseEntity(
      id: 42,
      description: 'Rent',
      category: 'Bill',
      averageAmount: 10000,
      confidenceScore: 1,
      frequency: RecurringFrequency.monthly,
      dayOfMonth: 1,
      dayOfWeek: 1,
      lastOccurrence: DateTime(2026, 5, 1),
      nextExpected: DateTime(2026, 6, 1),
      isActive: true,
      reminderEnabled: false,
    ),
  );
}

void main() {
  late _FakeRecurringDataSource fake;

  ProviderContainer makeContainer() {
    fake = _FakeRecurringDataSource();
    final container = ProviderContainer(
      overrides: [recurringLocalDataSourceProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test(
    'build() never auto-detects — only loads existing marked entries',
    () async {
      final container = makeContainer();
      fake.store.add(_existingMarkedEntry()); // pre-existing user data

      final result = await container.read(recurringProvider.future);

      expect(
        fake.savePatternsCalls,
        0,
        reason: 'auto-detection must not run on build()',
      );
      expect(result.length, 1);
      expect(result.first.description, 'Rent'); // existing data preserved
    },
  );

  test(
    'markExpenseAsRecurring adds one monthly entry from the expense',
    () async {
      final container = makeContainer();
      await container.read(recurringProvider.future);

      final outcome = await container
          .read(recurringProvider.notifier)
          .markExpenseAsRecurring(_expense());

      expect(outcome, MarkRecurringResult.added);
      expect(fake.store.length, 1);
      expect(fake.store.first.description, 'Netflix');
      expect(fake.store.first.frequency, RecurringFrequency.monthly);
      expect(fake.store.first.dayOfMonth, 10);
      expect(
        fake.savePatternsCalls,
        0,
        reason: 'added via addPattern, never the detection path',
      );
    },
  );

  test(
    'marking the same expense twice de-dupes — no silent duplicate',
    () async {
      final container = makeContainer();
      await container.read(recurringProvider.future);
      final notifier = container.read(recurringProvider.notifier);

      final first = await notifier.markExpenseAsRecurring(_expense());
      final second = await notifier.markExpenseAsRecurring(_expense());

      expect(first, MarkRecurringResult.added);
      expect(second, MarkRecurringResult.alreadyExists);
      expect(fake.store.length, 1);
    },
  );
}
