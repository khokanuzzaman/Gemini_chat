import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/navigation/app_shell_navigation.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../providers/expense_providers.dart';
import 'dashboard_empty_state.dart';
import 'recent_transaction_tile.dart';

class RecentTransactionsCard extends ConsumerWidget {
  const RecentTransactionsCard({super.key, required this.onOpenChat});

  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardControllerProvider);
    final data = dashboard.valueOrNull;
    final recent = [...?data?.recentExpenses]
      ..sort((a, b) => b.date.compareTo(a.date));
    final top = recent.take(5).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: 'সাম্প্রতিক লেনদেন',
          action: TextButton(
            onPressed: AppShellNavigation.openExpenses,
            child: const Text('সব দেখুন →'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (top.isEmpty)
          DashboardEmptyState(onOpenChat: onOpenChat)
        else
          AppCard(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                for (var i = 0; i < top.length; i++) ...[
                  RecentTransactionTile(expense: top[i]),
                  if (i != top.length - 1)
                    Divider(
                      height: 1,
                      color: context.borderColor.withValues(alpha: 0.55),
                    ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
