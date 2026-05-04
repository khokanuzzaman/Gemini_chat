import 'package:flutter/material.dart';

import '../../../../../core/widgets/widgets.dart';

class DashboardEmptyState extends StatelessWidget {
  const DashboardEmptyState({super.key, required this.onOpenChat});

  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: AppEmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: 'এখনো কোনো খরচ নেই',
        subtitle: 'চ্যাটে গিয়ে খরচ যোগ করুন',
        actionLabel: 'চ্যাটে যান',
        onAction: onOpenChat,
        compact: true,
      ),
    );
  }
}
