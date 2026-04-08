import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/core/ai/expense_result.dart';
import 'package:gemini_chat/features/chat/presentation/widgets/multiple_expense_confirmation_widget.dart';
import 'package:gemini_chat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:gemini_chat/features/wallet/presentation/providers/wallet_provider.dart';

void main() {
  test('ExpenseData parses common past date formats', () {
    expect(ExpenseData.parseDateValue('2/02/2026'), DateTime(2026, 2, 2));
    expect(ExpenseData.parseDateValue('2-2-2026'), DateTime(2026, 2, 2));
    expect(ExpenseData.parseDateValue('Feb 2, 2026'), DateTime(2026, 2, 2));
    expect(
      ExpenseData.parseDateValue('২ ফেব্রুয়ারি ২০২৬'),
      DateTime(2026, 2, 2),
    );
  });

  test('ExpenseData resolves relative and invalid dates safely', () {
    final today = DateTime.now();
    final yesterday = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 1));
    final relativeExpense = ExpenseData(
      amount: 60,
      category: 'Transport',
      description: 'রিকশা',
      date: 'গতকাল',
    );
    final invalidExpense = ExpenseData(
      amount: 30,
      category: 'Food',
      description: 'নাস্তা',
      date: 'not-a-date',
    );

    expect(relativeExpense.parsedDate, yesterday);
    expect(relativeExpense.displayDate, 'গতকাল');
    expect(invalidExpense.dateFallbackNote, isNotNull);
    expect(
      ExpenseData.isSameDay(invalidExpense.parsedDate, DateTime.now()),
      isTrue,
    );
  });

  testWidgets('multiple expense widget groups expenses by date', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProviderScope(
          overrides: [walletProvider.overrideWith(_TestWalletNotifier.new)],
          child: Scaffold(
            body: MultipleExpenseConfirmationWidget(
              expenses: const [
                ExpenseData(
                  amount: 30,
                  category: 'Food',
                  description: 'নাস্তা',
                  date: '2026-02-02',
                ),
                ExpenseData(
                  amount: 60,
                  category: 'Transport',
                  description: 'রিকশা',
                  date: '2026-02-02',
                ),
                ExpenseData(
                  amount: 200,
                  category: 'Food',
                  description: 'লাঞ্চ',
                  date: '2026-02-03',
                ),
              ],
              onSave: _noopSave,
              onCancel: _noop,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('২ ফেব্রুয়ারি, ২০২৬'), findsOneWidget);
    expect(find.text('৩ ফেব্রুয়ারি, ২০২৬'), findsOneWidget);
    expect(find.text('অতীত'), findsWidgets);
  });
}

Future<void> _noopSave(List<ExpenseData> _, int? walletId) async {}

void _noop() {}

class _TestWalletNotifier extends WalletNotifier {
  @override
  Future<List<WalletEntity>> build() async {
    final now = DateTime(2026, 1, 1);
    return [
      WalletEntity(
        id: 1,
        name: 'Cash',
        type: WalletType.cash,
        emoji: '💵',
        initialBalance: 0,
        currentBalance: 0,
        accountNumber: null,
        note: null,
        sortOrder: 1,
        isArchived: false,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
