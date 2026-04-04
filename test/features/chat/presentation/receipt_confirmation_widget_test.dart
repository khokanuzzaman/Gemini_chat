import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gemini_chat/features/chat/presentation/widgets/receipt_confirmation_widget.dart';

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
        home: Scaffold(
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
            onSave: (receiptData) async {
              savedReceipt = receiptData;
            },
            onCancel: () {},
          ),
        ),
      ),
    );

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
