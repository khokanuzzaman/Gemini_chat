import 'package:flutter/material.dart';

class AppShellNavigation {
  AppShellNavigation._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final ValueNotifier<int> selectedTab = ValueNotifier<int>(0);

  static void openDashboard() => _setTab(0);

  static void openChat() => _setTab(1);

  static void openExpenses() => _setTab(2);

  static void openAnalytics() => _setTab(3);

  static void handlePayload(String? payload) {
    switch (payload) {
      case 'daily_reminder':
        openChat();
        break;
      case 'budget_alert':
        openDashboard();
        break;
      case 'weekly_report':
        openAnalytics();
        break;
      default:
        break;
    }
  }

  static void _setTab(int index) {
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      navigator.popUntil((route) => route.isFirst);
    }
    selectedTab.value = index;
  }
}
