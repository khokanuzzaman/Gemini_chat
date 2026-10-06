import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/auth/google_auth_provider.dart';
import '../../../../../core/navigation/app_shell_navigation.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/bangla_formatters.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../anomaly/presentation/providers/anomaly_provider.dart';
import '../../providers/expense_providers.dart';

/// Where the header chart button should land. When the red anomaly badge is
/// showing, the user is being told "something unusual" — so take them to the
/// অ্যানোমালি sub-tab; with no alerts it is just the Analytics summary.
AnalyticsTab analyticsTabForAnomalyBadge(int highSeverityCount) {
  return highSeverityCount > 0 ? AnalyticsTab.anomaly : AnalyticsTab.summary;
}

class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(googleAuthProvider).session;
    final firstName = (session?.displayName ?? '').trim().split(' ').first;
    final greeting = _timeGreeting();
    final title = firstName.isEmpty ? greeting : '$greeting, $firstName';
    final lastRefreshed = ref.watch(dashboardLastRefreshedAtProvider);
    final anomalyCount = ref.watch(anomalyProvider).highSeverityCount;
    final secondLine = lastRefreshed == null
        ? 'টানুন রিফ্রেশ করতে'
        : 'শেষ আপডেট: ${BanglaFormatters.relativeFromNow(lastRefreshed)}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: context.primaryTextColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                secondLine,
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
        Badge(
          isLabelVisible: anomalyCount > 0,
          backgroundColor: AppColors.error,
          label: Text(anomalyCount > 9 ? '9+' : '$anomalyCount'),
          child: IconButton(
            icon: Icon(
              Icons.bar_chart_rounded,
              color: context.primaryTextColor,
            ),
            tooltip: 'বিশ্লেষণ',
            onPressed: () => AppShellNavigation.openAnalytics(
              tab: analyticsTabForAnomalyBadge(anomalyCount),
            ),
          ),
        ),
        const GlobalSettingsButton(),
      ],
    );
  }

  String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'সুপ্রভাত';
    if (hour < 17) return 'শুভ দুপুর';
    if (hour < 20) return 'শুভ সন্ধ্যা';
    return 'শুভ রাত্রি';
  }
}
