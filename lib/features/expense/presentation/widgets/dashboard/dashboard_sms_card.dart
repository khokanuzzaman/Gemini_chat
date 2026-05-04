import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/navigation/app_page_route.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/bangla_formatters.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../settings/settings_screen.dart';
import '../../../../sms_import/presentation/providers/sms_import_provider.dart';
import '../../../../sms_import/presentation/screens/sms_import_screen.dart';
import '../../../../sms_import/presentation/widgets/sms_import_entry_widgets.dart';

class DashboardSmsCard extends ConsumerStatefulWidget {
  const DashboardSmsCard({super.key});

  @override
  ConsumerState<DashboardSmsCard> createState() => _DashboardSmsCardState();
}

class _DashboardSmsCardState extends ConsumerState<DashboardSmsCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _pulseScale = Tween<double>(begin: 1, end: 1.015).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smsAutoImportProvider);

    if (!state.isEnabled) {
      _pulseController.stop();
      return const SmsImportDashboardTeaserCard();
    }

    if (state.hasPending) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
      return ScaleTransition(
        scale: _pulseScale,
        child: AppCard(
          onTap: () => SmsImportScreen.push(context),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.appColors.primary.withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.all(AppRadius.card),
                ),
                child: Icon(
                  Icons.sms_rounded,
                  color: context.appColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${BanglaFormatters.count(state.pendingTransactions.length)} টি নতুন লেনদেন পাওয়া গেছে',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: context.primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'ট্যাপ করে নিশ্চিত করুন',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      );
    }

    _pulseController.stop();
    return AppCard(
      onTap: () {
        Navigator.of(context).push(
          AppSlideRoute(builder: (_) => const SettingsScreen()),
        );
      },
      child: Row(
        children: [
          const Icon(Icons.sms_outlined, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'SMS স্বয়ংক্রিয় আমদানি চালু · শেষ স্ক্যান ${state.lastScanTime == null ? 'অজানা' : BanglaFormatters.relativeFromNow(state.lastScanTime!)}',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.secondaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
