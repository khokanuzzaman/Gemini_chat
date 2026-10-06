import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/navigation/app_shell_navigation.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/bangla_formatters.dart';
import '../../../../sms_import/presentation/providers/sms_import_provider.dart';
import '../../../../sms_import/presentation/screens/sms_import_screen.dart';

/// Pending count the user has hidden with ✕; the card returns when it changes
/// (a NEW detected transaction) — dismissing is never destructive.
final smsCardDismissedCountProvider = StateProvider<int?>((ref) => null);

/// The SMS moat: brass-soft card shown ONLY when detected transactions are
/// waiting to be confirmed. Brass is a fill here (on-brass text); never brass
/// text/icons on a light surface.
class HomeSmsCard extends ConsumerWidget {
  const HomeSmsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(smsAutoImportProvider);
    final count = state.pendingTransactions.length;
    final dismissed = ref.watch(smsCardDismissedCountProvider);
    if (!state.isEnabled || !state.hasPending || dismissed == count) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.cardGap),
      child: BrassSmsCard(
        title:
            'আপনার SMS থেকে ${BanglaFormatters.count(count)}টি লেনদেন পাওয়া গেছে',
        actionLabel: 'দেখুন ও নিশ্চিত করুন',
        onAction: () => SmsImportScreen.push(context),
        onDismiss: () =>
            ref.read(smsCardDismissedCountProvider.notifier).state = count,
      ),
    );
  }
}

/// First-run version: invites the user to turn SMS import on.
class HomeSmsTeaser extends ConsumerWidget {
  const HomeSmsTeaser({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(smsAutoImportProvider).isEnabled) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.cardGap),
      child: BrassSmsCard(
        title: 'SMS থেকে নিজে নিজে লেনদেন যোগ করুন',
        subtitle:
            'bKash, নগদ ও ব্যাংকের মেসেজ থেকে — ফোনের বাইরে কিছু যায় না।',
        actionLabel: 'চালু করুন',
        onAction: AppShellNavigation.openSmsImport,
      ),
    );
  }
}

class BrassSmsCard extends StatelessWidget {
  const BrassSmsCard({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.subtitle,
    this.onDismiss,
  });

  final String title;
  final String? subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: tokens.brassSoft,
        borderRadius: AppRadius.cardAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tokens.brass,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.sms_rounded, size: 18, color: tokens.onBrass),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: tokens.ink,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: tokens.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onDismiss != null)
                InkResponse(
                  onTap: onDismiss,
                  radius: 20,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: tokens.muted,
                      semanticLabel: 'পরে দেখব',
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: tokens.brass,
                foregroundColor: tokens.onBrass,
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                actionLabel,
                style: AppTextStyles.chipLabel.copyWith(color: tokens.onBrass),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
