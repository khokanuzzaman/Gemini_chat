import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_providers.dart';
import '../../../../core/analytics/usage_analytics.dart';
import '../../../../core/navigation/app_page_route.dart';
import '../../../../core/navigation/app_shell_navigation.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../category/presentation/screens/category_management_screen.dart';
import '../../../export/presentation/screens/export_screen.dart';
import '../../../plan/domain/plan_status.dart';
import '../../../settings/settings_screen.dart';
import '../../../sms_import/presentation/providers/sms_import_provider.dart';
import '../../../sms_import/presentation/screens/sms_import_screen.dart';
import '../../../wallet/presentation/screens/wallet_management_screen.dart';

/// আরও tab (DESIGN_SPEC §3.5): SMS আমদানি — the moat — on top with the brass
/// accent and a live status, then grouped rows (icon · label · chevron):
/// বিশ্লেষণ │ ওয়ালেট · ক্যাটাগরি · আয় │ এক্সপোর্ট · স্প্লিট বিল │ সেটিংস.
/// Security, backup and theme live inside the full Settings screen.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sms = ref.watch(smsAutoImportProvider);
    final smsStatus = smsHubStatus(
      enabled: sms.isEnabled,
      pending: sms.pendingTransactions.length,
    );

    void track(AnalyticsFeature feature) =>
        ref.read(usageAnalyticsProvider).featureOpen(feature);

    return AppPageScaffold(
      title: 'আরও',
      showBackButton: false,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SmsHubTile(
              status: smsStatus.text,
              hasPending: sms.pendingTransactions.isNotEmpty,
              onTap: () {
                track(AnalyticsFeature.smsImport);
                SmsImportScreen.push(context);
              },
            ),
            const SizedBox(height: AppSpacing.cardGap),
            _HubGroup(
              rows: [
                HubTile(
                  dense: true,
                  icon: Icons.bar_chart_rounded,
                  title: 'বিশ্লেষণ',
                  onTap: () {
                    track(AnalyticsFeature.analytics);
                    AppShellNavigation.openAnalytics();
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.cardGap),
            _HubGroup(
              rows: [
                HubTile(
                  dense: true,
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'ওয়ালেট',
                  onTap: () {
                    track(AnalyticsFeature.wallets);
                    Navigator.of(
                      context,
                    ).push(buildAppRoute(const WalletManagementScreen()));
                  },
                ),
                HubTile(
                  dense: true,
                  icon: Icons.category_rounded,
                  title: 'ক্যাটাগরি',
                  onTap: () {
                    track(AnalyticsFeature.categories);
                    Navigator.of(
                      context,
                    ).push(buildAppRoute(const CategoryManagementScreen()));
                  },
                ),
                HubTile(
                  dense: true,
                  icon: Icons.trending_up_rounded,
                  title: 'আয়',
                  onTap: AppShellNavigation.openIncome,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.cardGap),
            _HubGroup(
              rows: [
                HubTile(
                  dense: true,
                  icon: Icons.ios_share_rounded,
                  title: 'এক্সপোর্ট',
                  onTap: () {
                    track(AnalyticsFeature.export);
                    Navigator.of(
                      context,
                    ).push(buildAppRoute(const ExportScreen()));
                  },
                ),
                HubTile(
                  dense: true,
                  icon: Icons.call_split_rounded,
                  title: 'স্প্লিট বিল',
                  onTap: () {
                    track(AnalyticsFeature.split);
                    AppShellNavigation.openSplit();
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.cardGap),
            _HubGroup(
              rows: [
                HubTile(
                  dense: true,
                  icon: Icons.settings_rounded,
                  title: 'সেটিংস',
                  onTap: () {
                    track(AnalyticsFeature.settings);
                    Navigator.of(context).push(
                      AppSlideRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A card of [HubTile]s separated by hairlines.
class _HubGroup extends StatelessWidget {
  const _HubGroup({required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, row) in rows.indexed) ...[
            row,
            if (i != rows.length - 1)
              Divider(
                height: 1,
                indent: 64,
                endIndent: 16,
                color: context.tokens.line,
              ),
          ],
        ],
      ),
    );
  }
}

/// The moat. Brass is a FILL here: a brass-soft tile, a solid brass circle with the
/// on-brass glyph, ink text — never brass text or icons on a light surface.
class _SmsHubTile extends StatelessWidget {
  const _SmsHubTile({
    required this.status,
    required this.hasPending,
    required this.onTap,
  });

  final String status;
  final bool hasPending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      button: true,
      label: 'SMS আমদানি, $status',
      excludeSemantics: true,
      child: Material(
        color: tokens.brassSoft,
        borderRadius: AppRadius.cardAll,
        child: InkWell(
          borderRadius: AppRadius.cardAll,
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: tokens.brass,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.sms_rounded,
                    size: 24,
                    color: tokens.onBrass,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SMS আমদানি',
                        style: AppTextStyles.titleLarge.copyWith(
                          color: tokens.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        status,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: hasPending ? tokens.ink : tokens.muted,
                          fontWeight: hasPending ? FontWeight.w600 : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: tokens.ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
