import 'package:flutter/material.dart';

import '../../../../core/animations/app_pulse.dart';
import '../../../../core/theme/app_theme.dart';

class RecordingIndicator extends StatelessWidget {
  const RecordingIndicator({super.key, required this.duration});

  final String duration;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: const BorderRadius.all(AppRadius.input),
      ),
      child: Row(
        children: [
          AppPulse(
            minScale: 0.8,
            maxScale: 1.2,
            duration: const Duration(milliseconds: 800),
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'ভয়েস রেকর্ড হচ্ছে $duration',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
