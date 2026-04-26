import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/google_auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';

class GoogleDriveAuthCard extends ConsumerWidget {
  const GoogleDriveAuthCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(googleAuthProvider);
    final notifier = ref.read(googleAuthProvider.notifier);
    final session = state.session;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.all(AppRadius.card),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.cloud_sync_rounded,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Google Drive Backup',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: context.primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      session == null
                          ? 'ক্লাউড ব্যাকআপ চালু করতে একবার Google অ্যাকাউন্টে সাইন ইন করুন'
                          : '${session.displayName ?? 'Google account'} · ${session.email}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.secondaryTextColor,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: context.appColors.primary.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.all(AppRadius.card),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  session == null
                      ? Icons.info_outline_rounded
                      : Icons.verified_user_rounded,
                  size: 18,
                  color: session == null
                      ? context.appColors.primary
                      : AppColors.success,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    session == null
                        ? 'Backup setup-এর আগে debug/release SHA-1 add করে `android/app/google-services.json` বসাতে হবে। চাইলে `GOOGLE_WEB_CLIENT_ID` দিয়েও configure করতে পারবেন।'
                        : 'Sign-in ready. পরের ধাপে একই account দিয়ে Google Drive backup upload/download wire করা যাবে।',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.secondaryTextColor,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              state.errorMessage!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppActionButton(
                  label: session == null
                      ? 'Google দিয়ে সাইন ইন'
                      : 'সংযোগ বিচ্ছিন্ন করুন',
                  icon: session == null
                      ? Icons.login_rounded
                      : Icons.logout_rounded,
                  fullWidth: true,
                  onPressed: state.isBusy
                      ? null
                      : () async {
                          if (session == null) {
                            await notifier.signIn();
                            return;
                          }
                          await notifier.signOut(revokeAccess: true);
                        },
                ),
              ),
              if (session != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppActionButton(
                    label: 'সাইন আউট',
                    variant: AppActionButtonVariant.secondary,
                    fullWidth: true,
                    onPressed: state.isBusy ? null : () => notifier.signOut(),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
