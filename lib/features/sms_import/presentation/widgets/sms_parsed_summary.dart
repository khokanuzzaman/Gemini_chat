import 'package:flutter/material.dart';

import '../../../../core/sms/parsed_transaction.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';

/// What an imported SMS shows instead of its text. The message itself is never
/// stored (privacy: see CONTRIBUTING "SMS bodies are not stored"), so this is the
/// parsed summary: sender, kind, amount, date and the reference when there is one.
class SmsParsedSummary extends StatelessWidget {
  const SmsParsedSummary({super.key, required this.transaction});

  final ParsedTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final tokens = context.tokens;
    final who = (t.counterparty?.trim().isNotEmpty ?? false)
        ? t.counterparty!.trim()
        : t.merchantName?.trim();
    final rows = <(String, String)>[
      ('প্রেরক', t.sender),
      ('ধরন', t.kind.labelBn),
      ('পরিমাণ', BanglaFormatters.currency(t.amount)),
      if (t.fee != null && t.fee! > 0)
        ('ফি', BanglaFormatters.currency(t.fee!)),
      if (t.balanceAfter != null)
        ('ব্যালেন্স', BanglaFormatters.currency(t.balanceAfter!)),
      if (who != null && who.isNotEmpty) ('কার সাথে', who),
      if (t.accountMask?.trim().isNotEmpty ?? false)
        ('অ্যাকাউন্ট', t.accountMask!.trim()),
      if (t.reference?.trim().isNotEmpty ?? false)
        ('রেফারেন্স', t.reference!.trim()),
      (
        'তারিখ ও সময়',
        '${BanglaFormatters.fullDate(t.occurredAt)} · ${BanglaFormatters.time(t.occurredAt)}',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.mutedSurfaceColor,
        borderRadius: const BorderRadius.all(AppRadius.card),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(
                      label,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: tokens.muted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SelectableText(
                      value,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.primaryTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'মূল মেসেজটি অ্যাপে সংরক্ষণ করা হয় না — শুধু এই তথ্যগুলো রাখা হয়।',
            style: AppTextStyles.bodySmall.copyWith(color: tokens.muted),
          ),
        ],
      ),
    );
  }
}
