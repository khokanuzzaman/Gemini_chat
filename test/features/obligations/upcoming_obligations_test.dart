import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/features/debt/domain/entities/debt_entity.dart';
import 'package:gemini_chat/features/debt/presentation/providers/debt_providers.dart';
import 'package:gemini_chat/features/obligations/domain/upcoming_obligation.dart';
import 'package:gemini_chat/features/obligations/presentation/providers/upcoming_obligations_provider.dart';
import 'package:gemini_chat/features/recurring/domain/entities/recurring_expense_entity.dart';
import 'package:gemini_chat/features/recurring/presentation/providers/recurring_provider.dart';

RecurringExpenseEntity _recurring({
  int id = 1,
  String description = 'বাড়িভাড়া',
  String category = 'Housing',
  double amount = 15000,
  RecurringFrequency frequency = RecurringFrequency.monthly,
  int dayOfMonth = 16,
  int dayOfWeek = 1,
  DateTime? lastOccurrence,
  bool isActive = true,
  DateTime? nextExpected,
}) {
  return RecurringExpenseEntity(
    id: id,
    description: description,
    category: category,
    averageAmount: amount,
    confidenceScore: 1,
    frequency: frequency,
    dayOfMonth: dayOfMonth,
    dayOfWeek: dayOfWeek,
    lastOccurrence: lastOccurrence ?? DateTime(2026, 1, 16),
    nextExpected: nextExpected,
    isActive: isActive,
    reminderEnabled: false,
  );
}

DebtEntity _debt({
  int id = 1,
  String name = 'City Bank',
  DebtType type = DebtType.iOwe,
  DebtStatus status = DebtStatus.active,
  bool isEmi = true,
  double emiAmount = 5000,
  double remaining = 50000,
  DateTime? nextInstallment,
  DateTime? dueDate,
  int total = 12,
  int paid = 2,
}) {
  return DebtEntity(
    id: id,
    personName: name,
    type: type,
    originalAmount: 60000,
    remainingAmount: remaining,
    status: status,
    createdAt: DateTime(2026, 1, 1),
    dueDate: dueDate,
    isEMI: isEmi,
    emiAmount: isEmi ? emiAmount : 0,
    totalInstallments: isEmi ? total : 0,
    paidInstallments: isEmi ? paid : 0,
    nextInstallmentDate: nextInstallment,
  );
}

UpcomingObligations _merge(
  DateTime today, {
  List<RecurringExpenseEntity> recurring = const [],
  List<DebtEntity> debts = const [],
  int windowDays = 30,
}) {
  return mergeUpcomingObligations(
    today: today,
    recurring: recurring,
    debts: debts,
    windowDays: windowDays,
  );
}

void main() {
  final today = DateTime(2026, 10, 6, 15, 30); // time of day must not matter

  group('monthly dates, including day-31 rollover', () {
    DateTime next(DateTime t, int day, {DateTime? last}) =>
        nextMonthlyOccurrence(
          today: t,
          dayOfMonth: day,
          lastOccurrence: last ?? DateTime(2020, 1, 1),
        );

    test('later this month, today itself, or next month', () {
      expect(next(DateTime(2026, 10, 6), 16), DateTime(2026, 10, 16));
      expect(
        next(DateTime(2026, 10, 16), 16),
        DateTime(2026, 10, 16),
        reason: 'due today still counts',
      );
      expect(next(DateTime(2026, 10, 17), 16), DateTime(2026, 11, 16));
    });

    test('day 31 clamps to the month length and never drifts to the 28th', () {
      expect(next(DateTime(2026, 4, 15), 31), DateTime(2026, 4, 30));
      expect(next(DateTime(2026, 4, 30), 31), DateTime(2026, 4, 30));
      expect(next(DateTime(2026, 5, 1), 31), DateTime(2026, 5, 31));
      expect(next(DateTime(2026, 2, 10), 31), DateTime(2026, 2, 28));
      expect(
        next(DateTime(2026, 3, 1), 31),
        DateTime(2026, 3, 31),
        reason: 'March is 31 again — the original day is kept',
      );
    });

    test('February in a leap year', () {
      expect(next(DateTime(2028, 2, 10), 31), DateTime(2028, 2, 29));
      expect(next(DateTime(2028, 2, 10), 30), DateTime(2028, 2, 29));
      expect(next(DateTime(2027, 2, 10), 29), DateTime(2027, 2, 28));
    });

    test('rolls over the year boundary', () {
      expect(next(DateTime(2026, 12, 20), 5), DateTime(2027, 1, 5));
      expect(next(DateTime(2026, 12, 31), 31), DateTime(2026, 12, 31));
      expect(next(DateTime(2027, 1, 1), 31), DateTime(2027, 1, 31));
    });

    test('a future-dated entry does not fire before its own date', () {
      expect(
        next(DateTime(2026, 10, 6), 16, last: DateTime(2026, 10, 16)),
        DateTime(2026, 11, 16),
      );
    });

    test('a bad dayOfMonth falls back to the last occurrence\'s day', () {
      expect(
        next(DateTime(2026, 10, 6), 0, last: DateTime(2026, 9, 20)),
        DateTime(2026, 10, 20),
      );
    });

    test('the stale stored nextExpected is ignored', () {
      final result = _merge(
        today,
        recurring: [
          _recurring(dayOfMonth: 16, nextExpected: DateTime(2026, 2, 16)),
        ],
      );
      expect(result.items.single.dueDate, DateTime(2026, 10, 16));
    });
  });

  group('weekly dates', () {
    test('next matching weekday, today included, never before last', () {
      // 2026-10-06 is a Tuesday (weekday 2).
      expect(
        nextWeeklyOccurrence(
          today: DateTime(2026, 10, 6),
          dayOfWeek: 2,
          lastOccurrence: DateTime(2026, 9, 29),
        ),
        DateTime(2026, 10, 6),
      );
      expect(
        nextWeeklyOccurrence(
          today: DateTime(2026, 10, 6),
          dayOfWeek: 1,
          lastOccurrence: DateTime(2026, 9, 28),
        ),
        DateTime(2026, 10, 12),
      );
      expect(
        nextWeeklyOccurrence(
          today: DateTime(2026, 10, 6),
          dayOfWeek: 2,
          lastOccurrence: DateTime(2026, 10, 6),
        ),
        DateTime(2026, 10, 13),
      );
    });
  });

  group('window, filters, order', () {
    test('only the next 30 days; 31 days out is excluded, day 30 included', () {
      final result = _merge(
        DateTime(2026, 10, 6),
        recurring: [
          _recurring(id: 1, dayOfMonth: 6), // today
          _recurring(
            id: 2,
            description: 'ঠিক ৩০',
            dayOfMonth: 5,
          ), // Nov 5 = +30
          _recurring(
            id: 3,
            description: 'বাইরে',
            dayOfMonth: 6,
            frequency: RecurringFrequency.monthly,
            lastOccurrence: DateTime(2026, 10, 6),
          ), // Nov 6 = +31
        ],
      );
      expect(result.items.map((i) => i.sourceId), [1, 2]);
    });

    test('inactive and daily recurring entries are not obligations', () {
      final result = _merge(
        today,
        recurring: [
          _recurring(id: 1, isActive: false),
          _recurring(id: 2, frequency: RecurringFrequency.daily),
          _recurring(id: 3),
        ],
      );
      expect(result.items.map((i) => i.sourceId), [3]);
    });

    test('debts: only money I owe, open, with a date', () {
      final result = _merge(
        today,
        debts: [
          _debt(id: 1, nextInstallment: DateTime(2026, 10, 10)),
          _debt(
            id: 2,
            type: DebtType.theyOwe,
            nextInstallment: DateTime(2026, 10, 10),
          ),
          _debt(
            id: 3,
            status: DebtStatus.settled,
            nextInstallment: DateTime(2026, 10, 10),
          ),
          _debt(
            id: 4,
            status: DebtStatus.cancelled,
            nextInstallment: DateTime(2026, 10, 10),
          ),
          _debt(id: 5, nextInstallment: null),
          _debt(id: 6, remaining: 0, nextInstallment: DateTime(2026, 10, 10)),
          _debt(
            id: 7,
            nextInstallment: DateTime(2026, 12, 25),
          ), // beyond window
        ],
      );
      expect(result.items.map((i) => i.sourceId), [1]);
      expect(result.items.single.isEmi, isTrue);
      expect(result.items.single.amount, 5000);
    });

    test(
      'a plain (non-EMI) debt uses its due date and the remaining amount',
      () {
        final result = _merge(
          today,
          debts: [
            _debt(
              id: 9,
              name: 'রহিম',
              isEmi: false,
              remaining: 8000,
              dueDate: DateTime(2026, 10, 20),
            ),
          ],
        );
        final item = result.items.single;
        expect(item.dueDate, DateTime(2026, 10, 20));
        expect(item.amount, 8000);
        expect(item.isEmi, isFalse);
      },
    );

    test('overdue debts stay, are flagged, and sort first however late', () {
      final result = _merge(
        today,
        recurring: [_recurring(id: 1, dayOfMonth: 7)],
        debts: [
          _debt(
            id: 2,
            nextInstallment: DateTime(2026, 8, 1),
            status: DebtStatus.overdue,
          ),
          _debt(id: 3, name: 'Bank B', nextInstallment: DateTime(2026, 10, 5)),
        ],
      );
      expect(result.items.map((i) => (i.sourceId, i.isOverdue)), [
        (2, true),
        (3, true),
        (1, false),
      ]);
      expect(result.overdueCount, 2);
    });

    test(
      'sorted by date; same day -> bigger amount first; fully deterministic',
      () {
        final result = _merge(
          today,
          recurring: [
            _recurring(id: 1, description: 'ছোট', amount: 100, dayOfMonth: 16),
            _recurring(id: 2, description: 'বড়', amount: 900, dayOfMonth: 16),
            _recurring(id: 3, description: 'আগে', amount: 50, dayOfMonth: 9),
          ],
        );
        expect(result.items.map((i) => i.sourceId), [3, 2, 1]);
        expect(result.next!.sourceId, 3);
        expect(result.totalAmount, 1050);
        final again = _merge(
          today,
          recurring: [
            _recurring(id: 3, description: 'আগে', amount: 50, dayOfMonth: 9),
            _recurring(id: 1, description: 'ছোট', amount: 100, dayOfMonth: 16),
            _recurring(id: 2, description: 'বড়', amount: 900, dayOfMonth: 16),
          ],
        );
        expect(again.items.map((i) => i.sourceId), [
          3,
          2,
          1,
        ], reason: 'input order must not matter');
      },
    );

    test('empty inputs -> empty result', () {
      final result = _merge(today);
      expect(result.isEmpty, isTrue);
      expect(result.next, isNull);
      expect(result.totalAmount, 0);
    });
  });

  group('de-dup: an EMI payment marked recurring appears once', () {
    // The ledger writes the EMI payment expense as category "EMI",
    // description = the debt's person name; "mark as recurring" copies both.
    test('recurring EMI entry is dropped, the debt instalment wins', () {
      final result = _merge(
        today,
        recurring: [
          _recurring(
            id: 7,
            description: 'City Bank',
            category: 'EMI',
            amount: 5000,
            dayOfMonth: 10,
          ),
        ],
        debts: [
          _debt(
            id: 1,
            name: 'City Bank',
            nextInstallment: DateTime(2026, 10, 10),
          ),
        ],
      );
      expect(result.items, hasLength(1));
      expect(result.items.single.kind, ObligationKind.debt);
    });

    test('matching ignores case and surrounding spaces', () {
      final result = _merge(
        today,
        recurring: [
          _recurring(id: 7, description: '  city BANK ', category: 'emi'),
        ],
        debts: [
          _debt(
            id: 1,
            name: 'City Bank',
            nextInstallment: DateTime(2026, 10, 10),
          ),
        ],
      );
      expect(result.items.map((i) => i.kind), [ObligationKind.debt]);
    });

    test('an untitled EMI debt ("EMI") matches an untitled recurring EMI', () {
      final result = _merge(
        today,
        recurring: [_recurring(id: 7, description: 'EMI', category: 'EMI')],
        debts: [
          _debt(id: 1, name: '', nextInstallment: DateTime(2026, 10, 10)),
        ],
      );
      expect(result.items, hasLength(1));
    });

    test(
      'rent that merely shares the amount and day with an EMI is NOT hidden',
      () {
        final result = _merge(
          today,
          recurring: [
            _recurring(
              id: 7,
              description: 'বাড়িভাড়া',
              category: 'Housing',
              amount: 5000,
              dayOfMonth: 10,
            ),
          ],
          debts: [
            _debt(
              id: 1,
              name: 'City Bank',
              emiAmount: 5000,
              nextInstallment: DateTime(2026, 10, 10),
            ),
          ],
        );
        expect(result.items, hasLength(2));
      },
    );

    test('same name but a different category is not a duplicate', () {
      final result = _merge(
        today,
        recurring: [
          _recurring(id: 7, description: 'City Bank', category: 'Food'),
        ],
        debts: [
          _debt(
            id: 1,
            name: 'City Bank',
            nextInstallment: DateTime(2026, 10, 10),
          ),
        ],
      );
      expect(result.items, hasLength(2));
    });

    test(
      'if the debt is not an obligation (settled), the recurring entry stays',
      () {
        final result = _merge(
          today,
          recurring: [
            _recurring(id: 7, description: 'City Bank', category: 'EMI'),
          ],
          debts: [
            _debt(
              id: 1,
              name: 'City Bank',
              status: DebtStatus.settled,
              nextInstallment: DateTime(2026, 10, 10),
            ),
          ],
        );
        expect(result.items.single.kind, ObligationKind.recurring);
      },
    );
  });

  group('upcomingObligationsProvider', () {
    test('merges both notifiers using the injected clock', () async {
      final container = ProviderContainer(
        overrides: [
          obligationsClockProvider.overrideWithValue(
            () => DateTime(2026, 10, 6),
          ),
          recurringProvider.overrideWith(
            () => _FakeRecurring([_recurring(dayOfMonth: 16)]),
          ),
          debtListProvider.overrideWith(
            () => _FakeDebts([_debt(nextInstallment: DateTime(2026, 10, 10))]),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(recurringProvider.future);
      await container.read(debtListProvider.future);

      final result = container.read(upcomingObligationsProvider);
      expect(result.items.map((i) => i.kind), [
        ObligationKind.debt,
        ObligationKind.recurring,
      ]);
      expect(result.items.map((i) => i.dueDate), [
        DateTime(2026, 10, 10),
        DateTime(2026, 10, 16),
      ]);
    });

    test('is empty (not an error) while nothing has loaded', () {
      final container = ProviderContainer(
        overrides: [
          recurringProvider.overrideWith(() => _NeverRecurring()),
          debtListProvider.overrideWith(() => _NeverDebts()),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(upcomingObligationsProvider).isEmpty, isTrue);
    });
  });
}

class _FakeRecurring extends RecurringNotifier {
  _FakeRecurring(this._items);
  final List<RecurringExpenseEntity> _items;
  @override
  Future<List<RecurringExpenseEntity>> build() async => _items;
}

class _NeverRecurring extends RecurringNotifier {
  @override
  Future<List<RecurringExpenseEntity>> build() => Future.any(const []);
}

class _FakeDebts extends DebtListNotifier {
  _FakeDebts(this._items);
  final List<DebtEntity> _items;
  @override
  Future<DebtListState> build() async =>
      DebtListState(debts: _items, filter: DebtFilterType.all);
}

class _NeverDebts extends DebtListNotifier {
  @override
  Future<DebtListState> build() => Future.any(const []);
}
