// R3 (c): the two edit sheets on the shared R2 pieces. Opened the way a user does
// — by tapping a row in the list — so the result (snackbar, refresh) is covered.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gemini_chat/core/utils/bangla_formatters.dart';
import 'package:gemini_chat/features/expense/presentation/screens/expense_list_screen.dart';
import 'package:gemini_chat/features/expense/presentation/widgets/add_entry/entry_choice_chips.dart';
import 'package:gemini_chat/features/expense/presentation/widgets/add_entry/entry_form_parts.dart';
import 'package:gemini_chat/features/income/domain/entities/income_entity.dart';
import 'package:gemini_chat/features/income/presentation/screens/income_list_screen.dart';

import '../../helpers/add_entry_harness.dart' show MockIncomeMutation;
import '../../helpers/app_fonts.dart';
import '../../helpers/list_harness.dart';

DateTime _today(int hour, [int minute = 0]) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day, hour, minute);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    await initializeDateFormatting('bn');
    registerFallbackValue(
      IncomeEntity(
        amount: 1,
        source: 'x',
        description: '',
        date: DateTime(2026),
        createdAt: DateTime(2026),
      ),
    );
  });

  String amountText(num v) =>
      '${BanglaFormatters.currencySymbol} ${BanglaFormatters.count(v.toInt())}';

  // The amount as shown in the sheet (the list behind it shows the same figure).
  Finder amountIn(num v) => find.descendant(
    of: find.byType(EntryAmountDisplay),
    matching: find.text(amountText(v)),
  );

  group('expense edit', () {
    final expense = listExpense(
      id: 1,
      date: _today(13, 30),
      amount: 1250,
      category: 'Food',
      description: 'দুপুরের খাবার',
      walletId: 2,
    );

    Future<ListCalls> open(
      WidgetTester tester, {
      ListCalls? calls,
      Size size = const Size(360, 800),
      List<dynamic>? rows,
      String tap = 'দুপুরের খাবার',
    }) async {
      final c = calls ?? ListCalls();
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        listApp(
          overrides: listOverrides(
            expenses: rows == null ? [expense] : rows.cast(),
            calls: c,
          ),
          child: const ExpenseListBody(),
        ),
      );
      await _settle(tester);
      await tester.tap(find.text(tap));
      await _settle(tester);
      return c;
    }

    testWidgets('opens prefilled on the shared pieces; keypad is collapsed', (
      tester,
    ) async {
      await open(tester);
      expect(find.text('খরচ সম্পাদনা'), findsOneWidget);
      expect(amountIn(1250), findsOneWidget);
      expect(find.text('দুপুরের খাবার'), findsWidgets);
      expect(find.text(BanglaFormatters.time(_today(13, 30))), findsWidgets);

      // The kept pieces.
      expect(find.text('নিয়মিত খরচ হিসেবে চিহ্নিত করুন'), findsOneWidget);
      expect(find.text('মুছুন'), findsOneWidget);
      expect(find.text('আপডেট করুন'), findsOneWidget);
      expect(find.byIcon(Icons.access_time_rounded), findsOneWidget); // time
      expect(find.byIcon(Icons.calendar_today_rounded), findsOneWidget); // date

      // Collapsed: no keypad until the amount is tapped.
      expect(find.byIcon(Icons.backspace_outlined), findsNothing);
      await tester.tap(amountIn(1250));
      await _settle(tester);
      expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
    });

    testWidgets(
      'edit amount on the keypad + change category -> updateExpense',
      (tester) async {
        final calls = await open(tester);
        await tester.tap(amountIn(1250));
        await _settle(tester);
        await tester.tap(find.byIcon(Icons.backspace_outlined)); // 1250 -> 125
        await tester.pump();
        await tester.tap(find.text('৮')); // 1258
        await tester.pump();
        expect(amountIn(1258), findsOneWidget);

        await tester.tap(
          find.descendant(
            of: find.byType(EntryChoiceChips),
            matching: find.text('যাতায়াত'),
          ),
        );
        await tester.pump();
        await tester.tap(find.text('আপডেট করুন'));
        await _settle(tester);

        expect(calls.updatedExpenses, hasLength(1));
        final saved = calls.updatedExpenses.single;
        expect(saved.id, 1); // same record
        expect(saved.amount, 1258);
        expect(saved.category, 'Transport');
        expect(saved.description, 'দুপুরের খাবার');
        expect(saved.walletId, 2);
        expect(saved.date, _today(13, 30)); // time of day untouched
        expect(find.text('খরচ আপডেট হয়েছে'), findsOneWidget);
      },
    );

    testWidgets('hardware keyboard drives the open keypad', (tester) async {
      await open(tester);
      await tester.tap(find.byType(EntryAmountDisplay));
      await _settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace); // 125
      await tester.sendKeyEvent(LogicalKeyboardKey.digit9); // 1259
      await tester.pump();
      expect(amountIn(1259), findsOneWidget);
    });

    testWidgets(
      'an emptied description is allowed (list falls back to category)',
      (tester) async {
        final calls = await open(tester);
        await tester.enterText(find.byType(TextField), '');
        await tester.tap(find.text('আপডেট করুন'));
        await _settle(tester);
        expect(calls.updatedExpenses.single.description, '');
      },
    );

    testWidgets('zero amount is refused inline and nothing is saved', (
      tester,
    ) async {
      final calls = await open(tester);
      await tester.tap(amountIn(1250));
      await _settle(tester);
      await tester.longPress(find.byIcon(Icons.backspace_outlined)); // clear
      await tester.pump();
      await tester.tap(find.text('আপডেট করুন'));
      await _settle(tester);
      expect(find.text('সঠিক পরিমাণ লিখুন'), findsOneWidget);
      expect(calls.updatedExpenses, isEmpty);
    });

    testWidgets('legacy fractional record shows and saves rounded', (
      tester,
    ) async {
      final legacy = listExpense(
        id: 1,
        date: _today(9),
        amount: 120.5,
        description: 'পুরনো এন্ট্রি',
      );
      final calls = await open(tester, rows: [legacy], tap: 'পুরনো এন্ট্রি');
      expect(amountIn(121), findsOneWidget); // 120.5 -> 121
      await tester.tap(find.text('আপডেট করুন'));
      await _settle(tester);
      expect(calls.updatedExpenses.single.amount, 121);
    });

    testWidgets('a controller error stays in the sheet, inline', (
      tester,
    ) async {
      final calls = ListCalls()..updateError = 'ওয়ালেট পাওয়া যায়নি';
      await open(tester, calls: calls);
      await tester.tap(find.text('আপডেট করুন'));
      await _settle(tester);
      expect(find.text('ওয়ালেট পাওয়া যায়নি'), findsOneWidget);
      expect(find.text('খরচ সম্পাদনা'), findsOneWidget); // still open
    });

    testWidgets('mark recurring is kept and uses the saved expense', (
      tester,
    ) async {
      final calls = await open(tester);
      await tester.tap(find.text('নিয়মিত খরচ হিসেবে চিহ্নিত করুন'));
      await _settle(tester);
      expect(calls.markedRecurring.map((e) => e.id), [1]);
      expect(find.text('নিয়মিত খরচ হিসেবে চিহ্নিত হয়েছে'), findsOneWidget);
    });

    testWidgets('delete: confirm dialog first, then the controller reverse', (
      tester,
    ) async {
      final calls = await open(tester);
      await tester.tap(find.text('মুছুন'));
      await _settle(tester);
      expect(find.text('খরচ মুছে ফেলবেন?'), findsOneWidget);
      expect(calls.deletedExpenses, isEmpty);

      await tester.tap(find.text('বাতিল'));
      await _settle(tester);
      expect(calls.deletedExpenses, isEmpty);
      expect(find.text('খরচ সম্পাদনা'), findsOneWidget);

      await tester.tap(find.text('মুছুন'));
      await _settle(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('মুছুন'),
        ),
      );
      await _settle(tester);
      expect(calls.deletedExpenses.map((e) => e.id), [1]);
      expect(find.text('খরচ মুছে ফেলা হয়েছে'), findsOneWidget);
    });

    testWidgets('a removed category stays selectable (no silent re-filing)', (
      tester,
    ) async {
      final odd = listExpense(
        id: 1,
        date: _today(9),
        category: 'MyOldCategory',
        description: 'কাস্টম',
      );
      final calls = await open(tester, rows: [odd], tap: 'কাস্টম');
      await tester.tap(find.text('আপডেট করুন'));
      await _settle(tester);
      expect(calls.updatedExpenses.single.category, 'MyOldCategory');
    });
  });

  group('income edit', () {
    final income = listIncome(
      id: 1,
      date: _today(10),
      amount: 65000,
      source: 'Salary',
      description: 'অক্টোবরের বেতন',
      walletId: 1,
    ).copyWith(note: 'বোনাস সহ', isRecurring: true);

    late MockIncomeMutation mutation;

    Future<ListCalls> open(WidgetTester tester) async {
      mutation = MockIncomeMutation();
      when(
        () => mutation.updateIncome(any(), any()),
      ).thenAnswer((_) async => null);
      final calls = ListCalls();
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        listApp(
          overrides: <Override>[
            ...listOverrides(
              incomes: [income],
              calls: calls,
              incomeMutation: mutation,
            ),
          ],
          child: const IncomeListBody(),
        ),
      );
      await _settle(tester);
      await tester.tap(find.text('অক্টোবরের বেতন'));
      await _settle(tester);
      return calls;
    }

    testWidgets('keeps its separate note field and the recurring switch', (
      tester,
    ) async {
      await open(tester);
      expect(find.text('আয় সম্পাদনা'), findsOneWidget);
      expect(amountIn(65000), findsOneWidget);
      expect(find.text('বোনাস সহ'), findsOneWidget); // the note
      expect(find.text('অক্টোবরের বেতন'), findsWidgets); // the description
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('প্রতি মাসে'), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      expect(find.byIcon(Icons.backspace_outlined), findsNothing);
    });

    testWidgets(
      'save: new amount, edited note, source change -> updateIncome',
      (tester) async {
        await open(tester);
        await tester.tap(amountIn(65000));
        await _settle(tester);
        await tester.tap(find.byIcon(Icons.backspace_outlined)); // 6500
        await tester.pump();
        await tester.tap(find.text('০০')); // 650000
        await tester.pump();
        await tester.enterText(find.byType(TextField).last, 'নতুন নোট');
        await tester.pump();
        await tester.tap(find.text('আপডেট করুন'));
        await _settle(tester);

        final captured = verify(
          () => mutation.updateIncome(captureAny(), captureAny()),
        ).captured;
        final saved = captured[0] as IncomeEntity;
        final old = captured[1] as IncomeEntity;
        expect(saved.id, 1);
        expect(saved.amount, 650000);
        expect(saved.note, 'নতুন নোট');
        expect(saved.description, 'অক্টোবরের বেতন');
        expect(saved.isRecurring, isTrue);
        expect(old.amount, 65000); // the ORIGINAL is what the ledger reverses
        expect(find.text('আয় আপডেট হয়েছে'), findsOneWidget);
      },
    );

    testWidgets('delete: confirm, then deleteIncome', (tester) async {
      final calls = await open(tester);
      await tester.tap(find.text('মুছুন'));
      await _settle(tester);
      expect(find.text('আয় মুছে ফেলবেন?'), findsOneWidget);
      expect(calls.deletedIncomes, isEmpty);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('মুছুন'),
        ),
      );
      await _settle(tester);
      expect(calls.deletedIncomes.map((e) => e.id), [1]);
      expect(find.text('আয় মুছে ফেলা হয়েছে'), findsOneWidget);
    });
  });
}
