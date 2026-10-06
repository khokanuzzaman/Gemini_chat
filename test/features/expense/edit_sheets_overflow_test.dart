// R3 (c) overflow matrix for the two edit sheets: widths 320/360/411 × heights
// 568/640/850 × text scale 1.0/1.3 × light/dark, with the keypad open and with the
// system keyboard up over a long description / note.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gemini_chat/features/expense/presentation/screens/expense_list_screen.dart';
import 'package:gemini_chat/features/expense/presentation/widgets/add_entry/entry_form_parts.dart';
import 'package:gemini_chat/features/income/presentation/screens/income_list_screen.dart';

import '../../helpers/app_fonts.dart';
import '../../helpers/list_harness.dart';

const _long =
    'ঢাকা থেকে চট্টগ্রাম যাওয়ার বাস ভাড়া এবং হোটেলের অগ্রিম বুকিং বাবদ মোট খরচ — লম্বা বিবরণ';

DateTime _today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day, 21, 45);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    await initializeDateFormatting('bn');
  });

  final expense = listExpense(
    id: 1,
    date: _today(),
    amount: 12345678,
    description: _long,
    walletId: 2,
  );
  for (final width in [320.0, 360.0, 411.0]) {
    for (final height in [568.0, 640.0, 850.0]) {
      for (final scale in [1.0, 1.3]) {
        for (final brightness in Brightness.values) {
          final tag =
              '${width.toInt()}x${height.toInt()} ×$scale ${brightness.name}';

          Future<void> open(
            WidgetTester tester, {
            required bool income,
            required String tapText,
          }) async {
            tester.view.physicalSize = Size(width, height);
            tester.view.devicePixelRatio = 1;
            addTearDown(() {
              tester.view.reset();
              tester.view.resetViewInsets();
            });
            final overrides = <Override>[
              ...listOverrides(
                expenses: income ? const [] : [expense],
                incomes: income ? [_incomeRow] : const [],
                calls: ListCalls(),
              ),
            ];
            await tester.pumpWidget(
              listApp(
                overrides: overrides,
                brightness: brightness,
                textScale: scale,
                child: income
                    ? const IncomeListBody()
                    : const ExpenseListBody(),
              ),
            );
            await _settle(tester);
            await tester.tap(find.text(tapText));
            await _settle(tester);
          }

          testWidgets('expense edit, $tag', (tester) async {
            await open(tester, income: false, tapText: _long);
            expect(find.text('খরচ সম্পাদনা'), findsOneWidget);
            expect(tester.takeException(), isNull);
          });

          testWidgets('expense edit, keypad open, $tag', (tester) async {
            await open(tester, income: false, tapText: _long);
            await tester.tap(find.byType(EntryAmountDisplay));
            await _settle(tester);
            expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
            expect(tester.takeException(), isNull);
          });

          testWidgets('expense edit, keyboard up, $tag', (tester) async {
            await open(tester, income: false, tapText: _long);
            await tester.tap(find.byType(TextField));
            await tester.pump();
            tester.view.viewInsets = const FakeViewPadding(bottom: 280);
            await _settle(tester);
            expect(tester.takeException(), isNull);
          });

          testWidgets('income edit, $tag', (tester) async {
            await open(tester, income: true, tapText: _long);
            expect(find.text('আয় সম্পাদনা'), findsOneWidget);
            expect(tester.takeException(), isNull);
          });

          testWidgets('income edit, keypad open, $tag', (tester) async {
            await open(tester, income: true, tapText: _long);
            await tester.tap(find.byType(EntryAmountDisplay));
            await _settle(tester);
            expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
            expect(tester.takeException(), isNull);
          });

          testWidgets('income edit, keyboard up on the note, $tag', (
            tester,
          ) async {
            await open(tester, income: true, tapText: _long);
            await tester.ensureVisible(find.byType(TextField).last);
            await tester.tap(find.byType(TextField).last);
            await tester.pump();
            tester.view.viewInsets = const FakeViewPadding(bottom: 280);
            await _settle(tester);
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  }
}

final _incomeRow = listIncome(
  id: 1,
  date: _today(),
  amount: 98765432,
  description: _long,
).copyWith(note: _long, isRecurring: true);
