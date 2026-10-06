import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gemini_chat/core/theme/app_theme.dart';
import 'package:gemini_chat/features/expense/domain/entities/expense_entity.dart';
import 'package:gemini_chat/features/expense/domain/entities/expense_source.dart';
import 'package:gemini_chat/features/expense/presentation/widgets/expense_list/managed_expense_sheet.dart';
import 'package:gemini_chat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:gemini_chat/features/wallet/presentation/providers/wallet_provider.dart';

import '../../helpers/app_fonts.dart';

final _wallet = WalletEntity(
  id: 1,
  name: 'ব্র্যাক ব্যাংক সেভিংস অ্যাকাউন্ট',
  type: WalletType.bank,
  emoji: '🏦',
  initialBalance: 0,
  currentBalance: 0,
  accountNumber: null,
  note: null,
  sortOrder: 0,
  isArchived: false,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

ExpenseEntity _row(ExpenseSource source) => ExpenseEntity(
  id: 1,
  amount: 12345678,
  category: 'EMI',
  description: 'মোটরসাইকেল ঋণের মাসিক কিস্তি — ডাচ-বাংলা ব্যাংক লিমিটেড',
  date: DateTime(2026, 10, 5, 21, 30),
  walletId: 1,
  sourceType: source,
  sourceId: 7,
);

Future<void> _pump(
  WidgetTester tester,
  ExpenseSource source, {
  required Size size,
  required double scale,
  required Brightness brightness,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [walletByIdProvider.overrideWith((ref, id) => _wallet)],
      child: MaterialApp(
        theme: brightness == Brightness.dark
            ? AppTheme.darkTheme()
            : AppTheme.lightTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ManagedExpenseDetails(expense: _row(source)),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    await initializeDateFormatting('bn');
  });

  testWidgets(
    'debt row: explains why it is locked and offers the debt screen',
    (tester) async {
      await _pump(
        tester,
        ExpenseSource.debtPayment,
        size: const Size(360, 800),
        scale: 1,
        brightness: Brightness.light,
      );
      expect(find.text('দেনা-পাওনা থেকে পরিবর্তন করুন'), findsOneWidget);
      expect(
        find.textContaining('এখান থেকে বদলানো বা মুছা যায় না'),
        findsOneWidget,
      );
      // Read-only: no save / delete / amount field.
      expect(find.byType(TextField), findsNothing);
      expect(find.text('মুছুন'), findsNothing);
    },
  );

  testWidgets('goal row: locked, no debt navigation button', (tester) async {
    await _pump(
      tester,
      ExpenseSource.goalDeposit,
      size: const Size(360, 800),
      scale: 1,
      brightness: Brightness.light,
    );
    expect(find.text('দেনা-পাওনা থেকে পরিবর্তন করুন'), findsNothing);
    expect(find.textContaining('বদলানো বা মুছা যায় না'), findsOneWidget);
  });

  for (final width in [320.0, 360.0, 411.0]) {
    for (final height in [568.0, 850.0]) {
      for (final scale in [1.0, 1.3]) {
        for (final brightness in Brightness.values) {
          testWidgets(
            'no overflow ${width.toInt()}x${height.toInt()} ×$scale ${brightness.name}',
            (tester) async {
              await _pump(
                tester,
                ExpenseSource.debtPayment,
                size: Size(width, height),
                scale: scale,
                brightness: brightness,
              );
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  }
}
