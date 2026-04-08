import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gemini_chat/features/chat/presentation/widgets/receipt_confirmation_widget.dart';
import 'package:gemini_chat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:gemini_chat/features/wallet/presentation/providers/wallet_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('bn');
  });

  testWidgets('receipt save normalizes old parsed month to today by default', (
    tester,
  ) async {
    Map<String, dynamic>? savedReceipt;
    final today = DateTime.now();
    final todayIso =
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';

    await tester.pumpWidget(
      MaterialApp(
        home: ProviderScope(
          overrides: [walletProvider.overrideWith(_TestWalletNotifier.new)],
          child: Scaffold(
            body: ReceiptConfirmationWidget(
              receiptData: const {
                'merchant': 'Test Store',
                'date': '2025-03-01',
                'category': 'Food',
                'summary': 'Receipt summary',
                'total': 300,
                'items': [
                  {'name': 'খাবার', 'amount': 300},
                ],
              },
              onSave: (receiptData, _) async {
                savedReceipt = receiptData;
              },
              onCancel: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Receipt date current monthের বাইরে ছিল'),
      findsOneWidget,
    );

    await tester.tap(find.text('Save করুন'));
    await tester.pump();

    expect(savedReceipt, isNotNull);
    expect(savedReceipt!['date'], todayIso);
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
