import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gemini_chat/core/utils/bangla_formatters.dart';
import 'package:gemini_chat/features/obligations/domain/upcoming_obligation.dart';
import 'package:gemini_chat/features/plan/domain/plan_status.dart';

UpcomingObligation _ob({
  ObligationKind kind = ObligationKind.recurring,
  String title = 'বাড়িভাড়া',
  double amount = 15000,
  DateTime? due,
  bool overdue = false,
}) => UpcomingObligation(
  kind: kind,
  sourceId: 1,
  title: title,
  amount: amount,
  dueDate: due ?? DateTime(2026, 10, 16),
  isOverdue: overdue,
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('bn');
  });

  // Statuses use a non-breaking space after the currency symbol.
  String taka(num v) => BanglaFormatters.currency(v).replaceAll(' ', '\u00A0');

  group('budgetStatus', () {
    test('no plan -> a prompt, not a number', () {
      expect(budgetStatus(budgeted: null, spent: 500).text, 'বাজেট ঠিক করুন');
      expect(budgetStatus(budgeted: 0, spent: 500).text, 'বাজেট ঠিক করুন');
    });

    test('within budget: spent / budgeted · percent (floored)', () {
      final s = budgetStatus(budgeted: 60000, spent: 41890);
      expect(s.tone, StatusTone.normal);
      expect(
        s.text,
        'এই মাসে ${taka(41890)} / ${taka(60000)} · ${BanglaFormatters.count(69)}%',
      );
    });

    test('exactly on budget is not "over"', () {
      final s = budgetStatus(budgeted: 1000, spent: 1000);
      expect(s.tone, StatusTone.normal);
      expect(s.text, contains('১০০%'));
    });

    test('nothing spent yet -> 0%', () {
      expect(budgetStatus(budgeted: 1000, spent: 0).text, contains('০%'));
    });

    test('over budget -> attention, with the overshoot', () {
      final s = budgetStatus(budgeted: 60000, spent: 72500);
      expect(s.tone, StatusTone.attention);
      expect(s.text, '${taka(12500)} বেশি — বাজেট ছাড়িয়েছে');
    });
  });

  group('goalsStatus', () {
    test(
      'none -> prompt',
      () => expect(goalsStatus(active: 0).text, 'প্রথম লক্ষ্য ঠিক করুন'),
    );
    test(
      'the spec example',
      () => expect(goalsStatus(active: 3).text, '৩টি সক্রিয় লক্ষ্য'),
    );
    test(
      'one',
      () => expect(goalsStatus(active: 1).text, '১টি সক্রিয় লক্ষ্য'),
    );
  });

  group('debtStatus', () {
    test('no open debts', () {
      expect(
        debtStatus(active: 0, overdue: 0, iOwe: 0, owedToMe: 0).text,
        'কোনো ঋণ নেই',
      );
    });

    test('both directions', () {
      final s = debtStatus(active: 2, overdue: 0, iOwe: 50000, owedToMe: 3000);
      expect(s.tone, StatusTone.normal);
      expect(s.text, 'আমি দেব ${taka(50000)} · পাব ${taka(3000)}');
    });

    test('only one direction hides the zero side', () {
      expect(
        debtStatus(active: 1, overdue: 0, iOwe: 50000, owedToMe: 0).text,
        'আমি দেব ${taka(50000)}',
      );
      expect(
        debtStatus(active: 1, overdue: 0, iOwe: 0, owedToMe: 3000).text,
        'পাব ${taka(3000)}',
      );
    });

    test('overdue wins and is an attention', () {
      final s = debtStatus(active: 2, overdue: 2, iOwe: 50000, owedToMe: 0);
      expect(s.tone, StatusTone.attention);
      expect(s.text, '২টি মেয়াদ পেরিয়েছে');
    });

    test('open debts with nothing to show (all zero) still say how many', () {
      expect(
        debtStatus(active: 3, overdue: 0, iOwe: 0, owedToMe: 0).text,
        '৩টি সক্রিয়',
      );
    });
  });

  group('recurringStatus', () {
    test(
      'none marked',
      () => expect(recurringStatus(active: 0).text, 'কিছু চিহ্নিত নেই'),
    );

    test('count only when nothing is coming', () {
      expect(recurringStatus(active: 3).text, '৩টি নিয়মিত');
    });

    test('with the next one', () {
      final s = recurringStatus(active: 3, next: _ob());
      expect(
        s.text,
        '৩টি নিয়মিত · পরেরটি: বাড়িভাড়া ${BanglaFormatters.dayMonthLong(DateTime(2026, 10, 16))}',
      );
    });
  });

  group('upcomingStripStatus', () {
    test('nothing coming -> no strip', () {
      expect(upcomingStripStatus(const UpcomingObligations.empty()), isNull);
    });

    test('count and total', () {
      final s = upcomingStripStatus(
        UpcomingObligations([
          _ob(amount: 15000),
          _ob(kind: ObligationKind.debt, amount: 5000),
        ]),
      )!;
      expect(s.tone, StatusTone.normal);
      expect(s.text, 'আগামী ৩০ দিনে ২টি পরিশোধ · ${taka(20000)}');
    });

    test('overdue makes it an attention and says how many', () {
      final s = upcomingStripStatus(
        UpcomingObligations([
          _ob(kind: ObligationKind.debt, amount: 5000, overdue: true),
          _ob(amount: 15000),
        ]),
      )!;
      expect(s.tone, StatusTone.attention);
      expect(s.text, contains('১টি মেয়াদ পেরিয়েছে'));
    });
  });

  group('smsHubStatus', () {
    test('pending wins', () {
      expect(
        smsHubStatus(enabled: true, pending: 3).text,
        '৩টি লেনদেন নিশ্চিতের অপেক্ষায়',
      );
      // even if (oddly) not enabled: pending is what the user must act on
      expect(
        smsHubStatus(enabled: false, pending: 1).text,
        contains('অপেক্ষায়'),
      );
    });

    test('on, nothing pending', () {
      expect(
        smsHubStatus(enabled: true, pending: 0).text,
        startsWith('চালু আছে'),
      );
    });

    test('off -> invites turning it on', () {
      expect(
        smsHubStatus(enabled: false, pending: 0).text,
        startsWith('চালু করুন'),
      );
    });
  });
}
