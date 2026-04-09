import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_page_route.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/split_bill_entity.dart';
import '../providers/split_bill_provider.dart';
import '../utils/person_color.dart';
import '../widgets/split_suggestion_widget.dart';
import 'add_edit_split_screen.dart';

class SplitDetailScreen extends ConsumerWidget {
  const SplitDetailScreen({super.key, required this.splitId});

  final int splitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(splitBillReadyProvider);
    final splits = ref.watch(splitBillProvider);

    if (!ready) {
      return const AppPageScaffold(
        title: 'স্প্লিট',
        body: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(AppSpacing.screenPadding),
          child: AppLoadingState.list(),
        ),
      );
    }

    SplitBillEntity? split;
    for (final item in splits) {
      if (item.id == splitId) {
        split = item;
        break;
      }
    }

    if (split == null) {
      return const AppPageScaffold(
        title: 'স্প্লিট',
        body: AppErrorState(
          title: 'স্প্লিট খুঁজে পাওয়া যায়নি',
          message: 'এই split আর পাওয়া যাচ্ছে না',
        ),
      );
    }

    final currentSplit = split;
    final myPerson = _resolveMyPerson(currentSplit.persons);
    final myShare = myPerson?.shareAmount ?? 0;

    return AppPageScaffold(
      title: currentSplit.title,
      actions: [
        IconButton(
          onPressed: () {
            Navigator.of(context).push(
              AppSlideRoute(
                builder: (_) => AddEditSplitScreen(split: currentSplit),
              ),
            );
          },
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'সম্পাদনা',
        ),
        IconButton(
          onPressed: () => _confirmDelete(context, ref, currentSplit),
          icon: const Icon(Icons.delete_outline_rounded),
          tooltip: 'মুছুন',
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.md,
          AppSpacing.screenPadding,
          AppSpacing.xl,
        ),
        children: [
          AppHeroCard(
            label: 'মোট স্প্লিট',
            amount: BanglaFormatters.preciseCurrency(currentSplit.totalAmount),
            subtitle:
                '${BanglaFormatters.count(currentSplit.persons.length)} জন · ${BanglaFormatters.fullDate(currentSplit.date)}',
            icon: Icons.call_split_rounded,
            gradient: currentSplit.isSettled
                ? AppGradients.success
                : AppGradients.primary,
            trailing: AppChip(
              label: currentSplit.isSettled ? 'সম্পন্ন' : 'সক্রিয়',
              color: currentSplit.isSettled
                  ? AppColors.success
                  : AppColors.warning,
              compact: true,
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          const AppSectionHeader(title: 'ব্যক্তিভিত্তিক হিসাব'),
          const SizedBox(height: AppSpacing.sm),
          ...[
            for (
              var index = 0;
              index < currentSplit.persons.length;
              index++
            ) ...[
              _PersonBreakdownCard(
                person: currentSplit.persons[index],
                index: index,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
          if (currentSplit.settlements.isNotEmpty &&
              !currentSplit.isSettled) ...[
            const AppSectionHeader(title: 'সেটেলমেন্ট সাজেশন'),
            const SizedBox(height: AppSpacing.sm),
            ...[
              for (final settlement in currentSplit.settlements) ...[
                SplitSuggestionCard(settlement: settlement),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ],
          if (myPerson != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppCard(
              elevation: 1,
              child: _MyShareCardContent(
                myShare: myShare,
                onSave: myShare > 0
                    ? () => _saveAsExpense(context, ref, currentSplit, myShare)
                    : null,
              ),
            ),
          ],
          if (!currentSplit.isSettled) ...[
            const SizedBox(height: AppSpacing.md),
            AppActionButton(
              label: 'সব পরিশোধ হয়ে গেছে',
              icon: Icons.check_circle_outline_rounded,
              variant: AppActionButtonVariant.success,
              fullWidth: true,
              onPressed: () => _markSettled(context, ref, currentSplit.id),
            ),
          ],
          if (currentSplit.notes != null &&
              currentSplit.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            AppCard(
              elevation: 1,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.note_outlined,
                    size: 18,
                    color: context.secondaryTextColor,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      currentSplit.notes!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.primaryTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  SplitPerson? _resolveMyPerson(List<SplitPerson> persons) {
    for (final person in persons) {
      if (person.name.trim() == 'আমি') {
        return person;
      }
    }
    if (persons.isEmpty) {
      return null;
    }
    return persons.first;
  }

  Future<void> _markSettled(
    BuildContext context,
    WidgetRef ref,
    int splitId,
  ) async {
    await ref.read(splitBillProvider.notifier).markSettled(splitId);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('স্প্লিট সম্পন্ন হয়েছে')));
  }

  Future<void> _saveAsExpense(
    BuildContext context,
    WidgetRef ref,
    SplitBillEntity split,
    double myShare,
  ) async {
    final error = await ref
        .read(splitBillProvider.notifier)
        .saveMyShareAsExpense(
          split: split,
          myShare: myShare,
          category: split.category,
        );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'আমার অংশ expense হিসেবে save হয়েছে')),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SplitBillEntity split,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('স্প্লিট মুছবেন?'),
          content: Text('“${split.title}” স্থায়ীভাবে মুছে যাবে।'),
          actions: [
            AppActionButton(
              label: 'না',
              variant: AppActionButtonVariant.ghost,
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            AppActionButton(
              label: 'মুছুন',
              variant: AppActionButtonVariant.danger,
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }
    await ref.read(splitBillProvider.notifier).deleteSplit(split.id);
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('স্প্লিট মুছে গেছে')));
  }
}

class _MyShareCardContent extends StatelessWidget {
  const _MyShareCardContent({required this.myShare, required this.onSave});

  final double myShare;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final amountInfo = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'আমার অংশ',
              style: AppTextStyles.titleMedium.copyWith(
                color: context.primaryTextColor,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              BanglaFormatters.preciseCurrency(myShare),
              style: AppTextStyles.heroAmount.copyWith(
                color: context.primaryTextColor,
                fontSize: 28,
              ),
            ),
          ],
        );

        final saveButton = AppActionButton(
          label: 'Expense হিসেবে save করুন',
          icon: Icons.receipt_long_rounded,
          variant: AppActionButtonVariant.secondary,
          onPressed: onSave,
        );

        if (constraints.maxWidth < 420) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              amountInfo,
              const SizedBox(height: AppSpacing.md),
              SizedBox(width: double.infinity, child: saveButton),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: amountInfo),
            const SizedBox(width: AppSpacing.md),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: saveButton,
            ),
          ],
        );
      },
    );
  }
}

class _PersonBreakdownCard extends StatelessWidget {
  const _PersonBreakdownCard({required this.person, required this.index});

  final SplitPerson person;
  final int index;

  @override
  Widget build(BuildContext context) {
    final isPositive = person.balance >= 0;
    final tint = isPositive ? AppColors.success : AppColors.error;

    return AppCard(
      elevation: 1,
      child: AppListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: PersonColor.getColor(index),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            person.name.isEmpty ? '?' : person.name[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: person.name,
        subtitle:
            'ভাগ ${BanglaFormatters.preciseCurrency(person.shareAmount)} · দিয়েছে ${BanglaFormatters.preciseCurrency(person.amountPaid)}',
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isPositive ? 'ফেরত পাবে' : 'দিতে হবে',
              style: AppTextStyles.bodySmall.copyWith(
                color: tint,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              BanglaFormatters.preciseCurrency(person.balance.abs()),
              style: AppTextStyles.titleMedium.copyWith(color: tint),
            ),
          ],
        ),
      ),
    );
  }
}
