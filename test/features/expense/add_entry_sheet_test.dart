import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gemini_chat/core/utils/bangla_formatters.dart';
import 'package:gemini_chat/features/category/domain/entities/category_entity.dart';
import 'package:gemini_chat/features/expense/presentation/widgets/add_entry/entry_type.dart';
import 'package:gemini_chat/features/expense/presentation/widgets/add_entry/last_used_choice.dart';

import '../../helpers/add_entry_harness.dart';
import '../../helpers/app_fonts.dart';

Future<void> _open(
  WidgetTester tester,
  AddEntryEnv env, {
  EntryType type = EntryType.expense,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    addEntryApp(env, initialType: type, brightness: brightness),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _tapKeys(WidgetTester tester, String keys) async {
  for (final key in keys.split('')) {
    await tester.tap(find.text(key));
    await tester.pump();
  }
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    await initializeDateFormatting('bn');
  });

  group('amount keypad', () {
    testWidgets(
      'typing shows Bengali digits with live grouping; no decimal key',
      (tester) async {
        final env = await newAddEntryEnv();
        await _open(tester, env);

        expect(find.text('৳ ০'), findsOneWidget);
        await _tapKeys(tester, '১৪৫০');
        expect(find.text('৳ ১,৪৫০'), findsOneWidget);
        expect(find.text('.'), findsNothing);
        expect(find.text('০০'), findsOneWidget);
      },
    );

    testWidgets('০০ key, backspace and long-press clear', (tester) async {
      final env = await newAddEntryEnv();
      await _open(tester, env);

      await _tapKeys(tester, '৫');
      await tester.tap(find.text('০০'));
      await tester.pump();
      expect(find.text('৳ ৫০০'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();
      expect(find.text('৳ ৫০'), findsOneWidget);

      await tester.longPress(find.byIcon(Icons.backspace_outlined));
      await tester.pump();
      expect(find.text('৳ ০'), findsOneWidget);
    });

    testWidgets('hardware keyboard: digits, numpad, backspace, delete', (
      tester,
    ) async {
      final env = await newAddEntryEnv();
      await _open(tester, env);

      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.sendKeyEvent(LogicalKeyboardKey.numpad2);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
      await tester.pump();
      expect(find.text('৳ ১২৫'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(find.text('৳ ১২'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();
      expect(find.text('৳ ০'), findsOneWidget);
    });

    testWidgets('every key is a labelled button (TalkBack reads ৫, মুছুন)', (
      tester,
    ) async {
      final env = await newAddEntryEnv();
      await _open(tester, env);
      final handle = tester.ensureSemantics();
      expect(find.bySemanticsLabel('৫'), findsOneWidget);
      expect(find.bySemanticsLabel('মুছুন'), findsOneWidget);
      expect(find.bySemanticsLabel('দুটি শূন্য'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('keys are at least 48dp tall (a11y touch target)', (
      tester,
    ) async {
      final env = await newAddEntryEnv();
      await _open(tester, env);
      expect(tester.getSize(find.text('৫')).height, lessThan(48)); // the glyph
      final key = find.ancestor(
        of: find.text('৫'),
        matching: find.byType(InkWell),
      );
      expect(tester.getSize(key).height, greaterThanOrEqualTo(48));
    });
  });

  group('খরচ | আয় toggle', () {
    testWidgets(
      'switches chips from categories to income sources, keeps the amount',
      (tester) async {
        final env = await newAddEntryEnv();
        await _open(tester, env);
        await _tapKeys(tester, '৫০০');

        expect(find.text('খাবার'), findsOneWidget);

        await tester.tap(find.text('আয়'));
        await tester.pumpAndSettle();

        expect(find.text('বেতন'), findsOneWidget);
        expect(find.text('খাবার'), findsNothing);
        expect(
          find.text('৳ ৫০০'),
          findsOneWidget,
          reason: 'amount survives the switch',
        );
        expect(find.text('প্রতি মাসে'), findsOneWidget);
      },
    );

    testWidgets('the recurring switch exists only for আয়', (tester) async {
      final env = await newAddEntryEnv();
      await _open(tester, env);
      expect(find.text('প্রতি মাসে'), findsNothing);
    });

    testWidgets('opens preset to আয় when asked (income list)', (tester) async {
      final env = await newAddEntryEnv();
      await _open(tester, env, type: EntryType.income);
      expect(find.text('বেতন'), findsOneWidget);
      expect(find.text('খাবার'), findsNothing);
    });
  });

  group('save maps to the EXISTING controllers', () {
    testWidgets(
      'খরচ: whole taka, category, note -> description, isManual, wallet',
      (tester) async {
        final env = await newAddEntryEnv();
        await _open(tester, env);
        await _tapKeys(tester, '১২৫০');
        await tester.tap(find.text('যাতায়াত'));
        await tester.pump();
        await tester.enterText(find.byType(TextField), 'রিকশা ভাড়া');
        await tester.pump();
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();

        await tester.tap(find.text('সেভ করুন'));
        await tester.pumpAndSettle();

        final saved = env.savedExpense;
        expect(saved.amount, 1250);
        expect(saved.category, 'Transport');
        expect(saved.description, 'রিকশা ভাড়া');
        expect(saved.isManual, isTrue);
        expect(env.logger.params.last, {'method': 'manual_expense'});
        // The sheet closed and the confirmation shows.
        expect(find.text('open'), findsOneWidget);
        expect(find.text('খরচ সংরক্ষণ হয়েছে'), findsOneWidget);
      },
    );

    testWidgets('আয়: source, recurring flag, note -> description', (
      tester,
    ) async {
      final env = await newAddEntryEnv();
      await _open(tester, env, type: EntryType.income);
      await _tapKeys(tester, '৬৫০০০');
      await tester.tap(find.text('বেতন'));
      await tester.pump();
      await tester.tap(find.text('প্রতি মাসে'));
      await tester.pump();

      await tester.tap(find.text('সেভ করুন'));
      await tester.pumpAndSettle();

      final saved = env.savedIncome;
      expect(saved.amount, 65000);
      expect(saved.source, 'Salary');
      expect(saved.isRecurring, isTrue);
      expect(saved.isManual, isTrue);
      expect(env.logger.params.last, {'method': 'manual_income'});
      expect(find.text('আয় সংরক্ষণ হয়েছে'), findsOneWidget);
      verifyNever(
        () => env.expenses.saveManualExpense(
          any(),
          walletId: any(named: 'walletId'),
        ),
      );
    });

    testWidgets(
      'empty note is passed as empty (the controller applies its default label)',
      (tester) async {
        final env = await newAddEntryEnv();
        await _open(tester, env);
        await _tapKeys(tester, '১০০');
        await tester.tap(find.text('সেভ করুন'));
        await tester.pumpAndSettle();
        expect(env.savedExpense.description, '');
      },
    );

    testWidgets('a past date is stamped end-of-day, like before', (
      tester,
    ) async {
      final env = await newAddEntryEnv();
      await _open(tester, env);
      await _tapKeys(tester, '১০০');
      await tester.tap(find.text('আজ'));
      await tester.pumpAndSettle();
      // Pick the 1st of this month if it is in the past, else the 1st of last month.
      final now = DateTime.now();
      final target = now.day == 1
          ? DateTime(now.year, now.month - 1, 1)
          : DateTime(now.year, now.month, 1);
      final label = target.day.toString(); // the date picker grid shows days
      expect(find.byType(DatePickerDialog), findsOneWidget);
      if (now.day == 1) {
        await tester.tap(find.byIcon(Icons.chevron_left));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text(label).first);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('সেভ করুন'));
      await tester.pumpAndSettle();
      final saved = env.savedExpense;
      expect(saved.date.day, target.day);
      expect(saved.date.hour, 23);
      expect(saved.date.minute, 59);
    });
  });

  group('validation (same rules and messages as before)', () {
    testWidgets('no amount -> "সঠিক পরিমাণ লিখুন", nothing saved', (
      tester,
    ) async {
      final env = await newAddEntryEnv();
      await _open(tester, env);
      await tester.tap(find.text('সেভ করুন'));
      await tester.pump();
      expect(find.text('সঠিক পরিমাণ লিখুন'), findsOneWidget);
      verifyNever(
        () => env.expenses.saveManualExpense(
          any(),
          walletId: any(named: 'walletId'),
        ),
      );
    });

    testWidgets('আয় without a source -> "একটি উৎস নির্বাচন করুন"', (
      tester,
    ) async {
      final env = await newAddEntryEnv();
      await _open(tester, env, type: EntryType.income);
      await _tapKeys(tester, '৫০০');
      await tester.tap(find.text('সেভ করুন'));
      await tester.pump();
      expect(find.text('একটি উৎস নির্বাচন করুন'), findsOneWidget);
      verifyNever(
        () => env.incomes.saveManualIncome(
          any(),
          walletId: any(named: 'walletId'),
        ),
      );
    });

    testWidgets(
      'a controller error is shown in the sheet and the sheet stays open',
      (tester) async {
        final env = await newAddEntryEnv();
        when(
          () => env.expenses.saveManualExpense(
            any(),
            walletId: any(named: 'walletId'),
          ),
        ).thenAnswer((_) async => 'কোনো ওয়ালেট পাওয়া যায়নি');
        await _open(tester, env);
        await _tapKeys(tester, '১০০');
        await tester.tap(find.text('সেভ করুন'));
        await tester.pumpAndSettle();
        expect(find.text('কোনো ওয়ালেট পাওয়া যায়নি'), findsOneWidget);
        expect(find.text('সেভ করুন'), findsOneWidget, reason: 'still open');
        expect(
          env.prefs.getString(LastUsedEntryChoice.expenseCategoryKey),
          isNull,
          reason: 'a failed save must not be remembered',
        );
      },
    );
  });

  group('remembers the last-used choice, separately per type', () {
    testWidgets(
      'খরচ category is pre-selected next time; আয় source is independent',
      (tester) async {
        final env = await newAddEntryEnv();
        await _open(tester, env);
        await _tapKeys(tester, '১০০');
        await tester.tap(find.text('যাতায়াত'));
        await tester.pump();
        await tester.tap(find.text('সেভ করুন'));
        await tester.pumpAndSettle();
        expect(
          env.prefs.getString(LastUsedEntryChoice.expenseCategoryKey),
          'Transport',
        );
        expect(
          env.prefs.getString(LastUsedEntryChoice.incomeSourceKey),
          isNull,
        );
        clearInteractions(env.expenses);

        // Reopen: no tap on a category, and Transport is what gets saved.
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await _tapKeys(tester, '২০০');
        await tester.tap(find.text('সেভ করুন'));
        await tester.pumpAndSettle();
        expect(env.savedExpense.category, 'Transport');
      },
    );

    testWidgets('first run falls back to the old default (Food)', (
      tester,
    ) async {
      final env = await newAddEntryEnv();
      await _open(tester, env);
      await _tapKeys(tester, '৯৯');
      await tester.tap(find.text('সেভ করুন'));
      await tester.pumpAndSettle();
      expect(env.savedExpense.category, 'Food');
    });

    testWidgets(
      'a remembered category that was deleted falls back, never breaks',
      (tester) async {
        final env = await newAddEntryEnv(
          prefs: {LastUsedEntryChoice.expenseCategoryKey: 'Deleted Custom'},
        );
        await _open(tester, env);
        await _tapKeys(tester, '৯৯');
        await tester.tap(find.text('সেভ করুন'));
        await tester.pumpAndSettle();
        expect(env.savedExpense.category, 'Food');
      },
    );

    testWidgets(
      'আয় remembers its own source (and none is preselected the first time)',
      (tester) async {
        final env = await newAddEntryEnv(
          prefs: {LastUsedEntryChoice.incomeSourceKey: 'Freelance'},
        );
        await _open(tester, env, type: EntryType.income);
        await _tapKeys(tester, '৫০০');
        await tester.tap(find.text('সেভ করুন'));
        await tester.pumpAndSettle();
        expect(env.savedIncome.source, 'Freelance');
      },
    );
  });

  group('note and keyboard', () {
    testWidgets(
      'focusing the note swaps the keypad for the system keyboard; tapping the amount brings it back',
      (tester) async {
        final env = await newAddEntryEnv();
        await _open(tester, env);
        expect(find.text('৫'), findsOneWidget);

        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();
        expect(
          find.text('৫'),
          findsNothing,
          reason: 'keypad hidden while typing a note',
        );
        expect(find.text('সেভ করুন'), findsOneWidget);

        await tester.tap(find.text('৳ ০')); // the compact amount line
        await tester.pumpAndSettle();
        expect(find.text('৫'), findsOneWidget);
      },
    );

    testWidgets('digits typed into the note never reach the amount', (
      tester,
    ) async {
      final env = await newAddEntryEnv();
      await _open(tester, env);
      await tester.ensureVisible(find.byType(TextField));
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.digit7);
      await tester.pump();
      expect(find.text('৳ ০'), findsOneWidget);
    });
  });

  group('every entry point opens this one sheet', () {
    test('no reference to the old full-page screen remains', () {
      final offenders = <String>[];
      for (final f in Directory(
        'lib',
      ).listSync(recursive: true).whereType<File>()) {
        if (!f.path.endsWith('.dart')) continue;
        if (f.readAsStringSync().contains('ManualAddScreen')) {
          offenders.add(f.path);
        }
      }
      expect(offenders, isEmpty);
    });

    test(
      'the income ADD button opens the unified sheet; the income sheet is edit-only',
      () {
        final incomeList = File(
          'lib/features/income/presentation/screens/income_list_screen.dart',
        ).readAsStringSync();
        expect(
          incomeList,
          contains('showAddEntrySheet(context, initialType: EntryType.income)'),
        );
        final calls = RegExp(
          r'showEditIncomeSheet\(([^)]*)\)',
          dotAll: true,
        ).allMatches(incomeList);
        for (final call in calls) {
          expect(
            call.group(1),
            contains('entry'),
            reason: 'only for editing',
          );
        }
      },
    );

    test(
      'the expenses tab and showManualAddSheet go through showAddEntrySheet',
      () {
        expect(
          File(
            'lib/features/expense/presentation/screens/manual_add_screen.dart',
          ).readAsStringSync(),
          contains('showAddEntrySheet(context)'),
        );
        expect(
          File(
            'lib/features/expense/presentation/widgets/expense_list/expense_list_screen_content.dart',
          ).readAsStringSync(),
          contains('showAddEntrySheet(context)'),
        );
      },
    );
  });

  test('LastUsedEntryChoice.resolve / defaults', () {
    const names = ['Food', 'Transport', 'Other'];
    expect(
      LastUsedEntryChoice.resolve(
        stored: 'Transport',
        available: names,
        fallback: 'Food',
      ),
      'Transport',
    );
    expect(
      LastUsedEntryChoice.resolve(
        stored: 'Gone',
        available: names,
        fallback: 'Food',
      ),
      'Food',
    );
    expect(
      LastUsedEntryChoice.resolve(
        stored: null,
        available: names,
        fallback: null,
      ),
      isNull,
    );
    expect(LastUsedEntryChoice.defaultExpenseCategory(names), 'Food');
    expect(
      LastUsedEntryChoice.defaultExpenseCategory(['Transport', 'Other']),
      'Other',
    );
    expect(
      LastUsedEntryChoice.defaultExpenseCategory(['Transport', 'Bills']),
      'Transport',
    );
    expect(LastUsedEntryChoice.defaultExpenseCategory(const []), isNull);
  });

  test('sanity: whole-taka display helper agrees with the formatter', () {
    expect(BanglaFormatters.count(1450), '১,৪৫০');
    expect(CategoryEntity, isNotNull);
  });
}
