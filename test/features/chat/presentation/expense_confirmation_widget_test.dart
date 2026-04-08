import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gemini_chat/core/ai/expense_result.dart';
import 'package:gemini_chat/core/constants/app_strings.dart';
import 'package:gemini_chat/features/chat/presentation/widgets/expense_confirmation_widget.dart';
import 'package:gemini_chat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:gemini_chat/features/wallet/presentation/providers/wallet_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('bn');
  });

  testWidgets('expense confirmation shows amount and category', (tester) async {
    final expense = ExpenseData(
      amount: 60,
      category: 'Transport',
      description: 'রিকশা',
      date: '2026-02-02',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ProviderScope(
          overrides: [walletProvider.overrideWith(_TestWalletNotifier.new)],
          child: Scaffold(
            body: ExpenseConfirmationWidget(
              expense: expense,
              onSave: (_, walletId) async {},
              onCancel: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Transport'), findsOneWidget);
    expect(find.text('রিকশা'), findsOneWidget);
    expect(find.textContaining('৳'), findsWidgets);
  });

  testWidgets('save button calls onSave callback', (tester) async {
    final expense = ExpenseData(
      amount: 120,
      category: 'Food',
      description: 'লাঞ্চ',
      date: 'today',
    );
    ExpenseData? savedExpense;

    await tester.pumpWidget(
      MaterialApp(
        home: ProviderScope(
          overrides: [walletProvider.overrideWith(_TestWalletNotifier.new)],
          child: Scaffold(
            body: ExpenseConfirmationWidget(
              expense: expense,
              onSave: (value, _) async {
                savedExpense = value;
              },
              onCancel: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.saveButton));
    await tester.pump();

    expect(savedExpense, isNotNull);
    expect(savedExpense!.description, 'লাঞ্চ');
  });

  testWidgets('cancel button calls onCancel callback', (tester) async {
    final expense = ExpenseData(
      amount: 230,
      category: 'Healthcare',
      description: 'ওষুধ',
      date: 'today',
    );
    var cancelled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: ProviderScope(
          overrides: [walletProvider.overrideWith(_TestWalletNotifier.new)],
          child: Scaffold(
            body: ExpenseConfirmationWidget(
              expense: expense,
              onSave: (_, walletId) async {},
              onCancel: () {
                cancelled = true;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.cancelButton));
    await tester.pump();

    expect(cancelled, isTrue);
  });
}

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
