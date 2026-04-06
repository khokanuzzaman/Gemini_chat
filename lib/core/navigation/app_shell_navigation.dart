import 'package:flutter/material.dart';

class AppShellNavigation {
  AppShellNavigation._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final ValueNotifier<int> selectedTab = ValueNotifier<int>(0);
  static final ValueNotifier<int> analyticsTab = ValueNotifier<int>(0);

  static void openDashboard() => _setTab(0);

  static void openChat() => _setTab(1);

  static void openExpenses() => _setTab(2);

  static void openAnalytics({int tabIndex = 0}) {
    analyticsTab.value = tabIndex;
    _setTab(3);
  }

  static void openSplit() => _setTab(4);

  static void handlePayload(String? payload) {
    switch (payload) {
      case 'daily_reminder':
        openChat();
        break;
      case 'budget_alert':
        openDashboard();
        break;
      case 'anomaly_alert':
        openAnalytics(tabIndex: 1);
        break;
      case 'weekly_report':
        openAnalytics();
        break;
      case 'goal_reminder':
        openDashboard();
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
