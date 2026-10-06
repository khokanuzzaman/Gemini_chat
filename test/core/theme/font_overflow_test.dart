import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/core/theme/app_theme.dart';
import 'package:gemini_chat/core/utils/bangla_formatters.dart';
import 'package:gemini_chat/core/widgets/widgets.dart';
import 'package:gemini_chat/features/expense/presentation/providers/expense_providers.dart';
import 'package:gemini_chat/features/expense/presentation/widgets/dashboard/insights_strip/insights_strip.dart';
import 'package:gemini_chat/features/expense/presentation/widgets/dashboard/insights_strip/wallets_insight_page.dart';
import 'package:gemini_chat/features/expense/presentation/widgets/dashboard/net_worth_hero_card.dart';
import 'package:gemini_chat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:gemini_chat/features/wallet/presentation/providers/wallet_provider.dart';

import '../../helpers/app_fonts.dart';

/// R0b: Inter/Sora + Noto Sans Bengali are taller than the platform default and
/// Bengali has tall matras, so re-check the tightest layouts under the REAL
/// fonts (see `loadAppFonts`). A Flutter overflow is a thrown exception, so
/// `tester.takeException()` is the assertion.
///
/// Sizes: 320dp is the narrowest phone we support, 360dp the common small one.
/// 1.3 is a typical Android "larger text" setting.

class _FakeWallets extends WalletNotifier {
  _FakeWallets(this._wallets);
  final List<WalletEntity> _wallets;

  @override
  Future<List<WalletEntity>> build() async => _wallets;
}

WalletEntity _wallet(int id, String name, WalletType type, double balance) {
  final now = DateTime(2026, 10, 6);
  return WalletEntity(
    id: id,
    name: name,
    type: type,
    emoji: '👛',
    initialBalance: 0,
    currentBalance: balance,
    accountNumber: null,
    note: null,
    sortOrder: id,
    isArchived: false,
    createdAt: now,
    updatedAt: now,
  );
}

final _wallets = [
  _wallet(1, 'নগদ টাকা', WalletType.cash, 12495000),
  _wallet(2, 'ব্র্যাক ব্যাংক সঞ্চয়ী হিসাব', WalletType.bank, 9999999),
  _wallet(3, 'বিকাশ', WalletType.bkash, 2335),
];

List<Override> get _overrides => [
  walletProvider.overrideWith(() => _FakeWallets(_wallets)),
  walletMonthlySpentProvider.overrideWith((ref, id) async => 1234567),
  cashFlowProvider.overrideWith(
    (ref) async => const CashFlowData(
      income: 9999999,
      expense: 8765432,
      lastMonthIncome: 100,
      lastMonthExpense: 90,
    ),
  ),
];

Future<void> _pump(
  WidgetTester tester, {
  required Brightness brightness,
  required double width,
  required double textScale,
  required Widget child,
}) async {
  tester.view.physicalSize = Size(width, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: brightness == Brightness.dark
            ? AppTheme.darkTheme()
            : AppTheme.lightTheme(),
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: app!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    ),
  );
  // Let the async providers resolve; avoid pumpAndSettle (shimmers loop).
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

Widget _amountField() {
  // Mirrors manual_add_screen.dart `_AmountFieldCard` (private) — the add-expense
  // "keypad": a numeric TextField in heroAmount with a ৳ prefix.
  return Builder(
    builder: (context) => Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: context.mutedSurfaceColor,
        borderRadius: AppRadius.cardAll,
      ),
      child: Column(
        children: [
          Text('পরিমাণ', style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: TextField(
              controller: TextEditingController(text: '১,২৪,৯৫০.৫০'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              style: AppTextStyles.heroAmount,
              decoration: InputDecoration(
                hintText: '0',
                prefixText: '${BanglaFormatters.currencySymbol} ',
                prefixStyle: AppTextStyles.heroAmount,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _bottomNav() {
  // Mirrors main.dart's shell NavigationBar (72dp, labels always shown) and its
  // private `_NavIcon` (6dp dot + 6dp gap + icon).
  Widget icon(IconData data) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const SizedBox(width: 6, height: 6),
      const SizedBox(height: 6),
      Icon(data),
    ],
  );
  const labels = {
    'হোম': Icons.home_rounded,
    'চ্যাট': Icons.chat_bubble_rounded,
    'খরচ': Icons.receipt_long_rounded,
    'প্ল্যান': Icons.checklist_rounded,
    'আরও': Icons.grid_view_rounded,
  };
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    child: NavigationBar(
      height: 72,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      selectedIndex: 0,
      destinations: [
        for (final e in labels.entries)
          NavigationDestination(icon: icon(e.value), label: e.key),
      ],
    ),
  );
}

void main() {
  setUpAll(loadAppFonts);

  final scenarios = <String, Widget Function()>{
    'Home hero (NetWorthHeroCard)': () => NetWorthHeroCard(onTap: () {}),
    'AppHeroCard (fixed 140dp)': () => const AppHeroCard(
      label: 'এই মাসের খরচ',
      amount: '৳ ৯৯,৯৯,৯৯৯',
      subtitle: 'গত মাসের চেয়ে ১২% বেশি',
      icon: Icons.trending_down_rounded,
    ),
    'Wallet strip (224dp, grows with text scale)': () => Builder(
      builder: (context) => SizedBox(
        height: insightStripHeight(context),
        child: const WalletsInsightPage(),
      ),
    ),
    'Stat cards (এই মাসের খরচ)': () => const Row(
      children: [
        Expanded(
          child: AppStatCard(label: 'এই মাসের খরচ', value: '৳ ৮৭,৬৫,৪৩২'),
        ),
        SizedBox(width: 12),
        Expanded(
          child: AppStatCard(label: 'এই মাসের আয়', value: '৳ ৯৯,৯৯,৯৯৯'),
        ),
      ],
    ),
    'List rows': () => Column(
      children: const [
        AppListTile(
          title: 'বিকাশ থেকে ক্যাশ আউট চার্জ ও সরকারি ভ্যাট',
          subtitle: 'স্বয়ংক্রিয়ভাবে যোগ হয়েছে · ০৬ অক্টোবর ২০২৬',
          leadingEmoji: '💸',
          trailingAmount: 12495000,
          trailingAmountIsExpense: true,
          trailingSubtitle: 'নগদ টাকা',
        ),
        AppListTile(
          title: 'ক্ষ ত্র জ্ঞ ষ্ঠ ন্দ্র',
          subtitle: 'বেতন',
          leadingEmoji: '💰',
          trailingAmount: 9999999,
          trailingAmountIsIncome: true,
          dense: true,
        ),
      ],
    ),
    'Add-expense amount field': _amountField,
    'Bottom nav labels': _bottomNav,
  };

  for (final brightness in [Brightness.light, Brightness.dark]) {
    for (final width in [320.0, 360.0]) {
      for (final scale in [1.0, 1.3]) {
        for (final entry in scenarios.entries) {
          testWidgets(
            '${entry.key} — ${brightness.name}, ${width.toInt()}dp, ×$scale',
            (tester) async {
              await _pump(
                tester,
                brightness: brightness,
                width: width,
                textScale: scale,
                child: entry.value(),
              );
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  }
}
