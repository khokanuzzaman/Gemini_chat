import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gemini_chat/core/sms/parsed_transaction.dart';
import 'package:gemini_chat/core/theme/app_theme.dart';
import 'package:gemini_chat/core/utils/bangla_formatters.dart';
import 'package:gemini_chat/features/sms_import/presentation/widgets/sms_parsed_summary.dart';

import '../../helpers/app_fonts.dart';

ParsedTransaction _tx({String? reference = 'TRX12345', String? who}) =>
    ParsedTransaction(
      smsId: 1,
      sender: 'bKash',
      source: ParsedTransactionSource.bkash,
      direction: ParsedTransactionDirection.debit,
      kind: ParsedTransactionKind.payment,
      amount: 12345678,
      // Whatever is here must never be shown or stored.
      rawMessage: 'SECRET MESSAGE TEXT',
      receivedAt: DateTime(2026, 10, 5, 13, 5),
      occurredAt: DateTime(2026, 10, 5, 13, 5),
      fee: 5,
      balanceAfter: 1450,
      reference: reference,
      counterparty: who,
      accountMask: '••1234',
    );

void main() {
  setUpAll(() async {
    await loadAppFonts();
    await initializeDateFormatting('bn');
  });

  Future<void> pump(
    WidgetTester tester,
    ParsedTransaction t, {
    double width = 360,
    double scale = 1.0,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        builder: (c, child) => MediaQuery(
          data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(child: SmsParsedSummary(transaction: t)),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows the parsed fields, never the message text', (
    tester,
  ) async {
    await pump(tester, _tx(who: 'Foodpanda'));
    expect(find.text('bKash'), findsOneWidget);
    expect(find.text(ParsedTransactionKind.payment.labelBn), findsOneWidget);
    expect(find.text(BanglaFormatters.currency(12345678)), findsOneWidget);
    expect(find.text('TRX12345'), findsOneWidget);
    expect(find.text('Foodpanda'), findsOneWidget);
    expect(find.textContaining('SECRET MESSAGE TEXT'), findsNothing);
    // The balance is not part of what the app keeps, so it is not shown either.
    expect(find.text('ব্যালেন্স'), findsNothing);
    expect(find.text(BanglaFormatters.currency(1450)), findsNothing);
    expect(find.textContaining('সংরক্ষণ করা হয় না'), findsOneWidget);
  });

  testWidgets('omits rows that have no value', (tester) async {
    await pump(tester, _tx(reference: null));
    expect(find.text('রেফারেন্স'), findsNothing);
    expect(find.text('কার সাথে'), findsNothing);
  });

  for (final width in [320.0, 360.0, 411.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('no overflow ${width.toInt()} ×$scale', (tester) async {
        await pump(
          tester,
          _tx(who: 'ঢাকা বিশ্ববিদ্যালয় ক্যাফেটেরিয়া এন্ড রেস্টুরেন্ট'),
          width: width,
          scale: scale,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
