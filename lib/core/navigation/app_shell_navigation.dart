import 'package:flutter/material.dart';

import '../config/feature_flags.dart';
import 'app_page_route.dart';
import '../../features/debt/presentation/screens/debt_detail_screen.dart';
import '../../features/debt/presentation/screens/debt_list_screen.dart';
import '../../features/expense/presentation/screens/analytics_screen.dart';
import '../../features/income/presentation/screens/income_list_screen.dart';
import '../../features/sms_import/presentation/screens/sms_history_screen.dart';
import '../../features/sms_import/presentation/screens/sms_import_screen.dart';
import '../../features/split/presentation/screens/split_bill_screen.dart';

/// The bottom-nav tabs, in §4 order. চ্যাট is only a visible tab when AI is
/// enabled (Phase 2); with AI off the shell shows the other four.
enum AppTab { home, chat, expenses, plan, more }

/// The tabs the shell renders, in order. চ্যাট appears only when AI is enabled,
/// so Phase 2 re-adds it in its §4 position simply by flipping the flag.
List<AppTab> visibleAppTabs({required bool aiEnabled}) => <AppTab>[
  AppTab.home,
  if (aiEnabled) AppTab.chat,
  AppTab.expenses,
  AppTab.plan,
  AppTab.more,
];

class AppShellNavigation {
  AppShellNavigation._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// The selected bottom-nav tab. Semantic (an [AppTab]), so callers never
  /// depend on a raw index — the shell maps the enum to a position.
  static final ValueNotifier<AppTab> selectedTab = ValueNotifier<AppTab>(
    AppTab.home,
  );

  /// The Analytics screen's internal sub-tab (Summary/Category/Wallet/Income/
  /// Anomaly). Read by [AnalyticsScreen] when it opens.
  static final ValueNotifier<int> analyticsTab = ValueNotifier<int>(0);

  static void openDashboard() => _setTab(AppTab.home);

  static void openChat() =>
      _setTab(FeatureFlags.aiEnabled ? AppTab.chat : AppTab.home);

  static void openExpenses() => _setTab(AppTab.expenses);

  static void openPlan() => _setTab(AppTab.plan);

  static void openMore() => _setTab(AppTab.more);

  /// Analytics is no longer a tab — it opens as a pushed screen. [tabIndex]
  /// selects its inner sub-tab.
  static void openAnalytics({int tabIndex = 0}) {
    analyticsTab.value = tabIndex;
    _pushFromRoot(const AnalyticsScreen());
  }

  /// Split is no longer a tab — it opens as a pushed screen (reachable from আরও).
  static void openSplit() => _pushFromRoot(const SplitBillScreen());

  static void openDebts() => _pushFromRoot(const DebtListScreen());

  static void openDebtDetail(int debtId) =>
      _pushFromRoot(DebtDetailScreen(debtId: debtId), slide: true);

  static void openIncome() => _pushFromRoot(const IncomeListScreen());

  static void openSmsImport() => _pushFromRoot(const SmsImportScreen());

  static void openSmsHistory() => _pushFromRoot(const SmsHistoryScreen());

  static void handlePayload(String? payload) {
    if (payload != null && payload.startsWith('debt:')) {
      final debtId = int.tryParse(payload.substring(5));
      if (debtId != null) {
        openDebtDetail(debtId);
      }
      return;
    }

    switch (payload) {
      case 'daily_reminder':
        // With AI off the chat tab is inert, so send the reminder to the
        // dashboard instead of a dead chat surface.
        if (FeatureFlags.aiEnabled) {
          openChat();
        } else {
          openDashboard();
        }
        break;
      case 'budget_alert':
        openDashboard();
        break;
      case 'anomaly_alert':
        openAnalytics(tabIndex: 4);
        break;
      case 'weekly_report':
        openAnalytics();
        break;
      case 'goal_reminder':
        openDashboard();
        break;
      case 'sms_import':
        openSmsImport();
        break;
      default:
        break;
    }
  }

  static void _setTab(AppTab tab) {
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      navigator.popUntil((route) => route.isFirst);
    }
    selectedTab.value = tab;
  }

  static void _pushFromRoot(Widget page, {bool slide = false}) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return;
    }
    navigator.popUntil((route) => route.isFirst);
    navigator.push(
      slide ? AppSlideRoute(builder: (_) => page) : buildAppRoute(page),
    );
  }
}
