import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';

class SavingsRateInfoSheet extends StatelessWidget {
  const SavingsRateInfoSheet({super.key, required this.rate});

  final double rate;

  @override
  Widget build(BuildContext context) {
    final rateColor = rate >= 20
        ? AppColors.success
        : (rate >= 10
            ? AppColors.warning
            : (rate >= 0 ? AppColors.primary : AppColors.error));

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('সঞ্চয়ের হার কী?', style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            Text(
              'আপনার আয়ের কত শতাংশ আপনি সঞ্চয় করছেন তা দেখায়।',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 16),
            _RateRow(label: '২০%+ — চমৎকার ✅'),
            _RateRow(label: '১০-২০% — ভালো 👍'),
            _RateRow(label: '০-১০% — শুরু 🌱'),
            _RateRow(label: 'নেগেটিভ — সতর্কতা ⚠️'),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: rateColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'আপনার হার: ${BanglaFormatters.count(rate.round())}%',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: rateColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RateRow extends StatelessWidget {
  const _RateRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(label, style: AppTextStyles.bodySmall),
    );
  }
}
