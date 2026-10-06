import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/auth/google_auth_provider.dart';
import '../../../../../core/navigation/app_shell_navigation.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../anomaly/presentation/providers/anomaly_provider.dart';

/// Where the header chart button should land. When the anomaly badge is showing,
/// the user is being told "something unusual" — so take them to the অ্যানোমালি
/// sub-tab; with no alerts it is just the Analytics summary.
AnalyticsTab analyticsTabForAnomalyBadge(int highSeverityCount) {
  return highSeverityCount > 0 ? AnalyticsTab.anomaly : AnalyticsTab.summary;
}

String homeGreeting(DateTime now) {
  final hour = now.hour;
  if (hour < 5) return 'শুভ রাত্রি';
  if (hour < 12) return 'শুভ সকাল';
  if (hour < 17) return 'শুভ দুপুর';
  if (hour < 20) return 'শুভ সন্ধ্যা';
  return 'শুভ রাত্রি';
}

/// First word of the signed-in display name, or null when not signed in.
String? firstNameOf(String? displayName) {
  final trimmed = (displayName ?? '').trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return trimmed.split(RegExp(r'\s+')).first;
}

/// "শুভ সকাল" over the user's first name (only when signed in), then the
/// analytics button (with the anomaly badge, only when there are alerts) and
/// settings.
class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key, this.now});

  /// Injected clock for tests.
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = firstNameOf(
      ref.watch(googleAuthProvider).session?.displayName,
    );
    final greeting = homeGreeting(now ?? DateTime.now());
    final anomalyCount = ref.watch(anomalyProvider).highSeverityCount;
    final tokens = context.tokens;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    (name == null
                            ? AppTextStyles.titleLarge
                            : AppTextStyles.bodySmall)
                        .copyWith(
                          color: name == null ? tokens.ink : tokens.muted,
                        ),
              ),
              if (name != null)
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleLarge.copyWith(color: tokens.ink),
                ),
            ],
          ),
        ),
        Badge(
          isLabelVisible: anomalyCount > 0,
          backgroundColor: tokens.dangerFill,
          textColor: tokens.onFill,
          label: Text(anomalyCount > 9 ? '9+' : '$anomalyCount'),
          child: IconButton(
            icon: Icon(Icons.bar_chart_rounded, color: tokens.ink),
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
}
