import 'package:flutter/material.dart';

import '../../../../../core/config/feature_flags.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../screens/manual_add_screen.dart';

class DashboardEmptyState extends StatelessWidget {
  const DashboardEmptyState({super.key, required this.onOpenChat});

  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    // With AI off the chat surface is inert, so point the empty-state CTA at
    // manual entry instead of chat.
    final aiOn = FeatureFlags.aiEnabled;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: AppEmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: 'এখনো কোনো খরচ নেই',
        subtitle: aiOn
            ? 'চ্যাটে গিয়ে খরচ যোগ করুন'
            : 'ম্যানুয়ালি বা SMS থেকে খরচ যোগ করুন',
        actionLabel: aiOn ? 'চ্যাটে যান' : 'খরচ যোগ করুন',
        onAction: aiOn ? onOpenChat : () => showManualAddSheet(context),
        compact: true,
      ),
    );
  }
}
