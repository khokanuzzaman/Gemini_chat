import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/core/navigation/app_shell_navigation.dart';
import 'package:gemini_chat/features/expense/presentation/widgets/dashboard/dashboard_header.dart';
import 'package:gemini_chat/features/expense/presentation/widgets/dashboard/insights_strip/anomaly_insight_page.dart';

void main() {
  setUp(() => AppShellNavigation.analyticsTab.value = AnalyticsTab.summary);

  testWidgets('home anomaly card opens the Analytics anomaly sub-tab', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AnomalyInsightPage(count: 3, highCount: 1)),
      ),
    );

    await tester.tap(find.byType(AnomalyInsightPage));
    await tester.pump();

    // Navigator is not mounted in this test, so only the requested sub-tab is
    // recorded — which is exactly the routing decision under test.
    expect(AppShellNavigation.analyticsTab.value, AnalyticsTab.anomaly);
  });

  group('header chart button', () {
    test('with the anomaly badge showing, lands on অ্যানোমালি', () {
      expect(analyticsTabForAnomalyBadge(1), AnalyticsTab.anomaly);
      expect(analyticsTabForAnomalyBadge(12), AnalyticsTab.anomaly);
    });

    test('with no alerts, lands on the summary', () {
      expect(analyticsTabForAnomalyBadge(0), AnalyticsTab.summary);
    });
  });

  group('notification payloads', () {
    test('anomaly_alert opens the anomaly sub-tab', () {
      AppShellNavigation.handlePayload('anomaly_alert');
      expect(AppShellNavigation.analyticsTab.value, AnalyticsTab.anomaly);
    });

    test('weekly_report opens the summary sub-tab', () {
      AppShellNavigation.analyticsTab.value = AnalyticsTab.anomaly;
      AppShellNavigation.handlePayload('weekly_report');
      expect(AppShellNavigation.analyticsTab.value, AnalyticsTab.summary);
    });
  });

  test(
    'sub-tab order is the display order (segmented control index == enum)',
    () {
      // The Analytics segmented control indexes straight into AnalyticsTab.values,
      // so this order is user-visible. Change it deliberately, not by accident.
      expect(AnalyticsTab.values, <AnalyticsTab>[
        AnalyticsTab.summary,
        AnalyticsTab.category,
        AnalyticsTab.wallet,
        AnalyticsTab.income,
        AnalyticsTab.anomaly,
      ]);
    },
  );
}
