// FIX 3: the বাজেট প্ল্যানার screen — no AI reachable with the flag off, local
// rule-based suggestions that write only on a tap, Bengali numerals and category
// names, risk ordering and thresholds, and breathing room between cards.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gemini_chat/core/config/feature_flags.dart';
import 'package:gemini_chat/core/theme/app_theme.dart';
import 'package:gemini_chat/core/widgets/app_hero_card.dart';
import 'package:gemini_chat/core/widgets/app_progress_bar.dart';
import 'package:gemini_chat/features/budget/domain/budget_suggestions.dart';
import 'package:gemini_chat/features/budget/domain/entities/budget_plan_entity.dart';
import 'package:gemini_chat/features/budget/presentation/providers/budget_provider.dart';
import 'package:gemini_chat/features/budget/presentation/screens/budget_planner_screen.dart';
import 'package:gemini_chat/features/category/domain/entities/category_entity.dart';
import 'package:gemini_chat/features/category/presentation/providers/category_provider.dart';
import 'package:gemini_chat/features/expense/domain/entities/expense_entity.dart';
import 'package:gemini_chat/features/expense/domain/repositories/expense_repository.dart';
import 'package:gemini_chat/features/expense/presentation/providers/expense_providers.dart';

import '../../helpers/app_fonts.dart';

class _MockExpenseRepo extends Mock implements ExpenseRepository {}

class _FakeCategories extends CategoryNotifier {
  @override
  List<CategoryEntity> build() => defaultCategories;
}

class _FakeBudget extends BudgetNotifier {
  _FakeBudget(this.plan, this.applied);

  final BudgetPlanEntity plan;
  final List<List<CategoryLimitSuggestion>> applied;

  @override
  BudgetState build() => BudgetState(activeBudget: plan, allBudgets: [plan]);

  @override
  Future<void> applyLimitSuggestions(
    Iterable<CategoryLimitSuggestion> suggestions,
  ) async {
    applied.add(suggestions.toList());
  }
}

final _now = DateTime.now();
final _plan = BudgetPlanEntity(
  id: 1,
  monthlyIncome: 40000,
  categoryBudgets: const {
    'Food': 5000,
    'Healthcare': 1000,
    'Bill': 2000,
    'Other': 800,
  },
  totalBudgeted: 8800,
  savingsAmount: 31200,
  savingsPercentage: 78,
  aiExplanation: 'AI says hello',
  budgetRule: BudgetRule.seventyTwentyTen,
  createdAt: DateTime(2026, 9, 1),
  updatedAt: DateTime(2026, 9, 1),
  isActive: true,
);

ExpenseEntity _spent(String category, double amount, DateTime date) =>
    ExpenseEntity(
      amount: amount,
      category: category,
      description: '',
      date: date,
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('bn');
    await loadAppFonts();
  });

  Future<List<List<CategoryLimitSuggestion>>> pump(
    WidgetTester tester, {
    double scale = 1.0,
    bool dark = false,
  }) async {
    await tester.binding.setSurfaceSize(const Size(400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repo = _MockExpenseRepo();
    // This month: Food 112% (over), Healthcare 90% (near), Bill 30%, Other 12.5%.
    when(() => repo.getThisMonthExpenses()).thenAnswer(
      (_) async => [
        _spent('Food', 5600, _now),
        _spent('Healthcare', 900, _now),
        _spent('Bill', 600, _now),
        _spent('Other', 100, _now),
      ],
    );
    // Last months: Food 3,000 / Bill 2,237 a month — both differ from the plan.
    final m1 = DateTime(_now.year, _now.month - 1, 10);
    final m2 = DateTime(_now.year, _now.month - 2, 10);
    final m3 = DateTime(_now.year, _now.month - 3, 10);
    when(() => repo.getExpensesByDateRange(any(), any())).thenAnswer(
      (_) async => [
        for (final d in [m1, m2, m3]) ...[
          _spent('Food', 3000, d),
          _spent('Bill', 2237, d),
        ],
      ],
    );

    final applied = <List<CategoryLimitSuggestion>>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expenseRepositoryProvider.overrideWithValue(repo),
          categoryProvider.overrideWith(_FakeCategories.new),
          budgetProvider.overrideWith(() => _FakeBudget(_plan, applied)),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const BudgetPlannerScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return applied;
  }

  List<String> allText(WidgetTester tester) => [
    for (final w in tester.widgetList<Text>(find.byType(Text)))
      if (w.data != null) w.data!,
  ];

  testWidgets(
    'AI off: no sparkle, no "AI" wording, no AI-note card on the dashboard',
    (tester) async {
      await pump(tester);
      expect(find.byIcon(Icons.auto_awesome_rounded), findsNothing);
      expect(find.textContaining('AI'), findsNothing);
      expect(find.text('AI says hello'), findsNothing);
      // The history action stays.
      expect(find.byIcon(Icons.history_rounded), findsOneWidget);
    },
    skip: FeatureFlags.aiEnabled,
  );

  testWidgets(
    'AI off: the new-budget form has no AI wording or entry point either',
    (tester) async {
      await pump(tester);
      await tester.scrollUntilVisible(
        find.text('নতুন বাজেট তৈরি করুন'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('নতুন বাজেট তৈরি করুন'));
      await tester.pumpAndSettle();
      expect(find.textContaining('AI'), findsNothing); // dialog too
      await tester.tap(find.text('চালিয়ে যান'));
      await tester.pumpAndSettle();
      expect(find.text('বাজেট সেভ করুন'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome_rounded), findsNothing);
      expect(find.textContaining('AI'), findsNothing);
      expect(
        allText(tester).where((t) => RegExp('[0-9]').hasMatch(t)),
        isEmpty,
        reason: 'preset chips / hero amount must be in Bengali numerals',
      );
    },
    skip: FeatureFlags.aiEnabled,
  );

  testWidgets('every number on the dashboard is in Bengali numerals', (
    tester,
  ) async {
    await pump(tester);
    final offenders = allText(
      tester,
    ).where((t) => RegExp('[0-9]').hasMatch(t)).toList();
    expect(offenders, isEmpty);
  });

  testWidgets('default categories show in Bengali, not Healthcare/Other/Bill', (
    tester,
  ) async {
    await pump(tester);
    for (final bn in ['খাবার', 'স্বাস্থ্য', 'বিল', 'অন্যান্য']) {
      expect(find.text(bn), findsWidgets);
    }
    for (final en in ['Food', 'Healthcare', 'Bill', 'Other']) {
      expect(find.text(en), findsNothing);
    }
  });

  testWidgets('old labels are gone; new ones in place', (tester) async {
    await pump(tester);
    expect(find.text('ব্যবহারের সারাংশ'), findsNothing);
    expect(find.text('অগ্রগতি'), findsNothing);
    expect(find.text('সঞ্চয় লক্ষ্য'), findsNothing);
    expect(find.text('সঞ্চয়ের জন্য থাকে'), findsOneWidget);
    expect(find.textContaining('৭০/২০/১০ নিয়ম'), findsWidgets);
    expect(find.textContaining('% খরচ হয়েছে'), findsNWidgets(4));
    expect(find.textContaining('% ব্যবহার হয়েছে'), findsOneWidget); // in hero
  });

  testWidgets('rows are sorted by risk and coloured by threshold', (
    tester,
  ) async {
    await pump(tester);
    final tokens = AppTokens.light;
    double y(String bn) => tester.getTopLeft(find.text(bn).first).dy;
    // Food 112% > Healthcare 90% > Bill 30% > Other 12.5%.
    expect(y('খাবার'), lessThan(y('স্বাস্থ্য')));
    expect(y('স্বাস্থ্য'), lessThan(y('বিল')));
    expect(y('বিল'), lessThan(y('অন্যান্য')));

    // Row bars (the hero's bar is the first AppProgressBar; it is white).
    final bars = tester.widgetList<AppProgressBar>(find.byType(AppProgressBar));
    final colors = bars.skip(1).map((b) => b.color).toList();
    expect(colors, [
      tokens.danger,
      tokens.warning,
      tokens.primary,
      tokens.primary,
    ]);
    // Danger only past 100%: spending the exact limit stays a warning.
    expect(limitLevel(1000, 1000), LimitLevel.nearLimit);
  });

  testWidgets('cards are separated by at least 12px', (tester) async {
    await pump(tester);
    final hero = tester.getRect(find.byType(AppHeroCard));
    final income = tester.getRect(find.text('মাসিক আয়').first);
    expect(income.top - hero.bottom, greaterThanOrEqualTo(12));
    // Every direct card in the column: next top − previous bottom >= 12.
    final cards =
        find
            .byWidgetPredicate((w) => w.runtimeType.toString() == 'AppCard')
            .evaluate()
            .map((e) => tester.getRect(find.byWidget(e.widget)))
            .toList()
          ..sort((a, b) => a.top.compareTo(b.top));
    for (var i = 1; i < cards.length; i++) {
      final a = cards[i - 1];
      final b = cards[i];
      // Skip rows that sit side by side and cards nested in another card.
      final nested = b.top < a.bottom;
      if (nested || (b.top - a.top).abs() < 1) continue;
      expect(b.top - a.bottom, greaterThanOrEqualTo(12));
    }
  });

  testWidgets('suggestions: local, with a reason, written only on a tap', (
    tester,
  ) async {
    final applied = await pump(tester);
    expect(find.text('সীমার পরামর্শ'), findsOneWidget);
    // Food 5,000 -> 3,000 (3-month average), Bill 2,000 -> 2,200 (2,237 rounded).
    expect(find.textContaining('গত ৩ মাসে গড়ে'), findsNWidgets(2));
    expect(applied, isEmpty, reason: 'nothing is written until the user taps');

    await tester.scrollUntilVisible(
      find.text('সবগুলো প্রয়োগ করুন'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('প্রয়োগ').first);
    await tester.pumpAndSettle();
    expect(applied, hasLength(1));
    expect(applied.single, hasLength(1));
    expect(applied.single.single.suggestedLimit % 100, 0);
  });

  testWidgets('no overflow at text scale ×1.3, light and dark', (tester) async {
    for (final dark in [false, true]) {
      await pump(tester, scale: 1.3, dark: dark);
      expect(tester.takeException(), isNull);
    }
  });
}
