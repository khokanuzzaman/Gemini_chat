// R4: the প্ল্যান and আরও hubs and the full "আসন্ন পরিশোধ" list, on the shared Home
// harness (every provider faked, "today" fixed at 6 Oct 2026).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gemini_chat/core/theme/app_theme.dart';
import 'package:gemini_chat/core/utils/bangla_formatters.dart';
import 'package:gemini_chat/features/debt/domain/entities/debt_entity.dart';
import 'package:gemini_chat/features/goals/domain/entities/goal_entity.dart';
import 'package:gemini_chat/features/expense/presentation/screens/dashboard_screen.dart';
import 'package:gemini_chat/features/more/presentation/screens/more_screen.dart';
import 'package:gemini_chat/features/obligations/presentation/screens/upcoming_obligations_screen.dart';
import 'package:gemini_chat/features/plan/presentation/screens/plan_screen.dart';

import '../../helpers/app_fonts.dart';
import '../../helpers/home_harness.dart';

List<GoalEntity> goals(int active) => [
  for (var i = 0; i < active; i++)
    GoalEntity(
      id: i + 1,
      title: 'লক্ষ্য $i',
      emoji: '🎯',
      targetAmount: 10000,
      savedAmount: 1000,
      targetDate: DateTime(2027, 1, 1),
      createdAt: DateTime(2026, 1, 1),
      status: GoalStatus.active,
    ),
];

/// The populated Home scenario plus [goals]; the plan data comes from it.
HomeScenario scenario({
  int activeGoals = 3,
  double? thisMonth,
  List<DebtEntity>? debts,
  bool smsEnabled = true,
  int smsPending = 3,
}) {
  final base = HomeScenario.populated();
  return HomeScenario(
    thisMonth: thisMonth ?? base.thisMonth,
    budget: base.budget,
    recurring: base.recurring,
    debts: debts ?? base.debts,
    goals: goals(activeGoals),
    wallets: base.wallets,
    smsEnabled: smsEnabled,
    smsPending: smsPending,
  );
}

DebtEntity overdueDebt() => DebtEntity(
  id: 7,
  personName: 'রহিম',
  type: DebtType.iOwe,
  originalAmount: 8000,
  remainingAmount: 8000,
  status: DebtStatus.active,
  createdAt: DateTime(2020, 1, 1),
  dueDate: DateTime(2020, 2, 1),
);

Future<void> pump(
  WidgetTester tester,
  HomeScenario s,
  Widget home, {
  double width = 360,
  double height = 800,
  double scale = 1,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    homeApp(s, home: home, textScale: scale, brightness: brightness),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Color? textColor(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  setUpAll(() async {
    await loadAppFonts();
    await initializeDateFormatting('bn');
  });

  String taka(num v) => BanglaFormatters.currency(v);
  // Hub status lines keep the symbol glued to the number (non-breaking space).
  String hub(num v) => taka(v).replaceAll(' ', '\u00A0');

  group('প্ল্যান hub', () {
    testWidgets('four cards in order, each with a live one-line status', (
      tester,
    ) async {
      await pump(tester, scenario(), const PlanScreen());

      final titles = ['বাজেট', 'লক্ষ্য', 'দেনা-পাওনা', 'নিয়মিত খরচ'];
      final tops = [for (final t in titles) tester.getTopLeft(find.text(t)).dy];
      expect(tops, [...tops]..sort(), reason: 'order top to bottom');

      expect(
        find.text('এই মাসে ${hub(41890)} / ${hub(60000)} · ৬৯%'),
        findsOneWidget,
      );
      expect(find.text('৩টি সক্রিয় লক্ষ্য'), findsOneWidget);
      expect(find.text('আমি দেব ${hub(50000)}'), findsOneWidget);
      expect(
        find.text(
          '১টি নিয়মিত · পরেরটি: বাড়িভাড়া ${BanglaFormatters.dayMonthLong(DateTime(2026, 10, 16))}',
        ),
        findsOneWidget,
      );
    });

    testWidgets('the upcoming strip summarises what is due and sits on top', (
      tester,
    ) async {
      await pump(tester, scenario(), const PlanScreen());
      final strip = find.text('আগামী ৩০ দিনে ২টি পরিশোধ · ${hub(20000)}');
      expect(strip, findsOneWidget);
      expect(
        tester.getTopLeft(strip).dy,
        lessThan(tester.getTopLeft(find.text('বাজেট')).dy),
      );
    });

    testWidgets('first run: prompts instead of numbers, no strip', (
      tester,
    ) async {
      await pump(tester, HomeScenario.empty(), const PlanScreen());
      expect(find.text('বাজেট ঠিক করুন'), findsOneWidget);
      expect(find.text('প্রথম লক্ষ্য ঠিক করুন'), findsOneWidget);
      expect(find.text('কোনো ঋণ নেই'), findsOneWidget);
      expect(find.text('কিছু চিহ্নিত নেই'), findsOneWidget);
      expect(find.textContaining('আগামী ৩০ দিনে'), findsNothing);
    });

    testWidgets('over budget and an overdue debt use the danger colour', (
      tester,
    ) async {
      await pump(
        tester,
        scenario(thisMonth: 72500, debts: [overdueDebt()]),
        const PlanScreen(),
      );
      final danger = AppTokens.light.dangerText;
      expect(
        textColor(tester, '${hub(12500)} বেশি — বাজেট ছাড়িয়েছে'),
        danger,
      );
      expect(textColor(tester, '১টি মেয়াদ পেরিয়েছে'), danger);
      // a normal status is NOT danger
      expect(textColor(tester, '৩টি সক্রিয় লক্ষ্য'), isNot(danger));
    });

    testWidgets('দেনা-পাওনা carries the brass marker; the others do not', (
      tester,
    ) async {
      await pump(tester, scenario(), const PlanScreen());
      Color? circleOf(String title) {
        final tile = find.ancestor(
          of: find.text(title),
          matching: find.byType(Row),
        );
        final circle = find.descendant(
          of: tile.first,
          matching: find.byType(Container),
        );
        final decoration = tester.widget<Container>(circle.first).decoration;
        return (decoration as BoxDecoration?)?.color;
      }

      expect(circleOf('দেনা-পাওনা'), AppTokens.light.brassSoft);
      expect(circleOf('বাজেট'), AppTokens.light.primarySoft);
    });

    testWidgets('the strip opens the full upcoming list', (tester) async {
      await pump(tester, scenario(), const PlanScreen());
      await tester.tap(find.textContaining('আগামী ৩০ দিনে'));
      await tester.pumpAndSettle();
      expect(find.byType(UpcomingObligationsScreen), findsOneWidget);
    });
  });

  group('আসন্ন পরিশোধ list', () {
    testWidgets('grouped by how soon, with a total per group', (tester) async {
      await pump(tester, scenario(), const UpcomingObligationsScreen());
      expect(find.text('এই সপ্তাহে'), findsOneWidget); // EMI on the 10th
      expect(find.text('এই মাসে'), findsOneWidget); // rent on the 16th
      expect(find.text('City Bank'), findsOneWidget);
      expect(find.text('বাড়িভাড়া'), findsOneWidget);
      expect(find.text(taka(5000)), findsWidgets);
      expect(find.text(taka(15000)), findsWidgets);
    });

    testWidgets('overdue comes first and says so', (tester) async {
      await pump(
        tester,
        scenario(debts: [overdueDebt()]),
        const UpcomingObligationsScreen(),
      );
      expect(find.text('মেয়াদ পেরিয়েছে'), findsOneWidget);
      final overdue = tester.getTopLeft(find.text('মেয়াদ পেরিয়েছে')).dy;
      expect(overdue, lessThan(tester.getTopLeft(find.text('এই মাসে')).dy));
    });

    testWidgets('nothing due: an explicit empty state', (tester) async {
      await pump(
        tester,
        HomeScenario.empty(),
        const UpcomingObligationsScreen(),
      );
      expect(find.text('আগামী ৩০ দিনে কিছু বাকি নেই'), findsOneWidget);
    });
  });

  group('আরও hub', () {
    testWidgets('SMS আমদানি is on top, brass, with a live status', (
      tester,
    ) async {
      await pump(tester, scenario(), const MoreScreen());
      final sms = find.text('SMS আমদানি');
      expect(sms, findsOneWidget);
      expect(find.text('৩টি লেনদেন নিশ্চিতের অপেক্ষায়'), findsOneWidget);
      expect(
        tester.getTopLeft(sms).dy,
        lessThan(tester.getTopLeft(find.text('বিশ্লেষণ')).dy),
      );
      // Brass as a FILL: the tile background is brassSoft.
      final tile = find
          .ancestor(of: sms, matching: find.byType(Material))
          .first;
      expect(tester.widget<Material>(tile).color, AppTokens.light.brassSoft);
    });

    testWidgets('then the grouped rows, in the spec order', (tester) async {
      await pump(tester, scenario(), const MoreScreen());
      final rows = [
        'বিশ্লেষণ',
        'ওয়ালেট',
        'ক্যাটাগরি',
        'আয়',
        'এক্সপোর্ট',
        'স্প্লিট বিল',
        'সেটিংস',
      ];
      final tops = [for (final r in rows) tester.getTopLeft(find.text(r)).dy];
      expect(tops, [...tops]..sort());
      // icon + label + chevron only: no static subtitles any more.
      expect(find.textContaining('CSV'), findsNothing);
      expect(find.textContaining('ক্যাশ, বিকাশ'), findsNothing);
    });

    testWidgets('SMS status: enabled with nothing pending', (tester) async {
      await pump(
        tester,
        scenario(smsEnabled: true, smsPending: 0),
        const MoreScreen(),
      );
      expect(find.textContaining('চালু আছে'), findsOneWidget);
    });

    testWidgets('SMS status: off invites turning it on', (tester) async {
      await pump(
        tester,
        scenario(smsEnabled: false, smsPending: 0),
        const MoreScreen(),
      );
      expect(find.textContaining('চালু করুন'), findsOneWidget);
    });
  });

  group('Home links to the same list', () {
    testWidgets('"সব দেখুন" on the upcoming row opens it', (tester) async {
      await pump(tester, HomeScenario.populated(), const DashboardScreen());
      final link = find.byKey(const Key('home-upcoming-see-all'));
      await tester.ensureVisible(link);
      await tester.pump();
      await tester.tap(link);
      await tester.pumpAndSettle();
      expect(find.byType(UpcomingObligationsScreen), findsOneWidget);
    });
  });

  group('no overflow (320/360/411 × 568/640/850 × 1.0/1.3 × light/dark)', () {
    for (final width in [320.0, 360.0, 411.0]) {
      for (final height in [568.0, 640.0, 850.0]) {
        for (final scale in [1.0, 1.3]) {
          for (final brightness in Brightness.values) {
            final tag =
                '${width.toInt()}x${height.toInt()} ×$scale ${brightness.name}';
            final stress = scenario(thisMonth: 7250000, debts: [overdueDebt()]);

            testWidgets('plan, $tag', (tester) async {
              await pump(
                tester,
                stress,
                const PlanScreen(),
                width: width,
                height: height,
                scale: scale,
                brightness: brightness,
              );
              expect(tester.takeException(), isNull);
            });
            testWidgets('plan (first run), $tag', (tester) async {
              await pump(
                tester,
                HomeScenario.empty(),
                const PlanScreen(),
                width: width,
                height: height,
                scale: scale,
                brightness: brightness,
              );
              expect(tester.takeException(), isNull);
            });
            testWidgets('more, $tag', (tester) async {
              await pump(
                tester,
                stress,
                const MoreScreen(),
                width: width,
                height: height,
                scale: scale,
                brightness: brightness,
              );
              expect(tester.takeException(), isNull);
            });
            testWidgets('more (sms off), $tag', (tester) async {
              await pump(
                tester,
                scenario(smsEnabled: false, smsPending: 0),
                const MoreScreen(),
                width: width,
                height: height,
                scale: scale,
                brightness: brightness,
              );
              expect(tester.takeException(), isNull);
            });
            testWidgets('upcoming list, $tag', (tester) async {
              await pump(
                tester,
                stress,
                const UpcomingObligationsScreen(),
                width: width,
                height: height,
                scale: scale,
                brightness: brightness,
              );
              expect(tester.takeException(), isNull);
            });
          }
        }
      }
    }
  });
}
