import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/account_deletion_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import 'account_deletion_controller.dart';

/// "অ্যাকাউন্ট মুছুন": confirm (with the optional Drive-backup checkbox), run
/// [AccountDeletionService] behind a blocking progress dialog, then report. On any
/// failure the device is left untouched and the message says so.
Future<void> runAccountDeletionFlow(
  BuildContext context,
  WidgetRef ref, {
  AccountDeletionService Function(WidgetRef ref)? serviceBuilder,
}) async {
  var alsoDeleteDrive = true;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setLocal) => Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.cardAll),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'অ্যাকাউন্ট মুছে ফেলবেন?',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: context.primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'আপনার অ্যাকাউন্ট, ক্লাউডে রাখা ব্যবহারের তথ্য এবং এই ফোনের সব ডেটা (খরচ, আয়, ধার-দেনা, ওয়ালেট, লক্ষ্য, বাজেট) স্থায়ীভাবে মুছে যাবে। এটি আর ফেরানো যাবে না।',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: context.secondaryTextColor,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  CheckboxListTile(
                    key: const Key('delete-account-drive-checkbox'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: alsoDeleteDrive,
                    onChanged: (value) =>
                        setLocal(() => alsoDeleteDrive = value ?? false),
                    title: Text(
                      'আমার Google Drive-এর ব্যাকআপগুলোও মুছুন',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.primaryTextColor,
                      ),
                    ),
                    subtitle: Text(
                      alsoDeleteDrive
                          ? 'ব্যাকআপ মুছে গেলে নতুন ফোনে ডেটা ফিরিয়ে আনা যাবে না।'
                          : 'ব্যাকআপ আপনার Drive-এ থেকে যাবে। চাইলে পরে আবার সাইন ইন করে মুছতে পারবেন।',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.secondaryTextColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppActionButton(
                    label: 'বাদ দিন',
                    variant: AppActionButtonVariant.ghost,
                    fullWidth: true,
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppActionButton(
                    key: const Key('delete-account-confirm'),
                    label: 'অ্যাকাউন্ট মুছুন',
                    variant: AppActionButtonVariant.danger,
                    fullWidth: true,
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
  if (confirmed != true || !context.mounted) {
    return;
  }

  // Blocking progress: this touches the network and must not be interrupted.
  final navigator = Navigator.of(context, rootNavigator: true);
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Dialog(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                SizedBox(width: AppSpacing.md),
                Flexible(child: Text('অ্যাকাউন্ট মোছা হচ্ছে…')),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  final result = await (serviceBuilder ?? buildAccountDeletionService)(
    ref,
  ).delete(deleteDriveBackup: alsoDeleteDrive);
  navigator.pop(); // the progress dialog
  if (!context.mounted) {
    return;
  }

  if (result.isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('অ্যাকাউন্ট ও সব ডেটা মুছে ফেলা হয়েছে')),
    );
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        result.cancelled ? 'অ্যাকাউন্ট মোছা হয়নি' : 'অ্যাকাউন্ট মোছা যায়নি',
      ),
      content: Text(
        '${result.message}\n\nআপনার ফোনের ডেটা যেমন ছিল তেমনই আছে; আবার চেষ্টা করতে পারেন।',
      ),
      actions: [
        AppActionButton(
          label: 'ঠিক আছে',
          variant: AppActionButtonVariant.ghost,
          size: AppActionButtonSize.small,
          onPressed: () => Navigator.of(dialogContext).pop(),
        ),
      ],
    ),
  );
}
