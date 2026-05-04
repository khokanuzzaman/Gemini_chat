import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/auth/google_auth_provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/bangla_formatters.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../providers/expense_providers.dart';

class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(googleAuthProvider).session;
    final firstName = (session?.displayName ?? '').trim().split(' ').first;
    final greeting = _timeGreeting();
    final title = firstName.isEmpty ? greeting : '$greeting, $firstName';
    final lastRefreshed = ref.watch(dashboardLastRefreshedAtProvider);
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
