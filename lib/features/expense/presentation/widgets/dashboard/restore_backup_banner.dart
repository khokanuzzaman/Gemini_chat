import 'package:flutter/material.dart';

import '../../../../../core/backup/backup_models.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/bangla_formatters.dart';
import '../../../../../core/widgets/widgets.dart';

class RestoreBackupBanner extends StatelessWidget {
  const RestoreBackupBanner({
    super.key,
    required this.info,
    required this.onRestore,
    required this.onSkip,
  });

  final BackupFileInfo info;
  final VoidCallback onRestore;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.cardAll,
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.45),
          width: 1.4,
        ),
      ),
      child: AppCard(
        elevation: 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.cloud_download_rounded,
                  color: AppColors.success,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'পূর্বের ব্যাকআপ পাওয়া গেছে',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: context.primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${BanglaFormatters.fullDate(info.modifiedAt)} · ${_formatSize(info.sizeBytes)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppActionButton(
                    label: 'রিস্টোর করুন',
                    fullWidth: true,
                    onPressed: onRestore,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppActionButton(
                    label: 'এড়িয়ে যান',
                    fullWidth: true,
                    variant: AppActionButtonVariant.ghost,
                    onPressed: onSkip,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatSize(int sizeBytes) {
    if (sizeBytes <= 0) {
      return '0 B';
    }
    if (sizeBytes < 1024) {
      return '$sizeBytes B';
    }
    final kb = sizeBytes / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    }
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }
}
