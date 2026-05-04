import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';

class ChatScanningOverlay extends StatelessWidget {
  const ChatScanningOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        child: ColoredBox(
          color: context.primaryTextColor.withValues(alpha: 0.56),
          child: Center(
            child: AppCard(
              elevation: 4,
              borderRadius: const BorderRadius.all(AppRadius.heroCard),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 14),
                  Text(
                    'Receipt পড়ছি...',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: context.primaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ChatRagStatusBanner extends StatelessWidget {
  const ChatRagStatusBanner({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: const BorderRadius.all(AppRadius.card),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 18,
            color: context.ragChipTextColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Personal data ব্যবহার হচ্ছে',
              style: AppTextStyles.caption.copyWith(
                color: context.ragChipTextColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          InkWell(
            onTap: onDismiss,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: context.ragChipTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatRagIndicatorChip extends StatelessWidget {
  const ChatRagIndicatorChip({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.ragChipBackgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: context.appColors.primary.withValues(alpha: 0.16),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.storage_rounded,
              size: 14,
              color: context.ragChipTextColor,
            ),
            const SizedBox(width: 6),
            Text(
              'আপনার data থেকে',
              style: AppTextStyles.caption.copyWith(
                color: context.ragChipTextColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
