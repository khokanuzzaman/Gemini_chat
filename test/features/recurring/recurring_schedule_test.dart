import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gemini_chat/core/theme/app_theme.dart';
import 'package:gemini_chat/core/utils/bangla_formatters.dart';
import 'package:gemini_chat/features/recurring/domain/entities/recurring_expense_entity.dart';
import 'package:gemini_chat/features/recurring/domain/recurring_schedule.dart';
import 'package:gemini_chat/features/recurring/presentation/providers/recurring_provider.dart';
import 'package:gemini_chat/features/recurring/presentation/screens/recurring_screen.dart';

RecurringExpenseEntity _entry({
  RecurringFrequency frequency = RecurringFrequency.monthly,
  int dayOfMonth = 16,
  int dayOfWeek = 1,
  DateTime? lastOccurrence,
  DateTime? nextExpected,
  String description = 'বাড়িভাড়া',
}) {
  return RecurringExpenseEntity(
    id: 1,
    description: description,
    category: 'Housing',
    averageAmount: 15000,
    confidenceScore: 1,
    frequency: frequency,
    dayOfMonth: dayOfMonth,
    dayOfWeek: dayOfWeek,
    lastOccurrence: lastOccurrence ?? DateTime(2026, 9, 16),
    nextExpected: nextExpected,
    isActive: true,
    reminderEnabled: false,
  );
}

class _FakeRecurring extends RecurringNotifier {
  _FakeRecurring(this._items);
  final List<RecurringExpenseEntity> _items;
  @override
  Future<List<RecurringExpenseEntity>> build() async => _items;
}

void main() {
  group('nextDueDate (the one shared answer)', () {
    test('a month-old entry: the stored nextExpected is in the past, the real '
        'next date is not', () {
      // Marked on 16 Sep; the stored field was stamped 16 Oct and never advanced.
      final entry = _entry(
        lastOccurrence: DateTime(2026, 9, 16),
        nextExpected: DateTime(2026, 10, 16),
      );
      // Today is 20 Nov: 16 Oct is long gone, the next real due date is 16 Dec.
      expect(
        nextDueDate(entry, today: DateTime(2026, 11, 20)),
        DateTime(2026, 12, 16),
      );
      // Same entry, a few days before the 16th: this month.
      expect(
        nextDueDate(entry, today: DateTime(2026, 11, 10)),
        DateTime(2026, 11, 16),
      );
    });

    test('monthly day 31 across short months', () {
      final entry = _entry(
        dayOfMonth: 31,
        lastOccurrence: DateTime(2026, 1, 31),
      );
      expect(
        nextDueDate(entry, today: DateTime(2026, 2, 5)),
        DateTime(2026, 2, 28),
      );
      expect(
        nextDueDate(entry, today: DateTime(2026, 4, 5)),
        DateTime(2026, 4, 30),
      );
      expect(
        nextDueDate(entry, today: DateTime(2026, 3, 1)),
        DateTime(2026, 3, 31),
      );
    });

    test('weekly and daily', () {
      // 2026-10-06 is a Tuesday.
      final weekly = _entry(
        frequency: RecurringFrequency.weekly,
        dayOfWeek: 5, // Friday
        lastOccurrence: DateTime(2026, 9, 25),
      );
      expect(
        nextDueDate(weekly, today: DateTime(2026, 10, 6)),
        DateTime(2026, 10, 9),
      );

      final daily = _entry(
        frequency: RecurringFrequency.daily,
        lastOccurrence: DateTime(2026, 10, 1),
      );
      expect(
        nextDueDate(daily, today: DateTime(2026, 10, 6)),
        DateTime(2026, 10, 6),
      );
      final loggedToday = _entry(
        frequency: RecurringFrequency.daily,
        lastOccurrence: DateTime(2026, 10, 6),
      );
      expect(
        nextDueDate(loggedToday, today: DateTime(2026, 10, 6)),
        DateTime(2026, 10, 7),
      );
    });

    test('never returns a date before today, ignores time of day', () {
      final entry = _entry(dayOfMonth: 6, lastOccurrence: DateTime(2026, 9, 6));
      expect(
        nextDueDate(entry, today: DateTime(2026, 10, 6, 23, 59)),
        DateTime(2026, 10, 6),
      );
    });
  });

  group('Recurring screen', () {
    setUpAll(() => initializeDateFormatting('bn'));

    testWidgets('a month-old entry shows the correct "পরবর্তী" date, not the '
        'stale stored one', (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      // Due on the 1st of a month. Stale stored field: 45 days ago.
      final stale = today.subtract(const Duration(days: 45));
      final entry = _entry(
        dayOfMonth: 1,
        lastOccurrence: today.subtract(const Duration(days: 75)),
        nextExpected: stale,
      );
      final expected = today.day == 1
          ? today
          : DateTime(today.year, today.month + 1, 1);

      await tester.binding.setSurfaceSize(const Size(900, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recurringProvider.overrideWith(() => _FakeRecurring([entry])),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme(),
            home: const RecurringScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('পরবর্তী: ${BanglaFormatters.fullDate(expected)}'),
        findsOneWidget,
      );
      expect(
        find.textContaining(BanglaFormatters.fullDate(stale)),
        findsNothing,
        reason: 'the stale stored date must not be shown',
      );
    });
  });
}
